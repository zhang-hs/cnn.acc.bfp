#include<iostream>
#include<fstream>
#include<iomanip>
#include<stdint.h>
#include<unistd.h>
#include<string.h>
#include<assert.h>
#include<math.h>

#define COMP

#define BATCH_SIZE 64
#define FILE_LEN 1024

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

void classify_batch(char* fpgaFile, char* labelFile)
{
  char* fpga_byte = NULL;
  uint16_t* fpga_fp16 = NULL; 
  float* fpga_fp32 = NULL;
  char* ref_label_byte = NULL;
  float* ref_label_fp32 = NULL;
  float max_prob = 0.0;
  int   max_index = 0;
  int   correct_cnt = 0;
  char  out_label[1024];

  std::ifstream fpga_file_handle(fpgaFile, std::ios::in|std::ios::binary);
  std::ifstream label_file_handle(labelFile, std::ios::in);
  std::ifstream ref_label_handle("./data/batch.label.bin", std::ios::in);
  std::ofstream log_file_handle("label-log-fpga.txt", std::ios::out);

  if(fpga_file_handle==NULL) {
    std::cout << "ERROR: open fpga file." << std::endl;
    return;
  }
  if(label_file_handle==NULL) {
    std::cout << "ERROR: open label file." << std::endl;
    return;
  }
  if(ref_label_handle==NULL) {
    std::cout << "ERROR: open ref label file." << std::endl;
    return;
  }

  //--read byte from file
  fpga_byte = new char[BATCH_SIZE*FILE_LEN*2];
  fpga_fp32 = new float[BATCH_SIZE*FILE_LEN*4];
  ref_label_byte = new char[BATCH_SIZE*4];
  assert(fpga_byte!=NULL);
  assert(fpga_fp32!=NULL);
  assert(ref_label_byte!=NULL);

  fpga_file_handle.read(fpga_byte, BATCH_SIZE*FILE_LEN*2);
  ref_label_handle.read(ref_label_byte, BATCH_SIZE*4);

  //--transform to normal
  fpga_fp16 = reinterpret_cast<uint16_t*>(fpga_byte);
  to_float32(fpga_fp32, fpga_fp16);
  ref_label_fp32 = reinterpret_cast<float*>(ref_label_byte);

  for (int k = 0; k < BATCH_SIZE; k++) 
  {
    log_file_handle << k << "th image classification..." << std::endl;
    max_index = 0;
    max_prob  = 0.0;
    for(int i = 0; i < 32; i++)
     {
      for(int j = 0; j < 32; j++) 
      {
        if((i*32+j) < 1000 ) 
        {
          float cur_fpga = fpga_fp32[k*1024+i*32+j];
          if(max_prob < cur_fpga) 
          {
            max_prob = cur_fpga;
            max_index = i*32+j;
          }
        }
      }
    }

    label_file_handle.seekg(0, std::ios::beg);
    for(int l = 0; l <= max_index; l++) 
    {
      label_file_handle.getline(out_label, sizeof(out_label));
    }
    if(max_index == (int)ref_label_fp32[k])
      correct_cnt++;
    else
      log_file_handle << "Classification Error." << std::endl;

    log_file_handle << "|____> " << max_index << std::endl << std::endl;
    log_file_handle << "|____> " << out_label << std::endl << std::endl;
  }
  log_file_handle << "--------------" << std::endl;
  log_file_handle << "Top-1 Accuracy: " << (float)correct_cnt/BATCH_SIZE << std::endl;
  log_file_handle << "Correct count: " << correct_cnt << std::endl;

  delete [] fpga_byte;
  delete [] fpga_fp32;
  delete [] ref_label_byte;
  fpga_file_handle.close();
  log_file_handle.close();
  ref_label_handle.close();
  label_file_handle.close();
  return;
}

void classify_batch_caffe(char* caffeFile, char* labelFile)
{
  char* caffe_byte = NULL;
  float* caffe_fp32 = NULL;
  char* ref_label_byte = NULL;
  float* ref_label_fp32 = NULL;
  float max_prob = 0.0;
  int   max_index = 0;
  int   correct_cnt = 0;
  char  out_label[1024];

  std::ifstream caffe_file_handle(caffeFile, std::ios::in|std::ios::binary);
  std::ifstream label_file_handle(labelFile, std::ios::in);
  std::ifstream ref_label_handle("./data/batch.label.bin", std::ios::in);
  std::ofstream log_file_handle("label-log-caffe.txt", std::ios::out);

  if(caffe_file_handle==NULL) {
    std::cout << "ERROR: open fpga file." << std::endl;
    return;
  }
  if(label_file_handle==NULL) {
    std::cout << "ERROR: open label file." << std::endl;
    return;
  }
  if(ref_label_handle==NULL) {
    std::cout << "ERROR: open ref label file." << std::endl;
    return;
  }

  //--read byte from file
  caffe_byte = new char[BATCH_SIZE*FILE_LEN*4];
  ref_label_byte = new char[BATCH_SIZE*4];
  assert(caffe_byte!=NULL);
  assert(ref_label_byte!=NULL);

  caffe_file_handle.read(caffe_byte, BATCH_SIZE*FILE_LEN*4);
  ref_label_handle.read(ref_label_byte, BATCH_SIZE*4);

  //--transform to normal
  caffe_fp32 = reinterpret_cast<float*>(caffe_byte);
  ref_label_fp32 = reinterpret_cast<float*>(ref_label_byte);

  for (int k = 0; k < BATCH_SIZE; k++) {
    log_file_handle << k << "th image classification..." << std::endl;
    max_index = 0;
    max_prob  = 0.0;
    for(int i = 0; i < 32; i++) {
      for(int j = 0; j < 32; j++) {
        if((i*32+j) < 1000 ) {
          float cur_caffe = caffe_fp32[k*1000+i*32+j];
          if(max_prob < cur_caffe) {
            max_prob = cur_caffe;
            max_index = i*32+j;
          }
        }
      }
    }

    label_file_handle.seekg(0, std::ios::beg);
    for(int l = 0; l <= max_index; l++) {
      label_file_handle.getline(out_label, sizeof(out_label));
    }
    if(max_index == (int)ref_label_fp32[k])
      correct_cnt++;
    else
      log_file_handle << "Classification Error." << std::endl;

    log_file_handle << "|____> " << max_index << std::endl << std::endl;
    log_file_handle << "|____> " << out_label << std::endl << std::endl;
  }
  log_file_handle << "--------------" << std::endl;
  log_file_handle << "Top-1 Accuracy: " << (float)correct_cnt/BATCH_SIZE << std::endl;
  log_file_handle << "Correct count: " << correct_cnt << std::endl;

  delete [] caffe_byte;
  delete [] ref_label_byte;
  caffe_file_handle.close();
  log_file_handle.close();
  ref_label_handle.close();
  label_file_handle.close();
  return;
}


int main(int argc, char* argv[])
{
  assert(argc > 1);
  
  char opt;
  char fpga_file[100];
  char caffe_file[100];
  char label_file[100];
  bool _caffe_ = false;

  while((opt = getopt(argc, argv, "hf:c:l:"))!=EOF){
    switch(opt) {
      case 'h':
        std::cout << "-f fpga data, -c caffe data -l label file" << std::endl;
        return 0;
      case 'f': 
        strcpy(fpga_file, optarg);
        break;
      case 'c':
        strcpy(caffe_file, optarg);
        _caffe_ = true;
        break;
      case 'l':
        strcpy(label_file, optarg);
        break;
      default:
        std::cout << "Type -h for help" << std::endl;
        return 0;
    }
  }

  if(true == _caffe_) {
    classify_batch(fpga_file, label_file);
    classify_batch_caffe(caffe_file, label_file);
  }
  else {
    classify_batch(fpga_file, label_file);
  }

  return 0;
}
