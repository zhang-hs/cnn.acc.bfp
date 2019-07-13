#include<fstream>
#include<iostream>
#include<stdint.h>
#include<assert.h>

#define TOL 1e-3
#define CHECK

void to_float16(float* DataFp32, uint16_t* TransFp16, int FloatLen) {
  const float* cur_fp32_pointer = DataFp32;
  uint16_t* cur_fp16_pointer = TransFp16;
  int i = 0;

  for(i = 0; i < FloatLen; ++i) {
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

  return;
}
void to_float32(float* TransFp32, uint16_t* DataFp16, int FloatLen) {
  float* cur_fp32_pointer = TransFp32;
  uint16_t* cur_fp16_pointer = DataFp16;
  int i = 0;

  for (int i = 0; i < FloatLen; ++i)
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

int main(int argc, char* argv[]) {
    char* buffer;
    float* ref_float32;
    float* test_float32;
    uint16_t* test_float16;
    long file_size = 0;
    int num_size;

    assert(argc == 3);

    std::ifstream fp32_file_handle(argv[1], std::ios::in|std::ios::binary);
    if(fp32_file_handle == NULL) {
        std::cout << "ERROR: open fp32 file." << std::endl;
        return -1;
    }
    //--size = 13673960*4;
    //--size = 25088*4;
    fp32_file_handle.seekg(0, std::ios::end);
    file_size = fp32_file_handle.tellg();
    std::cout << "File Size: " << file_size << std::endl;
    fp32_file_handle.seekg(0, std::ios::beg);

    buffer = new char[file_size];
    fp32_file_handle.read(buffer, file_size);
    fp32_file_handle.close();

    ref_float32 = reinterpret_cast<float*>(buffer);
    num_size = file_size / 4;
    test_float32 = new float[num_size];
    test_float16 = new uint16_t[num_size];

    to_float16(ref_float32, test_float16, num_size); // transform to float16
    to_float32(test_float32, test_float16, num_size); // transform to float32

    #ifdef CHECK
    for (int i = 0; i < num_size; ++i)
    {
        float cur_ref_abs = ref_float32[i] < 0 ? -ref_float32[i] : ref_float32[i];
        float cur_test_abs = test_float32[i] < 0 ? -test_float32[i] : test_float32[i];
        if((cur_ref_abs - cur_test_abs) < TOL*cur_ref_abs)
          std::cout << "TEST Passed for " << i << "th transform." << std::endl;
        else
          std::cout << "TEST Failed for " << i << "th transform." << std::endl;
    }
    #endif

    std::ofstream fp16_file_handle(argv[2], std::ios::out|std::ios::binary);
    if(fp16_file_handle==NULL) {
      std::cout << "ERROR: open fp16 file." << std::endl;
      return -1;
    }
    char* wr_buffer = reinterpret_cast<char*>(test_float16);
    fp16_file_handle.write(wr_buffer, file_size/2);
    fp16_file_handle.close();

    delete[] test_float32;
    delete[] test_float16;
    delete[] buffer;

  return 0;
}
