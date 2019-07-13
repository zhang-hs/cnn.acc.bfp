// Transform data from float32 to block-float-point,
// Kernal:An output channel as a block,including float32->float16, to block-float-point,transform order
// Data:All as a block,find the maximum exponent
//#include"stdafx.h"
#include<stdio.h>
#include<string.h>
#include<fstream>
#include<iostream>
#include<malloc.h>
#include<stdint.h>
#include<cmath>

using namespace std;

#define OUT_CHANNEL 0 //0~12 corrsponding to conv1_1~conv5_3

int main()
{
  //file in floating-point
  const char* bias_fp32_fn = "../../data/caffe_32bits/conv1_1/conv1_1.bias.txt";
  const char* weight_fp32_fn = "../../data/caffe_32bits/conv1_1/conv1_1.weight.txt";
  const char* bottom_fp32_fn = "../../data/caffe_32bits/conv1_1/conv1_1.bottom.txt";
  //file in block-floating-point
  const char* bias_fp16_fn = "../../data/caffe_bfp/conv1_1/conv1_1.bias.txt";
  const char* weight_bfp_fn = "../../data/caffe_bfp/conv1_1/conv1_1.weight.txt";
  const char* param_fn  = "../../data/caffe_bfp/conv1_1/conv1_1.param.txt"; //bias_fp16+weight_bfp
  const char* bottom_fn = "../../data/caffe_bfp/conv1_1/conv1_1.bottom.txt"; //bottom_fp16(with 49-->64)

  ifstream bias_fp32_fd(bias_fp32_fn, ios::in | ios::binary);
  char* rd_bias_fp32_buffer = new char[OUT_CHANNEL*sizeof(float)];
  bias_fp32_fd.read(rd_bias_fp32_buffer, )

}
