//open a bin file
#include <stdio.h>
#include <cstring>
#include <fstream>
#include <iostream>
#include <stdint.h>
#include <malloc.h>
#include <cmath>
#include <stdlib.h>
using namespace std;

#define OUT_CHANNEL 64

int main() 
{
  const char* filename = "../../data/conv_op/conv_bottom_16x16_block_exp22.txt";
  // const char* filename = "../../data/conv_op/conv_weight_3x3_block_exp14.txt";

	ifstream fd(filename, ios::in | ios::binary);
	if(!fd.is_open())
	{
		cout << "error: open file wrong." << endl;
		return -1;
	}
	fd.seekg(0, ios::end);
	unsigned int file_size = fd.tellg();
	cout << "file size: " << file_size << endl;
	char* rd_buffer = new char[file_size];
	fd.seekg(0, ios::beg);
	fd.read(rd_buffer, file_size);
	fd.close();

	//modify it based on data type
  unsigned char* data_orig = reinterpret_cast<unsigned char*>(rd_buffer);
	// for(int i=0; i<file_size/sizeof(float); i++)
	// {
	// 	printf("%f\t", *(data_orig+i));
	// }
	for(int y=0; y<16; y++)
	{
		for(int x=0; x<16; x++)
			printf("%02x ",*(data_orig+y*16+x));
		printf("\n");
	}
	// for(int y=0; y<3; y++)
	// {
	// 	for(int x=0; x<3; x++)
	// 		printf("%02x ",*(data_orig+y*3+x));
	// 	printf("\n");
	// }
	
  return 0;
}