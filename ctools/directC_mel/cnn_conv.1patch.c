// read from char data file, calculate convolution continuously
#include<stdio.h>
#include<stdlib.h>
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
typedef union val float_t;

void readData(float_t *pfDst, int iPos_r, int iPos_c, int iFM_height, int iFM_width, FILE *pBottom);
void readParam(float_t *pfDst, FILE *pFWeight);
void cnnCorr(float* fCnn, float *fData, float* fWeight, int iM, int iN, int iK);

int main(int argc, char **argv)
{
  if(argc < 3){
    printf("usage: ./cnn_conv bottom_file weight_file\n");
    exit(0);
  }
  // open file
  FILE *pFBottom = NULL, *pFWeight = NULL;
  pFBottom = fopen(argv[1], "rb");
  pFWeight = fopen(argv[2], "rb");
  if(pFBottom<0 || pFWeight<0){
    printf("open file error\n");
    exit(1);
  }

  float_t fWeight[ker_height*ker_width * ker_channels]; // weight
  float_t fPatch[patch_height*patch_width * ker_height*ker_width]; // convolution data for cblas
  float_t fCnnConv[patch_height*patch_width * ker_channels];
  int     iPos_r, iPos_c; // convolution patch position (x,y)
  int     iFM_height, iFM_width; // feature map height/width
  iFM_height=224;
  iFM_width=224;
  iPos_r = 0;
  iPos_c = 0;
  rewind(pFBottom);
  rewind(pFWeight);
  // read data from bottom_file into fPatch
  readData(fPatch, iPos_r, iPos_c, iFM_height, iFM_width, pFBottom);
  // read data from weight_file, rotate, write into fWeight
  readParam(fWeight, pFWeight);
  fclose(pFBottom);
  fclose(pFWeight);
  // convolution
  // correlation of fPatch and rotated kernel -- fWeight
  cnnCorr((float*)fCnnConv, (float*)fPatch, (float*)fWeight, patch_height*patch_width, ker_channels, ker_height*ker_width);
  return(0);
}

void readData(float_t *pfDst, int iPos_r, int iPos_c, int iFM_height, int iFM_width, FILE *pFBottom)
{
  long iOffset, iOffset_r, iOffset_c;
  float_t fData[data_height*data_width];
  iOffset = 0;
  iOffset_r = 0;
  iOffset_c = 0;
  // read data from bottom_file into fData
  rewind(pFBottom);
  // patch
  for(int d_r=0; d_r<data_height; d_r++){
    iOffset_r = iPos_r + d_r-1;
    if(iOffset_r>=0 && iOffset_r<iFM_height){
      iOffset_c = iPos_c - 1;
      if(iOffset_c>=0){
        iOffset = (iOffset_r*iFM_width + iOffset_c)*sizeof(float_t);
      } else {
        iOffset = (iOffset_r*iFM_width)*sizeof(float_t);
      }
      fseek(pFBottom, iOffset, SEEK_SET);
    }
    for(int d_c=0; d_c<data_width; d_c++){
      iOffset_c = iPos_c + d_c-1;
      if(iOffset_r>=0 && iOffset_r<iFM_height &&
          iOffset_c>=0 && iOffset_c<iFM_width ){
        for(int i=0; i<sizeof(float_t); i++)
          fread(&(fData+d_r*data_width+d_c)->ucVal[sizeof(float_t)-1-i], 1, sizeof(char), pFBottom);
      }else{
        *((float*)fData+d_r*data_width+d_c) = 0.;
      }
    }
  }

  // read data from fData into fPatch
  for(int k_r=0; k_r<ker_height; k_r++){
    for(int k_c=0; k_c<ker_width; k_c++){
      for(int p_c=0; p_c<patch_width; p_c++){
        for(int p_r=0; p_r<patch_height; p_r++){
        //fPatch[(k_r*ker_width+k_c)*patch_height*patch_width + p_c*patch_height + p_r] // ker_height*ker_width x patch_height*patch_width
          pfDst[k_r*ker_width+k_c + (p_c*patch_height+p_r)*ker_height*ker_width] // patch_height*patch_width x ker_height*ker_widta
            = fData[p_c+k_c+ (p_r+k_r)*data_width];
        }
      }
    }
  }

  // check out fData
  printf("fData pointer: %p\n", fData);
  for(int i=0; i<data_height; i++){
    for(int j=0; j<data_width; j++){
      for(int k=0; k<sizeof(float_t); k++){
        printf("%x ", *((unsigned char*)(fData)+sizeof(float_t)*(i*data_width+j)+sizeof(float_t)-1-k));
      }
      printf("  ");
    }
    printf("\n");
  }

  printf("fData:\n");
  for(int i=0; i<data_height; i++){
    for(int j=0; j<data_width; j++){
      printf("%lf,", ((float_t*)(fData)+(i*data_width+j))->fVal);
    }
    printf("\n");
  }

//// check out patch of size patch_height*patch_width x ker_height*ker_width
//printf("fPatch:\n");
//for(int r=0; r<patch_height*patch_width; r++){
//  for(int c=0; c<ker_height*ker_width; c++)
//    printf("%f,", fPatch[r*patch_height*patch_width + c].fVal);
//  printf("\n");
//}

//// check out
//printf("convolution data\n");
//for(int k=0; k<ker_height*ker_width; k++){
//  printf("ker: %d\n", k);
//  for(int i=0; i<patch_height; i++){
//    for(int j=0; j<patch_width; j++){
//      printf("%f ",fPatch[k*patch_width*patch_height + i+j*patch_width].fVal);
//    }
//    printf("\n");
//  }
//  printf("\n");
//}


  return;
}

void readParam(float_t *pfDst, FILE *pFWeight)
{
//float_t fKernel[ker_channels*ker_height*ker_width]; // kernel

  // read data from weight_file into fKernel
  for(int k_ch=0; k_ch<ker_channels; k_ch++){
    for(int k_r=0; k_r<ker_width; k_r++){
      for(int k_c=0; k_c<ker_height; k_c++){
        for(int i=0; i<sizeof(float_t); i++)
        //fread(&(fKernel+k_ch*ker_height*ker_width + k_r*ker_width + k_c)->ucVal[sizeof(float_t)-1-i],
          fread(&(pfDst+k_ch*ker_height*ker_width + k_r*ker_width + k_c)->ucVal[sizeof(float_t)-1-i],
                1, sizeof(char), pFWeight);
      }
    }
  }
  // read data from fKernel into fWeight
//for(int w_ch=0; w_ch<ker_channels; w_ch++){
//  for(int w_i=0; w_i<ker_width*ker_height; w_i++)
//    pfDst[w_ch*ker_width*ker_height + ker_height*ker_width-1-w_i] = fKernel[w_ch*ker_width*ker_height + w_i];
//}

  // check out kernel
//printf("kernel:\n");
//for(int k_r=0; k_r<ker_height; k_r++){
//  for(int k_c=0; k_c<ker_width; k_c++)
//    printf("%lf,", fKernel[k_r*ker_width + k_c].fVal);
//  printf("\n");
//}
  printf("kernel:\n");
  for(int k_r=0; k_r<ker_height; k_r++){
    for(int k_c=0; k_c<ker_width; k_c++){
      for(int i=0; i<sizeof(float_t); i++){
        printf("%x ", *((unsigned char*)(pfDst) + sizeof(float_t)*(k_r*ker_width+k_c) + sizeof(float_t)-1-i));
      }
      printf(" ");
    }
    printf("\n");
  }

  return;
}

void cnnCorr(float *fCnn, float *fData, float* fWeight, int iM, int iN, int iK)
{
  int iLDA=iK, iLDB=iK, iLDC=iN;
  float fAlpha=1.0, fBeta=0.;
  cblas_sgemm(CblasRowMajor, CblasNoTrans, CblasTrans, iM, iN, iK, fAlpha, fData, iLDA, fWeight, iLDB, fBeta, fCnn, iLDC);

  // check out
  printf("convolution output:\n");
  for(int r=0; r<patch_height; r++){
    for(int c=0; c<patch_width; c++)
      printf("%lf,", fCnn[(r+c*patch_height)*ker_channels]);
    printf("\n");
  }

//for(int r=0; r<patch_height*patch_width; r++){
//  for(int c=0; c<ker_channels; c++)
//    printf("%lf,", fCnn[(r*ker_channels+c)]);
//  printf("\n");
//}

  return;
}
