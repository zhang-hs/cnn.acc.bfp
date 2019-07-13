// ---------------------------------------------------
// File       : conv.tb.c
//
// Description: read from char data file, compare data
//
// Version    : 1.0
// ---------------------------------------------------
#include<stdio.h>
#include<stdlib.h>
#include"DirectC.h"
#include<cblas.h>

#define data_height 16
#define data_width 16
#define patch_height 14
#define patch_width 14
#define ker_height 3
#define ker_width 3
#define ker_channels 32

union val{
  float fVal;
  unsigned char ucVal[sizeof(float)];
};
// -------------------------------- directC function -------------------------------- 
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

// reading control
void readControl(U resetDone, U convLastPos, U* readBottomData, U* bottomDataAddr,
                 U xEndPos, U yEndPos, U* xPos, U* yPos, U* isFirstFM, U* ithOffset,
                 U* barOffset, U* ithFM, U* readEnd, U* readKer, U* readKerAddr, U* ithKerSet)
{
  const int channels  = 3; // number of bottom channels
  const int fmSize    = 25088; // fmHeight*fmWidth*floatNumWidth/ddrDataWidth;
  const int kerSize   = 144;   // kerChannels*kerWidth*kerHeight*floatNumWidth/ddrDataWidth;
  const int numKerSet = 2; // number of ker_set
  *barOffset  = 1568; // fmWidth*atomicHeight*floatNumWidth/ddrDataWidth;
  if(resetDone) {
  // initialization
    *xPos = 0;
    *yPos = 0;
    *ithOffset = 0;
    *ithFM     = 0;
    // read kernel
    *ithKerSet = 0;
    *readKerAddr  = 0;
    *readKer= 1;
    *isFirstFM = 1;
    *readBottomData = 1;
    printf("reset done\n");
    printf("reading info: ");
    printf("resetDone readBottomData: %8x, ", *readBottomData);
    printf("readBottomData: %8x, ", *readBottomData);
    printf("bottomDataAddr: %8x, ", *bottomDataAddr);
    printf("xEndPos: %8x, ", xEndPos);
    printf("yEndPos: %8x,\n", yEndPos);
    printf("\txPos: %8x, ", *xPos);
    printf("yPos: %8x, ", *yPos);
    printf("isFirstFM: %8x, ", *isFirstFM);
    printf("ithOffset: %8x, ", *ithOffset);
    printf("barOffset: %8x, ", *barOffset);
    printf("ithFM: %8x\n", *ithFM);
    printf("\treadKer: %8x, ", *readKer);
    printf("ithKerSet: %8x, ", *ithKerSet);
    printf("readKerAddr: %8x, ", *readKerAddr);
    printf("readEnd: %8x\n", *readEnd);
  } else if(convLastPos) {
    *isFirstFM  = 0;
    *readEnd    = 0;
    *readKer    = 0;
    *readBottomData = 0;
  // convolution at last pos
    if(*ithKerSet < (numKerSet-1)) {
      *ithKerSet += 1;
      *readKer = 1;
      *readKerAddr += kerSize;
    } else {
      *ithKerSet    = 0;
      *readKer      = 1;
      *readKerAddr  = 0;
    }

    if(*ithKerSet == 0){
      if(*ithFM==(channels-1)){
        // xPos
        if(*xPos<xEndPos)
          *xPos += 1;
        else
          *xPos  = 0;
        // yPos
        if(*xPos == 0){
          if(*yPos < yEndPos)
            *yPos += 1;
          else{
            *yPos  = 0;
            *readEnd = 1;
          }
        }
        // ith feature map
        *ithFM = 0;
        *ithOffset = 0;
        *isFirstFM = 1;
      } else {
        *ithFM      += 1;
        *ithOffset  += fmSize;
        *isFirstFM   = 0;
      }
      *readBottomData = 1;
    }
    printf("convLastPos\n");
    printf("reading info: ");
    printf("convLastPos readBottomData: %8x, ", *readBottomData);
    printf("readBottomData: %8x, ", *readBottomData);
    printf("bottomDataAddr: %8x, ", *bottomDataAddr);
    printf("xEndPos: %8x, ", xEndPos);
    printf("yEndPos: %8x,\n", yEndPos);
    printf("\txPos: %8x, ", *xPos);
    printf("yPos: %8x, ", *yPos);
    printf("isFirstFM: %8x, ", *isFirstFM);
    printf("ithOffset: %8x, ", *ithOffset);
    printf("barOffset: %8x, ", *barOffset);
    printf("\tithFM: %8x\n", *ithFM);
    printf("readKer: %8x, ", *readKer);
    printf("ithKerSet: %8x, ", *ithKerSet);
    printf("readKerAddr: %8x, ", *readKerAddr);
    printf("readEnd: %8x\n", *readEnd);
  }
  return;
}

long getOffset(long lIthOffset, U xEndPos, U xPos, U yPos, int microPatchIndex)
{
  long lOffset;
  switch(microPatchIndex) {
    case 0:
      lOffset = lIthOffset+(((xEndPos+1)*(yPos-1)+xPos)*atomicHeight*atomicWidth - micro1PatchSize)*sizeof(union val);
      break;
    case 1:
      lOffset = lIthOffset+((xEndPos+1)*(yPos-1)+xPos)*atomicHeight*atomicWidth*sizeof(union val);
      break;
    case 2:
      lOffset = lIthOffset+(((xEndPos+1)*(yPos-1)+xPos)*atomicHeight*atomicWidth + micro1PatchSize)*sizeof(union val);
      break;
    case 3:
      lOffset = lIthOffset+(((xEndPos+1)*(yPos-1)+xPos)*atomicHeight*atomicWidth + micro2PatchSize)*sizeof(union val);
      break;
    case 4:
      lOffset = lIthOffset+(((xEndPos+1)*yPos+xPos)*atomicHeight*atomicWidth - micro1PatchSize)*sizeof(union val);
      break;
    case 5:
      lOffset = lIthOffset+((xEndPos+1)*yPos+xPos)*atomicHeight*atomicWidth*sizeof(union val);
      break;
    case 6:
      lOffset = lIthOffset+(((xEndPos+1)*yPos+xPos)*atomicHeight*atomicWidth + micro1PatchSize)*sizeof(union val);
      break;
    case 7:
      lOffset = lIthOffset+(((xEndPos+1)*yPos+xPos)*atomicHeight*atomicWidth + micro2PatchSize)*sizeof(union val);
      break;
    case 8:
      lOffset = lIthOffset+(((xEndPos+1)*(yPos+1)+xPos)*atomicHeight*atomicWidth - micro1PatchSize)*sizeof(union val);
      break;
    case 9:
      lOffset = lIthOffset+((xEndPos+1)*(yPos+1)+xPos)*atomicHeight*atomicWidth*sizeof(union val);
      break;
    case 10:
      lOffset = lIthOffset+(((xEndPos+1)*(yPos+1)+xPos)*atomicHeight*atomicWidth + micro1PatchSize)*sizeof(union val);
      break;
    case 11:
      lOffset = lIthOffset+(((xEndPos+1)*(yPos+1)+xPos)*atomicHeight*atomicWidth + micro2PatchSize)*sizeof(union val);
      break;
    default:
      lOffset = 0;
      break;
  }
  return(lOffset);
}

void readProcRam(void *fileDescriptor, U readBottomData, U xPos, U yPos, U xEndPos, U yEndPos, U barOffset, U ithFM, U* RAM, U* procRamFull)
{
  union val procRAM[16*16] = {0}; // processing memory
  union val microPatch[12][14*7]; //[12][microPatchHeight*microPatchWidth]

  long lIthOffset = ithFM*224*224*sizeof(union val); // fmHeight*fmWidth*floatNumWidth
  long lOffset;
  for(int i=0; i<12; i++) {
    for(int j=0; j<14*7; j++) {
      microPatch[i][j].fVal = 0.0;
    }
  }

  if(readBottomData) {
    int microPatchIndex[12];
    int numOfIndex;
    // read patch
    if(yPos == 0){
      if(xPos == 0) {
      // 5,6,7,9,10,11
        numOfIndex = 6;
        microPatchIndex[0]=5; microPatchIndex[1]=6;  microPatchIndex[2]=7;
        microPatchIndex[3]=9; microPatchIndex[4]=10; microPatchIndex[5]=11;
      } else if(xPos == xEndPos) {
      // 4,5,6,8,9,10
        numOfIndex = 6;
        microPatchIndex[0]=4; microPatchIndex[1]=5; microPatchIndex[2]=6;
        microPatchIndex[3]=8; microPatchIndex[4]=9; microPatchIndex[5]=10;
      } else {
      // 4,5,6,7,8,9,10,11
        numOfIndex = 8;
        microPatchIndex[0]=4;   microPatchIndex[1]=5; microPatchIndex[2]=6;   microPatchIndex[3]=7;
        microPatchIndex[4]=8;   microPatchIndex[5]=9; microPatchIndex[6]=10;  microPatchIndex[7]=11;
      }
    } else if(yPos == yEndPos) {
      if(xPos == 0) {
      // 1,2,3,5,6,7
        numOfIndex = 6;
        microPatchIndex[0]=1; microPatchIndex[1]=2; microPatchIndex[2]=3;
        microPatchIndex[3]=5; microPatchIndex[4]=6; microPatchIndex[5]=7;
      } else if(xPos == xEndPos) {
      // 0,1,2,4,5,6
        numOfIndex = 6;
        microPatchIndex[0]=0; microPatchIndex[1]=1; microPatchIndex[2]=2;
        microPatchIndex[3]=4; microPatchIndex[4]=5; microPatchIndex[5]=6;
      } else {
      // 0,1,2,3,4,5,6,7
        numOfIndex = 8;
        microPatchIndex[0]=0; microPatchIndex[1]=1; microPatchIndex[2]=2; microPatchIndex[3]=3;
        microPatchIndex[4]=4; microPatchIndex[5]=5; microPatchIndex[6]=6; microPatchIndex[7]=7;
      }
    } else {
      if(xPos == 0) {
      // 1,2,3,5,6,7,9,10,11
        numOfIndex = 9;
        microPatchIndex[0]=1; microPatchIndex[1]=2;   microPatchIndex[2]=3;
        microPatchIndex[3]=5; microPatchIndex[4]=6;   microPatchIndex[5]=7;
        microPatchIndex[6]=9; microPatchIndex[7]=10;  microPatchIndex[8]=11;
      } else if(xPos == xEndPos) {
      // 0,1,2,4,5,6,8,9,10
        numOfIndex = 9;
        microPatchIndex[0]=0; microPatchIndex[1]=1; microPatchIndex[2]=2;
        microPatchIndex[3]=4; microPatchIndex[4]=5; microPatchIndex[5]=6;
        microPatchIndex[6]=8; microPatchIndex[7]=9; microPatchIndex[8]=10;
      } else {
      // 0,1,2,3,4,5,6,7,8,9,10,11
        numOfIndex = 12;
        microPatchIndex[0] =0; microPatchIndex[1] =1;  microPatchIndex[2] =2;
        microPatchIndex[3] =3; microPatchIndex[4] =4;  microPatchIndex[5] =5;
        microPatchIndex[6] =6; microPatchIndex[7] =7;  microPatchIndex[8] =8;
        microPatchIndex[9] =9; microPatchIndex[10]=10; microPatchIndex[11]=11;
      }
    }

    for(int i=0; i<numOfIndex; i++) {
      union val *p = microPatch[microPatchIndex[i]];
      lOffset = getOffset(lIthOffset, xEndPos, xPos, yPos, microPatchIndex[i]);
      printf("index: %4d, lOffset: %16x\n", microPatchIndex[i], lOffset);
      fseek(fileDescriptor, lOffset, SEEK_SET);
      for(int j=0; j<micro1PatchSize; j++)
        fread((p++), 1, sizeof(union val), (FILE*)fileDescriptor);
    // check
    //p = microPatch[microPatchIndex[i]];
    //for(int r=0; r<microPatchHeight; r++){
    //  for(int c=0; c<microPatchWidth; c++){
    //    for(int k=0; k<sizeof(union val); k++)
    //      printf("%.2x",p->ucVal[sizeof(union val)-1-k]);
    //    printf("_");
    //    ++p;
    //  }
    //  printf("\n");
    //}
    }

    // filling procRAM
    memcpy((void*)procRAM, (void*)&microPatch[0][14*7-1], sizeof(union val));
    memcpy((void*)(procRAM+1), (void*)&microPatch[1][14*7-microPatchWidth], sizeof(union val)*microPatchWidth);
    memcpy((void*)(procRAM+1+microPatchWidth), (void*)&microPatch[2][14*7-microPatchWidth], sizeof(union val)*microPatchWidth);
    memcpy((void*)(procRAM+15), (void*)&microPatch[3][14*7-microPatchWidth], sizeof(union val));
    for(int i=0; i<microPatchHeight; i++)
      memcpy((void*)(procRAM+16+16*i), (void*)&microPatch[4][6+i*microPatchWidth], sizeof(union val));
    for(int i=0; i<microPatchHeight; i++){
      memcpy((void*)(procRAM+16+1+16*i), (void*)&microPatch[5][i*microPatchWidth], sizeof(union val)*microPatchWidth);
    }
    for(int i=0; i<microPatchHeight; i++){
      memcpy((void*)(procRAM+16+1+7+16*i), (void*)&microPatch[6][i*microPatchWidth], sizeof(union val)*microPatchWidth);
    }
    for(int i=0; i<microPatchHeight; i++)
      memcpy((void*)(procRAM+16+15+16*i), (void*)&microPatch[7][i*microPatchWidth], sizeof(union val));
    memcpy((void*)(procRAM+16*15), (void*)&microPatch[8][6], sizeof(union val));
    memcpy((void*)(procRAM+16*15+1), (void*)&microPatch[9][0], sizeof(union val)*microPatchWidth);
    memcpy((void*)(procRAM+16*15+8), (void*)&microPatch[10][0], sizeof(union val)*microPatchWidth);
    memcpy((void*)(procRAM+16*16-1), (void*)&microPatch[11][0], sizeof(union val));

    // check
  //union val *p = procRAM;
  //for(int r=0; r<16; r++){
  //  for(int c=0; c<16; c++){
  //    for(int i=0; i<sizeof(union val); i++)
  //      printf("%.2x",p->ucVal[sizeof(union val)-1-i]);
  //    printf("_");
  //    ++p;
  //  }
  //  printf("\n");
  //}

    // copy to RAM
    memcpy((void*)RAM, (void*)procRAM, (sizeof(union val)*16*16));
    *procRamFull = 1;
    printf("memory copied to RAM\n");
  }
  return;
}

void readProcKer(void *fileDescriptor, U readKerData, U readKerAddr, U ithKerSet, U* kerRam, U* kerRamFull)
{
  long lOffset;
  const int iKerHeight = 3;
  const int iKerWidth  = 3;
  const int iKerChannels = 32;
  const long lKerSetSize = iKerChannels*iKerHeight*iKerWidth;
  lOffset = ithKerSet*lKerSetSize*sizeof(union val);
  printf("ker lOffset: %8x\n", lOffset);
  fseek(fileDescriptor, lOffset, SEEK_SET);
  fread(kerRam, 1, lKerSetSize*sizeof(union val), (FILE*) fileDescriptor);
  *kerRamFull = 1;

//// check
//union val *p;
//p=(union val*)kerRam;
//for(int i=0; i<32*9/16; i++) {
//  for(int j=0; j<16; j++){
//    for(int k=0; k<sizeof(union val); k++)
//      printf("%.2x", p->ucVal[sizeof(union val)-1-k]);
//    printf("_");
//    ++p;
//  }
//  printf("\n");
//}

  return;
}

float* reformBottomData(const U* bottomData)
{
  float *p=NULL, *tmp=NULL;
  float *pData=NULL;
  const int kerHeight=3, kerWidth=3, kerChannels=32;
  const int dataHeight = 16, dataWidth=16;
  p=(float*)malloc(atomicHeight*atomicWidth*kerHeight*kerWidth*sizeof(union val));
  pData = (float*)bottomData;
  tmp = p;
  for(int kerRow=0; kerRow<kerHeight; kerRow++){
    for(int kerCol=0; kerCol<kerWidth; kerCol++){
      for(int patchCol=0; patchCol<atomicWidth; patchCol++){
        for(int patchRow=0; patchRow<atomicHeight; patchRow++){
        //*(tmp+kerRow*kerWidth+kerCol + (patchCol*atomicHeight+patchRow)*kerHeight*kerWidth)
        //  = *(pData+kerRow*atomicWidth+kerCol + patchRow*atomicWidth+patchCol);
          memcpy((tmp+kerRow*kerWidth+kerCol + (patchCol*atomicHeight+patchRow)*kerHeight*kerWidth), (pData+kerRow*dataWidth+kerCol + patchRow*dataWidth+patchCol), sizeof(union val));
        }
      }
    }
  }

//// check
//union val* pCheck = (union val*)tmp;
//for(int r=0; r<atomicHeight*atomicWidth; r++){
//  for(int c=0; c<kerHeight*kerWidth; c++){
//    for(int k=0; k<sizeof(union val); k++)
//      printf("%.2x", (pCheck+c+kerHeight*kerWidth*r)->ucVal[sizeof(union val)-1-k]);
//    printf("_");
//  }
//  printf("\n");
//}
//pCheck=(union val*) bottomData;
//for(int r=0; r<16; r++){
//  for(int c=0; c<16; c++){
//    for(int i=0; i<sizeof(union val); i++)
//      printf("%.2x", pCheck->ucVal[sizeof(union val)-1-i]);
//    printf("_");
//    ++pCheck;
//  }
//  printf("\n");
//}

  return(p);
}

float* reformKerData(U* kerData)
{
  float* p=NULL;
  const int kerHeight=3, kerWidth=3, kerChannels=32;
  p=(float*)malloc(sizeof(union val)*kerChannels*kerHeight*kerWidth);
  memcpy((void*)p, (void*)kerData, sizeof(union val)*kerChannels*kerHeight*kerWidth);
  return(p);
}

/*
void cnnConv(U startConv, U* convOutput, U* bottomData, U* kerData)
{
  if(startConv){
    const int kerHeight=3, kerWidth=3, kerChannels=32;
    const int dataHeight = 16, dataWidth=16;
    float *convPatch=NULL;
    float *convKer=NULL;
    float *convResult= (float*)malloc(kerChannels*atomicHeight*atomicWidth*sizeof(union val));
    convPatch = reformBottomData(bottomData);
    convKer   = reformKerData(kerData);

    // correlation
    int iLDA=kerHeight*kerWidth;
    int iLDB=kerHeight*kerWidth;
    int iLDC=kerChannels;
    float fAlpha=1.0, fBeta=0.;
    cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasTrans, atomicHeight*atomicWidth, kerChannels, kerHeight*kerWidth, fAlpha, convPatch, iLDA, convKer, iLDB, fBeta, convResult, iLDC);
    free(convPatch);
    free(convKer);
    free(convResult);
    convPatch =NULL;
    convKer   =NULL;
    convResult=NULL;

  //// check
  //union val* p=convOutput;
  //for(int i=0; i<dataHeight*dataWidth; i++){
  //  for(int j=0; j<kerHeight*kerWidth; j++){
  //  }
  //}
  }

  return;
}
*/

// // read a float num
// int readFloatNum(void *fileDescriptor, U* const fVal)
// {
//   size_t ulCheck;
// //union val fRead, fIntermediate;
//   ulCheck = fread((void*)fVal, 1, sizeof(union val), (FILE*)fileDescriptor);
// //memcpy(fVal, (void*)&fIntermediate, sizeof(union val));
//   if(ulCheck != sizeof(union val)){
//     printf("read size: %lu != 1\n", ulCheck);
//     exit(0);
//   }
//   return((int)ulCheck);
// }

int readFloatNum(void *fileDescriptor, U* const fVal)
{
  size_t ulCheck;
  union val fRead, fIntermediate;
  ulCheck = fread((void*)&fRead, 1, sizeof(union val), (FILE*)fileDescriptor);
  // rearrange byte position
  for(int i=0; i<sizeof(union val); i++)
    fIntermediate.ucVal[i] = fRead.ucVal[sizeof(union val)-1-i];

  memcpy(fVal, (void*)&fIntermediate, sizeof(union val));
  if(ulCheck != sizeof(union val)){
    printf("read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  return((int)ulCheck);
}

//void cmpFloatNum(U dataValid, U numOfValidData, U* data, U* RAM, U cnt)
U cmpFloatNum(U dataValid, U numOfValidData, U* data, U* RAM, U cnt, U xPos, U yPos, U ithFM)
// U cnt -- current position on RAM
{
  U checkPass = 1;
  U i=0;
  union val *pData  = data;
  union val *pRAM   = RAM;
  pRAM += cnt;
  if(dataValid) {
    for(i=0; i<numOfValidData; i++){
      for(int s=0; s<sizeof(union val); s++) {
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

void printProcRam(U* RAM, U procRamFull)
{
  const int convRamHeight = 16;
  const int convRamWidth  = 16;
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
