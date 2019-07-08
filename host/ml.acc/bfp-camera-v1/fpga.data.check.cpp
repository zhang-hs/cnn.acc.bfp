#include<iostream>
#include<fstream>
#include<iomanip>
#include<stdint.h>
#include<unistd.h>
#include<string.h>
#include<assert.h>
#include<math.h>

#define BATCH_SIZE 64
#define FILE_LEN 1024

#define ABS(val) \
  ((val)<0 ? -(val) : (val))

void to_float32(float* transFp32, uint16_t* origFp16) {
  float* cur_fp32_pointer = transFp32;
  uint16_t* cur_fp16_pointer = origFp16;
  int i = 0;

  for (int i = 0; i < BATCH_SIZE*FILE_LEN; ++i)
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

  return;
}

void fpga_data_check(char* fpgaFile, char* caffeFile)
{
  char* fpga_byte = NULL;
  char* caffe_byte = NULL;
  uint16_t* fpga_fp16 = NULL; 
  float* fpga_fp32 = NULL;
  float* caffe_fp32 = NULL; 
  float err_fpga[1000];
  float err_max = 0.0;
  float err_batch = 0.0;
  float sig_energy = 0.0;
  float err_energy = 0.0;
  float sig_energy_batch = 0.0;
  float err_energy_batch = 0.0;

  std::ifstream fpga_file_handle(fpgaFile, std::ios::in|std::ios::binary);
  std::ifstream caffe_file_handle(caffeFile, std::ios::in|std::ios::binary);
  std::ofstream log_file_handle("comp-log.txt", std::ios::out);

  if(fpga_file_handle==NULL) {
    std::cout << "ERROR: open fpga file." << std::endl;
    return;
  }
  if(caffe_file_handle==NULL) {
    std::cout << "ERROR: open caffe file." << std::endl;
    return;
  }

  //--read byte from file
  fpga_byte = new char[BATCH_SIZE*FILE_LEN*2];
  caffe_byte = new char[BATCH_SIZE*FILE_LEN*4];
  fpga_fp32 = new float[BATCH_SIZE*FILE_LEN*4];
  assert(fpga_byte!=NULL);
  assert(caffe_byte!=NULL);
  assert(fpga_fp32!=NULL);

  fpga_file_handle.read(fpga_byte, BATCH_SIZE*FILE_LEN*2);
  caffe_file_handle.read(caffe_byte, BATCH_SIZE*FILE_LEN*4);

  //--transform to normal
  caffe_fp32 = reinterpret_cast<float*>(caffe_byte);
  fpga_fp16 = reinterpret_cast<uint16_t*>(fpga_byte);
  to_float32(fpga_fp32, fpga_fp16);

  for (int k = 0; k < BATCH_SIZE; k++) {
    log_file_handle << k << "th image comparison" << std::endl;
    err_max = 0.0;
    err_energy = 0.0;
    sig_energy = 0.0;
    for(int i = 0; i < 32; i++) {
      for(int j = 0; j < 32; j++) {
        if((i*32+j) < 1000 ) {
          float cur_fpga = fpga_fp32[k*1024+i*32+j];
          float cur_caffe = caffe_fp32[k*1000+i*32+j];
          float cur_err = ABS(cur_fpga - cur_caffe);
          if(cur_err > err_max) err_max = cur_err;

          err_fpga[i*32+j]  = cur_err;

          sig_energy += cur_caffe * cur_caffe;
          err_energy += cur_err * cur_err;
          err_batch += cur_err;

          log_file_handle << "FPGA: " << std::setw(12) << cur_fpga << "\t"; 
          log_file_handle << "CAFFE: " << std::setw(12) << cur_caffe << "\t";
          log_file_handle << "ERROR: " << std::setw(12) << cur_err;
          log_file_handle << std::endl;
        }
      }
    }
    sig_energy_batch += sig_energy;
    err_energy_batch += err_energy;
    log_file_handle << k << "th image: Max Error: " << err_max << std::endl;
    log_file_handle << k << "th image: SNR: " << sqrt(err_energy/sig_energy) << std::endl << std::endl;
    std::cout << "Max Error: " << err_max << std::endl;
    std::cout << "SNR: " << sqrt(err_energy/sig_energy) << std::endl;
  }
  log_file_handle << "Batch Conclusion-----------------------------------" << std::endl;
  log_file_handle << "Batch Avaerage SNR: " << sqrt(err_energy_batch/sig_energy_batch) << std::endl;
  log_file_handle << "Batch Avaerage Error: " << err_batch/(BATCH_SIZE*1000)<< std::endl;

  delete [] fpga_byte;
  delete [] caffe_byte;
  delete [] fpga_fp32;
  fpga_file_handle.close();
  caffe_file_handle.close();
  log_file_handle.close();
  return;
}

int main(int argc, char* argv[])
{
  char opt;
  char fpga_file[100];
  char caffe_file[100];

  assert(argc > 1);
  while((opt = getopt(argc, argv, "hf:c:"))!=EOF){
    switch(opt) {
      case 'h':
        std::cout << "-f fpga data, -c caffe data" << std::endl;
        return 0;
      case 'f': 
        strcpy(fpga_file, optarg);
        break;
      case 'c':
        strcpy(caffe_file, optarg);
        break;
      default:
        std::cout << "Type -h for help" << std::endl;
        return 0;
    }
  }

  fpga_data_check(fpga_file, caffe_file);

  return 0;
}
