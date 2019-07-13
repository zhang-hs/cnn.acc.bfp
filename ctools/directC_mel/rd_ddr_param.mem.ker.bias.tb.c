// ---------------------------------------------------
// File       : rd_ddr_param.ker.bias.tb.c
//
// Description: rd_ddr_param.mem.ker.bias.tb.c DirectC c file
//
// Version    : 1.0
// ---------------------------------------------------
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include"DirectC.h"

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

void readProcRam(void *fileDescriptor, U readBottomData, U xPos, U yPos, U xEndPos, U yEndPos, U barOffset, U ithOffset, U* RAM )
{
  union val procRAM[22*15] = {0}; // processing memory
  union val *p = procRAM;

  long lIthOffset = ithOffset*ddrDataWidth/floatNumWidth*sizeof(union val);
  long lBarOffset = barOffset*ddrDataWidth/floatNumWidth*sizeof(union val);
  long lOffset;
//printf("(x,y): (%.4d, %4d)\n", xPos, yPos);
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
    memcpy((void*)RAM, (void*)procRAM, (sizeof(union val)*procRamHeight*21));
    printf("memory copied to RAM\n");
  }
  return;
}

void readControl(U loadingDone, U dataFull, U* readBottomData, U* bottomDataAddr,
                 U xEndPos, U yEndPos, U* xPos, U* yPos, U* isFirstFM, U* ithOffset,
                 U* barOffset, U* ithFM, U* readEnd )
{
  const int channels  = 3; // number of bottom channels
  const int fmSize    = 25088; // fmHeight*fmWidth*floatNumWidth/ddrDataWidth;
  *barOffset = 1568; // fmWidth*atomicHeight*floatNumWidth/ddrDataWidth;
  *isFirstFM = 0;
  *readEnd   = 0;
  *readBottomData = 0;
  if(loadingDone) {
  // initialization
    *xPos = 0;
    *yPos = 0;
    *isFirstFM = 1;
    *ithOffset = 0;
    *ithFM     = 0;
    *readBottomData = 1;
    printf("reading info: ");
    printf("bottomDataAddr: %8x, ", *bottomDataAddr);
    printf("xEndPos: %8x, ", xEndPos);
    printf("yEndPos: %8x, ", yEndPos);
    printf("xPos: %8x, ", *xPos);
    printf("yPos: %8x, ", *yPos);
    printf("isFirstFM: %8x, ", *isFirstFM);
    printf("ithOffset: %8x, ", *ithOffset);
    printf("barOffset: %8x, ", *barOffset);
    printf("ithFM: %8x, ", *ithFM);
    printf("readEnd: %8x\n", *readEnd);
  } else if(dataFull) {
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
    printf("reading info: ");
    printf("bottomDataAddr: %8x, ", *bottomDataAddr);
    printf("xEndPos: %8x, ", xEndPos);
    printf("yEndPos: %8x, ", yEndPos);
    printf("xPos: %8x, ", *xPos);
    printf("yPos: %8x, ", *yPos);
    printf("isFirstFM: %8x, ", *isFirstFM);
    printf("ithOffset: %8x, ", *ithOffset);
    printf("barOffset: %8x, ", *barOffset);
    printf("ithFM: %8x, ", *ithFM);
    printf("readEnd: %8x\n", *readEnd);
  }
  return;
}

// print weight
void printWeight(U* weightData)
{
  union val *p = (union val*) weightData;
  const int numOfDataInBurst=16;
  const int numOfWeightBurst=18;
  for(int i=0; i<numOfWeightBurst; i++){
    for(int j=0; j<numOfDataInBurst; j++){
      for(int k=0; k<sizeof(union val); k++){
        printf("%.2x", (p+i*numOfDataInBurst + numOfDataInBurst-1 - j)->ucVal[sizeof(union val)-1-k]);
      }
      printf("_");
    }
    printf("\n");
  }
  return;
}


// print bias
void printBias(U* biasData, U numOfBiasBurst)
{
  union val *p = biasData;
  const int numOfDataInBurst=16;
  for(int i=0; i<numOfBiasBurst; i++){
    for(int j=0; j<numOfDataInBurst; j++){
      for(int k=0; k<sizeof(union val); k++){
        printf("%.2x", (p+i*numOfDataInBurst + numOfDataInBurst-1 - j)->ucVal[sizeof(union val)-1-k]);
      }
      printf("_");
    }
    printf("\n");
  }
  return;
}
