`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/10/29 15:27:11
// Module Name: rd_ddr_param
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: read weight and bias parameter
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module rd_ddr_param #(
  parameter FLOAT_NUM_WIDTH  = 16,
  parameter DATA_WIDTH       = 8,
  parameter DDR_DATA_WIDTH   = 64,
  parameter DDR_BURST_LEN    = 8,
  parameter K_C              = 64  //ppmac kernal channels
)(
  input  wire             clk,
  input  wire             rst_n,
  input  wire             ddr_rdy,
  output reg  [29:0]      ddr_addr,
  output reg  [2:0]       ddr_cmd,
  output reg              ddr_en,
//  input  wire [2:0]       ker_size, 
  input  wire [511:0]     ddr_rd_data, //one ddr busrt
  input  wire             ddr_rd_data_valid,
  
  input  wire             rd_param,
  input  wire             rd_param_ker_only,
//  input  wire [4:0]       rd_param_ker_burst_num,
  input  wire [4:0]       rd_param_bias_burst_num, // number of conv layer bias data, 16bits*512/512=16
  input  wire [29:0]      rd_param_addr,
  
  output reg  [511:0]     rd_param_data,
  output reg              rd_param_valid,
  output reg              rd_param_bias_valid, // bias valid if not read_kernel_only
  output reg              rd_param_bias_valid_last, // last valid bias data
  output reg              rd_param_full
);
  localparam RD_KER_DATA_NUM  = 3*3*K_C; //k_h*k_w*k_c
  localparam RD_KER_BURST_NUM = (RD_KER_DATA_NUM*DATA_WIDTH/DDR_DATA_WIDTH+7)/DDR_BURST_LEN;  //= rd_param_ker_burst num, 3*3*8/64/8=9
  localparam RD_PARAM_RST   = 3'd0;
  localparam RD_PARAM_BIAS  = 3'd1;
  localparam RD_PARAM_KER   = 3'd2;
  
  reg [2:0]       _rd_param_state;
  reg [2:0]       _rd_param_next_state;
  reg [29:0]      _rd_param_addr;
  reg             _rd_param_next_burst;
  reg [4:0]       _rd_param_burst_cnt;
  reg [4:0]       _rd_param_valid_cnt;
  reg             _rd_param_next_valid;
  reg             _rd_param_valid_on_bias;
  reg             _rd_param_has_bias;
  wire            _rd_param_bias_last;
  wire            _rd_ker_last;
  wire            _rd_param_last;
  reg             _rd_param_valid;
  reg             _rd_param_bias_valid;
  wire            _rd_param_bias_valid_last;
  wire[511:0]     _rd_param_data;
  reg             _rd_param_full;

  always@(posedge clk) begin
    rd_param_full             <= _rd_param_full;
    rd_param_valid            <= _rd_param_valid;
    rd_param_bias_valid       <= _rd_param_bias_valid;
    rd_param_bias_valid_last  <= _rd_param_bias_valid_last;
    rd_param_data             <= _rd_param_data;
  end
  
  assign _rd_param_data  = _rd_param_valid ? ddr_rd_data : 512'b0;
  assign _rd_param_bias_last  = (_rd_param_burst_cnt == rd_param_bias_burst_num-1'b1 );
  assign _rd_ker_last         = _rd_param_has_bias ? (_rd_param_burst_cnt == RD_KER_BURST_NUM + rd_param_bias_burst_num):
                                                     (_rd_param_burst_cnt == RD_KER_BURST_NUM);
  assign _rd_param_last       = _rd_param_has_bias ? ((_rd_param_valid_cnt == RD_KER_BURST_NUM + rd_param_bias_burst_num - 1'b1) && ddr_rd_data_valid) :
                                                     ((_rd_param_valid_cnt == (RD_KER_BURST_NUM - 1)) && ddr_rd_data_valid);  // _rd_param_valid_cnt = _rd_param_burst_cnt - 1
  assign _rd_param_bias_valid_last = _rd_param_has_bias ? (_rd_param_valid_cnt == rd_param_bias_burst_num-1'b1) : 1'b0;

  // FF
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_param_state <= RD_PARAM_RST;
    end else begin
      _rd_param_state <= _rd_param_next_state;
    end
  end
  // state transition
  always@(_rd_param_state or rd_param or _rd_param_bias_last or _rd_param_last or
          rd_param_ker_only) begin
    _rd_param_next_state = RD_PARAM_RST;
    case(_rd_param_state)
      RD_PARAM_RST: begin
        if(rd_param) begin
          if(rd_param_ker_only)
            _rd_param_next_state = RD_PARAM_KER;
          else
            _rd_param_next_state = RD_PARAM_BIAS;
        end else begin
          _rd_param_next_state = RD_PARAM_RST;
        end
      end
      RD_PARAM_BIAS: begin
        if(_rd_param_bias_last)
          _rd_param_next_state = RD_PARAM_KER;
        else
          _rd_param_next_state = RD_PARAM_BIAS;
      end
      RD_PARAM_KER: begin
        if(_rd_param_last)
          _rd_param_next_state = RD_PARAM_RST;
        else
          _rd_param_next_state = RD_PARAM_KER;
      end
    endcase
  end
  // logic
  always@(_rd_param_state or ddr_rdy or ddr_rd_data_valid or _rd_ker_last or 
          _rd_param_addr or _rd_param_last or _rd_param_valid_on_bias) begin
    ddr_en    = 1'b0;
    ddr_addr  = 30'h0;
    ddr_cmd   = 3'b1; // read
    _rd_param_valid      = 1'b0;
    _rd_param_bias_valid = 1'b0;
    _rd_param_full       = 1'b0;
    _rd_param_next_burst = 1'b0;
    _rd_param_next_valid = 1'b0;
    case(_rd_param_state)
      RD_PARAM_RST: begin
        ddr_en = 1'b0;
      end

      RD_PARAM_BIAS: begin
        if(ddr_rdy) begin
          ddr_en  = 1'b1;
          ddr_cmd = 3'b1;
          ddr_addr= _rd_param_addr;
          _rd_param_next_burst = 1'b1;
        end
        if(ddr_rd_data_valid) begin
          _rd_param_next_valid = 1'b1;
          _rd_param_valid      = 1'b1;
          // bias valid
          _rd_param_bias_valid = 1'b1;
        end
      end

      RD_PARAM_KER: begin
        if(ddr_rdy) begin
          ddr_cmd = 3'b1;
          ddr_addr= _rd_param_addr;
          if(_rd_ker_last) begin
            ddr_en = 1'b0;
            _rd_param_next_burst = 1'b0;
          end else begin
            ddr_en = 1'b1;
            _rd_param_next_burst = 1'b1;
          end
        end
        if(ddr_rd_data_valid) begin
          _rd_param_next_valid = 1'b1;
          _rd_param_valid      = 1'b1;
          if(_rd_param_valid_on_bias) begin
            _rd_param_bias_valid = 1'b1;
          end
        end
        if(_rd_param_last) begin
          _rd_param_full = 1'b1;
        end
      end
    endcase
  end
  // need to read bias, record rd_param_ker_only in case it is transient
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_param_has_bias <= 1'b0;
    end else begin
      if(rd_param_ker_only) begin
        _rd_param_has_bias <= 1'b0;
      end else begin
        _rd_param_has_bias <= 1'b1;
      end
      if(_rd_param_last) begin
        _rd_param_has_bias <= 1'b0;
      end
    end
  end
  // read addr
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_param_addr <= 30'h0;
      _rd_param_burst_cnt <= 5'h0;
      _rd_param_valid_cnt <= 5'h0;
    end else begin
      // initialization
      if(rd_param && (_rd_param_state == RD_PARAM_RST)) begin
        _rd_param_addr <= rd_param_addr;
        _rd_param_burst_cnt <= 5'h0;
        _rd_param_valid_cnt <= 5'h0;
      end
      // increment
      if(_rd_param_next_burst) begin
        _rd_param_addr <= _rd_param_addr + 4'h8;
        _rd_param_burst_cnt <= _rd_param_burst_cnt + 1'b1;
      end
      if(_rd_param_next_valid) begin
        _rd_param_valid_cnt <= _rd_param_valid_cnt + 1'b1;
      end
      // reset to zero
      if(_rd_param_last) begin
        _rd_param_addr <= 30'h0;
        _rd_param_burst_cnt <= 5'h0;
        _rd_param_valid_cnt <= 5'h0;
      end
    end
  end
  // bias valid
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_param_valid_on_bias <= 1'b0;
    end else begin
      if(_rd_param_next_state == RD_PARAM_BIAS) begin
        _rd_param_valid_on_bias <= 1'b1;
      end
      if(_rd_param_bias_valid_last) begin
        _rd_param_valid_on_bias <= 1'b0;
      end
    end
  end


endmodule
