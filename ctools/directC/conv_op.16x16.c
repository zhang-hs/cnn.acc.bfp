// ---------------------------------------------------
// File       : conv_op.16x16.c
//
// Description: read from char data file, calculate convolution continuously
//
// Version    : 1.0
// ---------------------------------------------------
#include<stdio.h>
#include<stdlib.h>
#include<stdint.h>
#include<string.h>
#include"DirectC.h"

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

void readProcRam(void *fileDescriptor, U* procRam, U* readFileDone) //read 8-bits number
{
  uint8_t ram[16*16] = {0}; // processing memory

  fread(ram, sizeof(uint8_t), 16*16, (FILE*)fileDescriptor);
  memcpy(procRam, ram, 16*16*sizeof(uint8_t));
  *readFileDone = 1;
  printf("data copied to procRam\n");
  return;
}

void readProcKer(void *fileDescriptor, U* procKer, U* readFileDone)
{
  uint8_t ram[3*3] = {0}; // processing memory

  fread(ram, sizeof(uint8_t), 3*3, (FILE*)fileDescriptor);
  memcpy(procKer, ram, 3*3*sizeof(uint8_t));
  *readFileDone = 1;
  printf("ker copied to procKer\n");
  return;
}

void readTopDirectC(void *fileDescriptor, U* procTop, U* readFileDone) //read 8-bits number
{
  uint32_t ram[14*14] = {0}; // processing memory

  fread(ram, sizeof(uint32_t), 14*14, (FILE*)fileDescriptor);
  memcpy(procTop, ram, 14*14*sizeof(uint32_t));
  *readFileDone = 1;
  printf("Top copied to procTop\n");
  return;
}

//convert 16-bit floating point array to 32-bit floating point array
void FphtoFp(uint16_t shortData, float* pFloat, uint32_t bottomExp, uint32_t kerExp)
{
  uint32_t xContent, xSign, xExp;

  xContent  = shortData & 0x7fff;
  xSign     = shortData & 0x8000;
  xExp      = shortData & 0x7c00;

  xContent <<= 13;
  xSign    <<= 16;

  xContent += 0x38000000;
  if((bottomExp+kerExp) < 30)
    xContent += ((30-bottomExp-kerExp) << 23);  
  else 
    xContent += ((bottomExp + kerExp - 30) << 23);
  xContent  = (xExp==0) ? 0 : xContent;

  xContent  |= xSign;
  memcpy(pFloat, &xContent, sizeof(unsigned int));
}

void cmpCnnCorr(U bottomExp, U kerExp, U convX, U convY, U* topDirectC, uint16_t* convTopFph, U* err)
{
  float curFp[1]= {0};
  float top_directC[14*14] = {0};
  float cur_err = 0;
  float cur_err_rel = 0;
  float* err_rel_total = (float*)err;
  int x, y;

  memcpy(top_directC, topDirectC, 14*14*sizeof(uint32_t));
  // for(y=0; y<14; y++)
  // {
  //   for(x=0; x<14; x++)
  //   {
  //     printf("%f ",top_directC[y*14+x]);
  //   }
  //   printf("\n");
  // }
  FphtoFp(convTopFph, curFp, bottomExp, kerExp); 
  // printf("%f ",*curFp);
  // if(convY == 13)
  //   printf("\n");

  cur_err = top_directC[14*convY+convX] - *curFp;
  cur_err_rel = cur_err/top_directC[14*convY+convX];
  *err_rel_total += cur_err_rel;
  printf("(%d,%d)\t%f\t%f\t%f\t%f\n",convX, convY, top_directC[14*convY+convX], *curFp, cur_err, cur_err_rel);
  if((convX == 13) && (convY == 13))
    printf("Average relative error: %f\n", *err_rel_total/(14*14));
  err = (unsigned int*)err_rel_total;

  return;
}

void printFp(U* Fp)
{
  float* float32 = (float*)Fp;
  float float32_ave = *float32;
  float32_ave = float32_ave/(14*14);

  printf("Average relative error: %f\n", float32_ave);
}
