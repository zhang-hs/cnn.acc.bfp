// ---------------------------------------------------
// File       : conv.c
//
// Description: Comparing simulation data with Caffe data based on floating point number, and is used for single-layer simulation.
//
// Version    : 1.0
// ---------------------------------------------------

#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<string.h>
#include"DirectC.h"
#include<cblas.h>
#include<math.h>

union val{
  float fVal;
  unsigned char ucVal[sizeof(float)];
};

//layer_index: conv1_1
#define atomicHeight    14  //bottom, the top one is half only pooling is performed
#define atomicWidth     14
#define convRamHeight   16  //bottom, the top on is half only pooling is performed
#define convRamWidth    16
#define fmHeight        28 //bottom fm height, the top one is half only pooling is performed
#define fmWidth         28
#define kerChannels     64  //number of parallel convolution kernals
#define kerWidth        3
#define kerHeight       3
#define channels   512  // number of bottom channels // <-x
#define biasNUM    512 // number of top channels
#define biasMax    512
#define epsilonError  14.0 // 5_3 -> 8.0, 4-3 -> 14.0, 4_1 -> 32.0, 3_3 -> 32.0, 3_2 -> 16.0, 3_1 -> 16.0, 2_2 -> 16.0, 2_1 -> 12.0, 1_2 -> 4.0 , 1_1 -> 4.0
#define relativeError 0.15 // 5_3 -> 0.2, 4-3 -> 0.15, 4_1 -> 0.25, 3_3 -> 0.25, 3_2 -> 0.25, 3_1 -> 0.25, 2_2 -> 0.25, 2_1 -> 0.15, 1_2 -> 0.1 , 1_1 -> 0.1
#define absError      3.6 // 5_3 -> 2.0, 4-3 -> 3.6 , 4_1 -> 6.8 , 3_3 -> 6.8 , 3_2 -> 4.7 , 3_1 -> 4.7 , 2_2 -> 4.7 , 2_1 -> 2.3 , 1_2 -> 0.45, 1_1 -> 0.4
#define epsilonErrorConvop  epsilonError/channels
#define relativeErrorConvop relativeError/channels
#define channelNum biasNUM
#define numKerSet  2 // number of ker_set
#define fmSize          (fmHeight*fmWidth*sizeof(union val))
#define fmSize16bits    (fmHeight*fmWidth*sizeof(uint16_t))
#define fmSize8bits     (fmHeight*fmWidth*sizeof(uint8_t))

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

// void write2File(void* fileDescriptor, U wrEnable, U wrOffset, const U* const wrData)
// {
//   unsigned int Offset;
//   Offset = wrOffset*8;
//   if(wrEnable) {
//     fseek((FILE*)fileDescriptor, Offset, SEEK_SET);
//     fwrite(wrData, 64, sizeof(char), (FILE*)fileDescriptor);
//   }
//   return;
// }
void write2File(void* fileDescriptor, U wrEnable, U poolEn, U posX, U posY, U quarterIdx, U channelIdx, U* wrData)
{
  unsigned int offset;
  if(poolEn){
    offset = (posY*atomicWidth+posX)*biasNUM*49 + channelIdx*49;
  } else {
    offset = (posY*atomicWidth+posX)*biasNUM*49*4 + channelIdx*49*4 + quarterIdx*49;
  }
  offset = offset*sizeof(unsigned short);
  if(wrEnable) {
    fseek((FILE*)fileDescriptor, offset, SEEK_SET);
    fwrite(wrData, 49, sizeof(unsigned short), (FILE*)fileDescriptor);
  }
  return;
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
  ulCheck = fread((void*)fVal, 1, sizeof(float), (FILE*)fileDescriptor);
  if(ulCheck != sizeof(float)){
    printf("(readFloatNum in conv.c) read size: %lu != 1\n", ulCheck);
    exit(0);
  }
  return((int)ulCheck);
}
int read16bitNum(void *fileDescriptor, U* pShortFloat)
{
  size_t ulCheck;
  unsigned short uiFloatData;
  void * vpShortFloat = pShortFloat;
  ulCheck = fread(&uiFloatData, 1, sizeof(unsigned short), (FILE*) fileDescriptor);
  if(ulCheck != sizeof(unsigned short)){
    printf("(read16bitNum in conv.c) read size: %lu != 1\n", ulCheck);
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

//read a 16*16 sized procRam data(32bits)
void readProcRam_32bit(void* fileDescriptor, U readBottomData, U ithFM,
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
        fread(&(ram_[0])+fmWidth, sizeof(union val), (convRamHeight-2)*fmWidth, (FILE*)fileDescriptor); //filling upper and lower padding with 0
      } else {
        fread(&(ram_[0])+fmWidth, sizeof(union val), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor); //filling upper padding with 0
      }
    } else if(yPos==yEndPos) {
      offset += (ithFM*fmSize + sizeof(union val)*(yPos*atomicHeight-1)*fmWidth); //upper padding
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(union val), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor);
    } else {
      offset += (ithFM*fmSize + sizeof(union val)*(yPos*atomicHeight-1)*fmWidth);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(union val), convRamHeight*fmWidth, (FILE*)fileDescriptor);
    }

    int i, j, k, m, n, p;
    if(xPos==0){
      for(i=0; i<convRamHeight; i++)
        pRam[i*convRamWidth].fVal = 0.; //filling left padding with 0 
      if(xPos==xEndPos) //14x14
        for(j=0; j<convRamHeight; j++)
          pRam[j*convRamWidth+convRamWidth-1].fVal = 0.;  //filling right padding with 0
    //printf("before assignment\n");
      for(k=0; k<convRamHeight; k++){
        if(xPos==xEndPos) {
          memcpy(pRam+k*convRamWidth+1, ram_+ k*fmWidth, sizeof(union val)*(convRamWidth-2));
        } else {
          memcpy(pRam+k*convRamWidth+1, ram_+ k*fmWidth, sizeof(union val)*(convRamWidth-1));
        }
      }
    //printf("after assignment\n");
    } else if(xPos==xEndPos){
      for(m=0; m<convRamHeight; m++)
        pRam[convRamWidth-1 + m*convRamWidth].fVal = 0.;
      for( n=0; n<convRamHeight; n++){
        memcpy(pRam+n*convRamWidth, ram_+n*fmWidth+xPos*atomicWidth-1, sizeof(union val)*(convRamWidth-1));
      }
    } else {
      for(p=0; p<convRamHeight; p++){
        memcpy(pRam+p*convRamWidth, ram_+p*fmWidth+xPos*atomicWidth-1, sizeof(union val)*convRamWidth);
      }
    }
    printf("directC procRam readed(32-bit): %d-ithFM, %d-xPos, %d-yPos\n", ithFM, xPos, yPos);
    int r_h, r_w;
    for(r_h=0; r_h<convRamHeight; r_h++){
      for(r_w=0; r_w<convRamWidth; r_w++){
        printf("%f ",pRam[r_h*convRamWidth+r_w].fVal);
      }
      printf("\n");
    }
  }
}

//read a 16*16 sized procRam data(16bits) 
void readProcRam_16bit(void* fileDescriptor, U readBottomData, U ithFM,
                  U xPos, U yPos, U xEndPos, U yEndPos, U* procRam) 
{
  uint16_t* pRam = (uint16_t*) procRam;
  uint16_t ram_[convRamHeight*fmWidth]={0};
  long  offset = 0;
  if(readBottomData){
    if(yPos==0) {
      offset += (0+ithFM*fmSize16bits);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      if(yPos==yEndPos) { // 14x14
        fread(&(ram_[0])+fmWidth, sizeof(uint16_t), (convRamHeight-2)*fmWidth, (FILE*)fileDescriptor); //filling upper and lower padding with 0
      } else {
        fread(&(ram_[0])+fmWidth, sizeof(uint16_t), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor); //filling upper padding with 0
      }
    } else if(yPos==yEndPos) {
      offset += (ithFM*fmSize16bits + sizeof(uint16_t)*(yPos*atomicHeight-1)*fmWidth); //upper padding
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(uint16_t), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor);
    } else {
      offset += (ithFM*fmSize16bits + sizeof(uint16_t)*(yPos*atomicHeight-1)*fmWidth);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(uint16_t), convRamHeight*fmWidth, (FILE*)fileDescriptor);
    }

    int i, j, k, m, n, p;
    if(xPos==0){
      for(i=0; i<convRamHeight; i++)
        pRam[i*convRamWidth] = 0; //filling left padding with 0 
      if(xPos==xEndPos) //14x14
        for(j=0; j<convRamHeight; j++)
          pRam[j*convRamWidth+convRamWidth-1] = 0;  //filling right padding with 0
    //printf("before assignment\n");
      for(k=0; k<convRamHeight; k++){
        if(xPos==xEndPos) {
          memcpy(pRam+k*convRamWidth+1, ram_+ k*fmWidth, sizeof(uint16_t)*(convRamWidth-2));
        } else {
          memcpy(pRam+k*convRamWidth+1, ram_+ k*fmWidth, sizeof(uint16_t)*(convRamWidth-1));
        }
      //for(int j=0; j<convRamWidth-1; i++){
      //  pRam[i*convRamWidth + j+1] = ram_[i*fmWidth + j];
      //}
      }
    //printf("after assignment\n");
    } else if(xPos==xEndPos){
      for(m=0; m<convRamHeight; m++)
        pRam[convRamWidth-1 + m*convRamWidth] = 0.;
      for(n=0; n<convRamHeight; n++){
        memcpy(pRam+n*convRamWidth, ram_+n*fmWidth+xPos*atomicWidth-1, sizeof(uint16_t)*(convRamWidth-1));
      //for(int j=0; j<convRamWidth-1; j++){
      //  pRam[i*convRamWidth + j] = ram_[i*fmWidth + xPos*atomicWidth-1 + j];
      //}
      }
    } else {
      for( p=0; p<convRamHeight; p++){
        memcpy(pRam+p*convRamWidth, ram_+p*fmWidth+xPos*atomicWidth-1, sizeof(uint16_t)*convRamWidth);
      //for(int j=0; j<convRamWidth; j++){
      //  pRam[i*convRamWidth + j] = ram_[i*fmWidth + xPos*atomicWidth-1 + j];
      //}
      }
    }
    // // display error position ram data
    // if(xPos == 15 && yPos == 1) {
    //   printf(".at position x: %d, y: %d, fm channel num: %d\n", xPos, yPos, ithFM);
    //   for(int i=0; i<convRamHeight; i++) {
    //     printf(".");
    //     for(int j=0; j<convRamWidth; j++) {
    //       printf("%.4x ", pRam[i*convRamWidth + j]);
    //     }
    //     printf("\n");
    //   }
    // }
    printf("directC procRam readed(16-bit): %d-ithFM, %d-xPos, %d-yPos\n", ithFM, xPos, yPos);
  }
}

//read a 16*16 sized procRam data(8bits)
void readProcRam_8bit(void* fileDescriptor, U readBottomData, U ithFM,
                  U xPos, U yPos, U xEndPos, U yEndPos, U* procRam) 
{
  uint8_t* pRam = (uint8_t*) procRam;
  uint8_t ram_[convRamHeight*fmWidth]={0};
  long  offset = 0;
  if(readBottomData){
    if(yPos==0) {
      offset += (0+ithFM*fmSize8bits);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      if(yPos==yEndPos) { // 14x14
        fread(&(ram_[0])+fmWidth, sizeof(uint8_t), (convRamHeight-2)*fmWidth, (FILE*)fileDescriptor); //filling upper and lower padding with 0
      } else {
        fread(&(ram_[0])+fmWidth, sizeof(uint8_t), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor); //filling upper padding with 0
      }
    } else if(yPos==yEndPos) {
      offset += (ithFM*fmSize8bits + sizeof(uint8_t)*(yPos*atomicHeight-1)*fmWidth); //upper padding
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(uint8_t), (convRamHeight-1)*fmWidth, (FILE*)fileDescriptor);
    } else {
      offset += (ithFM*fmSize8bits + sizeof(uint8_t)*(yPos*atomicHeight-1)*fmWidth);
      fseek((FILE*)fileDescriptor, offset, SEEK_SET);
      fread(&(ram_[0]), sizeof(uint8_t), convRamHeight*fmWidth, (FILE*)fileDescriptor);
    }

    int i, j, k, m, n, p;
    if(xPos==0){
      for(i=0; i<convRamHeight; i++)
        pRam[i*convRamWidth] = 0; //filling left padding with 0 
      if(xPos==xEndPos) //14x14
        for(j=0; j<convRamHeight; j++)
          pRam[j*convRamWidth+convRamWidth-1] = 0;  //filling right padding with 0
    //printf("before assignment\n");
      for(k=0; k<convRamHeight; k++){
        if(xPos==xEndPos) {
          memcpy(pRam+k*convRamWidth+1, ram_+ k*fmWidth, sizeof(uint8_t)*(convRamWidth-2));
        } else {
          memcpy(pRam+k*convRamWidth+1, ram_+ k*fmWidth, sizeof(uint8_t)*(convRamWidth-1));
        }
      }
    //printf("after assignment\n");
    } else if(xPos==xEndPos){
      for(m=0; m<convRamHeight; m++)
        pRam[convRamWidth-1 + m*convRamWidth] = 0.;
      for( n=0; n<convRamHeight; n++){
        memcpy(pRam+n*convRamWidth, ram_+n*fmWidth+xPos*atomicWidth-1, sizeof(uint8_t)*(convRamWidth-1));
      }
    } else {
      for(p=0; p<convRamHeight; p++){
        memcpy(pRam+p*convRamWidth, ram_+p*fmWidth+xPos*atomicWidth-1, sizeof(uint8_t)*convRamWidth);
      }
    }
    printf("directC procRam readed: %d-ithFM, %d-xPos, %d-yPos\n", ithFM, xPos, yPos);
    // int r_h, r_w;
    // for(r_h=0; r_h<convRamHeight; r_h++){
    //   for(r_w=0; r_w<convRamWidth; r_w++){
    //     printf("%2x\t",pRam[r_h*convRamWidth+r_w]);
    //   }
    //   printf("\n");
    // }
  }
}

//compare two 16*16 sized data blocks(16bits)
U cmpRam_16bit(U cmpEnable, U* ramDirectC, U* ramVerilog)
{
  int notPass = 0;
  uint16_t* pRamDirectC = (uint16_t*) ramDirectC;
  uint16_t* pRamVerilog = (uint16_t*) ramVerilog;
  uint16_t error = 0;
  int i, j, k, m, n, p;
  if(cmpEnable) {
    printf("procRam data check\n");
    for(i=0; i<convRamHeight*convRamWidth; i++) {
      error = (*pRamVerilog) - (*pRamDirectC);
      if(error != 0) {
        printf("check error of %d-th procRam, value: %.4x, true value: %.4x\n", i, *pRamVerilog, *pRamDirectC);
        notPass = 1;
      }
      pRamDirectC++;
      pRamVerilog++;
    }
    if(notPass) {
      pRamVerilog = (uint16_t*) ramVerilog;
      pRamDirectC = (uint16_t*) ramDirectC;
      printf("directC:\n");
      for(k=0; k<convRamHeight; k++) {
        for( j=0; j<convRamWidth; j++) {
          printf("%.4x ", *pRamDirectC);
          pRamDirectC++;
        }
        printf("\n");
      }
      printf("verilog:\n");
      for(m=0; m<convRamHeight; m++) {
        for(n=0; n<convRamWidth; n++) {
          printf("%.4x ", *pRamVerilog);
          pRamVerilog++;
        }
        printf("\n");
      }
    } else{
      printf("check PASSED\n");
    }
  }
  return(notPass);
}
//compare two 16*16 sized data blocks(8bits)
U cmpRam_8bit(U cmpEnable, U* ramDirectC, U* ramVerilog)
{
  int notPass = 0;
  uint8_t* pRamDirectC = (uint8_t*) ramDirectC;
  uint8_t* pRamVerilog = (uint8_t*) ramVerilog;
  uint8_t error = 0;
  int i, j, k, m, n, p;
  if(cmpEnable) {
    printf("procRam data check\n");
    for(i=0; i<convRamHeight*convRamWidth; i++) {
      error = (*pRamVerilog) - (*pRamDirectC);
      if(error != 0) {
        printf("check error of %d-th procRam, value: %.2x, true value: %.2x\n", i, *pRamVerilog, *pRamDirectC);
        notPass = 1;
      }
      pRamDirectC++;
      pRamVerilog++;
    }
    if(notPass) {
      pRamVerilog = (uint8_t*) ramVerilog;
      pRamDirectC = (uint8_t*) ramDirectC;
      printf("directC:\n");
      for(k=0; k<convRamHeight; k++) {
        for( j=0; j<convRamWidth; j++) {
          printf("%.2x ", *pRamDirectC);
          pRamDirectC++;
        }
        printf("\n");
      }
      printf("verilog:\n");
      for(m=0; m<convRamHeight; m++) {
        for(n=0; n<convRamWidth; n++) {
          printf("%.2x ", *pRamVerilog);
          pRamVerilog++;
        }
        printf("\n");
      }
    }else{
      printf("check PASSED\n");
      pRamVerilog = (uint8_t*) ramVerilog;
      pRamDirectC = (uint8_t*) ramDirectC;
      printf("directC:\n");
      for(k=0; k<convRamHeight; k++) {
        for( j=0; j<convRamWidth; j++) {
          printf("%.2x ", *pRamDirectC);
          pRamDirectC++;
        }
        printf("\n");
      }
      printf("verilog:\n");
      for(m=0; m<convRamHeight; m++) {
        for(n=0; n<convRamWidth; n++) {
          printf("%.2x ", *pRamVerilog);
          pRamVerilog++;
        }
        printf("\n");
      }
    }
  }
  return(notPass);
}
//compare two 1*16 sized data(8bits)
U cmpRam(U cmpEnable, U* ramDirectC, U* ramVerilog, U col, U row)
{
  int notPass = 0;
  uint8_t* pRamDirectC = (uint8_t*) ramDirectC;
  uint8_t* pRamVerilog = (uint8_t*) ramVerilog;
  uint8_t error = 0;
  int i, j, k, m, n, p;
  if(cmpEnable) {
    // printf("procRam data check (col:%02d, row:%02d)\n", col,row);
    pRamDirectC += col;
    for(i=0; i<convRamHeight; i++) {
      error = (*pRamVerilog) - (*pRamDirectC);
      if(error != 0) {
        // printf("check error of %d-th procRam %d-th column, value: %.2x, true value: %.2x\n", i, col, *pRamVerilog, *pRamDirectC);
        notPass = 1;
      }
      pRamDirectC += convRamWidth;
      pRamVerilog++ ;
    }
      // if(col == 0)
      // {
      //   pRamDirectC = (uint8_t*) ramDirectC;
      //   printf("directC:\n");
      //   for(k=0; k<convRamHeight; k++) {
      //     for(j=0; j<convRamWidth; j++) {
      //       printf("%.2x ", *pRamDirectC);
      //       pRamDirectC++;
      //     }
      //     printf("\n");
      //   }
      // }
    if(notPass) {
      printf("error: procRam data check (col:%02d, row:%02d)\n", col,row);
      pRamDirectC = (uint8_t*) ramDirectC;
      printf("directC:\n");
      for(k=0; k<convRamHeight; k++) {
          for(j=0; j<convRamWidth; j++) {
            printf("%.2x ", *pRamDirectC);
            pRamDirectC++;
          }
          printf("\n");
      }
      pRamVerilog = (uint8_t*) ramVerilog;
      printf("verilog:\n");
      for(m=0; m<convRamHeight; m++) {
          printf("%.2x ", *pRamVerilog);
          pRamVerilog++;
      }
      printf("\n");
    } 
    // else{
    //   printf("check PASSED\n");
    // }
  }
  return(notPass);
}

//read a 64*3*3 sized kernal data(32bits) in original order
void readProcKer_32bit(void* fileDescriptor, U readKerData, U ithKer, U* procKer)
{
  void *pvKer = procKer;
  union val* pKer = pvKer;
  union val ker_[kerChannels*kerWidth*kerHeight] = {0};
  int ith = ithKer/kerChannels;
  // long offset = biasNUM*sizeof(union val); // bias offset: numOfBias*sizeof(union val), conv1_1 bias number
  long offset = 0;
  if(readKerData){
    offset += (ith*kerChannels*kerWidth*kerHeight*sizeof(union val));
    fseek((FILE*)fileDescriptor, offset, SEEK_SET);
    fread((&ker_[0]), sizeof(union val), kerChannels*kerWidth*kerHeight, (FILE*) fileDescriptor);
    memcpy(pKer, ker_, kerChannels*kerWidth*kerHeight*sizeof(union val));

    printf("directC ker readed(32-bit): %d-ith\n", ith); //idx of ker_patch(64 kernals make one patch)
    // display kernel data
    int i, j;
    for(i=0; i<kerChannels; i++) { // row
      for(j=0; j<kerWidth*kerHeight; j++) {
        printf("%f\t", ker_[i*kerHeight*kerWidth + j].fVal);
      }
      printf("\n");
    }
  }
  // printf("ker data read\n");
}

//read a 64*3*3 sized kernal data(8bits)
void readProcKer(void* fileDescriptor, U readKerData, U ithKer, U* procKer)
{
  void *pvKer = procKer;
  uint8_t* pKer = pvKer;
  uint8_t ker_[kerChannels*kerWidth*kerHeight] = {0};
  int ith = ithKer/kerChannels;
  long offset = biasNUM*sizeof(uint16_t); // bias offset: numOfBias*sizeof(union val), conv1_1 bias number
  if(readKerData){
    offset += (ith*kerChannels*kerWidth*kerHeight*sizeof(uint8_t));
    fseek((FILE*)fileDescriptor, offset, SEEK_SET);
    fread((&ker_[0]), sizeof(uint8_t), kerChannels*kerWidth*kerHeight, (FILE*) fileDescriptor);
    memcpy(pKer, ker_, kerChannels*kerWidth*kerHeight*sizeof(uint8_t));

    printf("directC ker readed: %d-ith\n", ith); //idx of ker_patch(64 kernals make one patch)
    // display kernel data
    // int i, j;
    // for(i=0; i<kerChannels; i++) { // row
    //   for(j=0; j<kerWidth*kerHeight; j++) {
    //     printf("%02x\t", ker_[i*kerHeight*kerWidth + j]);
    //   }
    //   printf("\n");
    // }
  }
  // printf("ker data read\n");
}

//compare two 64*3*3 sized kernal data(8bits)
U cmpKer(U cmpKerEnable, U* kerDirectC, U* kerVerilog)
{
  int notPass = 0;
  uint8_t* pKerDirectC = (uint8_t*) kerDirectC;
  uint8_t* pKerVerilog = (uint8_t*) kerVerilog;
  uint8_t error = 0;
  int i, j, k, m, n, p;
  if(cmpKerEnable) {
    // printf("kernal check\n");
    for(i=0; i<64*kerHeight*kerWidth; i++) {
      error = (*pKerVerilog) - (*pKerDirectC);
      if(error != 0) {
        printf("check error of %d-th procKer, value: %.2x, true value: %.2x\n", i, *pKerVerilog, *pKerDirectC);
        notPass = 1;
      }
      pKerDirectC++;
      pKerVerilog++;
    }
  }
  if(!notPass)  
    printf("kernal check PASSED\n");

  return(notPass);
}

//read all the bias data (16bits) of current layer
void readProcBias_16bit(void* fileDescriptor, U readBiasData, U* procBias)
{
  uint16_t* pBias = (uint16_t*)procBias;
  uint16_t bias_[biasNUM];
  long offset = 0;
  if(readBiasData){
    offset += 0;
    fseek((FILE*) fileDescriptor, offset, SEEK_SET);
    fread((&bias_[0]), sizeof(uint16_t), biasNUM, (FILE*) fileDescriptor);
    memcpy(pBias, bias_, biasNUM*sizeof(uint16_t));
  printf("directC bias readed\n");
  //printf(".");
  //for(int i=0; i<biasNUM; i++)
  //  printf("%.8x ", bias_[i]);
  }
}
//read all the bias data (29bits) of current layer
void readProcBias(void* fileDescriptor, U readBiasData, U* procBias)
{
  uint32_t* pBias = (uint32_t*)procBias;
  uint32_t bias_[biasNUM];
  long offset = 0;
  if(readBiasData){
    offset += 0;
    fseek((FILE*) fileDescriptor, offset, SEEK_SET);
    fread((&bias_[0]), sizeof(uint32_t), biasNUM, (FILE*) fileDescriptor);
    memcpy(pBias, bias_, biasNUM*sizeof(uint32_t));
  printf("directC bias readed\n");
  //printf(".");
  //for(int i=0; i<biasNUM; i++)
  //  printf("%.8x ", bias_[i]);
  }
}

//compare all the bias of one layer(16bits)
U cmpBias_16bit(U cmpBiasEnable, U* biasDirectC, U* biasVerilog)
{
  int notPass = 0;
  uint16_t* pBiasDirectC = (uint16_t*)biasDirectC;
  uint16_t* pBiasVerilog = (uint16_t*)biasVerilog;
  uint16_t error = 0;
  int i, j, k, m, n, p;
  if(cmpBiasEnable) {
    // printf("bias check (in fp_16 format)\n");
    for(i=0; i<biasNUM; i++){
      error = (*pBiasVerilog) - (*pBiasDirectC);
      if(error != 0) {
        printf("check error of %d-th procBias, value: %.4x, true value: %.4x\n", i, *pBiasVerilog, *pBiasDirectC);
        notPass = 1;
      }
      pBiasDirectC++;
      pBiasVerilog++;
    }
  }
  if(!notPass)
    printf("bias check PASSED (in fp_16 format) \n");
  return(notPass);
}

//compare all the bias of one layer(29bits)
U cmpBias(U cmpBiasEnable, U* biasDirectC, U* biasVerilog)
{
  int notPass = 0;
  uint32_t* pBiasDirectC = (uint32_t*)biasDirectC;
  uint32_t* pBiasVerilog = (uint32_t*)biasVerilog;
  uint32_t error = 0;
  int i, j, k, m, n, p;
  if(cmpBiasEnable) {
    // printf("bias check\n");
    for(i=0; i<biasNUM; i++){
      error = (*pBiasVerilog) - (*pBiasDirectC);
      if(error != 0) {
        printf("check error of %d-th procBias, value: %.8x, true value: %.8x\n", i, *pBiasVerilog, *pBiasDirectC);
        notPass = 1;
      }
      pBiasDirectC++;
      pBiasVerilog++;
    }
  }
  if(!notPass)
    printf("bias check PASSED\n");
  return(notPass);
}

//check conv_op output
//-------------------------------------------------------------------------------
// conv operation
void rearrangeRamData(U rearrangeEn, U* procPatch, U* procRam) //size: convRamWidth x convRamWidth --> (kerWidth*kerWidth) x (convRamWidth-kerWidth+1)(convRamWidth-kerWidth+1)
{
  union val* pPatch = (union val*)procPatch;
  union val* pDst = (union val*) procRam;
  
  int k_r, k_c, p_c, p_r; 
  if(rearrangeEn) {
    // read data from fData into fPatch
    for(p_r=0; p_r<atomicHeight; p_r++){
      for(p_c=0; p_c<atomicWidth; p_c++){
        for(k_r=0; k_r<kerHeight; k_r++){
          for(k_c=0; k_c<kerWidth; k_c++){
            memcpy(&pDst[(p_r*atomicWidth+p_c)*kerHeight*kerWidth + k_r*kerWidth + k_c], &pPatch[p_r*convRamWidth+p_c + k_r*convRamWidth+k_c], sizeof(union val));
          }
        }
      }
    }

    // float* pfDst = (float*)pDst;
    // printf("rearranged ram\n");
    // int i, j;
    // for(i=0; i<atomicHeight*atomicWidth; i++) {
    // for(j=0; j<kerHeight*kerWidth; j++)
    //   printf("%f\t", pDst[j + i*kerHeight*kerWidth].fVal);
    // //printf("%8.8x %5.3f ", pDst[j + i*kerHeight*kerWidth], pfDst[j + i*kerHeight*kerWidth]);
    // printf("\n");
    // }

  }
}

void rearrangeKerData(U rearrangeEn, U* procKer, U* procBlasKer) //size: kerWidth x kerWidth --> 1x(kerWidth*kerWdith)
{
  union val* pVerilogKer= (void*)procKer;
  union val* pBlasKer   = (void*)procBlasKer;

  //it needs to be a transpose matrix.
  int i;
  for(i=0; i<kerChannels*kerHeight*kerWidth; i++){
    memcpy(pBlasKer, pVerilogKer, sizeof(union val));
    pBlasKer++;
    pVerilogKer++;
  }
  // pBlasKer=(void*)procBlasKer;
  // printf("rearranged ker\n");
  // int k, j;
  // for(k=0; k<kerChannels; k++) {
  // for(j=0; j<kerHeight*kerWidth; j++)
  //   printf("%f\t", pBlasKer[j + k*kerHeight*kerWidth].fVal);
  // printf("\n");
  // }
}

//translate fixed numbers in 29bits to float numbers, which are in Complement form
int Fixed29toFp(float* DataFp32, unsigned int DataFixed, unsigned char BlockExp) {
	float* cur_fp32_pointer = DataFp32;
  
	unsigned char cur_exp = BlockExp;
	unsigned int cur_data = DataFixed;
	unsigned int content, sign, exp_diff, flag;

  //scheme 1
	sign =  (cur_data & 0x10000000) >> 28;
	content = cur_data & 0x0fffffff;
	if(sign)
		*cur_fp32_pointer = (float)((~content + 0x00000001)&0x0fffffff) * (-1) * pow(2,(cur_exp-30-12));
	else
		*cur_fp32_pointer = (float)content * (1) * pow(2,(cur_exp-30-12));

	return 0;
}

// correlation, conv_op out
U cmpCnnCorr(U* pData, U* pWeight, U* pVerilogOutput, U* pVerilogExp, U curKerset, U convX, U convY, U* pMaxError)
{
  void* vpBlasData= pData; // void pointer
  float* fpBlasData= vpBlasData;
  void* vpWeight  = pWeight;
  float* fpWeight  = vpWeight;
  void* vpVerilog = pVerilogOutput;
  unsigned int* uipCheckOutput = pVerilogOutput;
  unsigned char* pExp = pVerilogExp;
  void* vpMaxError= pMaxError;
  unsigned int* uipMaxError = vpMaxError;

  //verilog
  float fpVerilogFloat[kerChannels] = {0.0};
  void* vpVerilogFloat = fpVerilogFloat;
  unsigned int* uipVerilogFloat = vpVerilogFloat;
  int j;
  for (j=0; j<kerChannels; j++)
  {
    Fixed29toFp(&fpVerilogFloat[j], uipCheckOutput[j], pExp[curKerset+j]);
  }
 
  //directC: 
  float fpCnn[kerChannels] = {0};
  void* vpCnn = fpCnn;
  unsigned int* uipCnn = vpCnn;
  fpBlasData += (convY*atomicHeight + convX)*kerHeight*kerWidth;
  int m,n;
  for(m=0; m<kerChannels; m++){
    for(n=0; n<kerHeight*kerWidth; n++){
      fpCnn[m] += fpBlasData[n]*fpWeight[m*kerHeight*kerWidth+n];
    }
  }

  //cblas
  // int iM = 1; //atomicHeight*atomicWidth;
  // int iN = kerChannels;
  // int iK = kerHeight*kerWidth;
  // int iLDA=iK, iLDB=iK, iLDC=iN;
  // float fAlpha=1.0, fBeta=0.;
  // cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasTrans, iM, iN, iK, fAlpha, fpBlasData, iLDA, fpWeight, iLDB, fBeta, fpCnn, iLDC);

  //check error
  float f_c = 0;
  float f_v = 0;
  unsigned int ui_c = 0;
  unsigned int ui_v = 0;
  unsigned int uiError = 0;
  float fError = 0.;
  float fErrorRel = 0.;
  int i;
  int returnValue = 0;
  for(i=0; i<kerChannels; i++){
    unsigned int uiCheckNotPass = 0;

    f_c = fpCnn[i];
    f_v = fpVerilogFloat[i];
    ui_c = uipCnn[i];
    ui_v = uipVerilogFloat[i];
    
    // if(fabs(f_c) > fabs(f_v)){
    if(ui_c > ui_v) {
      fError = f_c - f_v;
      fErrorRel = fabs(fError/f_c);
      uiError = ui_c - ui_v;
    } else {
      fError = f_v - f_c;
      fErrorRel = fabs(fError/f_c);
      uiError = ui_v - ui_c;
    }
    // if(fErrorRel > 0.001)
    //   uiCheckNotPass = 1;

    if(fabs(f_c) < epsilonErrorConvop){
      if(fabs(f_v)>(10*epsilonErrorConvop))
        uiCheckNotPass  = 1;
    } else {
        if(fErrorRel > relativeError)
          uiCheckNotPass = 1;
    }
    // if(uiCheckNotPass){
    //   returnValue = 1;
    //   // printf("convop error at channel:%2d, x:%2d, y:%2d\tverilog:%8x, directC:%8x, uiError=%8x, fError=%8.4f, fErrorRel=%.4f, \n", i, convX, convY, uipCheckOutput[i], uipCnn[i], uiError, fError, fErrorRel);
    //   printf("convop error at channel:%2d, x:%2d, y:%2d,\tverilog:%8.4f,\tdirectC:%8.4f,\tfError=%8.4f,\tfErrorRel=%8.4f, \n", i, convX, convY, f_v, f_c, fError, fErrorRel);
    // }
    printf("convop error at channel:%2d, x:%2d, y:%2d,\tverilog:%8.4f,\tdirectC:%8.4f,\tfError=%8.4f,\tfErrorRel=%8.4f, \n", i, convX, convY, f_v, f_c, fError, fErrorRel);
  }

  return(returnValue);
}
//----------------------------------------------------------------------------------


//Comparing Verilog output with original 32-bit floating point number
//-------------------------------------------------------------------
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
  int i, j, k, m, n, p;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = fmHeight/2*fmWidth/2*channelIdx + patchOffset;
    printf("channel: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, patchOffset, posX, posY);
    // read data
    fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    for(j=0; j<atomicHeight/2; j++){
      fread(&directCResult[j*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth/2;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    }
    // convert short float data from verilogData
    for(i=0; i<49; i++) {
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
    for(k=0; k<atomicHeight/2; k++) {
      fread(&directCResult[k*atomicWidth/2], sizeof(unsigned int), atomicWidth/2, pFOrigTop);
      offset += fmWidth;
      fseek(pFOrigTop, offset*sizeof(unsigned int), SEEK_SET);
    //printf("patchOffset: %d\n", patchOffset);
    }
    // convert short float data from verilogData
    for(m=0; m<49; m++) {
      shortCvt2UInt(uipVerilog[m], &outputData_[m]);
    }
    printf("comparison without pooling\n");
  }
  // comparison
  if(cmp7x7En){
    int r, c, ir, ic;
    for(r=0; r<atomicHeight/2; r++) {
      for( c=0; c<atomicWidth/2; c++) {
        if(directCResult[r*atomicWidth/2 + c] > outputData_[r*atomicWidth/2+c]) {
          uiError = (directCResult[r*atomicWidth/2 + c] - outputData_[r*atomicWidth/2+c]);
          memcpy(&f0, &directCResult[r*atomicWidth/2 + c], sizeof(unsigned int)); //f0: the bigger one
          memcpy(&f1, &outputData_[r*atomicWidth/2+c], sizeof(unsigned int)); //f1: the smaller one
          iDirectCAtF0 = 1; //directC is f0
        } else {
          uiError = (outputData_[r*atomicWidth/2+c] - directCResult[r*atomicWidth/2 + c]);
          memcpy(&f0, &outputData_[r*atomicWidth/2+c], sizeof(unsigned int));
          memcpy(&f1, &directCResult[r*atomicWidth/2 + c], sizeof(unsigned int));
          iDirectCAtF0 = 0;
        }
        // check error
        if(((iDirectCAtF0==1) && ((f0) < epsilonError)) || ((iDirectCAtF0==0) && ((f1) < epsilonError))){ //directC < 
          if(((iDirectCAtF0==1) && (fabs(f1)>(10*epsilonError))) || ((iDirectCAtF0==0) && (fabs(f0)> (10*epsilonError)))) {  //verilog <
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
          printf("relative *top data error: channelNum: %4d, row: %2d, col: %2d, verilog: %8.8x, directC: %8.8x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f, f0: %.8f, f1: %.8f\n", channelIdx, r+1, c+1,
                      outputData_[r*atomicWidth/2 + c], directCResult[r*atomicWidth/2 + c], (f0)-(f1), fabs((f0)-(f1))/(f0), fabs((f0)-(f1))/(f1), (f0), (f1));
        }
      }
    }
    // inspection
    printf("-directC fm data:\n");
    for( ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for( ic=0; ic<atomicWidth/2; ic++){
        printf("%.8x ", directCResult[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
    printf("-verilog fm data:\n");
    printf("32 bit:\n");
    for( ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for( ic=0; ic<atomicWidth/2; ic++){
        printf("%.8x ", outputData_[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
    printf("16 bit:\n");
    for( ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for( ic=0; ic<atomicWidth/2; ic++){
        printf("%.4x ", uipVerilog[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
  }
  return(uiCheckNotPass);
//return(0);
}
//------------------------------------------------------------------------------------------------

//Comparing Verilog output results with block-floating-point based 16-bit semi-precision floating-point results 
//-------------------------------------------------------------------
U cmp7x7output_bfp(U cmp7x7En, U cmpPoolEn, void* fileDescriptor, U posX, U posY, U quarterIdx, U channelIdx, U* verilogOutputData)
{
  FILE* pFOrigTop;
  pFOrigTop = fileDescriptor;
  unsigned int outputData_[49]={0};
  unsigned int directCResult_[49]={0};
  unsigned short directCResult[49]={0};
  void *pvVerilog = verilogOutputData;
  unsigned short* uipVerilog = pvVerilog;
  unsigned int uiError;
  float f0, f1;
  unsigned int uiCheckNotPass = 0;
  unsigned int uiPrintPos     = 0;
  int   iDirectCAtF0 = 0;
  // read top data from file
  int patchOffset, offset;
  int i, j, k, m, n, p;
  if(cmpPoolEn) {
  // with pooling
    patchOffset = posX*atomicWidth/2 + posY*atomicHeight/2*fmWidth/2;
    offset = fmHeight/2*fmWidth/2*channelIdx + patchOffset;
    printf("channel: %d, patchOffset: %d, x: %d, y: %d\n", channelIdx, patchOffset, posX, posY);
    // read data
    fseek(pFOrigTop, offset*sizeof(unsigned short), SEEK_SET);
    for(j=0; j<atomicHeight/2; j++){
      fread(&directCResult[j*atomicWidth/2], sizeof(unsigned short), atomicWidth/2, pFOrigTop);
      offset += fmWidth/2;
      fseek(pFOrigTop, offset*sizeof(unsigned short), SEEK_SET);
    }
    // convert short float data from verilogData
    for(i=0; i<49; i++) {
      shortCvt2UInt(uipVerilog[i], &outputData_[i]);
      shortCvt2UInt(directCResult[i], &directCResult_[i]);
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
    fseek(pFOrigTop, offset*sizeof(unsigned short), SEEK_SET);
    for(k=0; k<atomicHeight/2; k++) {
      fread(&directCResult[k*atomicWidth/2], sizeof(unsigned short), atomicWidth/2, pFOrigTop);
      offset += fmWidth;
      fseek(pFOrigTop, offset*sizeof(unsigned short), SEEK_SET);
    //printf("patchOffset: %d\n", patchOffset);
    }
    // convert short float data from verilogData
    for(m=0; m<49; m++) {
      shortCvt2UInt(uipVerilog[m], &outputData_[m]);
      shortCvt2UInt(directCResult[m], &directCResult_[m]);
    }
    printf("comparison without pooling\n");
  }
  // comparison
  if(cmp7x7En){
    int r, c, ir, ic;
    for(r=0; r<atomicHeight/2; r++) {
      for( c=0; c<atomicWidth/2; c++) {
        if(directCResult_[r*atomicWidth/2 + c] > outputData_[r*atomicWidth/2+c]) {
          uiError = (directCResult_[r*atomicWidth/2 + c] - outputData_[r*atomicWidth/2+c]);
          memcpy(&f0, &directCResult_[r*atomicWidth/2 + c], sizeof(unsigned int)); //f0: the bigger one
          memcpy(&f1, &outputData_[r*atomicWidth/2+c], sizeof(unsigned int)); //f1: the smaller one
          iDirectCAtF0 = 1; //directC is f0
        } else {
          uiError = (outputData_[r*atomicWidth/2+c] - directCResult_[r*atomicWidth/2 + c]);
          memcpy(&f0, &outputData_[r*atomicWidth/2+c], sizeof(unsigned int));
          memcpy(&f1, &directCResult_[r*atomicWidth/2 + c], sizeof(unsigned int));
          iDirectCAtF0 = 0;
        }
        // check error
        if(((iDirectCAtF0==1) && ((f0) < 1)) || ((iDirectCAtF0==0) && ((f1) < 1))){ //directC < 
          if(((iDirectCAtF0==1) && (fabs(f1)>(1))) || ((iDirectCAtF0==0) && (fabs(f0)> (1)))) {  //verilog >
            uiCheckNotPass  = 1;
            uiPrintPos      = 1;
          } else {
            uiPrintPos      = 0;
          }
        } else {
          if(iDirectCAtF0==1) {
            if(fabs((f0)-(f1))/(f0) > 0.001) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          } else {
            if(fabs((f0)-(f1))/(f1) > 0.001) {
              uiCheckNotPass  = 1;
              uiPrintPos      = 1;
            } else {
              uiPrintPos      = 0;
            }
          }
        }
        if(uiPrintPos) {
          printf("relative *top data error: channelNum: %4d, row: %2d, col: %2d, verilog: %.4x, directC: %.4x, fError=%8.6f, rError0=%8.6f, rError1=%8.6f, f0: %.8f, f1: %.8f\n", channelIdx, r+1, c+1,
                      uipVerilog[r*atomicWidth/2 + c], directCResult[r*atomicWidth/2 + c], (f0)-(f1), fabs((f0)-(f1))/(f0), fabs((f0)-(f1))/(f1), (f0), (f1));
        }
      }
    }
    // inspection
    printf("-directC fm data:\n");
    printf("16 bit:\n");
    for( ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for( ic=0; ic<atomicWidth/2; ic++){
        printf("%.4x ", directCResult[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
    printf("-verilog fm data:\n");
    printf("16 bit:\n");
    for( ir=0; ir<atomicHeight/2; ir++){
      printf("-");
      for( ic=0; ic<atomicWidth/2; ic++){
        printf("%.4x ", uipVerilog[ir*atomicWidth/2 + ic]);
      }
      printf("\n");
    }
  }
  return(uiCheckNotPass);
//return(0);
}
//------------------------------------------------------------------------------------------------




