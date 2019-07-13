#include<stdio.h>
#include<stdint.h>
#include"DirectC.h"

// transform to 16-bit float
void to_float16(U Fp32, U* Fp16);

// restore to 32-bit float
void to_float32(U Fp16, U* Fp32);

void to_float16(U Fp32, U* Fp16) {
  uint32_t cur_data = (uint32_t)Fp32;
  uint32_t t1;
  uint32_t t2;
  uint32_t t3;

  t1 = cur_data & 0x7fffffff; // exp and mantisa
  t2 = cur_data & 0x80000000; // sign
  t3 = cur_data & 0x7f800000; // exp

  if(t1 & 0x00001000) // round
      t1 = t1 | 0x00002000;

  t1 >>= 13; // 23-bit to 10-bit
  t2 >>= 16; // 32-bit to 16-bit position

  t1 -= 0x1c000; // adjust bias

  t1 = (t3 < 0x38800000) ? 0 : t1; // to zero
  t1 = (t3 > 0x47000000) ? 0x7bff : t1; // to max

  t1 |= t2;

  *((uint16_t*)Fp16) = t1;

  return;
}

void to_float32(U Fp16, U* Fp32) {
  uint32_t t1;
  uint32_t t2;
  uint32_t t3;
  uint16_t cur_data = Fp16;

  t1 = cur_data & 0x7fff;
  t2 = cur_data & 0x8000;
  t3 = cur_data & 0x7c00;

  t1 <<= 13; // 10-bits to 23-bits
  t2 <<= 16; // 16-bit to 32-bit positin

  t1 += 0x38000000; // ajdust bias
  t1 = (t3 == 0) ? 0 : t1;

  t1 |= t2;

  *((uint32_t*)Fp32) = t1;
}
