// ---------------------------------------------------
// File       : conv.c
//
// Description: compare data, conv layer directC
//
// Version    : 1.0
// ---------------------------------------------------

#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<string.h>
#include"DirectC.h"
//#include<cblas.h>
#include<math.h>

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

int read16bitFloatNum(void *fileDescriptor, U* pShortFloat)
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
/*
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
*/

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
