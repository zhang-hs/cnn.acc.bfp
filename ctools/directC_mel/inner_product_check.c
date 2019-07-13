// DirectC code to check input and output for inner_product module
#include<stdio.h>
#include<math.h>
#include<stdint.h>
#include<string.h>
#include"DirectC.h"

#define FP16

#define PARAM_BUF_SIZE 288
#define FW 32 // float width

#define Dtype float
#define VAL_LEVEL 1.0
#define ERR_FEED 5e-1
#define ERR_OUT_RLA 1.5e-1
#define ERR_OUT_ABS  1.5e-1

#define DATADIR "./../../data/fc"

// define input data type
#ifdef FP16
    #define DItype uint16_t
#else
    #define DItype float
#endif

#define ERROR(Str) \
    printf("ERROR: %s.\n\n", Str)

#define ABS(Val) \
    ( (Val)<0 ? -(Val) : (Val)) 

#define EXPECT_EQ(Ref, Veri) \
    int equal_flag; \
    if(Ref == Veri) \
        equal_flag = 1; \
    else \
        equal_flag = 0; 

#define EXPECT_NE(Ref, Veri, Tol, ErrFlag) \
    Dtype error = ABS(Ref-Veri); \
    if(ABS(Ref) > VAL_LEVEL) \
        error  = error / ABS(Ref); \
    if(error < Tol) {\
        *ErrFlag = 0; \
    } \
    else {\
        *ErrFlag = 1; \
    } 


void directC_test();
U param_in_check(U Weight_or_Bias, U VeriWeight, U VeriBias, U Addr);
U data_in_check(U VeriData, U DataAddr, U PixelPos, U ChannelPos);
U increment_out_check(U Weight_or_Bias, U VeriWeight, U VeriBias, U VeriData, U VeriOut, U Addr);
void out_check(U CurLayer, U IPOutAddr, U IPOutData, U* SigEnergy, U* ErrEnergy, U* ErrFlag);
U error_status(U CurLayer, U SigEnergy, U ErrEnergy);

// DirectC test

void to_float32(U shortData, U* pUInt)
{
  unsigned int xContent, xSign, xExp;
  xContent  = shortData & 0x7fff;
  xSign     = shortData & 0x8000;
  xExp      = shortData & 0x7c00;
  xContent <<= 13;
  xSign    <<= 16;
  if(xExp==0x7c00){
    xContent  += 0x7fffffff;
  } else {
    xContent  += 0x38000000;
    xContent  = (xExp==0) ? 0 : xContent;
  }
  xContent  |= xSign;
  memcpy(pUInt, &xContent, sizeof(unsigned int));
}

void directC_test(){
    printf("Test Passed.\n");
}

// check weight and bias
U param_in_check(U Weight_or_Bias, U VeriWeight, U VeriBias, U Addr)
{
    FILE *ref_param_handle = NULL;
    FILE *simv_log_handle = NULL;
    char bin_prefix[100];
    strcpy(bin_prefix, DATADIR);
    DItype refer_param = 0;
    DItype *f_weight = (DItype*) &VeriWeight;
    DItype *f_bias = (DItype*) &VeriBias;
    #ifdef FP16
    if(NULL == (ref_param_handle=fopen(strcat(bin_prefix, "/ip_param_fp16.bin"), "r"))) {
        printf("ERROR: open reference param file.\n\n");
        return 1;
    }
    #else
    if(NULL == (ref_param_handle=fopen(strcat(bin_prefix, "/ip_param.bin"), "r"))) {
        printf("ERROR: open reference param file.\n\n");
        return 1;
    }
    #endif
    if(NULL == (simv_log_handle=fopen("ip_param_simv_log.txt", "a"))) {
        printf("ERROR: open log file.\n\n");
        return 1;
    }

    fseek(ref_param_handle, Addr*sizeof(DItype), SEEK_SET);
    fread(&refer_param, sizeof(DItype), 1, ref_param_handle);

    if(1 == Weight_or_Bias) {
        // fprintf(simv_log_handle, "\nCheck weight......\n");
        EXPECT_EQ(refer_param, *f_weight);    
        #ifdef FP16
        if(equal_flag)
            fprintf(simv_log_handle, "%4dth weight check passed -> [ref: %4x----veri: %4x]. \n", Addr, refer_param, *f_weight);
        else
            fprintf(simv_log_handle, "%4dth weight check failed -> [ref: %4x----veri: %4x]. \n", Addr, refer_param, *f_weight); 
        #else
        if(equal_flag)
            fprintf(simv_log_handle, "%4dth weight check passed -> [ref: %12f----veri: %12f]. \n", Addr, refer_param, *f_weight);
        else                                
            fprintf(simv_log_handle, "%4dth weight check failed -> [ref: %12f----veri: %12f]. \n", Addr, refer_param, *f_weight); 
        #endif
    }
    else {
        // fprintf(simv_log_handle, "\nCheck bias......\n");
        EXPECT_EQ(refer_param, *f_bias);    
        #ifdef FP16
        if(equal_flag)
            fprintf(simv_log_handle, "%4dth bias check passed -> [ref: %4x----veri: %4x]. \n", Addr, refer_param, *f_bias);
        else
            fprintf(simv_log_handle, "%4dth bias check failed -> [ref: %4x----veri: %4x]. \n", Addr, refer_param, *f_bias); 
        #else
        if(equal_flag)
            fprintf(simv_log_handle, "%4dth bias check passed -> [ref: %12f----veri: %12f]. \n", Addr, refer_param, *f_bias);
        else
            fprintf(simv_log_handle, "%4dth bias check failed -> [ref: %12f----veri: %12f]. \n", Addr, refer_param, *f_bias); 
        #endif
    }

    fclose(ref_param_handle);
    fclose(simv_log_handle);
    return 0;
}

// check layer input data
U data_in_check(U VeriData, U DataAddr, U PixelPos, U ChannelPos) {
    FILE *ref_data_handle = NULL;
    FILE *simv_log_handle = NULL;
    char bin_prefix[100];
    strcpy(bin_prefix, DATADIR);

    unsigned short refer_data = 0;
    unsigned short *f_data = (unsigned short*) &VeriData;
    int errFlag;
    //--int DataAddr = (ChannelPos /32)*1536 + (ChannelPos%32) + (PixelPos*32);

    if(NULL == (ref_data_handle=fopen(strcat(bin_prefix,"/fc6_input.bin"), "r"))) {
        ERROR("open reference data file");
        return 1;
    }
    if(NULL == (simv_log_handle=fopen("ip_data_simv_log.txt", "a"))) {
        ERROR("open log file");
        return 1;
    }
    fseek(ref_data_handle, DataAddr*sizeof(unsigned short), SEEK_SET);
    fread(&refer_data, sizeof(unsigned short), 1, ref_data_handle);

    fprintf(simv_log_handle, "%3dth Channel,%2dth Pixel Check.", ChannelPos, PixelPos);
    EXPECT_EQ(refer_data, *f_data);
    if(equal_flag)
        fprintf(simv_log_handle, "Passed -> [ref: %4x----veri: %4x]. \n", refer_data, *f_data);
    else
        fprintf(simv_log_handle, "Failed -> [ref: %4x----veri: %4x]. \n", refer_data, *f_data); 

    fclose(ref_data_handle);
    fclose(simv_log_handle);

    return 0;
}

U data_in_check_fp32(U VeriData, U DataAddr, U PixelPos, U ChannelPos) {
    FILE *ref_data_handle = NULL;
    FILE *simv_log_handle = NULL;
    char bin_prefix[100];
    strcpy(bin_prefix, DATADIR);

    Dtype refer_data = 0;
    Dtype *f_data = (Dtype*) &VeriData;
    int errFlag;
    //--int DataAddr = (ChannelPos /32)*1536 + (ChannelPos%32) + (PixelPos*32);

    if(NULL == (ref_data_handle=fopen(strcat(bin_prefix,"/fc6_input.bin"), "r"))) {
        ERROR("open reference data file");
        return 1;
    }
    if(NULL == (simv_log_handle=fopen("ip_data_simv_log.txt", "a"))) {
        ERROR("open log file");
        return 1;
    }
    fseek(ref_data_handle, DataAddr*sizeof(Dtype), SEEK_SET);
    fread(&refer_data, sizeof(Dtype), 1, ref_data_handle);

    fprintf(simv_log_handle, "%3dth Channel,%2dth Pixel Check.", ChannelPos, PixelPos);
    EXPECT_NE(refer_data, *f_data, ERR_FEED, &errFlag);
    if(!errFlag)
        fprintf(simv_log_handle, "Passed. diff: %f -> [ref: %12f----veri: %12f]. \n", 
                error, refer_data, *f_data); \
    else
        fprintf(simv_log_handle, "Failed. diff: %f -> [ref: %12f----veri: %12f]. \n", 
                error, refer_data, *f_data); \

    fclose(ref_data_handle);
    fclose(simv_log_handle);

    return 0;
}

// incremental output check for each accumulation
U increment_out_check(U Weight_or_Bias, U VeriWeight, U VeriBias, U VeriData, U VeriOut, U Addr) {
    FILE *simv_out_handle = NULL;
    FILE *simv_log_handle = NULL;

    Dtype *f_data = (Dtype*) &VeriData;
    Dtype *f_weight = (Dtype*) &VeriWeight;
    Dtype *f_bias = (Dtype*) &VeriBias;
    Dtype *f_out = (Dtype*) &VeriOut;
    Dtype prev_inc_out;
    int errFlag;

    if(NULL == (simv_out_handle=fopen("ip_inc_out_simv.bin", "ab+"))) {
        ERROR("open out data file");
        return 1;
    }
    if(NULL == (simv_log_handle=fopen("ip_inc_out_simv_log.txt", "a"))) {
        ERROR("open log file");
        return 1;
    }

    if(1 == Weight_or_Bias) {
        fseek(simv_out_handle, -4, SEEK_END);
        fread(&prev_inc_out, sizeof(Dtype), 1, simv_out_handle);
        EXPECT_NE(prev_inc_out, *f_out, 1e-3, &errFlag);
        
        Dtype cur_inc_out = (*f_weight) * (*f_data) + prev_inc_out;
        fwrite(&cur_inc_out, sizeof(Dtype), 1, simv_out_handle);
    }
    else if(0 == Weight_or_Bias){
        // if(0 == Addr) {
            fseek(simv_out_handle, 0, SEEK_SET);
            fwrite(f_bias, sizeof(Dtype), 1, simv_out_handle);
        // }
        // else {
        //     fprintf(simv_log_handle, "%2dth out check failed: unexpected bias -> %f.\n", Addr, *f_bias);
        // }
    }

    fclose(simv_out_handle);
    fclose(simv_log_handle);
    return 0;
}

//check out data for each out neuron
void out_check(U CurLayer, U IPOutAddr, U IPOutData, U* SigEnergy, U* ErrEnergy, U* ErrFlag){
    FILE *simv_ref_handle = NULL;
    FILE *simv_log_handle = NULL;
    char bin_prefix[100];
    strcpy(bin_prefix, DATADIR);

    Dtype refer_out = 0;
    Dtype *veri_out = (Dtype*) &IPOutData;
    
    if(0 == CurLayer) {
        if(NULL == (simv_ref_handle=fopen(strcat(bin_prefix,"/fc6_1_output.bin"), "r"))) {
            ERROR("open reference data file");
            *ErrFlag = 1;
            return;
        }
    }
    else if(1 == CurLayer) {
        if(NULL == (simv_ref_handle=fopen(strcat(bin_prefix,"/fc6_2_output.bin"), "r"))) {
            ERROR("open reference data file");
            *ErrFlag = 1;
            return;
        }    
    }
    else if(2 == CurLayer) {
        if(NULL == (simv_ref_handle=fopen(strcat(bin_prefix,"/fc7_1_output.bin"), "r"))) {
            ERROR("open reference data file");
            *ErrFlag = 1;
            return;
        }
    }
    else if(3 == CurLayer) {
        if(NULL == (simv_ref_handle=fopen(strcat(bin_prefix, "/fc7_2_output.bin"), "r"))) {
            ERROR("open reference data file");
            *ErrFlag = 1;
            return;
        }
    }
    else{
        if(NULL == (simv_ref_handle=fopen(strcat(bin_prefix,"/fc8_output.bin"), "r"))) {
            ERROR("open reference data file");
            *ErrFlag = 1;
            return;
        }
    }
    if(NULL == (simv_log_handle=fopen("ip_out_simv_log.txt", "a"))) {
        ERROR("open log file");
        *ErrFlag = 1;
        return;
    }
    fseek(simv_ref_handle, IPOutAddr*sizeof(Dtype), SEEK_SET);
    fread(&refer_out, sizeof(Dtype), 1, simv_ref_handle);

    // check ip out
    Dtype out_error = 0.0;
    if(refer_out > VAL_LEVEL) {
        EXPECT_NE(refer_out, *veri_out, ERR_OUT_RLA, ErrFlag);
        out_error = error;
    }
    else {
        EXPECT_NE(refer_out, *veri_out, ERR_OUT_ABS, ErrFlag);
        out_error = error;
    }

    if(!(*ErrFlag)){
        fprintf(simv_log_handle, "%dth layer, %4dth out check passed. diff: %f -> [ref: %12f----veri: %12f]. \n", 
                CurLayer, IPOutAddr, out_error, refer_out, *veri_out); 
    }
    else {
        fprintf(simv_log_handle, "%dth layer, %4dth out check failed. diff: %f -> [ref: %12f----veri: %12f]. \n", 
                CurLayer, IPOutAddr, out_error, refer_out, *veri_out); 
    }

    // record error and signal energy
    *((Dtype*)SigEnergy) += (refer_out * refer_out);  
    *((Dtype*)ErrEnergy) += (ABS(refer_out - (*veri_out)) * ABS(refer_out - (*veri_out)));

    fclose(simv_ref_handle);
    fclose(simv_log_handle);

    return;
}

U error_status(U CurLayer, U SigEnergy, U ErrEnergy) {
    FILE* nsr_log_handle = NULL;
    Dtype* sig_energy = (Dtype*)&SigEnergy;
    Dtype* err_energy = (Dtype*)&ErrEnergy;

    if(NULL == (nsr_log_handle=fopen("ip_nsr_log.txt", "a"))){ 
        ERROR("open nsr log file");
        return 1;
    }

    Dtype nsr = sqrt((*err_energy) / (*sig_energy));

    fprintf(nsr_log_handle, "%dth layer:\n", CurLayer);
    fprintf(nsr_log_handle, "total noise, signal ----> %f, %f.\n", *err_energy, *sig_energy);
    fprintf(nsr_log_handle, "noise to signal ratio ----> %f.\n\n", nsr);

    fclose(nsr_log_handle);

    return 0;
}
