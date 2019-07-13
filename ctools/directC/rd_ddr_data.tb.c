// ---------------------------------------------------
// File       : rd_ddr_data.tb.c
//
// Description: rd_ddr_data.tb.v DirectC c file
//
// Version    : 1.0
// ---------------------------------------------------
#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<string.h>
#include"DirectC.h"
#include<math.h>

const int atomicHeight      = 14;
const int atomicWidth       = 14;
const int microPatchHeight  = 14;
const int microPatchWidth   = 7;
const int micro3PatchSize   = 14*7*3; // size of 3 micro-patch
const int micro2PatchSize   = 14*7*2; // size of 2 micro-patch
const int micro1PatchSize   = 14*7*1; // size of 1 micro-patch
const int procRamWidth  = 3*7 + 1; // processing ram width
const int procRamHeight = 14+1; // processing ram height - 1 pel (top row)
const int ddrDataWidth  = 64;
const int floatNumWidth = 32;

union val{
  float fVal;
  unsigned char ucVal[sizeof(float)];
};

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
// open file to write
void* wrFileDescriptor(char *fileName)
{
  FILE *fd = NULL;
  printf("file name: %s\n", fileName);
  fd = fopen(fileName, "w");
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

int read16bitNum(void *fileDescriptor, U* pShortFloat)
{
  size_t ulCheck;
  unsigned short uiFloatData;
  void * vpShortFloat = pShortFloat;
  ulCheck = fread(&uiFloatData, 1, sizeof(unsigned short), (FILE*) fileDescriptor);
  if(ulCheck != sizeof(unsigned short)){
    printf("(readFloatNum in conv.c) read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  memcpy(pShortFloat, &uiFloatData, sizeof(unsigned short));
//printf("data read: %.4x %.4x\n", uiFloatData, *pShortFloat);
  return((int)ulCheck);
}

int read8bitNum(void *fileDescriptor, U* pChar)
{
  size_t ulCheck;
  uint8_t uiCharData;
  void * vpChar = pChar;
  ulCheck = fread(&uiCharData, 1, sizeof(uint8_t), (FILE*) fileDescriptor);
  if(ulCheck != sizeof(uint8_t)){
    printf("(read8bitNum in conv.c) read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  memcpy(pChar, &uiCharData, sizeof(uint8_t));
//printf("data read: %.4x %.4x\n", uiFloatData, *pShortFloat);
  return((int)ulCheck);
}




//unused
//-----------------------------------------------------------------------
// read a float num
int readFloatNum(void *fileDescriptor, U* const fVal)
{
  size_t ulCheck;
//union val fRead, fIntermediate;
  ulCheck = fread((void*)fVal, 1, sizeof(union val), (FILE*)fileDescriptor);
//memcpy(fVal, (void*)&fIntermediate, sizeof(union val));
  if(ulCheck != sizeof(union val)){
    printf("read size: %lu != 1\n", ulCheck);
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
  int i;
  for(i=0; i<arrayNum; i++)
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



int read32and16bitNum(void *fileDescriptor, U* pFloat, U* pShortFloat)
{
  size_t ulCheck;
  unsigned int uiFloatData;
  //void * vpFloat = pFloat;
  void * vpShortFloat = pShortFloat;
  ulCheck = fread(&uiFloatData, 1, sizeof(unsigned int), (FILE*) fileDescriptor);
  if(ulCheck != sizeof(unsigned int)){
    printf("(readFloatNum in conv.c) read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  memcpy(pFloat, &uiFloatData, sizeof(unsigned int));
  cvt2Short(uiFloatData, (unsigned short*)vpShortFloat);
//printf("data read: %.8x %.4x\n", uiFloatData, *pShortFloat);
  return((int)ulCheck);
}



U cmp8bitData(U cmpEnable, U* ramDirectC, U* ramVerilog)
{
  int checkPass = 0;
  uint8_t* pRamDirectC = ( uint8_t*) ramDirectC;
  uint8_t* pRamVerilog = ( uint8_t*) ramVerilog;
  uint8_t error = 0;
  U error_sum = 0;
  int i,j;
  //pRamVerilog += (3*3-1);
  if(cmpEnable) {
      pRamVerilog = (uint8_t *) ramVerilog;
      pRamDirectC = (uint8_t *) ramDirectC;
      //pRamVerilog += (3*3-1);
      printf("fixed_directC:\n");
      for(i=0; i<1; i++) {
        for(j=0; j<6; j++) {
          printf("%4x\t", *pRamDirectC);
          pRamDirectC++;
        }
        printf("\n");
      }
      printf("fixed_verilog:\n");
      for(i=0; i<1; i++) {
        for(j=0; j<6; j++) {
          printf("%4x\t", *pRamVerilog);
          pRamVerilog++;
        }
        printf("\n");
      }

      //check for err
    pRamVerilog = (uint8_t *) ramVerilog;
    pRamDirectC = (uint8_t *) ramDirectC;
    printf("check err:\n");
    for(i=0; i<1; i++) {
        for(j=0; j<6; j++) {
            if((*pRamDirectC) > (*pRamVerilog))
                error = (*pRamDirectC) - (*pRamVerilog);
            else
                error = (*pRamVerilog) - (*pRamDirectC);

            printf("%4x\t",error);
            error_sum += error;

            pRamDirectC++;
            pRamVerilog++;
            }
       printf("\n");
       }
    printf("error_sum:%x\n",error_sum);
    }
  return(error_sum);
}

U cmp32bitData(U cmpEnable, U* ramDirectC, U* ramVerilog)
{
  int checkPass = 0;
  unsigned int* pRamDirectC = (unsigned int*) ramDirectC;
  unsigned* pRamVerilog = (unsigned int*) ramVerilog;
  unsigned int error = 0;
  int i,j;
  //pRamVerilog += (3*3-1);
  if(cmpEnable) {
    printf("check err:\n");
    for(i=0; i<3; i++) {
        for(j=0; j<3; j++) {
            if((*pRamDirectC) > (*pRamVerilog))
                error = (*pRamDirectC) - (*pRamVerilog);
            else
                error = (*pRamVerilog) - (*pRamDirectC);

            if(error > 0x7f) {
                printf("err\t");
                checkPass = 1;
            }
        pRamDirectC++;
        pRamVerilog--;
        printf("\n");
       }
    }

    if(1) {
      pRamVerilog = (unsigned int *) ramVerilog;
      pRamDirectC = (unsigned int *) ramDirectC;
      int i,j;
      //pRamVerilog += (3*3-1);
      printf("directC:\n");
      for(i=0; i<3; i++) {
        for(j=0; j<3; j++) {
          printf("%x ", *pRamDirectC);
          pRamDirectC++;
        }
        printf("\n");
      }
      printf("verilog:\n");
      for(i=0; i<3; i++) {
        for(j=0; j<3; j++) {
          printf("%x ", *pRamVerilog);
          pRamVerilog++;
        }
        printf("\n");
      }
    }
  }
  return(checkPass);
}

void write2File(void* fileDescriptor, U wrEnable, U wrOffset, const U* const wrData)
{
  unsigned int Offset;
  Offset = wrOffset*8;
  if(wrEnable) {
    fseek((FILE*)fileDescriptor, Offset, SEEK_SET);
    fwrite(wrData, 64, sizeof(char), (FILE*)fileDescriptor);
  }
  return;
}

// filling procRAM
/*
void readProcRam(void *fileDescriptor, U readBottomData, U xPos, U yPos, U xEndPos, U yEndPos, U barOffset, U ithOffset)
{
  union val procRAM[22*15] = {0}; // processing memory
  union val *p = procRAM;

  long lIthOffset = ithOffset*sizeof(union val);
  long lBarOffset = barOffset*sizeof(union val);
  long lOffset;
  printf("(x,y): (%.4d, %4d)\n", xPos, yPos);
  if(readBottomData) {
    // read patch
    if(xPos == 0) {
      lOffset = lIthOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight)*sizeof(union val);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(int i=0; i<micro3PatchSize; i++)
        fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
    } else if(xPos == xEndPos) {
      lOffset = lIthOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight - micro1PatchSize)*sizeof(union val);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(int i=0; i<micro1PatchSize; i++)
        fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
    } else {
      lOffset = lIthOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight + xPos*atomicWidth*atomicHeight + micro1PatchSize)*sizeof(union val);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(int i=0; i<micro2PatchSize; i++)
        fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
    }

    // read padding
    int numOfMicroPatch;
    if(xPos==0)
      numOfMicroPatch = 3;
    else if( xPos==xEndPos)
      numOfMicroPatch = 1;
    else
      numOfMicroPatch = 2;

    if(yPos != yEndPos) {
      if(xPos == 0) {
      //lOffset = lIthOffset + lBarOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight)*sizeof(union val);
        lOffset = lIthOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight)*sizeof(union val);
      } else if(xPos == xEndPos) {
      //lOffset = lIthOffset + lBarOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight - micro1PatchSize)*sizeof(union val);
        lOffset = lIthOffset + ((xEndPos+1)*(yPos+2)*atomicWidth*atomicHeight - micro1PatchSize)*sizeof(union val);
      } else {
      //lOffset = lIthOffset + lBarOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight + xPos*atomicWidth*atomicHeight + micro1PatchSize)*sizeof(union val);
        lOffset = lIthOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight + xPos*atomicWidth*atomicHeight + micro1PatchSize)*sizeof(union val);
      }
      for(int n=0; n<numOfMicroPatch; n++){
        fseek(fileDescriptor, lOffset, SEEK_SET);
        for(int i=0; i<microPatchWidth; i++)
          fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
        lOffset += micro1PatchSize*sizeof(union val);
      }
    }

    // print
    int posOnMicroPatch1; // current position on micro patch
    int microPatchStride;
    printf("procRAM content:\n");
    // print patch
    posOnMicroPatch1 = 0;
    for(int h=0; h<procRamHeight-1; h++){
      microPatchStride = 0;
      for(int num=0; num<numOfMicroPatch; num++){
        for(int w=0; w<microPatchWidth; w++){
          for(int i=0; i<sizeof(union val); i++)
            printf("%.2x", (&procRAM[posOnMicroPatch1+microPatchStride+w])->ucVal[sizeof(union val) - 1 - i]);
          //printf("%.3d", posOnMicroPatch1+microPatchStride+w);
          printf("_");
        }
        microPatchStride += microPatchWidth*microPatchHeight;
      }
      posOnMicroPatch1 += microPatchWidth;
      printf("\n");
    }
    // print padding
    microPatchStride = 0;
    if(yPos != yEndPos) {
      for(int num=0; num<numOfMicroPatch; num++){
        for(int w=0; w<microPatchWidth; w++){
          for(int i=0; i<sizeof(union val); i++)
            printf("%.2x", (&procRAM[numOfMicroPatch*microPatchHeight*microPatchWidth + microPatchStride + w])->ucVal[sizeof(union val)-1-i]);
        //printf("%.3d", numOfMicroPatch*microPatchHeight*microPatchWidth + microPatchStride + w);
          printf("_");
        }
        microPatchStride += microPatchWidth;
      }
      printf("\n");
    }
  }
  return;
}
 */

void readProcRam(void *fileDescriptor, U readBottomData, U xPos, U yPos, U xEndPos, U yEndPos, U barOffset, U ithOffset, U* RAM )
{
  union val procRAM[22*15] = {0}; // processing memory
  union val *p = procRAM;

  long lIthOffset = ithOffset*ddrDataWidth/floatNumWidth*sizeof(union val);
  long lBarOffset = barOffset*ddrDataWidth/floatNumWidth*sizeof(union val);
  long lOffset;
  int i;
//printf("(x,y): (%.4d, %4d)\n", xPos, yPos);
  if(readBottomData) {
    // read patch
    if(xPos == 0) {
      lOffset = lIthOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight)*sizeof(union val);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(i=0; i<micro3PatchSize; i++)
        fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
    } else if(xPos == xEndPos) {
      lOffset = lIthOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight - micro1PatchSize)*sizeof(union val);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(i=0; i<micro1PatchSize; i++)
        fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
    } else {
      lOffset = lIthOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight + xPos*atomicWidth*atomicHeight + micro1PatchSize)*sizeof(union val);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(i=0; i<micro2PatchSize; i++)
        fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
    }

    // read padding
    int numOfMicroPatch;
    if(xPos==0)
      numOfMicroPatch = 3;
    else if( xPos==xEndPos)
      numOfMicroPatch = 1;
    else
      numOfMicroPatch = 2;
    
    int n,i;
    if(yPos != yEndPos) {
      if(xPos == 0) {
      //lOffset = lIthOffset + lBarOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight)*sizeof(union val);
        lOffset = lIthOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight)*sizeof(union val);
      } else if(xPos == xEndPos) {
      //lOffset = lIthOffset + lBarOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight - micro1PatchSize)*sizeof(union val);
        lOffset = lIthOffset + ((xEndPos+1)*(yPos+2)*atomicWidth*atomicHeight - micro1PatchSize)*sizeof(union val);
      } else {
      //lOffset = lIthOffset + lBarOffset + ((xEndPos+1)*yPos*atomicWidth*atomicHeight + xPos*atomicWidth*atomicHeight + micro1PatchSize)*sizeof(union val);
        lOffset = lIthOffset + ((xEndPos+1)*(yPos+1)*atomicWidth*atomicHeight + xPos*atomicWidth*atomicHeight + micro1PatchSize)*sizeof(union val);
      }
      for(n=0; n<numOfMicroPatch; n++){
        fseek(fileDescriptor, lOffset, SEEK_SET);
        for(i=0; i<microPatchWidth; i++)
          fread((p++), 1, sizeof(union val), (FILE*) fileDescriptor);
        lOffset += micro1PatchSize*sizeof(union val);
      }
    }

    // print
    int posOnMicroPatch1; // current position on micro patch
    int microPatchStride;
    int h, num, w;
    printf("procRAM content:\n");
    // print patch
    posOnMicroPatch1 = 0;
    for(h=0; h<procRamHeight-1; h++){
      microPatchStride = 0;
      for(num=0; num<numOfMicroPatch; num++){
        for(w=0; w<microPatchWidth; w++){
          for(i=0; i<sizeof(union val); i++)
            printf("%.2x", (&procRAM[posOnMicroPatch1+microPatchStride+w])->ucVal[sizeof(union val) - 1 - i]);
          //printf("%.3d", posOnMicroPatch1+microPatchStride+w);
          printf("_");
        }
        microPatchStride += microPatchWidth*microPatchHeight;
      }
      posOnMicroPatch1 += microPatchWidth;
      printf("\n");
    }
    // print padding
    microPatchStride = 0;
    if(yPos != yEndPos) {
      for(num=0; num<numOfMicroPatch; num++){
        for(w=0; w<microPatchWidth; w++){
          for(i=0; i<sizeof(union val); i++)
            printf("%.2x", (&procRAM[numOfMicroPatch*microPatchHeight*microPatchWidth + microPatchStride + w])->ucVal[sizeof(union val)-1-i]);
        //printf("%.3d", numOfMicroPatch*microPatchHeight*microPatchWidth + microPatchStride + w);
          printf("_");
        }
        microPatchStride += microPatchWidth;
      }
      printf("\n");
    }
    memcpy((void*)RAM, (void*)procRAM, (sizeof(union val)*procRamHeight*21));
    printf("memory copied to RAM\n");
  }
  return;
}

//void cmpFloatNum(U dataValid, U numOfValidData, U* data, U* RAM, U cnt)
U cmpFloatNum(U dataValid, U numOfValidData, U* data, U* RAM, U cnt, U xPos, U yPos, U ithFM)
// U cnt -- current position on RAM
{
  U checkPass = 1;
  U i=0;
  union val *pData  = data;
  union val *pRAM   = RAM;
  int s;
  pRAM += cnt;
  if(dataValid) {
    for(i=0; i<numOfValidData; i++){
      for(s=0; s<sizeof(union val); s++) {
        if(pData->ucVal[s] != pRAM->ucVal[s]) {
          printf("pData: %2x, pRAM: %2x\n", pData->ucVal[s], pRAM->ucVal[s]);
          checkPass = 0;
          printf("ERROR on cnt: %d, ", cnt);
          printf("xPos: %8x, ", xPos);
          printf("yPos: %8x, ", yPos);
          printf("ithFM: %8x\n", ithFM);
        //exit(1);
        }
      }
    //printf("data:%8x, RAM: %8x\n", *pData, *pRAM);
    //printf("checked\n");
      ++pData;
      ++pRAM;
    }
  }
  return checkPass;
}

//extern void     readControl(input bit loadingDone, input bit dataFull, output bit readBottomData,
//                            inout bit[29:0] bottomDataAddr, input bit[8:0] xEndPos,
//                            input bit[8:0] yEndPos, inout bit[8:0] xPos, inout bit[8:0] yPos,
//                            output bit isFirstFM, inout bit[29:0] ithOffset, inout bit[29:0] barOffset,
//                            inout bit[9:0] ithFM, output bit readEnd); // control reading process
void readControl(U loadingDone, U dataFull, /*U memPatchValid,*/ U* readBottomData, U* bottomDataAddr,
                 U xEndPos, U yEndPos, U* xPos, U* yPos, U* isFirstFM, U* ithOffset,
                 U* barOffset, U* ithFM, U* readEnd )
{
  const int channels  = 3; // number of bottom channels
  const int fmSize    = 16384; // fmHeight*fmWidth*floatNumWidth/ddrDataWidth;
  *barOffset = 1024; // fmWidth*atomicHeight*floatNumWidth/ddrDataWidth;
  *isFirstFM = 0;
  *readEnd   = 0;
  *readBottomData = 0;
  if(loadingDone /*&& memPatchValid*/) {
  // initialization
    *xPos = 0;
    *yPos = 0;
    *isFirstFM = 1;
    *ithOffset = 0;
    *ithFM     = 0;
    *readBottomData = 1;
    printf("reading info: \n");
    printf("bottomDataAddr:%08x, ", *bottomDataAddr);
    printf("readDataBotom:%08x, ", *readBottomData);
    //printf("xEndPos:%08x,\t", xEndPos);
    //printf("yEndPos:%08x,\t", yEndPos);
    printf("xPos:%08x, ", *xPos);
    printf("yPos:%08x,\n", *yPos);
    printf("isFirstFM:%08x, ", *isFirstFM);
    printf("ithOffset:%08x, ", *ithOffset);
    printf("barOffset:%08x, ", *barOffset);
    printf("ithFM:%08x, ", *ithFM);
    printf("readEnd:%08x\n", *readEnd);
  } else if(dataFull/* && memPatchValid*/) {
  // data full
    if(*ithFM==(channels-1)) {
      // xPos
      if(*xPos < xEndPos)
        *xPos += 1;
      else
        *xPos  = 0;
      // update yPos
      if(*xPos == 0) {
        if(*yPos < yEndPos)
          *yPos += 1;
        else {
          *yPos    = 0;
          *readEnd = 1;
        }
      }
      // ith feature map
      *ithFM     = 0;
      *ithOffset = 0;
      // next fm is the first
      *isFirstFM = 1;
    } else {
      // ith feature map
      *ithFM     += 1;
      *ithOffset += fmSize;
      *isFirstFM  = 0;
    }
    *readBottomData = 1;
    printf("reading info: \n");
    printf("bottomDataAddr:%08x, ", *bottomDataAddr);
    printf("readDataBotom:%08x, ", *readBottomData);
    //printf("xEndPos:%08x,\t", xEndPos);
    //printf("yEndPos:%08x,\t", yEndPos);
    printf("xPos:%08x, ", *xPos);
    printf("yPos:%08x,\n", *yPos);
    printf("isFirstFM:%08x, ", *isFirstFM);
    printf("ithOffset:%08x, ", *ithOffset);
    printf("barOffset:%08x, ", *barOffset);
    printf("ithFM:%08x, ", *ithFM);
    printf("readEnd:%08x\n", *readEnd);
  }
  return;
}
