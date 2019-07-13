// check how do floating-point-number denote 0 and its conversion
#include <stdio.h>
#include <cstring>
#include <stdint.h>
#include <stdlib.h>

using namespace std;
#define NUM_H 1
#define NUM_W 1
#define random(a, b) ((float)rand() / RAND_MAX *(b-a)+a)

int CheckFpBits(uint32_t* DataFp32)
{
  uint32_t cur_data = *DataFp32;
  uint32_t t1;
  uint32_t t2;
  uint32_t t3;
  
  t1 = cur_data & 0x80000000;
  t2 = cur_data & 0x7f800000;
  t3 = cur_data & 0x007fffff;

  printf("sign: %08x\n", t1);
  printf("exp: %08x\n", t2);
  printf("mant: %08x\n", t3);
}

int CheckFphBits(uint16_t* DataFph)
{
  uint16_t cur_data = *DataFph;
  uint16_t t1;
  uint16_t t2;
  uint16_t t3;
  
  t1 = cur_data & 0x8000;
  t2 = cur_data & 0x7c00;
  t3 = cur_data & 0x00ff;

  printf("sign: %04x\n", t1);
  printf("exp: %04x\n", t2);
  printf("mant: %04x\n", t3);
}

int FptoFph(float* DataFp32, uint16_t* DataFph)
{
  const float* cur_fp32_pointer = DataFp32;
  uint16_t* cur_fp16_pointer = DataFph;
  int i = 0;

  for(i = 0; i < NUM_H*NUM_W; ++i) {
    uint32_t cur_data = *((uint32_t*)cur_fp32_pointer);
    uint32_t t1;
    uint32_t t2;
    uint32_t t3;

    t1 = cur_data & 0x7fffffff;
    t2 = cur_data & 0x80000000;
    t3 = cur_data & 0x7f800000;

    t1 >>= 13; // 23-bit to 10-bit
    t2 >>= 16; // 32-bit to 16-bit position

    t1 -= 0x1c000; // adjust bias

    t1 = (t3 < 0x38800000) ? 0 : t1; // to zero
    t1 = (t3 > 0x47000000) ? 0x7bff : t1; // to max

    t1 |= t2;

    *(uint16_t*)cur_fp16_pointer = t1;

    cur_fp16_pointer++;
    cur_fp32_pointer++;
  }

  return 0;
}

int FphtoFp(float* DataFp32, uint16_t* DataFph) {
  float* cur_fp32_pointer = DataFp32;
  uint16_t* cur_fp16_pointer = DataFph;
  int i = 0;

  for (int i = 0; i < NUM_H*NUM_W; ++i)
  {
    uint32_t t1;
    uint32_t t2;
    uint32_t t3;
    uint16_t cur_data = *cur_fp16_pointer;

    t1 = cur_data & 0x7fff;
    t2 = cur_data & 0x8000;
    t3 = cur_data & 0x7c00;

    t1 <<= 13; // 10-bits to 23-bits
    t2 <<= 16; // 16-bit to 32-bit positin

    t1 += 0x38000000; // ajdust bias
    t1 = (t3 == 0) ? 0 : t1; 

    t1 |= t2;

    *((uint32_t*)cur_fp32_pointer) = t1;

    cur_fp16_pointer++;
    cur_fp32_pointer++;
  }

  return 0;
}

int main() {
  float fp32_orig = 0.0;
  float* fp32 = &fp32_orig;
  uint16_t* fp16 = new uint16_t [1];
  float* fp32_fp16 = new float [1];

  printf("float_orig: %f\n", *fp32);
  CheckFpBits((uint32_t*)fp32);

  FptoFph(fp32, fp16);
  CheckFphBits(fp16);

  FphtoFp(fp32_fp16, fp16);
  printf("float_fp16: %f\n", *fp32_fp16);
  CheckFpBits((uint32_t*)fp32_fp16);

	return 0;
}

