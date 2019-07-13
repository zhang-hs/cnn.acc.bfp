// ---------------------------------------------------
// File       : conv.c
//
// Description: compare data, conv layer directC
//
// Version    : 1.0
// ---------------------------------------------------

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include"DirectC.h"
#include<cblas.h>
#include<math.h>

union val{
  float fVal;
  unsigned char ucVal[sizeof(float)];
};
#define atomicHeight        14
#define atomicWidth         14
#define convRamHeight       16
#define convRamWidth        16
#define microPatchHeight    14
#define microPatchWidth     7
#define micro3PatchSize     14*7*3 // size of 3 micro-patch
#define micro2PatchSize     14*7*2 // size of 2 micro-patch
#define micro1PatchSize     14*7*1 // size of 1 micro-patch
#define procRamWidth    3*7 + 1 // processing ram width
#define procRamHeight   14+1 // processing ram height - 1 pel (top row)
#define ddrDataWidth    64
#define floatNumWidth   32
#define fmHeight   14 // <-x
#define fmWidth    14 // <-x
#define kerChannels  32
#define kerWidth   3
#define kerHeight  3
#define channels   512 // number of bottom channels // <-x
#define biasNUM    512 // number of top channels
#define biasMax    512
#define epsilonError  14.0  // 5_3 -> 8.0, 4-3 -> 14.0, 4_1 -> 32.0, 3_3 -> 32.0, 3_2 -> 16.0, 3_1 -> 16.0, 2_2 -> 16.0, 2_1 -> 12.0, 1_2 -> 4.0 , 1_1 -> 4.0
#define relativeError 0.15  // 5_3 -> 0.2, 4-3 -> 0.15, 4_1 -> 0.25, 3_3 -> 0.25, 3_2 -> 0.25, 3_1 -> 0.25, 2_2 -> 0.25, 2_1 -> 0.15, 1_2 -> 0.1 , 1_1 -> 0.1
#define absError      3.6   // 5_3 -> 2.0, 4-3 -> 3.6 , 4_1 -> 6.8 , 3_3 -> 6.8 , 3_2 -> 4.7 , 3_1 -> 4.7 , 2_2 -> 4.7 , 2_1 -> 2.3 , 1_2 -> 0.45, 1_1 -> 0.4
#define channelNum biasNUM
#define fmSize     (fmHeight*fmWidth*sizeof(union val)) // fmHeight*fmWidth*floatNumWidth/ddrDataWidth;
#define kerSize    (kerChannels*kerWidth*kerHeight*sizeof(union val))
#define numKerSet  2 // number of ker_set

// float point adder
void fp_adder(U aValid, U aData, U bValid, U bData, U* resultValid, U* resultData)
{
  if(aValid && bValid) {
    float A, B, result;
    memcpy(&A, &aData, sizeof(float));
    memcpy(&B, &bData, sizeof(float));
    *resultValid = 1;
    result = A + B;
    memcpy(resultData, &result, sizeof(float));
  }
}

// float point multiplier
void fp_mul(U aValid, U aData, U bValid, U bData, U* resultValid, U* resultData)
{
  if(aValid && bValid) {
    float A, B, result;
    memcpy(&A, &aData, sizeof(float));
    memcpy(&B, &bData, sizeof(float));
    *resultValid = 1;
    result = A * B;
    memcpy(resultData, &result, sizeof(float));
  }
}

// open file with file name
void* getFileDescriptor(char *fileName)
{
  FILE *fd = NULL;
  printf("file name: %s\n", fileName);
  fd = fopen(fileName, "r");
  if(fd <= 0){
    printf("could not open file: %s\n", fileName);
  } else {
    printf("%s opened\n", fileName);
  }
  return((void*)fd);
}

// close opened file
void closeFile(void *fileDescriptor)
{
  int status;
  status = fclose((FILE*) fileDescriptor);
  if(status == 0) {
    printf("file colsed with no error\n");
  } else {
    printf("file colsed with ERROR\n");
  }
  return;
}

int readFloatNum(void *fileDescriptor, U* const fVal)
{
  size_t ulCheck;
  union val fRead, fIntermediate;
  ulCheck = fread((void*)fVal, 1, sizeof(union val), (FILE*)fileDescriptor);
  if(ulCheck != sizeof(union val)){
    printf("(readFloatNum in conv.c) read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  return((int)ulCheck);
}

void cvt2Short(unsigned int floatData, unsigned short* pShortFloat)
{
  unsigned int contentVerilog, signVerilog, expVerilog;
  contentVerilog  = floatData & 0x7fffffff;
  signVerilog     = floatData & 0x80000000;
  expVerilog      = floatData & 0x7f800000;

  contentVerilog  >>= 13;
  signVerilog     >>= 16;
  contentVerilog  -= 0x1c000;

  contentVerilog  = (expVerilog < 0x38800000) ? 0 : contentVerilog;
  contentVerilog  = (expVerilog > 0x47000000) ? 0x7fff : contentVerilog;

  contentVerilog |= signVerilog;
  // *pShortFloat = (unsigned short) contentVerilog;
  memcpy(pShortFloat, &contentVerilog, sizeof(unsigned short));
}

//convert 16-bit floating point array to 32-bit floating point array
void convertFpH2Fp(U* pFpH, U* pFp, U arrayNum)
{
  void* pvCurFpH = pFpH;
  const unsigned short* pCurFpH = pvCurFpH;
  U*       pCurFp = pFp;

  for(int i=0; i<arrayNum; i++)
  {
    unsigned int t1;
    unsigned int t2;
    unsigned int t3;
    unsigned short curData = *pCurFpH;

    t1 = curData & 0x7fff;
    t2 = curData & 0x8000;
    t3 = curData & 0x7c00;

    t1 <<= 13; // 10-bits to 23-bits
    t2 <<= 16; // sign of 16-bit to 32-bit positin

    t1 += 0x38000000; // ajdust bias
    t1 = (t3 == 0) ? 0 : t1;

    t1 |= t2;

    *pCurFp = t1;
    
    pCurFp ++;
    pCurFpH ++;
  }
}

void shortCvt2Float(unsigned short shortData, float* pFloat)
{
  unsigned int xContent, xSign, xExp;
  xContent  = shortData & 0x7fff;
  xSign     = shortData & 0x8000;
  xExp      = shortData & 0x7c00;
  xContent <<= 13;
  xSign    <<= 16;
  if(xExp==0x7c00){
    xContent  += 0x7fffffff;
  } else {
    xContent  += 0x38000000;
    xContent  = (xExp==0) ? 0 : xContent;
  }
  xContent  |= xSign;
  memcpy(pFloat, &xContent, sizeof(unsigned int));
}

void shortCvt2UInt(unsigned short shortData, unsigned int* pUInt)
{
  unsigned int xContent, xSign, xExp;
  xContent  = shortData & 0x7fff;
  xSign     = shortData & 0x8000;
  xExp      = shortData & 0x7c00;
  xContent <<= 13;
  xSign    <<= 16;
  if(xExp==0x7c00){
    xContent  += 0x7fffffff;
  } else {
    xContent  += 0x38000000;
    xContent  = (xExp==0) ? 0 : xContent;
  }
  xContent  |= xSign;
  memcpy(pUInt, &xContent, sizeof(unsigned int));
}

int readFloatcvt16bit(void *fileDescriptor, U* pShortFloat)
{
  size_t ulCheck;
  unsigned int uiFloatData;
  void * vpShortFloat = pShortFloat;
  ulCheck = fread(&uiFloatData, 1, sizeof(unsigned int), (FILE*) fileDescriptor);
  if(ulCheck != sizeof(unsigned int)){
    printf("(readFloatNum in conv.c) read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  cvt2Short(uiFloatData, (unsigned short*)vpShortFloat);
//printf("data read: %.8x %.4x\n", uiFloatData, *pShortFloat);
  return((int)ulCheck);
}

void printProcRam(U* RAM, U procRamFull)
{
  union val *pRam = (union val*)RAM;
  pRam += (convRamHeight*convRamWidth-1);
  if(procRamFull){
    for(int i=0; i<convRamHeight; i++){
      for(int j=0; j<convRamWidth; j++){
        for(int k=0; k<sizeof(union val); k++)
          printf("%.2x", pRam->ucVal[sizeof(union val)-1-k]);
        printf("_");
        --pRam;
      }
      printf("\n");
    }
  }
}

void readProcRam(void* fileDescriptor, U readBottomData, U ithFM,
                  U xPos, U yPos, U xEndPos, U yEndPos, U* procRam)
{
  union val* pRam = (union val*) procRam;
  union val ram_[convRamHeight*fmWidth]={0};
  long  offset = 0;
  if(readBottomData){
    if(yPos==0) {
      offset += (0+ithFM*fmSize);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      if(yPos==yEndPos) { // 14x14
        fread(&(ram_[0])+fmWidth, sizeof(union val), (convRamHeight-2)*fmWidth, (FILE*)fileDescriptor);
      } else {
        fread(&(ram_[0])+fmWidth, sizeof(union val), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor);
      }
    } else if(yPos==yEndPos) {
      offset += (ithFM*fmSize + sizeof(union val)*(yPos*atomicHeight-1)*fmWidth);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(union val), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor);
    } else {
      offset += (ithFM*fmSize + sizeof(union val)*(yPos*atomicHeight-1)*fmWidth);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(union val), convRamHeight*fmWidth, (FILE*)fileDescriptor);
    }

    if(xPos==0){
      for(int i=0; i<convRamHeight; i++)
        pRam[i*convRamWidth].fVal = 0.;
      if(xPos==xEndPos)
        for(int i=0; i<convRamHeight; i++)
          pRam[i*convRamWidth+convRamWidth-1].fVal = 0.;
    //printf("before assignment\n");
      for(int i=0; i<convRamHeight; i++){
        if(xPos==xEndPos) {
          memcpy(pRam+i*convRamWidth+1, ram_+ i*fmWidth, sizeof(union val)*(convRamWidth-2));
        } else {
          memcpy(pRam+i*convRamWidth+1, ram_+ i*fmWidth, sizeof(union val)*(convRamWidth-1));
        }
      //for(int j=0; j<convRamWidth-1; i++){
      //  pRam[i*convRamWidth + j+1] = ram_[i*fmWidth + j];
      //}
      }
    //printf("after assignment\n");
    } else if(xPos==xEndPos){
      for(int i=0; i<convRamHeight; i++)
        pRam[convRamWidth-1 + i*convRamWidth].fVal = 0.;
      for(int i=0; i<convRamHeight; i++){
        memcpy(pRam+i*convRamWidth, ram_+i*fmWidth+xPos*atomicWidth-1, sizeof(union val)*(convRamWidth-1));
      //for(int j=0; j<convRamWidth-1; j++){
      //  pRam[i*convRamWidth + j] = ram_[i*fmWidth + xPos*atomicWidth-1 + j];
      //}
      }
    } else {
      for(int i=0; i<convRamHeight; i++){
        memcpy(pRam+i*convRamWidth, ram_+i*fmWidth+xPos*atomicWidth-1, sizeof(union val)*convRamWidth);
      //for(int j=0; j<convRamWidth; j++){
      //  pRam[i*convRamWidth + j] = ram_[i*fmWidth + xPos*atomicWidth-1 + j];
      //}
      }
    }
    // display error position ram data
    if(xPos == 15 && yPos == 1) {
      printf(".at position x: %d, y: %d, fm channel num: %d\n", xPos, yPos, ithFM);
      for(int i=0; i<convRamHeight; i++) {
        printf(".");
        for(int j=0; j<convRamWidth; j++) {
          printf("%.8x ", pRam[i*convRamWidth + j]);
        }
        printf("\n");
      }
    }
  }
}

U cmpRam_32bitData(U cmpEnable, U* ramDirectC, U* ramVerilog)
{
  int checkPass = 0;
  unsigned int* pRamDirectC = (unsigned int*) ramDirectC;
  unsigned int* pRamVerilog = (unsigned int*) ramVerilog;
  unsigned int error = 0;
  pRamVerilog += (convRamHeight*convRamWidth-1);
  if(cmpEnable) {
    for(int i=0; i<convRamHeight*convRamWidth; i++) {
      if((*pRamDirectC) > (*pRamVerilog))
        error = (*pRamDirectC) - (*pRamVerilog);
      else
        error = (*pRamVerilog) - (*pRamDirectC);

      if(error > 0x007fffff) {
        printf(">23 bit error of %d-th procRam, value: %.8x, true value: %.8x\n", i, *pRamVerilog, *pRamDirectC);
        checkPass = 1;
      }
      pRamDirectC++;
      pRamVerilog--;
    }
    if(error > 0x0000ffff) {
      pRamVerilog = (unsigned int*) ramVerilog;
      pRamDirectC = (unsigned int*) ramDirectC;
      pRamVerilog += (convRamHeight*convRamWidth-1);
      printf("directC:\n");
      for(int i=0; i<convRamHeight; i++) {
        for(int j=0; j<convRamWidth; j++) {
          printf("%.4x ", *pRamDirectC);
          pRamDirectC++;
        }
        printf("\n");
      }
      printf("verilog:\n");
      for(int i=0; i<convRamHeight; i++) {
        for(int j=0; j<convRamWidth; j++) {
          printf("%.4x ", *pRamVerilog);
          pRamVerilog--;
        }
        printf("\n");
      }
    }
  }
  return(checkPass);
}

U cmpRam(U cmpEnable, U* ramDirectC, U* ramVerilog)
{
  int checkPass = 0;
  void *vPointer;
  vPointer  = ramDirectC;
  unsigned int* pRamDirectC = (unsigned int*) vPointer;
  unsigned short ram_[convRamHeight*convRamWidth];
  unsigned short *pRam = &ram_[0];
  for(int i=0; i<convRamHeight; i++) {
    for(int j=0; j<convRamWidth; j++) {
      cvt2Short(*pRamDirectC, &(ram_[i*convRamHeight + j]));
      pRamDirectC++;
    }
  }
  vPointer = ramVerilog;
  unsigned short* pRamVerilog = (unsigned short*) vPointer;
  unsigned short* pRamCheck = (unsigned short*) vPointer;
  unsigned short error = 0;
  pRamVerilog += (convRamHeight*convRamWidth-1);
  pRamCheck   += (convRamHeight*convRamWidth-1);
  if(cmpEnable) {
  //for(int i=0; i<convRamHeight; i++) {
  //  printf(".");
  //  for(int j=0; j<convRamWidth; j++) {
  //    printf("%.4x ", ram_[i*convRamWidth + j]);
  //  }
  //  printf("\n");
  //}
    printf(".in conv.c, cmpRam, ramVerilog\n");
    for(int i=0; i<convRamHeight; i++) {
      printf(".");
      for(int j=0; j<convRamWidth; j++) {
        printf("%.4x ", *pRamCheck);
        pRamCheck--;
      }
      printf("\n");
    }
    for(int i=0; i<convRamHeight*convRamWidth; i++) {
      if((*pRam) > (*pRamVerilog))
        error = (*pRam) - (*pRamVerilog);
      else
        error = (*pRamVerilog) - (*pRam);

      if(error > 0x07ff) {
        printf(">23 bit error of %d-th procRam, value: %.8x, true value: %.8x\n", i, *pRamVerilog, *pRam);
        checkPass = 1;
      }
      pRam++;
      pRamVerilog--;
    }
    if(checkPass) {
      vPointer  = ramVerilog;
      pRamVerilog = (unsigned short*) vPointer;
      pRam  = &ram_[0];
      pRamVerilog += (convRamHeight*convRamWidth-1);
      printf("directC:\n");
      for(int i=0; i<convRamHeight; i++) {
        for(int j=0; j<convRamWidth; j++) {
          printf("%.4x ", *pRam);
          pRam++;
        }
        printf("\n");
      }
      printf("verilog:\n");
      for(int i=0; i<convRamHeight; i++) {
        for(int j=0; j<convRamWidth; j++) {
          printf("%.4x ", *pRamVerilog);
          pRamVerilog--;
        }
        printf("\n");
      }
    }
  }
  if(!checkPass)  printf("patch data check passed\n");
  else            printf("patch data check FAILED\n");
  return(checkPass);
}

void readProcKer(void* fileDescriptor, U readKerData, U ithKer, U* procKer)
{
  void *pvKer = procKer;
  union val* pKer = pvKer;
  union val ker_[kerChannels*kerWidth*kerHeight] = {0};
  int ith = ithKer/kerChannels;
  long offset = biasNUM*sizeof(union val); // bias offset: numOfBias*sizeof(union val), conv1_1 bias number
  if(readKerData){
    offset += (ith*kerChannels*kerWidth*kerHeight*sizeof(union val));
    fseek((FILE*)fileDescriptor, offset, SEEK_SET);
    fread((&ker_[0]), sizeof(union val), kerChannels*kerWidth*kerHeight, (FILE*) fileDescriptor);
    memcpy(pKer, ker_, kerChannels*kerWidth*kerHeight*sizeof(union val));
  //// display kernel data
  //if(ithKer == 32 || ithKer == 96 || ithKer == 160) {
  //  printf(". %d-th set kernel data\n", ithKer);
  //  for(int i=0; i<kerHeight; i++) { // row
  //    printf(".");
  //    for(int j=0; j<kerWidth; j++) {
  //      printf("%.8x ", ker_[22*kerHeight*kerWidth + i*kerWidth + j]);
  //    }
  //    printf("\n");
  //  }
  //}
  }
  printf("ker data read\n");
}

U cmpKer32bit(U cmpKerEnable, U* kerDirectC, U* kerVerilog)
{
  int checkPass = 0;
  unsigned int* pKerDirectC = (unsigned int*)kerDirectC;
  unsigned int* pKerVerilog = (unsigned int*)kerVerilog;
  unsigned int error = 0;
  pKerVerilog += (kerChannels*kerHeight*kerWidth-1);
  if(cmpKerEnable) {
    for(int i=0; i<kerChannels*kerHeight*kerWidth; i++) {
      if((*pKerDirectC) > (*pKerVerilog))
        error = (*pKerDirectC) - (*pKerVerilog);
      else
        error = (*pKerVerilog) - (*pKerDirectC);

      if(error>1) {
        printf(">1 bit error of %d-th procKer, value: %.8x, true value: %.8x\n", i, *pKerVerilog, *pKerDirectC);
        checkPass = 1;
      }
      pKerDirectC++;
      pKerVerilog--;
    }
  }
  return(checkPass);
}

U cmpKer(U cmpKerEnable, U* kerDirectC, U* kerVerilog)
{
  int checkPass = 0;
  void * vPointer;
  vPointer = kerDirectC;
  unsigned int* pKerDirectC = (unsigned int*)vPointer;
  unsigned short kerRam_[kerChannels*kerWidth*kerHeight];
  for(int i=0; i<kerChannels; i++) {
    for(int j=0; j<kerHeight; j++) {
      for(int k=0; k<kerWidth; k++) {
        cvt2Short(*pKerDirectC, &kerRam_[i*kerWidth*kerHeight + j*kerWidth + k]);
        pKerDirectC++;
      }
    }
  }
  unsigned short error = 0;
  vPointer  = kerVerilog;
  unsigned short* pKerVerilog = (unsigned short*)vPointer;
  unsigned short* pKer = &kerRam_[0];
  pKerVerilog += (kerChannels*kerHeight*kerWidth-1);
  if(cmpKerEnable) {
    for(int i=0; i<kerChannels*kerHeight*kerWidth; i++) {
      if((*pKer) > (*pKerVerilog))
        error = (*pKer) - (*pKerVerilog);
      else
        error = (*pKerVerilog) - (*pKer);

      if(error>1) {
        printf(">1 bit error of %d-th procKer, value: %.8x, true value: %.8x\n", i, *pKerVerilog, *pKer);
        checkPass = 1;
      }
      pKer++;
      pKerVerilog--;
    }
  }
  if(!checkPass)  printf("kernel data check passed\n");
  else            printf("kernel data check FAILED\n");
  return(checkPass);
}

void readProcBias(void* fileDescriptor, U readBiasData, U* procBias)
{
  union val* pBias = (union val*)procBias;
  union val bias_[biasNUM];
  long offset = 0;
  if(readBiasData){
    offset += 0;
    fseek((FILE*) fileDescriptor, offset, SEEK_SET);
    fread((&bias_[0]), sizeof(union val), biasNUM, (FILE*) fileDescriptor);
    memcpy(pBias, bias_, biasNUM*sizeof(union val));
  //printf(".directC bias read:\n");
  //printf(".");
  //for(int i=0; i<biasNUM; i++)
  //  printf("%.8x ", bias_[i]);
  }
}

U cmpBias32bit(U cmpBiasEnable, U* biasDirectC, U* biasVerilog)
{
  int checkPass = 0;
  unsigned int* pBiasDirectC = (unsigned int*)biasDirectC;
  unsigned int* pBiasVerilog = (unsigned int*)biasVerilog;
  unsigned int error = 0;
  if(cmpBiasEnable) {
  //for(int i=0; i<biasMax; i++){
  //  printf("%d: verilog bias: %8.8x\n", i, *pBiasVerilog);
  //  pBiasVerilog++;
  //}
    pBiasVerilog += (biasMax-1);
    for(int i=0; i<biasNUM; i++){
      if((*pBiasDirectC) > (*pBiasVerilog))
        error = (*pBiasDirectC) - (*pBiasVerilog);
      else
        error = (*pBiasVerilog) - (*pBiasDirectC);
      
      if(error>1) {
        printf(">1 bit error of %d-th procBias, value: %.8x, true value: %.8x\n", i, *pBiasVerilog, *pBiasDirectC);
        checkPass = 1;
      }
      pBiasDirectC++;
      pBiasVerilog--;
    }
  }
  return(checkPass);
}

U cmpBias(U cmpBiasEnable, U* biasDirectC, U* biasVerilog)
{
  int checkPass = 0;
  void * vPointer;
  vPointer  = biasDirectC;
  unsigned int* pBiasDirectC = (unsigned int*)vPointer;
  unsigned short biasRam_[biasNUM];
  for(int i=0; i<biasNUM; i++) {
    cvt2Short(*pBiasDirectC, &biasRam_[i]);
    pBiasDirectC++;
  }
  vPointer = biasVerilog;
  unsigned short* pBiasVerilog = (unsigned short*)vPointer;
  unsigned short* pBias = &biasRam_[0];
  unsigned short error = 0;
  if(cmpBiasEnable) {
  //for(int i=0; i<biasMax; i++){
  //  printf("%d: verilog bias: %8.8x\n", i, *pBiasVerilog);
  //  pBiasVerilog++;
  //}
    pBiasVerilog += (biasMax-1);
    for(int i=0; i<biasNUM; i++){
      if((*pBias) > (*pBiasVerilog))
        error = (*pBias) - (*pBiasVerilog);
      else
        error = (*pBiasVerilog) - (*pBias);
      
      if(error>1) {
        printf(">1 bit error of %d-th procBias, value: %.4x, true value: %.4x\n", i, *pBiasVerilog, *pBias);
        checkPass = 1;
      }
      pBias++;
      pBiasVerilog--;
    }
  }
  return(checkPass);
}

// conv operation
void rearrangeRamData(U rearrangeEn, U* procPatch, U* procRam)
{
  union val* pPatch = (union val*)procPatch;
  union val* pDst = (union val*) procRam;
  if(rearrangeEn) {
    // read data from fData into fPatch
    for(int k_r=0; k_r<kerHeight; k_r++){
      for(int k_c=0; k_c<kerWidth; k_c++){
        for(int p_c=0; p_c<atomicWidth; p_c++){
          for(int p_r=0; p_r<atomicHeight; p_r++){
            memcpy(&pDst[k_r*kerWidth+k_c + (p_c*atomicHeight+p_r)*kerHeight*kerWidth], &pPatch[(convRamHeight*convRamWidth-1) - (p_c+k_c+ (p_r+k_r)*convRamWidth)], sizeof(union val));
          }
        }
      }
    }
  //float* pfDst = (float*)pDst;
  //for(int i=0; i<atomicHeight*atomicWidth; i++) {
  //  printf("%3d: ", i);
  //  for(int j=0; j<kerHeight*kerWidth; j++)
  //    printf("%8.8x ", pDst[j + i*kerHeight*kerWidth]);
  //  //printf("%8.8x %5.3f ", pDst[j + i*kerHeight*kerWidth], pfDst[j + i*kerHeight*kerWidth]);
  //  printf("\n");
  //}
  }
}

void rearrangeKerData(U rearrangeEn, U* procKer, U* procBlasKer)
{
  union val* pVerilogKer= (void*)procKer;
  union val* pBlasKer   = (void*)procBlasKer;
  pVerilogKer += kerChannels*kerHeight*kerWidth-1;
  for(int i=0; i<kerChannels*kerHeight*kerWidth; i++){
    memcpy(pBlasKer, pVerilogKer, sizeof(union val));
    pBlasKer++;
    pVerilogKer--;
  }
//pBlasKer=(void*)procBlasKer;
//printf("ker data:\n");
//for(int i=0; i<kerChannels; i++) {
//  printf("%3d: ", i);
//  for(int j=0; j<kerHeight*kerWidth; j++)
//    printf("%8.8x ", pBlasKer[j + i*kerHeight*kerWidth]);
//  printf("\n");
//}
}

// correlation
U cmpCnnCorr(U* pData, U* pWeight, U* pVerilogOutput, U convX, U convY, U* pMaxError)
{
  void* vpBlasData= pData; // void pointer
  void* vpWeight  = pWeight;
  void* vpVerilog = pVerilogOutput;
  void* vpMaxError= pMaxError;
  float afCnn[kerChannels];
  float* fpBlasData= vpBlasData;
  float* fpWeight  = vpWeight;
  void* vpCnn = afCnn;
  unsigned int* uipCnn = vpCnn;
  unsigned int* uipCheckOutput = pVerilogOutput;
  unsigned int* uipMaxError = vpMaxError;
//for(int i=0; i<atomicHeight*atomicWidth; i++){
//  printf("%3d: ", i);
//  for(int j=0; j<kerHeight*kerWidth; j++){
//    printf("%8.8x ", (union val)fpBlasData[j + i*kerHeight*kerWidth]);
//  }
//  printf("\n");
//}
//printf("address offset: %d\n", (convX*atomicHeight + convY)*kerHeight*kerWidth);
  fpBlasData += (convX*atomicHeight + convY)*kerHeight*kerWidth;
  int iM = 1; //atomicHeight*atomicWidth;
  int iN = kerChannels;
  int iK = kerHeight*kerWidth;
  int iLDA=iK, iLDB=iK, iLDC=iN;
  unsigned int uiError = 0;
  float fError = 0.;
  float* f0 = 0;
  float* f1 = 0;
  float fAlpha=1.0, fBeta=0.;
  cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasTrans, iM, iN, iK, fAlpha, fpBlasData, iLDA, fpWeight, iLDB, fBeta, afCnn, iLDC);
//printf("conv data:\n");
//for(int i=0; i<kerHeight*kerWidth; i++)
//  printf("%8x ", (union val)fpBlasData[i]);
//printf("\n");
//printf("conv ker:\n");
//for(int i=0; i<kerHeight*kerWidth; i++)
//  printf("%8x ", (union val)fpWeight[i]);
//printf("\n");

  for(int i=0; i<kerChannels; i++){
    if(uipCnn[i] > uipCheckOutput[32-1-i]){
      f0 = (void*)&uipCnn[i];
      f1 = (void*)&uipCheckOutput[32-1-i];
    //memcpy(&f0, &uipCnn[i], sizeof(float));
    //memcpy(&f1, &uipCheckOutput[32-1-i], sizeof(float));
      uiError = (uipCnn[i] - uipCheckOutput[32-1-i]);
      fError  = (*f0) - (*f1);
    }else{
      f0 = (void*)&uipCheckOutput[32-1-i];
      f1 = (void*)&uipCnn[i];
    //memcpy(&f0, &uipCnn[i], sizeof(float));
    //memcpy(&f1, &uipCheckOutput[32-1-i], sizeof(float));
      uiError = (uipCheckOutput[32-1-i] - uipCnn[i]);
      fError  = (*f0) - (*f1);
    }
    if(*uipMaxError < uiError){
      *uipMaxError = uiError;
    //printf("verilog: %8x, directC: %8x, uiError= %8x, fError=%8.6f, at x: %d, y: %d\n", uipCheckOutput[32-1-i], uipCnn[i], uiError, fError, convX, convY);
    }
  //if((int)(log2(uiError)+1)>11) // print convolution error
  //  printf("%3d: cblas: %8.8x, verilog: %8.8x, uiError = %8x, uiError bits: %3.1f\n", i, uipCnn[i], uipCheckOutput[32-1-i], uiError, log2(uiError));
  }
  if(uiError>1)
    return(1); // check failed
  else
    return(0);
}

U cmpTop32bit(U cmpTopEn, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U* verilogResult, U* pMaxError)
{
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned int directCResult[channelNum*atomicHeight*atomicWidth]={0};
  void *pvVerilog = verilogResult;
  void *pvMaxError= pMaxError;
  union val* pVerilog = pvVerilog;
  unsigned int* uipVerilog = pvVerilog;
  unsigned int uiError;
  unsigned int *uipMaxError= pvMaxError;
  float* f0, *f1;
  int   iDirectCAtF0 = 0;
  unsigned int uiCheckNotPass = 0;
  unsigned int uiPrintPos     = 0;
  // read top data from file
  int patchOffset, offset;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = 0;
    for(int i=0; i<channelNum; i++) {
      offset = fmHeight/2*fmWidth/2*i + patchOffset;
      for(int j=0; j<atomicHeight/2; j++) {
        fseek(pFOrigTop, offset*sizeof(union val), SEEK_SET);
        fread(&directCResult[j*atomicWidth/2 + i*atomicHeight/2*atomicWidth/2], sizeof(union val), atomicWidth/2, pFOrigTop);
        offset += fmWidth/2;
      }
    }
    // comparison
    if(cmpTopEn){
      for(int i=0; i<channelNum; i++){
        for(int r=0; r<atomicHeight/2; r++) {
          for(int c=0; c<atomicWidth/2; c++) {
            if(directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c] > uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)]){
              uiError = directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c] - uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f0 = (void*)&directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
              f1 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              iDirectCAtF0 = 1;
            }else{
              uiError = uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)] - directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
              f0 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f1 = (void*)&directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
              iDirectCAtF0 = 0;
            }
            // check error
            if(((iDirectCAtF0==1) && ((*f0) < epsilonError)) || ((iDirectCAtF0==0) && ((*f1) < epsilonError))){
              if(((iDirectCAtF0==1) && (fabs(*f1)>(10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(*f0)> (10*epsilonError)))) {
                uiCheckNotPass  = 1;
                uiPrintPos      = 1;
              } else {
                uiPrintPos      = 0;
              }
            } else {
              if(iDirectCAtF0==1) {
                if(fabs((*f0)-(*f1))/(*f0) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              } else {
                if(fabs((*f0)-(*f1))/(*f1) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              }
            }
            if(uiPrintPos) {
              printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f\n", i, r, c,
                          uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                          directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1), fabs((*f0)-(*f1))/(*f0), fabs((*f0)-(*f1))/(*f1));
            //printf("*directC fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
            //  }
            //  printf("\n");
            //}
            //printf("*verilog fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
            //  }
            //  printf("\n");
            //}
            }
          }
        }
      //// inspection
      //printf("-directC fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
      //  }
      //  printf("\n");
      //}
      //printf("-verilog fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
      //  }
      //  printf("\n");
      //}
      }
    }
    printf("top data(with pooling) comparison end\n");
    return(uiCheckNotPass);
  } else {
  // without pooling
    patchOffset = posX*atomicWidth + posY*atomicHeight*fmWidth;
    offset = 0;
    for(int i=0; i<channelNum; i++) {
      offset = fmHeight*fmWidth*i + patchOffset;
      for(int j=0; j<atomicHeight; j++) {
        fseek(pFOrigTop, offset*sizeof(union val), SEEK_SET);
        fread(&directCResult[j*atomicWidth + i*atomicHeight*atomicWidth], sizeof(union val), atomicWidth, pFOrigTop);
        offset += fmWidth;
      }
    }
    // comparison
    if(cmpTopEn){
      for(int i=0; i<channelNum; i++){
        for(int r=0; r<atomicHeight; r++) {
          for(int c=0; c<atomicWidth; c++) {
            if(directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c] > uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)]){
              uiError = directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c] - uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f0 = (void*)&directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
              f1 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              iDirectCAtF0 = 1;
            }else{
              uiError = uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)] - directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
              f0 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f1 = (void*)&directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
              iDirectCAtF0 = 0;
            }
            // check error
            if(((iDirectCAtF0==1) && ((*f0) < epsilonError)) || ((iDirectCAtF0==0) && ((*f1) < epsilonError))){
              if(((iDirectCAtF0==1) && (fabs(*f1)> (10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(*f0)> (10*epsilonError)))) {
                uiCheckNotPass  = 1;
                uiPrintPos      = 1;
              } else {
                uiPrintPos      = 0;
              }
            } else {
              if(iDirectCAtF0==1) {
                if(fabs((*f0)-(*f1))/(*f0) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              } else {
                if(fabs((*f0)-(*f1))/(*f1) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              }
            }
            if(uiPrintPos) {
              printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f\n", i, r, c,
                          uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                          directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1), fabs((*f0)-(*f1))/(*f0), fabs((*f0)-(*f1))/(*f1));
            //printf("*directC fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
            //  }
            //  printf("\n");
            //}
            //printf("*verilog fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
            //  }
            //  printf("\n");
            //}
            }
          //printf("top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n", i, r, c,
          //            uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
          //            directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1));
          }
        }
      //// inspection
      //printf("-directC fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
      //  }
      //  printf("\n");
      //}
      //printf("-verilog fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
      //  }
      //  printf("\n");
      //}
      }
    }
    printf("top data(without pooling) comparison end\n");
    return(uiCheckNotPass);
  }
}

U cmpTop(U cmpTopEn, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U* verilogResult, U* pMaxError)
{
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned short directCResult[channelNum*atomicHeight*atomicWidth]={0};
  unsigned int topRam_[channelNum*atomicHeight*atomicWidth]={0};
  void *pvVerilog = verilogResult;
  void *pvMaxError= pMaxError;
  union val* pVerilog = pvVerilog;
  unsigned int* uipVerilog = pvVerilog;
  unsigned int uiError;
  unsigned int *uipMaxError= pvMaxError;
  float* f0, *f1;
  int   iDirectCAtF0 = 0;
  unsigned int uiCheckNotPass = 0;
  unsigned int uiPrintPos     = 0;
  // read top data from file
  int patchOffset, offset;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = 0;
    for(int i=0; i<channelNum; i++) {
      offset = fmHeight/2*fmWidth/2*i + patchOffset;
      for(int j=0; j<atomicHeight/2; j++) {
        fseek(pFOrigTop, offset*sizeof(union val), SEEK_SET);
        fread(&topRam_[j*atomicWidth/2 + i*atomicHeight/2*atomicWidth/2], sizeof(union val), atomicWidth/2, pFOrigTop);
        offset += fmWidth/2;
      }
    }
    // convert to 16bit
    for(int i=0; i<channelNum; i++) {
      for(int j=0; j<atomicHeight/2; j++) {
        for(int k=0; k<atomicWidth/2; k++) {
          cvt2Short(topRam_[i*atomicHeight/2*atomicWidth/2 + j*atomicWidth/2 + k], &directCResult[i*atomicHeight/2*atomicWidth/2 + j*atomicWidth/2 + k]);
        }
      }
    }
    // comparison
    if(cmpTopEn){
      for(int i=0; i<channelNum; i++){
        for(int r=0; r<atomicHeight/2; r++) {
          for(int c=0; c<atomicWidth/2; c++) {
            if(directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c] > uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)]){
              uiError = directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c] - uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f0 = (void*)&directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
              f1 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              iDirectCAtF0 = 1;
            }else{
              uiError = uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)] - directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
              f0 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f1 = (void*)&directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
              iDirectCAtF0 = 0;
            }
            // check error
            if(((iDirectCAtF0==1) && ((*f0) < epsilonError)) || ((iDirectCAtF0==0) && ((*f1) < epsilonError))){
            //if(((iDirectCAtF0==1) && (fabs(*f1)>(10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(*f0)> (10*epsilonError)))) {
              if(fabs((*f0)-(*f1)) > absError ) {
                uiCheckNotPass  = 1;
                uiPrintPos      = 1;
              } else {
                uiPrintPos      = 0;
              }
            } else {
              if(iDirectCAtF0==1) {
                if(fabs((*f0)-(*f1))/(*f0) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              } else {
                if(fabs((*f0)-(*f1))/(*f1) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              }
            }
            if(uiPrintPos) {
              printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f\n", i, r, c,
                          uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                          directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1), fabs((*f0)-(*f1))/(*f0), fabs((*f0)-(*f1))/(*f1));
            //printf("*directC fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
            //  }
            //  printf("\n");
            //}
            //printf("*verilog fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
            //  }
            //  printf("\n");
            //}
            }
          }
        }
      //// inspection
      //printf("-directC fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
      //  }
      //  printf("\n");
      //}
      //printf("-verilog fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
      //  }
      //  printf("\n");
      //}
      }
    }
    printf("top data(with pooling) comparison end\n");
    return(uiCheckNotPass);
  } else {
  // without pooling
    patchOffset = posX*atomicWidth + posY*atomicHeight*fmWidth;
    offset = 0;
    for(int i=0; i<channelNum; i++) {
      offset = fmHeight*fmWidth*i + patchOffset;
      for(int j=0; j<atomicHeight; j++) {
        fseek(pFOrigTop, offset*sizeof(union val), SEEK_SET);
        fread(&directCResult[j*atomicWidth + i*atomicHeight*atomicWidth], sizeof(union val), atomicWidth, pFOrigTop);
        offset += fmWidth;
      }
    }
    // convert to 16bit
    for(int i=0; i<channelNum; i++) {
      for(int j=0; j<atomicHeight; j++) {
        for(int k=0; k<atomicWidth; k++) {
          cvt2Short(topRam_[i*atomicHeight*atomicWidth + j*atomicWidth + k], &directCResult[i*atomicHeight*atomicWidth + j*atomicWidth + k]);
        }
      }
    }
    // comparison
    if(cmpTopEn){
      for(int i=0; i<channelNum; i++){
        for(int r=0; r<atomicHeight; r++) {
          for(int c=0; c<atomicWidth; c++) {
            if(directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c] > uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)]){
              uiError = directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c] - uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f0 = (void*)&directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
              f1 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              iDirectCAtF0 = 1;
            }else{
              uiError = uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)] - directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
              f0 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
              f1 = (void*)&directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
              iDirectCAtF0 = 0;
            }
            // check error
            if(((iDirectCAtF0==1) && ((*f0) < epsilonError)) || ((iDirectCAtF0==0) && ((*f1) < epsilonError))){
            //if(((iDirectCAtF0==1) && (fabs(*f1)> (10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(*f0)> (10*epsilonError)))) {
              if(fabs((*f0)-(*f1)) > absError ) {
                uiCheckNotPass  = 1;
                uiPrintPos      = 1;
              } else {
                uiPrintPos      = 0;
              }
            } else {
              if(iDirectCAtF0==1) {
                if(fabs((*f0)-(*f1))/(*f0) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              } else {
                if(fabs((*f0)-(*f1))/(*f1) > relativeError) {
                  uiCheckNotPass  = 1;
                  uiPrintPos      = 1;
                } else {
                  uiPrintPos      = 0;
                }
              }
            }
            if(uiPrintPos) {
              printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f\n", i, r, c,
                          uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                          directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1), fabs((*f0)-(*f1))/(*f0), fabs((*f0)-(*f1))/(*f1));
            //printf("*directC fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
            //  }
            //  printf("\n");
            //}
            //printf("*verilog fm data:\n");
            //for(int ir=0; ir<atomicHeight; ir++){
            //  printf("*");
            //  for(int ic=0; ic<atomicWidth; ic++){
            //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
            //  }
            //  printf("\n");
            //}
            }
          //printf("top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n", i, r, c,
          //            uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
          //            directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1));
          }
        }
      //// inspection
      //printf("-directC fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
      //  }
      //  printf("\n");
      //}
      //printf("-verilog fm data:\n");
      //for(int ir=0; ir<atomicHeight; ir++){
      //  printf("-");
      //  for(int ic=0; ic<atomicWidth; ic++){
      //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
      //  }
      //  printf("\n");
      //}
      }
    }
    printf("top data(without pooling) comparison end\n");
    return(uiCheckNotPass);
  }
}

U cmp7x7output32bit(U cmp7x7En, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U quarterIdx, U channelIdx, U* verilogOutputData)
{
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned int directCResult[49]={0};
  void *pvVerilog = verilogOutputData;
  union val* pVerilog = pvVerilog;
  unsigned int* uipVerilog = pvVerilog;
  unsigned int uiError;
  float* f0, *f1;
  unsigned int uiCheckNotPass = 0;
  unsigned int uiPrintPos     = 0;
  int   iDirectCAtF0 = 0;
  // read top data from file
  int patchOffset, offset;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = fmHeight/2*fmWidth/2*channelIdx + patchOffset;
    printf("channel: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, patchOffset, posX, posY);
    // read data
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(int j=0; j<atomicHeight/2; j++){
      fread(&directCResult[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth/2;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    }
    printf("comparison with pooling\n");
  } else {
  // without pooling
    // quarter index
    if(quarterIdx==0) {
      patchOffset = posX*atomicWidth + posY*atomicHeight*fmWidth;
      printf("at 0, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==1){
      patchOffset = (posX*atomicWidth + atomicWidth/2) + posY*atomicHeight*fmWidth;
      printf("at 1, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==2){
      patchOffset = posX*atomicWidth + (posY*atomicHeight + atomicHeight/2)*fmWidth;
      printf("at 2, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==3){
      patchOffset = (posX*atomicWidth + atomicWidth/2) + (posY*atomicHeight + atomicHeight/2)*fmWidth;
      printf("at 3, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    }
    printf("quarterIdx: %d, patchOffset: %d\n", quarterIdx, patchOffset);
    offset = fmHeight*fmWidth*channelIdx + patchOffset;
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(int j=0; j<atomicHeight/2; j++) {
      fread(&directCResult[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    //printf("patchOffset: %d\n", patchOffset);
    }
    printf("comparison without pooling\n");
  }
  // comparison
  if(cmp7x7En){
    for(int r=0; r<atomicHeight/2; r++) {
      for(int c=0; c<atomicWidth/2; c++) {
        if(directCResult[r*atomicWidth/2 + c] > uipVerilog[7*7-1 - (r*atomicWidth/2+c)]) {
          uiError = (directCResult[r*atomicWidth/2 + c] - uipVerilog[7*7-1 - (r*atomicWidth/2+c)]);
          f0  = (void*)&directCResult[r*atomicWidth/2 + c];
          f1  = (void*)&uipVerilog[7*7-1 - (r*atomicWidth/2+c)];
          iDirectCAtF0 = 1;
        } else {
          uiError = (uipVerilog[7*7-1 - (r*atomicWidth/2+c)] - directCResult[r*atomicWidth/2 + c]);
          f0  = (void*)&uipVerilog[7*7-1 - (r*atomicWidth/2+c)];
          f1  = (void*)&directCResult[r*atomicWidth/2 + c];
          iDirectCAtF0 = 0;
        }
        // check error
        if(((iDirectCAtF0==1) && ((*f0) < epsilonError)) || ((iDirectCAtF0==0) && ((*f1) < epsilonError))){
          if(((iDirectCAtF0==1) && (fabs(*f1)>(10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(*f0)> (10*epsilonError)))) {
            uiCheckNotPass  = 1;
            uiPrintPos      = 1;
          } else {
            uiPrintPos      = 0;
          }
        } else {
          if(iDirectCAtF0==1) {
            if(fabs((*f0)-(*f1))/(*f0) > relativeError) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          } else {
            if(fabs((*f0)-(*f1))/(*f1) > relativeError) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          }
        }
        if(uiPrintPos) {
          printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f\n", channelIdx, r, c,
                      uipVerilog[7*7-1- (r*atomicWidth/2 + c)],
                      directCResult[r*atomicWidth/2 + c], (*f0)-(*f1), fabs((*f0)-(*f1))/(*f0), fabs((*f0)-(*f1))/(*f1));
        }
      }
    }
    // inspection
    printf("-directC fm data:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.8x ", directCResult[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
    printf("-verilog fm data:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.8x ", uipVerilog[7*7-1 - (ir*atomicWidth/2 + ic)]);
      }
      printf("\n");
    }
  }
  return(uiCheckNotPass);
}

U cmp7x7output_version1(U cmp7x7En, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U quarterIdx, U channelIdx, U* verilogOutputData)
{
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned int topRam_[49]={0};
  unsigned short directCResult[49]={0};
  void *pvVerilog = verilogOutputData;
  unsigned short* uipVerilog = pvVerilog;
  unsigned short uiError;
  float f0, f1;
  unsigned int uiCheckNotPass = 0;
  unsigned int uiPrintPos     = 0;
  int   iDirectCAtF0 = 0;
  // read top data from file
  int patchOffset, offset;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = fmHeight/2*fmWidth/2*channelIdx + patchOffset;
    printf("channel: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, patchOffset, posX, posY);
    // read data
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(int j=0; j<atomicHeight/2; j++){
      fread(&topRam_[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth/2;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    }
    for(int i=0; i<49; i++) {
      cvt2Short(topRam_[i], &directCResult[i]);
    }
    printf("comparison with pooling\n");
  } else {
  // without pooling
    // quarter index
    if(quarterIdx==0) {
      patchOffset = posX*atomicWidth + posY*atomicHeight*fmWidth;
      printf("at 0, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==1){
      patchOffset = (posX*atomicWidth + atomicWidth/2) + posY*atomicHeight*fmWidth;
      printf("at 1, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==2){
      patchOffset = posX*atomicWidth + (posY*atomicHeight + atomicHeight/2)*fmWidth;
      printf("at 2, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==3){
      patchOffset = (posX*atomicWidth + atomicWidth/2) + (posY*atomicHeight + atomicHeight/2)*fmWidth;
      printf("at 3, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    }
    printf("quarterIdx: %d, patchOffset: %d\n", quarterIdx, patchOffset);
    offset = fmHeight*fmWidth*channelIdx + patchOffset;
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(int j=0; j<atomicHeight/2; j++) {
      fread(&topRam_[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    //printf("patchOffset: %d\n", patchOffset);
    }
    for(int i=0; i<49; i++) {
      cvt2Short(topRam_[i], &directCResult[i]);
    }
    printf("comparison without pooling\n");
  }
  // comparison
  if(cmp7x7En){
    for(int r=0; r<atomicHeight/2; r++) {
      for(int c=0; c<atomicWidth/2; c++) {
        if(directCResult[r*atomicWidth/2 + c] > uipVerilog[7*7-1 - (r*atomicWidth/2+c)]) {
          uiError = (directCResult[r*atomicWidth/2 + c] - uipVerilog[7*7-1 - (r*atomicWidth/2+c)]);
          shortCvt2Float(directCResult[r*atomicWidth/2 + c], &f0);
          shortCvt2Float(uipVerilog[7*7-1 - (r*atomicWidth/2+c)], &f1);
          iDirectCAtF0 = 1;
        } else {
          uiError = (uipVerilog[7*7-1 - (r*atomicWidth/2+c)] - directCResult[r*atomicWidth/2 + c]);
          shortCvt2Float(uipVerilog[7*7-1 - (r*atomicWidth/2+c)], &f0);
          shortCvt2Float(directCResult[r*atomicWidth/2 + c], &f1);
          iDirectCAtF0 = 0;
        }
        // check error
        if(((iDirectCAtF0==1) && ((f0) < epsilonError)) || ((iDirectCAtF0==0) && ((f1) < epsilonError))){
          if(((iDirectCAtF0==1) && (fabs(f1)>(10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(f0)> (10*epsilonError)))) {
            uiCheckNotPass  = 1;
            uiPrintPos      = 1;
          } else {
            uiPrintPos      = 0;
          }
        } else {
          if(iDirectCAtF0==1) {
            if(fabs((f0)-(f1))/(f0) > relativeError) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          } else {
            if(fabs((f0)-(f1))/(f1) > relativeError) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          }
        }
        if(uiPrintPos) {
          printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f\n", channelIdx, r, c,
                      uipVerilog[7*7-1- (r*atomicWidth/2 + c)],
                      directCResult[r*atomicWidth/2 + c], (f0)-(f1), fabs((f0)-(f1))/(f0), fabs((f0)-(f1))/(f1));
        }
      }
    }
    // inspection
    printf("-directC fm data:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.4x ", directCResult[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
    printf("-verilog fm data:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.4x ", uipVerilog[7*7-1 - (ir*atomicWidth/2 + ic)]);
      }
      printf("\n");
    }
  }
  return(uiCheckNotPass);
}

U cmp7x7output(U cmp7x7En, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U quarterIdx, U channelIdx, U* verilogOutputData)
{
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned int outputData_[49]={0};
  unsigned int directCResult[49]={0};
  void *pvVerilog = verilogOutputData;
  unsigned short* uipVerilog = pvVerilog;
  unsigned int uiError;
  float f0, f1;
  unsigned int uiCheckNotPass = 0;
  unsigned int uiPrintPos     = 0;
  int   iDirectCAtF0 = 0;
  // read top data from file
  int patchOffset, offset;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = fmHeight/2*fmWidth/2*channelIdx + patchOffset;
    printf("channel: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, patchOffset, posX, posY);
    // read data
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(int j=0; j<atomicHeight/2; j++){
      fread(&directCResult[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth/2;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    }
    // convert short float data from verilogData
    for(int i=0; i<49; i++) {
      shortCvt2UInt(uipVerilog[i], &outputData_[i]);
    }
    printf("comparison with pooling\n");
  } else {
  // without pooling
    // quarter index
    if(quarterIdx==0) {
      patchOffset = posX*atomicWidth + posY*atomicHeight*fmWidth;
      printf("at 0, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==1){
      patchOffset = (posX*atomicWidth + atomicWidth/2) + posY*atomicHeight*fmWidth;
      printf("at 1, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==2){
      patchOffset = posX*atomicWidth + (posY*atomicHeight + atomicHeight/2)*fmWidth;
      printf("at 2, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    } else if(quarterIdx==3){
      patchOffset = (posX*atomicWidth + atomicWidth/2) + (posY*atomicHeight + atomicHeight/2)*fmWidth;
      printf("at 3, channel: %d, quarterIdx: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, quarterIdx, patchOffset, posX, posY);
    }
    printf("quarterIdx: %d, patchOffset: %d\n", quarterIdx, patchOffset);
    offset = fmHeight*fmWidth*channelIdx + patchOffset;
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(int j=0; j<atomicHeight/2; j++) {
      fread(&directCResult[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    //printf("patchOffset: %d\n", patchOffset);
    }
    // convert short float data from verilogData
    for(int i=0; i<49; i++) {
      shortCvt2UInt(uipVerilog[i], &outputData_[i]);
    }
    printf("comparison without pooling\n");
  }
  // comparison
  if(cmp7x7En){
    for(int r=0; r<atomicHeight/2; r++) {
      for(int c=0; c<atomicWidth/2; c++) {
        if(directCResult[r*atomicWidth/2 + c] > outputData_[7*7-1 - (r*atomicWidth/2+c)]) {
          uiError = (directCResult[r*atomicWidth/2 + c] - outputData_[7*7-1 - (r*atomicWidth/2+c)]);
          memcpy(&f0, &directCResult[r*atomicWidth/2 + c], sizeof(unsigned int));
          memcpy(&f1, &outputData_[7*7-1 - (r*atomicWidth/2+c)], sizeof(unsigned int));
          iDirectCAtF0 = 1;
        } else {
          uiError = (outputData_[7*7-1 - (r*atomicWidth/2+c)] - directCResult[r*atomicWidth/2 + c]);
          memcpy(&f0, &outputData_[7*7-1 - (r*atomicWidth/2+c)], sizeof(unsigned int));
          memcpy(&f1, &directCResult[r*atomicWidth/2 + c], sizeof(unsigned int));
          iDirectCAtF0 = 0;
        }
        // check error
        if(((iDirectCAtF0==1) && ((f0) < epsilonError)) || ((iDirectCAtF0==0) && ((f1) < epsilonError))){
          if(((iDirectCAtF0==1) && (fabs(f1)>(10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(f0)> (10*epsilonError)))) {
            uiCheckNotPass  = 1;
            uiPrintPos      = 1;
          } else {
            uiPrintPos      = 0;
          }
        } else {
          if(iDirectCAtF0==1) {
            if(fabs((f0)-(f1))/(f0) > relativeError) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          } else {
            if(fabs((f0)-(f1))/(f1) > relativeError) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          }
        }
        if(uiPrintPos) {
          printf("relative *top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f, f0: %.8f, f1: %.8f\n", channelIdx, r, c,
                      outputData_[7*7-1- (r*atomicWidth/2 + c)], directCResult[r*atomicWidth/2 + c], (f0)-(f1), fabs((f0)-(f1))/(f0), fabs((f0)-(f1))/(f1), (f0), (f1));
        }
      }
    }
    // inspection
    printf("-directC fm data:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.8x ", directCResult[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
    printf("-verilog fm data:\n");
    printf("32 bit:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.8x ", outputData_[7*7-1 - (ir*atomicWidth/2 + ic)]);
      }
      printf("\n");
    }
    printf("16 bit:\n");
    for(int ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for(int ic=0; ic<atomicWidth/2; ic++){
        printf("%.4x ", uipVerilog[7*7-1 - (ir*atomicWidth/2 + ic)]);
      }
      printf("\n");
    }
  }
  return(uiCheckNotPass);
//return(0);
}
