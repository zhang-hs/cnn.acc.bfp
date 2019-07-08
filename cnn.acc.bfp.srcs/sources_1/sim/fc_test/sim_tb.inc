`ifdef FP16
extern "C" bit param_in_check(input bit[1-1:0] Weight_or_Bias, input bit[16-1:0] VeriWeight, input bit[16-1:0] VeriBias, input bit[32-1:0] Addr);
extern "C" bit data_in_check(input bit[32-1:0] VeriData, input bit[15-1:0] DataAddr,input bit[12-1:0] PixelPos, input bit[10-1:0] ChannelPos);
`else
extern "C"  bit param_in_check(input bit[1-1:0] Weight_or_Bias, input bit[32-1:0] VeriWeight, input bit[32-1:0] VeriBias, input bit[32-1:0] Addr);
extern "C" bit data_in_check(input bit[32-1:0] VeriData, input bit[15-1:0] DataAddr,input bit[12-1:0] PixelPos, input bit[10-1:0] ChannelPos);
`endif

extern "C"  bit increment_out_check(input bit Weight_or_Bias, input bit[32-1:0] VeriWeight, input bit[32-1:0] VeriBias, input bit[32-1:0] VeriData, input bit[32-1:0] VeriOut, input bit[32-1:0] Addr);
extern "C"  void out_check(input bit[3-1:0] CurLayer, input bit[12-1:0] IPOutAddr, input bit[32-1:0] IPOutData, output bit[32-1:0] SigEnergy, output bit[32-1:0] ErrEnergy, output bit ErrFlag);
extern "C"  bit error_status(input bit[3-1:0] CurLayer, input bit[32-1:0] SigEnergy, input bit[32-1:0] ErrEnergy);

// float transform
extern "C" void to_float16(input bit[32-1:0] Fp32, output bit[16-1:0] Fp16);
extern "C" void to_float32(input bit[16-1:0] Fp16, output bit[32-1:0] Fp32);

