// ---------------------------------------------------
// File       : conv.c
//
// Description: compare data, conv layer directC
//
// Version    : 1.0
// ---------------------------------------------------

#include<stdio.h>
#include<stdlib.h>
#include"DirectC.h"
#include<cblas.h>
#include<math.h>

union val{
  float fVal;
  unsigned char ucVal[sizeof(float)];
};

//const int atomicHeight      = 14;
//const int atomicWidth       = 14;
//const int convRamHeight     = 16;
//const int convRamWidth      = 16;
//const int microPatchHeight  = 14;
//const int microPatchWidth   = 7;
//const int micro3PatchSize   = 14*7*3; // size of 3 micro-patch
//const int micro2PatchSize   = 14*7*2; // size of 2 micro-patch
//const int micro1PatchSize   = 14*7*1; // size of 1 micro-patch
//const int procRamWidth  = 3*7 + 1; // processing ram width
//const int procRamHeight = 14+1; // processing ram height - 1 pel (top row)
//const int ddrDataWidth  = 64;
//const int floatNumWidth = 32;
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
#define fmHeight   224
#define fmWidth    224
#define kerChannels  32
#define kerWidth   3
#define kerHeight  3
#define channels   3 // number of bottom channels
#define fmSize     (fmHeight*fmWidth*sizeof(union val)) // fmHeight*fmWidth*floatNumWidth/ddrDataWidth;
#define kerSize    (kerChannels*kerWidth*kerHeight*sizeof(union val))
#define numKerSet  2 // number of ker_set

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
//ulCheck = fread((void*)&fRead, 1, sizeof(union val), (FILE*)fileDescriptor);
//// rearrange byte position
//for(int i=0; i<sizeof(union val); i++)
//  fIntermediate.ucVal[i] = fRead.ucVal[sizeof(union val)-1-i];

//memcpy(fVal, (void*)&fIntermediate, sizeof(union val));
  if(ulCheck != sizeof(union val)){
    printf("read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  return((int)ulCheck);
}

void printProcRam(U* RAM, U procRamFull)
{
//const int convRamHeight = 16;
//const int convRamWidth  = 16;
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
//const int fmHeight  = 224;
//const int fmWidth   = 224;
//const int kerChannels = 32;
//const int kerWidth  = 3;
//const int kerHeight = 3;
//const int channels  = 3; // number of bottom channels
//const int fmSize    = fmHeight*fmWidth*sizeof(union val); // fmHeight*fmWidth*floatNumWidth/ddrDataWidth;
//const int kerSize   = kerChannels*kerWidth*kerHeight*sizeof(union val);
//const int numKerSet = 2; // number of ker_set
//*barOffset  = 1568; // fmWidth*atomicHeight*floatNumWidth/ddrDataWidth;
  union val ram_[convRamHeight*fmWidth]={0};
  long  offset = 0;
  if(readBottomData){
    if(yPos==0) {
      offset += (0+ithFM*fmSize);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
    //printf("before read\n");
      fread(&(ram_[0])+fmWidth, sizeof(union val), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor);
    //printf("after read\n");
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
    //printf("before assignment\n");
      for(int i=0; i<convRamHeight; i++){
        memcpy(pRam+i*convRamWidth+1, ram_+ i*fmWidth, sizeof(union val)*(convRamWidth-1));
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
  //printf("data read by using directC:\n");
  //for(int i=0; i<convRamHeight; i++){
  //  for(int j=0; j<convRamWidth; j++)
  //    printf("%.8x_", pRam[i*convRamWidth + j]);
  //  printf("\n");
  //}
  }
}

U cmpRam(U cmpEnable, U* ramDirectC, U* ramVerilog)
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

      if(error > 0x000fffff) {
        printf(">20 bit error of %d-th procRam, value: %.8x, true value: %.8x error: %.8x\n", i, *pRamVerilog, *pRamDirectC, error);
        checkPass = 1;
      }
      pRamDirectC++;
      pRamVerilog--;
    }
  }
  return(checkPass);
}

void readProcKer(void* fileDescriptor, U readKerData, U ithKer, U* procKer)
{
#define biasNUM 64 // conv1_1 bias number
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
  }
  printf("ker data read\n");
}

U cmpKer(U cmpKerEnable, U* kerDirectC, U* kerVerilog)
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

void readProcBias(void* fileDescriptor, U readBiasData, U* procBias)
{
#define biasNUM 64 // conv1_1 bias number
  union val* pBias = (union val*)procBias;
  union val bias_[biasNUM];
  long offset = 0;
  if(readBiasData){
    offset += 0;
    fseek((FILE*) fileDescriptor, offset, SEEK_SET);
    fread((&bias_[0]), sizeof(union val), biasNUM, (FILE*) fileDescriptor);
    memcpy(pBias, bias_, biasNUM*sizeof(union val));
  }
}

U cmpBias(U cmpBiasEnable, U* biasDirectC, U* biasVerilog)
{
#define biasNUM 64 // conv1_1 bias number
#define biasMax 512
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

// conv operation
void rearrangeRamData(U rearrangeEn, U* procPatch, U* procRam)
{
  union val* pPatch = (union val*)procPatch;
//pPatch += (convRamHeight*convRamWidth-1);
  union val* pDst = (union val*) procRam;
  if(rearrangeEn) {
    // read data from fData into fPatch
    for(int k_r=0; k_r<kerHeight; k_r++){
      for(int k_c=0; k_c<kerWidth; k_c++){
        for(int p_c=0; p_c<atomicWidth; p_c++){
          for(int p_r=0; p_r<atomicHeight; p_r++){
          //fPatch[(k_r*ker_width+k_c)*patch_height*patch_width + p_c*patch_height + p_r] // ker_height*ker_width x patch_height*patch_width
          //pDst[k_r*kerWidth+k_c + (p_c*atomicHeight+p_r)*kerHeight*kerWidth] // patch_height*patch_width x ker_height*ker_widta
          //  = pPatch[p_c+k_c+ (p_r+k_r)*convRamWidth];
            memcpy(&pDst[k_r*kerWidth+k_c + (p_c*atomicHeight+p_r)*kerHeight*kerWidth], &pPatch[(convRamHeight*convRamWidth-1) - (p_c+k_c+ (p_r+k_r)*convRamWidth)], sizeof(union val));
          //memcpy(&pDst[k_r*kerWidth+k_c + (p_c*atomicHeight+p_r)*kerHeight*kerWidth], &pPatch[(p_c+k_c+ (p_r+k_r)*convRamWidth)], sizeof(union val));
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
//cnnCorr((float*)fCnnConv, (float*)fPatch, (float*)fWeight, patch_height*patch_width, ker_channels, ker_height*ker_width);
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
      printf("verilog: %8x, directC: %8x, uiError= %8x, fError=%8.6f\n", uipCheckOutput[32-1-i], uipCnn[i], uiError, fError);
    }
  //if((int)(log2(uiError)+1)>11)
  //  printf("%3d: cblas: %8.8x, verilog: %8.8x, uiError = %8x, uiError bits: %3.1f\n", i, uipCnn[i], uipCheckOutput[32-1-i], uiError, log2(uiError));
  }
  if(uiError>1)
    return(1); // check failed
  else
    return(0);
}

U cmpTopConv1_1(U cmpTopEn, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U* verilogResult, U* pMaxError)
//U cmpTop(U cmpTopEn, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U* verilogResult, U* pMaxError)
{
#define channelNum 64
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
  // read top data from file
  int patchOffset, offset;
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
  // check
//for(int i=0; i<channelNum; i++) {
//  printf("%3d-th channel:\n", i);
//  for(int r=0; r<atomicHeight; r++) {
//    for(int c=0; c<atomicWidth; c++)
//      printf("%8.8x ", directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c]);
//    printf("\n");
//  }
//}
//for(int i=0; i<channelNum; i++) {
//  printf("%3d-th channel:\n", i);
//  for(int r=0; r<atomicHeight; r++) {
//    for(int c=0; c<atomicWidth; c++) {
//      printf("%8.8x ", pVerilog[channelNum*atomicHeight*atomicWidth-1-(i*atomicHeight*atomicWidth + r*atomicWidth + c)]); //-(i*atomicHeight*atomicWidth + r*atomicWidth + c)
//    }
//    printf("\n");
//  }
//}
  // comparison
  if(cmpTopEn){
    for(int i=0; i<channelNum; i++){
      for(int r=0; r<atomicHeight; r++) {
        for(int c=0; c<atomicWidth; c++) {
          if(directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c] > uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)]){
            uiError = directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c] - uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
            f0 = (void*)&directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
            f1 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
          }else{
            uiError = uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)] - directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
            f0 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
            f1 = (void*)&directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c];
          }
          if(*uipMaxError < uiError){
            *uipMaxError = uiError;
            printf("maximum top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, uiError=%8.8x, fError=%8.6f\n", i, r, c,
                        uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                        directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], uiError, (*f0)-(*f1));
            printf("directC fm data:\n");
            for(int ir=0; ir<atomicHeight; ir++){
              for(int ic=0; ic<atomicWidth; ic++){
                printf("%.8x ", directCResult[i*atomicHeight*atomicWidth + ir*atomicWidth + ic]);
              }
              printf("\n");
            }
            printf("verilog fm data:\n");
            for(int ir=0; ir<atomicHeight; ir++){
              for(int ic=0; ic<atomicWidth; ic++){
                printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
              }
              printf("\n");
            }
          }
        //printf("top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n", i, r, c,
        //            uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
        //            directCResult[i*atomicHeight*atomicWidth + r*atomicWidth + c], (*f0)-(*f1));
        }
      }
    }
  }
  printf("top data(without pooling) comparison end\n");
  return(0);
}

//U cmpTopPool0(U cmpTopEn, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U* verilogResult, U* pMaxError)
U cmpTop(U cmpTopEn, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U* verilogResult, U* pMaxError)
{
#define channelNum 64
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned int directCResult[channelNum*(atomicHeight/2)*(atomicWidth/2)]={0};
  void *pvVerilog = verilogResult;
  void *pvMaxError= pMaxError;
  union val* pVerilog = pvVerilog;
  unsigned int* uipVerilog = pvVerilog;
  unsigned int uiError;
  int checkPass=0;
  unsigned int *uipMaxError= pvMaxError;
  float* f0, *f1;
  // read top data from file
  int patchOffset, offset;
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
          }else{
            uiError = uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)] - directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
            f0 = (void*)&uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)];
            f1 = (void*)&directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c];
          }
          if(*uipMaxError < uiError){
            *uipMaxError = uiError;
            printf("maximum top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n", i, r, c,
                        uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                        directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c], (*f0)-(*f1));
            printf("directC fm data:\n");
            for(int ir=0; ir<atomicHeight/2; ir++){
              for(int ic=0; ic<atomicWidth/2; ic++){
                printf("%.8x ", directCResult[i*atomicHeight/2*atomicWidth/2 + ir*atomicWidth/2 + ic]);
              }
              printf("\n");
            }
            printf("verilog fm data:\n");
            for(int ir=0; ir<atomicHeight; ir++){
              for(int ic=0; ic<atomicWidth; ic++){
                printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
              }
              printf("\n");
            }
          }
        //printf("top data error: channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n", i, r, c,
        //            uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
        //            directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c], (*f0)-(*f1));
          if(uiError>0x0000ffff) {
            printf(">16 bit error at channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n",  i, r, c,
                      uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                      directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c], (*f0)-(*f1));
            if(uiError>0x007fffff) {
              if(((*f0)-(*f1)) > 1.0) {
                checkPass = 1;
              } else {
                checkPass = 0;
              }
              printf(">20 bit error at channelNum: %8d, row: %8d, col: %8d, verilog: %8.8x, directC: %8.8x, fError=%8.6f\n",  i, r, c,
                        uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)],
                        directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c], (*f0)-(*f1));
            } else {
              checkPass = 0;
            }
            printf("directC fm data:\n");
            for(int ir=0; ir<atomicHeight/2; ir++){
              for(int ic=0; ic<atomicWidth/2; ic++){
                printf("%.8x ", directCResult[i*atomicHeight/2*atomicWidth/2 + ir*atomicWidth/2 + ic]);
              }
              printf("\n");
            }
            printf("verilog fm data:\n");
            for(int ir=0; ir<atomicHeight; ir++){
              for(int ic=0; ic<atomicWidth; ic++){
                printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + ir*atomicWidth + ic)]);
              }
              printf("\n");
            }
          }
        }
      }
    //printf("directC fm data:\n");
    //for(int r=0; r<atomicHeight/2; r++){
    //  for(int c=0; c<atomicWidth/2; c++){
    //    printf("%.8x ", directCResult[i*atomicHeight/2*atomicWidth/2 + r*atomicWidth/2 + c]);
    //  }
    //  printf("\n");
    //}
    //printf("verilog fm data:\n");
    //for(int r=0; r<atomicHeight; r++){
    //  for(int c=0; c<atomicWidth; c++){
    //    printf("%.8x ", uipVerilog[channelNum*atomicHeight*atomicWidth-1 - (i*atomicHeight*atomicWidth + r*atomicWidth + c)]);
    //  }
    //  printf("\n");
    //}
    }
  }
  printf("top data(with pooling) comparison end\n");
  return(checkPass);
}
