// convert float32 to block-floating-point
#include <stdio.h>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdint.h>
#include <malloc.h>
#include <cmath>
#include <stdlib.h>

using namespace std;

#define NUM_H 1000000
#define NUM_W 6
#define random(a, b) ((float)rand() / RAND_MAX *(b-a)+a)

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

// convert float32 to fixed(bfp)(1sign + 7mant)
int FphtoFixed(uint16_t* DataFph, uint8_t* DataFixed, uint8_t* BlockExp) {
	uint16_t* cur_fph_pointer = DataFph;
	uint8_t* cur_fixed_pointer = DataFixed;
	uint8_t* cur_BlockExp_pointer = BlockExp;
    uint8_t MaxExp = 0;
    //float* cur_err = err;

    for(int i=0; i < NUM_H*NUM_W; i++)
    {
        uint16_t cur_data = *cur_fph_pointer;
        uint16_t cur_exp;
        cur_exp = (cur_data & 0x7c00) >> 10;
        if(cur_exp > MaxExp)
            MaxExp = cur_exp;
        cur_fph_pointer++;
    }
    cur_fph_pointer -= NUM_H*NUM_W;
    //complement
    /*
    if(MaxExp < 0x0f)
        MaxExp = ((~((0x0f- MaxExp)&0x0f)+1) | 0x10);
    else
        MaxExp = MaxExp - 0x0f;
    */
    *cur_BlockExp_pointer = MaxExp; 

    for(int j=0; j < NUM_H*NUM_W; j++)
    {
        uint16_t cur_data = *cur_fph_pointer;
        uint16_t content, sign, cur_exp, exp_diff;

        sign = (cur_data & 0x8000) >> 8;
        content = (cur_data & 0x3ff) | 0x400;
        cur_exp = (cur_data & 0x7c00) >> 10;
        exp_diff = MaxExp - cur_exp; //right shift exp_diff+4 bits;
        
        
        // if( (content>>(exp_diff+4)&0xff) < 0x7f)
        //     content = content + (((content>>(exp_diff+4))&0x0001)<<(exp_diff+2)) + (0x0001<<(exp_diff+2));
        // content >>= (exp_diff+4);
        // if(sign)
        //     content = ~content + 0x0001; 
        
        //round to even
        content >>= exp_diff + 2;
        if((content & 0x1fc) != 0x1fc)
            content = content + ((content>>2)&0x0001) + 0x0001; //round to even
            // content = content + 0x0002; //round
        content >>= 2;
        if(sign)
            content = ~content + 0x0001;

        *cur_fixed_pointer = content;
        
        *cur_fph_pointer++;
        *cur_fixed_pointer++;
    }
	return 0;
}
/*
void FixedtoFph(uint16_t* DataFph, uint8_t* DataFixed, uint8_t* BlockExp)
{
    uint16_t* cur_fph_pointer = DataFph;
    uint8_t*  cur_fixed_pointer = DataFixed;
    uint8_t*  BlockExp_pointer = BlockExp;

    for(int i=0; i<NUM_H*NUM_W; i++)
    {
        uint8_t cur_fixed = *cur_fixed_pointer;
        uint16_t cur_exp = *((uint16_t*)BlockExp_pointer);
        uint16_t content, sign;

        sign = cur_fixed & 0x80;
        cur_exp = (cur_exp+15) << 10;
        content = (cur_fixed & 0x3f) << 4;

        content = content | cur_exp | sign;

        *cur_fph_pointer = content;

        cur_fixed_pointer++;
        cur_fph_pointer++; 
    }
}
*/
/*
int FixedtoFp(float* DataFp32, uint8_t* DataFixed, uint8_t* BlockExp) 
{
	float* cur_float32_pointer = DataFp32;
	uint8_t* cur_fixed_pointer = DataFixed;
	uint8_t* BlockExp_pointer = BlockExp;

		for (int i = 0; i < NUM_H*NUM_W; i++) {
            uint8_t cur_fixed = *cur_fixed_pointer;
			uint32_t cur_exp = *((uint32_t*)BlockExp_pointer);
            //cur_exp = cur_exp + 0x0000000f;
			uint32_t content, sign;

				content = cur_fixed & 0x3f;//bug
				sign = cur_fixed & 0x80;

				content <<= 17;
				sign <<= 24;
				cur_exp = (cur_exp << 23) + 0x38000000;

				content = content | cur_exp | sign;

				*((uint32_t*)cur_float32_pointer) = content;

				cur_float32_pointer++;
				cur_fixed_pointer++;
	}
	return 0;
}
*/
int FixedtoFp(float* DataFp32, uint8_t* DataFixed, uint8_t* BlockExp) 
{
    float* cur_float32_pointer = DataFp32;
	uint8_t* cur_fixed_pointer = DataFixed;
	uint8_t* BlockExp_pointer = BlockExp;

    for(int i=0; i<NUM_H*NUM_W; i++)
    {
        uint8_t cur_fixed = *cur_fixed_pointer;
        uint8_t cur_exp = *BlockExp_pointer;
        uint8_t content,sign;

        content = cur_fixed & 0x7f;
        sign = (cur_fixed & 0x80) >> 7;
        if(sign)
            *cur_float32_pointer = (float)((~content+0x01)&0x7f) *  pow((-1),sign) * pow(2,(cur_exp-15-6));
        else
            *cur_float32_pointer = (float)content *  pow((-1),sign) * pow(2,(cur_exp-15-6));

        cur_float32_pointer++;
        cur_fixed_pointer++;
    }
    return 0;
}

int main() {
    // const char* float32_filename = "../../data/bfp_trans/float32_c.txt";
    // const char* float16_filename = "../../data/bfp_trans/float16_c.txt";
    // const char* fixed8_filename = "../../data/bfp_trans/fixed8_c.txt";
    // const char* blockexp_filename = "../../data/bfp_trans/blockexp_c.txt";
    // const char* float32_fixed8_filename = "../../data/bfp_trans/float32_fixed_c.txt";
    const char* float32_filename = "../float32_c.txt";
    const char* float16_filename = "../float16_c.txt";
    const char* fixed8_filename = "../fixed8_c.txt";
    const char* blockexp_filename = "../blockexp_c.txt";
    const char* float32_fixed8_filename = "../float32_fixed_c.txt";

    float* float32 = new float [NUM_H*NUM_W];
    float* float32_fph16 = new float [NUM_H*NUM_W];
    float* float32_fixed8 = new float [NUM_H*NUM_W];
    uint16_t* float16 = new uint16_t [NUM_H*NUM_W];
    uint8_t* fixed8 = new uint8_t [NUM_H*NUM_W];
    uint8_t* exp5 = new uint8_t [1];
    float* err = new float [NUM_H*NUM_W];
    float err_sum = 0.0;
    float err_max_square = 0.0;
    float err_square = 0.0;
    
    //generate random numbers in float32
    for(int i=0; i<NUM_H; i++)
        for(int j=0; j<NUM_W; j++)
            *(float32+i*NUM_W+j) = pow((-1),j) * random(0,1);
    printf("orig_data\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
            printf("%f\t",*(float32+i*NUM_W+j));
        printf("\n");
    }
    
    printf("hex:orig_data\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
            printf("%4x\t",*((uint32_t*)float32+i*NUM_W+j));
        printf("\n");
    }
    
	//float32 to fph(16) back to 32
    FptoFph(float32, float16);
    ///*
    ofstream float16_file_handle(float16_filename, ios::out | ios::binary);
	if (!float16_file_handle.is_open()) {
		cout << "ERROR: create float16_file_handle file failed." << endl;
		return -1;
	}
	char* wr_buffer_float16 = reinterpret_cast<char*>(float16);
	float16_file_handle.write(wr_buffer_float16, NUM_H*NUM_W*sizeof(uint16_t));
    float16_file_handle.close();
    //*/

    
    printf("hex:fph16\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
            printf("%4x\t",*((uint16_t*)float16+i*NUM_W+j));
        printf("\n");
    }
    
    FphtoFp(float32_fph16, float16);
    ///*
    ofstream float32_file_handle(float32_filename, ios::out | ios::binary);
	if (!float32_file_handle.is_open()) {
		cout << "ERROR: create float32_file_handle file failed." << endl;
		return -1;
	}
	char* wr_buffer_float32 = reinterpret_cast<char*>(float32_fph16);
	float32_file_handle.write(wr_buffer_float32, NUM_H*NUM_W*sizeof(float));
    float32_file_handle.close();
    //*/
    printf("float32_fph16:\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
        {
            printf("%f\t",*(float32_fph16+i*NUM_W+j));
        }
        printf("\n");
    }
    
    printf("hex:float32_fph16\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
            printf("%4x\t",*((uint32_t*)float32_fph16+i*NUM_W+j));
        printf("\n");
    }
    
    ///*
    //fph16 to fixed8 and back to 32
    FphtoFixed(float16, fixed8, exp5);
    ///*
    ofstream fixed8_file_handle(fixed8_filename, ios::out | ios::binary);
	if (!fixed8_file_handle.is_open()) {
		cout << "ERROR: create fixed8_file_handle file failed." << endl;
		return -1;
	}
	char* wr_buffer_fixed8 = reinterpret_cast<char*>(fixed8);
	fixed8_file_handle.write(wr_buffer_fixed8, NUM_H*NUM_W*sizeof(uint8_t));
    fixed8_file_handle.close();
    ofstream blockexp_file_handle(blockexp_filename, ios::out | ios::binary);
	if (!blockexp_file_handle.is_open()) {
		cout << "ERROR: create blockexp_file_handle file failed." << endl;
		return -1;
	}
	char* wr_buffer_exp = reinterpret_cast<char*>(exp5);
	blockexp_file_handle.write(wr_buffer_exp, 1*sizeof(uint8_t));
    blockexp_file_handle.close();
    //*/
    printf("hex:fixed8,exp5\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
            printf("%4x,%4x\t",*(fixed8+i*NUM_W+j),*exp5);
        printf("\n");
    }
    
    FixedtoFp(float32_fixed8, fixed8, exp5);
    ///*
    ofstream float32_fixed8_handle(float32_fixed8_filename, ios::out | ios::binary);
	if (!float32_fixed8_handle.is_open()) {
		cout << "ERROR: create float32_fixed8_handle file failed." << endl;
		return -1;
	}
	char* wr_buffer_float32_fixed8 = reinterpret_cast<char*>(float32_fixed8);
	float32_fixed8_handle.write(wr_buffer_float32_fixed8, NUM_H*NUM_W*sizeof(float));
    float32_fixed8_handle.close();
    //*/
    printf("float32_fixed8:\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
        {
            printf("%f\t",*(float32_fixed8+i*NUM_W+j));
        }
        printf("\n");
    }
    printf("hex:float32_fixed8\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
            printf("%4x\t",*((uint32_t*)float32_fixed8+i*NUM_W+j));
        printf("\n");
    }
    
    //err
    printf("error_fph16_fixed8:\n");
    for(int i=0; i<NUM_H; i++)
    {
        for(int j=0; j<NUM_W; j++)
        {
            float err = *(float32_fph16+i*NUM_W+j)-*(float32_fixed8+i*NUM_W+j);
            printf("%f\t",err);
            err_sum += err;
            err_square = pow(err,2);
            if(err_max_square < err_square)
                err_max_square = err_square;
        }
        printf("\n");
    }
    printf("err_ave:\t%f\n",err_sum/(NUM_H*NUM_W));
    printf("err_max_square:\t%f\n",err_max_square);
    //*/
    delete[] float32;
    delete[] float32_fph16;
    delete[] float32_fixed8;
    delete[] fixed8;
    delete[] exp5;
    delete[] err;

	return 0;
}

