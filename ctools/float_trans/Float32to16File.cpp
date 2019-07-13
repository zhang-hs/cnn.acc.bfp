// Transform data from float32 to block-float-point,
// Kernal:An output channel as a block,including float32->float16, to block-float-point,transform order
// Data:All as a block,find the maximum exponent
//#include"stdafx.h"
#include <stdio.h>
#include <string>
#include <fstream>
#include <iostream>
#include <stdint.h>
#include <malloc.h>
#include <cmath>
//#include <assert.h>
using namespace std;

#define KER_SIZE 9 //3*3
#define IN_CHANNEL 3
#define OUT_CHANNEL 64
#define IN_BATCH 16
#define OUT_BATCH 64
#define IMG_SIZE_ORIG 224
#define	IMG_SIZE 256

#define	TOL 1e-3

// convert float32 to float16
int Float32to16(float* DataFp32, uint16_t* DataFp16, int FloatLen) {
	float* cur_fp32_pointer = DataFp32;
	uint16_t* cur_fp16_pointer = DataFp16;

	for (int idx = 0; idx < FloatLen; idx++) {
				uint32_t cur_data = *((uint32_t*)cur_fp32_pointer);
				uint32_t content, sign, exp;

				content = cur_data & 0x7fffffff;
				sign = cur_data & 0x80000000;
				exp = cur_data & 0x7f800000;

				content >>= 13; // 23-bit to 10-bit
				sign >>= 16; // 32-bit to 16-bit position

				content -= 0x1c000; // adjust bias

				content = (exp < 0x38800000) ? 0 : content; // to zero
				content = (exp > 0x47000000) ? 0x7bff : content; // to max

				if (cur_data & 0x1000)	//rounding off
					content++;

				content |= sign;

				*(uint16_t*)cur_fp16_pointer = content;

				cur_fp32_pointer++;
				cur_fp16_pointer++;
	}

	return 0;
}

int Float16to32(float* DataFp32, uint16_t* DataFp16, int FloatLen) {
	float* cur_fp32_pointer = DataFp32;
	uint16_t* cur_fp16_pointer = DataFp16;

	for (int idx = 0; idx < FloatLen; idx++) {
				uint16_t cur_data = *cur_fp16_pointer;
				uint32_t content, sign, exp;

				content = cur_data & 0x7fff;
				sign = cur_data & 0x8000;
				exp = cur_data & 0x7c00;

				content <<= 13; // 10-bits to 23-bits
				sign <<= 16; // 16-bit to 32-bit positin

				content += 0x38000000; // ajdust bias
				content = (exp == 0) ? 0 : content;

				content |= sign;

				*((uint32_t*)cur_fp32_pointer) = content;

				cur_fp16_pointer++;
				cur_fp32_pointer++;
	}
	return 0;
}


int main() {
	
	char* buffer;
	float* float32;
	uint16_t* float16;
	long file_size = 0;
	int num_size;

	char* fp32_filename = "./data.32bits/conv1_1/conv1_1.bias.txt";
	char* fp16_filename = "./data.32bits/conv1_1.output.c/conv1_1.param.txt";

	//assert(argc == 3);
	//std::ifstream fp32_file_handle(argv[1], std::ios::in | std::ios::binary);
	ifstream fp32_file_handle(fp32_filename, ios::in | ios::binary);
	if (!fp32_file_handle.is_open()) {
		cout << "ERROR: open fp32 file failed." << endl;
		return -1;
	}

	fp32_file_handle.seekg(0, ios::end);
	file_size = fp32_file_handle.tellg();
	cout << "File Size: " << file_size << endl;
	fp32_file_handle.seekg(0, ios::beg);

	buffer = new char[file_size];
	fp32_file_handle.read(buffer, file_size);
	fp32_file_handle.close();

	float32 = reinterpret_cast<float*>(buffer);
	num_size = file_size / 4;
	if (num_size != OUT_CHANNEL) {
		cout << "ERROR: opened wrong fp32 weight file." << endl;
		return -1;
	}
	float16 = new uint16_t[num_size];

	Float32to16(float32, float16, num_size);

#ifdef CHECK
	CheckAll();
#endif

	ofstream fp16_file_handle(fp16_filename, ios::out | ios::binary);
	if (!fp16_file_handle.is_open()) {
		cout << "ERROR: create fp16 file failed." << endl;
		return -1;
	}
	char* wr_buffer_fp16 = reinterpret_cast<char*>(float16);
	fp16_file_handle.write(wr_buffer_fp16, file_size/2);
	fp16_file_handle.close();

	delete[] float16;
	delete[] buffer;
	
	//CheckTransKerOrder();
	//CheckFloat32toBfp();

	return 0;
}
