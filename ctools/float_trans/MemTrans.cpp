// Transform original image data to 7x7 unit storate form
#include<stdio.h>
#include<fstream>
#include<iostream>
#include<stdint.h>
#include<assert.h>
#include<string.h>

#define UNIT_SIZE 7
#define IMAGE_SIZE 224
#define TRANS_SIZE 256
#define STRIDE 15

int transImage( float* OrigData, float* TransData ) {
  
  int unitsCol = IMAGE_SIZE / UNIT_SIZE;
  int unitsRow = IMAGE_SIZE / UNIT_SIZE;
  int c = 0, i = 0, j = 0; 
  int ii = 0, jj = 0; 

  for( c = 0; c < 3; ++c ) {
    float* offsetImage = OrigData + c * IMAGE_SIZE * IMAGE_SIZE;
    float* offsetUnit = TransData + c * TRANS_SIZE * TRANS_SIZE;
    for( i = 0; i < unitsRow; ++i ) {
      for( j = 0; j < unitsCol; ++j ) {
        float* addrImage = offsetImage + ( i * UNIT_SIZE * IMAGE_SIZE ) + ( j * UNIT_SIZE );
        float* addrUnit = offsetUnit + ( i * unitsCol + j ) * ( UNIT_SIZE * UNIT_SIZE + STRIDE);
        for( ii = 0; ii < UNIT_SIZE; ++ii ) {	//get 7 pixels in each line(224)  of image
          memcpy( addrUnit, addrImage, UNIT_SIZE*sizeof(float) );
          addrUnit +=  UNIT_SIZE;	
          addrImage += IMAGE_SIZE; 
        }
      } 
    }
  }

  // Check
  for( c = 0; c < 3; ++c ) {
    printf("%dth Image\n", c);
    for( i = 0; i < unitsRow; ++i ) {
      for( j = 0; j < unitsCol; ++j ) {
        float* addrUnit = TransData + c * TRANS_SIZE * TRANS_SIZE + ( i * unitsCol + j ) * ( UNIT_SIZE * UNIT_SIZE + STRIDE);
        printf("%dth Unit Block\n",i*unitsCol+j );
        for( ii = 0; ii < UNIT_SIZE; ++ii ) {
          for( jj = 0; jj < UNIT_SIZE; ++jj ) {
            printf( "%f\t", *(addrUnit+jj) );
          }
          printf( "\n" );
          addrUnit += UNIT_SIZE;
        }
        printf("\n");
      } 
    }
   printf("\n");
  }

  return 0;
}

int main() {
  int c = 0, i = 0, j = 0;
  // Generate original 3x224x224 data
  float* origData = ( float* ) malloc( 3 * IMAGE_SIZE * IMAGE_SIZE * sizeof(float) );
  for( c = 0; c < 3; ++c ){
    for( i = 0; i < IMAGE_SIZE; ++i ) {
      for( j = 0; j < IMAGE_SIZE; ++j ) {
        *(origData + c*IMAGE_SIZE*IMAGE_SIZE + i*IMAGE_SIZE + j) = i * 1.0 + c;
      }
    }
  }

  for( c = 0; c < 3; ++c ){
    printf("%dth Image\n", c);
    for( i = 0; i < IMAGE_SIZE; ++i ) {
      printf("%dth Row\n", i);
      for( j = 0; j < IMAGE_SIZE; ++j ) {
        printf( "%f\t", *(origData + c*IMAGE_SIZE*IMAGE_SIZE + i*IMAGE_SIZE + j) );
      }
      printf("\n");
    }
    printf("\n");
  }
  // transform original data into 7x7 unit storage form
  float* transData = ( float* ) malloc( 3 * TRANS_SIZE * TRANS_SIZE * sizeof(float) );
  memset(transData, 0, 3 * TRANS_SIZE * TRANS_SIZE * sizeof(float) );
  transImage(origData, transData);

  free(origData);
  free(transData);
  return 0;
}
