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
//#include<assert.h>

using namespace std;

#define FM_SIZE 224
#define KER_SIZE 3 //3*3
#define IN_CHANNEL 3
#define OUT_CHANNEL 64
#define UNIT_SIZE 7
#define TRANS_SIZE 256
#define STRIDE 15

#define	TOL 1e-3
#define random(a, b) ((float)rand() / RAND_MAX)

int FptoFph(float* DataFp32, uint16_t* DataFph, unsigned int num)
{
  const float* cur_fp32_pointer = DataFp32;
  uint16_t* cur_fp16_pointer = DataFph;
  unsigned int i = 0;

  for(i = 0; i < num; ++i) {
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

int FphtoFp(float* DataFp32, uint16_t* DataFph, unsigned int num) {
  float* cur_fp32_pointer = DataFp32;
  uint16_t* cur_fp16_pointer = DataFph;
  unsigned int i = 0;

  for (i = 0; i < num; ++i)
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

// find the maximum exponent of input feather maps
int FindBlockExp(uint16_t* DataFph, uint8_t* BlockExp) {
	uint16_t* cur_fp16_pointer = DataFph;
	uint8_t* cur_be_pointer = BlockExp;
	
	uint8_t MaxExp = 0;
	/*
	unsigned int in, data;
	for (in = 0; in < IN_CHANNEL*FM_SIZE*FM_SIZE; in++) {
		for (data = 0; data < 1; data++) {
			uint16_t cur_data = *cur_fp16_pointer;
			uint16_t cur_exp;
			cur_exp = (cur_data & 0x7c00) >> 10;
			if (cur_exp > MaxExp)
				MaxExp = cur_exp;
			cur_fp16_pointer++;
		}
	}
	*/
	int c, i, j, ii, jj;
	int unitsCol = FM_SIZE / UNIT_SIZE;
	int unitsRow = FM_SIZE / UNIT_SIZE;
  for( c = 0; c < IN_CHANNEL; ++c ) {
    for( i = 0; i < unitsRow; ++i ) {
      for( j = 0; j < unitsCol; ++j ) {
        uint16_t* cur_addr = cur_fp16_pointer + c*TRANS_SIZE*TRANS_SIZE + (i*unitsCol+j)*(UNIT_SIZE*UNIT_SIZE + STRIDE);
        for( ii = 0; ii < UNIT_SIZE; ++ii ) {
          for( jj = 0; jj < UNIT_SIZE; ++jj ) {
						uint16_t cur_exp = (*cur_addr & 0x7c00) >> 10;
						if (cur_exp > MaxExp)
							MaxExp = cur_exp;
          }
          cur_addr += UNIT_SIZE;
        }
      } 
    }
  }
	*cur_be_pointer = MaxExp;

	return 0;
}

// convert float32 to block-floating-point
int Fphtofixed(uint16_t* DataFph, uint8_t* DataFixed, uint8_t* BlockExp) {
	uint16_t* cur_fp16_pointer = DataFph;
	uint8_t* cur_fixed_pointer = DataFixed;
	uint8_t* cur_be_pointer = BlockExp;
	
	int out = 0, in = 0, ker = 0;
	for (out = 0; out < OUT_CHANNEL; out++) {
		uint8_t MaxExp = 0;
		for (in = 0; in < IN_CHANNEL; in++) {
			for (ker = 0; ker < KER_SIZE*KER_SIZE; ker++) {
				uint16_t cur_data = *cur_fp16_pointer;
				uint16_t cur_exp;
				cur_exp = (cur_data & 0x7c00) >> 10;
				if (cur_exp > MaxExp)
					MaxExp = cur_exp;
				cur_fp16_pointer++;
			}
		}
		*cur_be_pointer = MaxExp;

		cur_fp16_pointer -= IN_CHANNEL*KER_SIZE*KER_SIZE;
		for (in = 0; in < IN_CHANNEL; in++) {
			for (ker = 0; ker < KER_SIZE*KER_SIZE; ker++) {
				uint16_t cur_data = *cur_fp16_pointer;
				uint16_t content, sign, cur_exp, exp_diff;

				sign = (cur_data & 0x8000) >> 8;
				content = (cur_data & 0x3ff) | 0x400;
				cur_exp = (cur_data & 0x7c00) >> 10;
				exp_diff = MaxExp - cur_exp; //right shift exp_diff+4 bits;

				//round to even
				content >>= exp_diff + 2;
				if((content & 0x1fc) != 0x1fc)
					content = content + ((content>>2)&0x0001) + 0x0001;
				content >>= 2;
				if(sign)
					content = ~content + 0x0001;

				*cur_fixed_pointer = content;

				cur_fp16_pointer++;
				cur_fixed_pointer++;
			}
		}
		cur_be_pointer++;
	}
	return 0;
}

int FixedtoFp(float* DataFp32, uint8_t* DataFixed, uint8_t* BlockExp) {
	float* cur_fp32_pointer = DataFp32;
	uint8_t* cur_fixed_pointer = DataFixed;
	uint8_t* cur_be_pointer = BlockExp;
	
	int out = 0, in = 0, ker = 0;
	for (out = 0; out < OUT_CHANNEL; out++) {
		uint8_t cur_exp = *cur_be_pointer;	
		for (in = 0; in < IN_CHANNEL; in++) {
			for (ker = 0; ker < KER_SIZE*KER_SIZE; ker++) {
				uint8_t cur_fixed = *cur_fixed_pointer;
				uint8_t content, sign;

				content = cur_fixed & 0x7f;
				sign = (cur_fixed & 0x80) >> 7;
				if(sign)
					*cur_fp32_pointer = (float)((~content+0x01)&0x7f) *  pow((-1),sign) * pow(2,(cur_exp-15-6));
				else
					*cur_fp32_pointer = (float)content *  pow((-1),sign) * pow(2,(cur_exp-15-6));

				cur_fp32_pointer++;
			    cur_fixed_pointer++;
			}
		}
		cur_be_pointer++;
	}
	return 0;
}

// trans to 7x7
int TransFmOrder(float* OrigData, float* TransData) {
	//Trans
	int unitsCol = FM_SIZE / UNIT_SIZE;
	int unitsRow = FM_SIZE / UNIT_SIZE;
	int c = 0, i = 0, j = 0;
	int ii = 0, jj = 0;

	for(c = 0; c < IN_CHANNEL; ++c)
	{
		float* offsetFm = OrigData + c*FM_SIZE*FM_SIZE;
		float* offsetUnit = TransData + c*TRANS_SIZE*TRANS_SIZE;
		for(i = 0; i < unitsRow; ++i)
		{
			for(j = 0; j < unitsCol; ++j)
			{
				float* addrFm = offsetFm + (i*UNIT_SIZE*FM_SIZE) + (j*UNIT_SIZE);
				float* addrUnit = offsetUnit + (i*unitsCol+j) * (UNIT_SIZE*UNIT_SIZE+STRIDE);
				for(ii = 0; ii < UNIT_SIZE; ++ii)
				{
					memcpy(addrUnit, addrFm, UNIT_SIZE*sizeof(float));
					addrUnit += UNIT_SIZE;
					addrFm += FM_SIZE;
				}
			}
		}
	}

	//check
  for( c = 0; c < IN_CHANNEL; ++c ) {
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
	ofstream outf("out.txt");
	streambuf *default_buf = cout.rdbuf(); //get cout outputs
	cout.rdbuf(outf.rdbuf()); //redirect cout output to file
	cout.rdbuf(default_buf); //restore cout default output, output to screen
  const char* fm_orig_filename = "../../data/caffe_32bit/conv1_1/conv1_1.bottom.txt";
  const char* ker_orig_filename = "../../data/caffe_32bit/conv1_1/conv1_1.weight.txt";
	const char* fm_fp16_filename = "../../data/caffe_bfp/conv1_1/conv1_1.bottom.txt";
  const char* ker_fixed8_filename = "../../data/caffe_bfp/conv1_1/conv1_1.weight.txt";
  const char* BlockExp_filename = "../../data/caffe_bfp/conv1_1/conv1_1.blockexp.txt";
  //const char* float32_fixed8_filename = "../../data/bfp_trans/float32_fixed_c.txt";
	//check
	int c, i, j, ii, jj;
	int unitsCol = FM_SIZE / UNIT_SIZE;
	int unitsRow = FM_SIZE / UNIT_SIZE;
  float err_sum = 0.0;
  float err_max_square = 0.0;
  float err_square = 0.0;

	//ker_orig_file to ker_fixed8_file
	//--------------------------------------------------------------------
	///*
	ifstream ker_orig_fd(ker_orig_filename, ios::in | ios::binary);
	if (!ker_orig_fd.is_open()) {
		cout << "ERROR: create ker_orig file failed." << endl;
		return -1;
	}
	ker_orig_fd.seekg(0, ios::end);
	unsigned int ker_file_size = ker_orig_fd.tellg();
	if(ker_file_size != IN_CHANNEL*OUT_CHANNEL*KER_SIZE*KER_SIZE*sizeof(float))
	{
		cout << "ERROR: opend wrong file." << endl;
	}
	char* rd_buffer_ker = new char[ker_file_size];
	ker_orig_fd.seekg(0, ios::beg);
	ker_orig_fd.read(rd_buffer_ker, ker_file_size);
	ker_orig_fd.close();
	float* ker_orig = reinterpret_cast<float*>(rd_buffer_ker);
	//check
	/*
	cout << endl << endl << endl << "ker_orig" << endl;
  for( c = 0; c < OUT_CHANNEL; ++c ) {
		cout << c << "dth ker" << endl;
    for( i = 0; i < IN_CHANNEL; ++i ) {
      for( j = 0; j < KER_SIZE*KER_SIZE; ++j ) {
        float* addrUnit = ker_orig + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				//printf( "%f\t", *(addrUnit+jj) );
				cout << *addrUnit << "\t";
      }
			cout << endl;
		}	
   cout << endl;
  }
	*/
	uint16_t* ker_fp16 = new uint16_t[ker_file_size/4];
	uint8_t* ker_fixed8 = new uint8_t[ker_file_size/4];
  uint8_t* ker_BlockExp = new uint8_t[OUT_CHANNEL];
	FptoFph(ker_orig, ker_fp16, ker_file_size/4);
	//float* ker_fp32_16 = new float[ker_file_size/4];
	//FphtoFp(ker_fp32_16, ker_fp16, ker_file_size/4);
	//check
	/*
	cout << endl << endl << endl << "ker_fp32_from_fp16" << endl;
  for( c = 0; c < OUT_CHANNEL; ++c ) {
		cout << c << "dth ker" << endl;
    for( i = 0; i < IN_CHANNEL; ++i ) {
      for( j = 0; j < KER_SIZE*KER_SIZE; ++j ) {
        float* addrUnit = ker_fp32_16 + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				//printf( "%f\t", *(addrUnit+jj) );
				cout << *addrUnit << "\t";
      }
			cout << endl;
		}	
   cout << endl;
  }
	*/
	//check
	/*
	err_sum = 0.0;
  err_max_square = 0.0;
  err_square = 0.0;
	cout << endl << endl << endl << "err_ker_fp32_fp16" << endl;
  for( c = 0; c < OUT_CHANNEL; ++c ) {
		cout << c << "dth ker" << endl;
    for( i = 0; i < IN_CHANNEL; ++i ) {
      for( j = 0; j < KER_SIZE*KER_SIZE; ++j ) {
        float* addrUnit1 = ker_fp32_16 + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				float* addrUnit2 = ker_orig + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				float err = *(addrUnit1)-*(addrUnit2);
				cout << err << "\t";
				err_sum += err;
        err_square = pow(err,2);
        if(err_max_square < err_square)
          err_max_square = err_square;
      }
			cout << endl;
		}	
   cout << endl;
  }
	cout << "err_ave" << "\t" << err_sum/(ker_file_size/4) << endl;
	cout << "err_max_square" << "\t" << err_max_square << endl;
	*/
	///*
	Fphtofixed(ker_fp16, ker_fixed8, ker_BlockExp);
	//float* ker_fp32_8 = new float[ker_file_size/4];
	//FixedtoFp(ker_fp32_8, ker_fixed8, ker_BlockExp);
	//check
	/*
	cout << endl << endl << endl << "ker_fp32_from_fixed8" << endl;
  for( c = 0; c < OUT_CHANNEL; ++c ) {
		cout << c << "dth ker" << endl;
    for( i = 0; i < IN_CHANNEL; ++i ) {
      for( j = 0; j < KER_SIZE*KER_SIZE; ++j ) {
        float* addrUnit = ker_fp32_8 + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				//printf( "%f\t", *(addrUnit+jj) );
				cout << *addrUnit << "\t";
      }
			cout << endl;
		}	
   cout << endl;
  }
	*/
	/*
	err_sum = 0.0;
  err_max_square = 0.0;
  err_square = 0.0;
	cout << endl << endl << endl << "err_ker_fp32_fixed8" << endl;
  for( c = 0; c < OUT_CHANNEL; ++c ) {
		cout << c << "dth ker" << endl;
    for( i = 0; i < IN_CHANNEL; ++i ) {
      for( j = 0; j < KER_SIZE*KER_SIZE; ++j ) {
        float* addrUnit1 = ker_fp32_16 + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				float* addrUnit2 = ker_fp32_8 + c*IN_CHANNEL*KER_SIZE*KER_SIZE + i*KER_SIZE*KER_SIZE + j;
				float err = *(addrUnit1)-*(addrUnit2);
				cout << err << "\t";
				err_sum += err;
        err_square = pow(err,2);
        if(err_max_square < err_square)
          err_max_square = err_square;
      }
			cout << endl;
		}	
   cout << endl;
  }
	cout << "err_ave" << "\t" << err_sum/(ker_file_size/4) << endl;
	cout << "err_max_square" << "\t" << err_max_square << endl;
	*/
	///*
	ofstream ker_fixed8_fd(ker_fixed8_filename, ios::out | ios::binary);
	if(!ker_fixed8_fd.is_open())
	{
		cout << "ERROR: create ker_fixed8 file failed." << endl;
		return -1;
	}
	char* wr_buffer_ker = reinterpret_cast<char*>(ker_fixed8);
	ker_fixed8_fd.write(wr_buffer_ker, ker_file_size/4);
	ker_fixed8_fd.close();
	ofstream BlockExp_fd(BlockExp_filename, ios::out | ios::binary);
	if(!BlockExp_fd.is_open())
	{
		cout << "ERROR: create BlockExp file failed." << endl;
		return -1;
	}
	char* wr_buffer_ker_be = reinterpret_cast<char*>(ker_BlockExp);
	BlockExp_fd.write(wr_buffer_ker_be, OUT_CHANNEL);
	BlockExp_fd.close();
	//*/

	//fm_orig_file to fm_fp16_file
	//----------------------------------------------------------------
	///*
	cout << 1 << endl;
	ifstream fm_orig_fd(fm_orig_filename, ios::in | ios::binary);
	if (!fm_orig_fd.is_open()) {
		cout << "ERROR: create fm_orig file failed." << endl;
		return -1;
	}
	fm_orig_fd.seekg(0, ios::end);
	unsigned int fm_file_size = fm_orig_fd.tellg();
	if(fm_file_size != IN_CHANNEL*TRANS_SIZE*TRANS_SIZE*sizeof(float))
	{
		cout << "ERROR: opend wrong file." << endl;
		return -1;
	}
	char* rd_buffer_fm = new char[fm_file_size];
	fm_orig_fd.seekg(0, ios::beg);
	fm_orig_fd.read(rd_buffer_fm, fm_file_size);
	fm_orig_fd.close();
	float* fm_orig = reinterpret_cast<float*>(rd_buffer_fm); 
	//*/
	//check
	/*
	cout << endl << endl << endl << "fm_orig" << endl;
  for( c = 0; c < IN_CHANNEL; ++c ) {
		cout << c << "dth Image" << endl;
    for( i = 0; i < unitsRow; ++i ) {
      for( j = 0; j < unitsCol; ++j ) {
        float* addrUnit = fm_orig + c*TRANS_SIZE*TRANS_SIZE + (i*unitsCol+j)*(UNIT_SIZE*UNIT_SIZE + STRIDE);
        cout << (i*unitsCol+j) << "th Unit Block" << endl;
        for( ii = 0; ii < UNIT_SIZE; ++ii ) {
          for( jj = 0; jj < UNIT_SIZE; ++jj ) {
						//printf( "%f\t", *(addrUnit+jj) );
						cout << *(addrUnit+jj) << "\t";
          }
          cout << endl;
          addrUnit += UNIT_SIZE;
        }
        cout << endl;
      } 
    }
   cout << endl;
  }
	*/
	///*
	uint16_t* fm_fp16 = new uint16_t[fm_file_size/4];
	FptoFph(fm_orig, fm_fp16, fm_file_size/4);
	cout << 2 << endl;
	//float* fm_fp32_16 = new float[fm_file_size/4];
	//FphtoFp(fm_fp32_16, fm_fp16, fm_file_size/4);
	//*/
	//check
	/*
	cout << endl << endl << endl << "fm_fp32_from_fp16" << endl;
  for( c = 0; c < IN_CHANNEL; ++c ) {
		cout << c << "dth Image" << endl;
    for( i = 0; i < unitsRow; ++i ) {
      for( j = 0; j < unitsCol; ++j ) {
        float* addrUnit = fm_fp32_16 + c*TRANS_SIZE*TRANS_SIZE + (i*unitsCol+j)*(UNIT_SIZE*UNIT_SIZE + STRIDE);
        cout << (i*unitsCol+j) << "th Unit Block" << endl;
        for( ii = 0; ii < UNIT_SIZE; ++ii ) {
          for( jj = 0; jj < UNIT_SIZE; ++jj ) {
						//printf( "%f\t", *(addrUnit+jj) );
						cout << *(addrUnit+jj) << "\t";
          }
          cout << endl;
          addrUnit += UNIT_SIZE;
        }
        cout << endl;
      } 
    }
   cout << endl;
  }
	//check error
	err_sum = 0.0;
  err_max_square = 0.0;
  err_square = 0.0;
	cout << endl << endl << endl << "err_fm_fp32_fp16" << endl;
  for( c = 0; c < IN_CHANNEL; ++c ) {
		cout << c << "dth Image" << endl;
    for( i = 0; i < unitsRow; ++i ) {
      for( j = 0; j < unitsCol; ++j ) {
        float* addrUnit1 = fm_fp32_16 + c*TRANS_SIZE*TRANS_SIZE + (i*unitsCol+j)*(UNIT_SIZE*UNIT_SIZE + STRIDE);
        float* addrUnit2 = fm_orig + c*TRANS_SIZE*TRANS_SIZE + (i*unitsCol+j)*(UNIT_SIZE*UNIT_SIZE + STRIDE);
				cout << (i*unitsCol+j) << "th Unit Block" << endl;
        for( ii = 0; ii < UNIT_SIZE; ++ii ) {
          for( jj = 0; jj < UNIT_SIZE; ++jj ) {
						//printf( "%f\t", *(addrUnit+jj) );
						float err = *(addrUnit1+jj)-*(addrUnit2+jj);
						cout << err << "\t";
						err_sum += err;
            err_square = pow(err,2);
            if(err_max_square < err_square)
                err_max_square = err_square;
          }
          cout << endl;
          addrUnit1 += UNIT_SIZE;
					addrUnit2 += UNIT_SIZE;
        }
        cout << endl;
      } 
    }
   cout << endl;
  }
	cout << "err_ave" << "\t" << err_sum/(fm_file_size/4) << endl;
	cout << "err_max_square" << "\t" << err_max_square << endl;
	*/
	///*
	uint8_t* fm_BlockExp = new uint8_t[1];
	FindBlockExp(fm_fp16, fm_BlockExp);
	cout << 3 << endl;
	ofstream fm_fp16_fd(fm_fp16_filename, ios::out | ios::binary);
	if(!fm_fp16_fd.is_open())
	{
		cout << "ERROR: create fm_fp16 file failed." << endl;
		return -1;
	}
	char* wr_buffer_fm = reinterpret_cast<char*>(fm_fp16);
	fm_fp16_fd.write(wr_buffer_fm, fm_file_size/2);
	fm_fp16_fd.close();
	ofstream BlockExp_fm_fd(BlockExp_filename, ios::out | ios::binary | ios::app);
	if(!BlockExp_fm_fd.is_open())
	{
		cout << "ERROR: create BlockExp file failed." << endl;
		return -1;
	}
	char* wr_buffer_fm_be = reinterpret_cast<char*>(fm_BlockExp);
	BlockExp_fm_fd.write(wr_buffer_fm_be, 1);
	BlockExp_fm_fd.close();
  //*/

 	outf.close();
	delete[] rd_buffer_ker;
	delete[] ker_fp16;
	delete[] ker_fixed8;
	delete[] ker_BlockExp;
	delete[] rd_buffer_fm;
	delete[] fm_fp16;
	
	return 0;
}
