// ---------------------------------------------------
// File       : topFSM.tb.c
//
// Description: DirectC c file
//
// Version    : 1.0
// ---------------------------------------------------
#include<stdio.h>
#include<stdlib.h>
#include"DirectC.h"

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

int readFloatNum(void *fileDescriptor, U* const fVal)
{
  size_t ulCheck;
  union val fRead, fIntermediate;
//ulCheck = fread((void*)fVal, 1, sizeof(union val), (FILE*)fileDescriptor);
  ulCheck = fread((void*)&fRead, 1, sizeof(union val), (FILE*)fileDescriptor);
  // little endian -> big endian
  for(int i=0; i<sizeof(union val); i++) {
    fIntermediate.ucVal[i] = fRead.ucVal[sizeof(union val)-1-i];
  }
  memcpy(fVal, (void*)&fIntermediate, sizeof(union val));
  if(ulCheck != sizeof(union val)){
    printf("read size: %lu != 1\n", ulCheck);
  }
  return((int)ulCheck);
}
