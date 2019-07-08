`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/10/30 14:28:59
// Module Name: rd_ddr_exp
// Project Name: cnn.bfp.acc
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: Read block-exponent of bottom and kernal data from DDR.
//              update block-exponent of bottom data after the convolution of current layer' is finished.
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module rd_ddr_exp #(
  parameter DATA_WIDTH       = 8,
  parameter EXP_WIDTH        = 5
)(
  input  wire                         clk,
  input  wire                         rst_n,
  input  wire                         ddr_rdy,
  output reg  [29:0]                  ddr_addr,
  output reg  [2:0]                   ddr_cmd,
  output reg                          ddr_en,
  input  wire [511:0]                 ddr_rd_data,
  input  wire                         ddr_rd_data_valid,
  //rd options
  input  wire                         rd_exp,
  input  wire [3:0]                   rd_exp_ker_burst_num, // number of conv layer bias data, 8bits*512/512=8
  input  wire                         rd_exp_ker_only, //valid except for conv1_1 layer
  input  wire [29:0]                  rd_exp_addr,
  input  wire [EXP_WIDTH-1:0]         rd_exp_bottom_exp_in, //max exp of bottom, input from wr_ddr_data
  input  wire                         rd_exp_bottom_exp_in_valid,
  
  output reg  [EXP_WIDTH-1:0]         rd_exp_bottom_exp,
  output reg                          rd_exp_bottom_exp_valid,
  output reg  [(EXP_WIDTH+1)*64-1:0]  rd_exp_bias_exp, //increase 1bit to prevent upward overflow
  output reg                          rd_exp_bias_valid,
  output reg                          rd_exp_bias_valid_last,
  output reg                          rd_exp_full
);

  localparam RD_EXP_RST     = 2'b00;
  localparam RD_EXP_BOTTOM  = 2'b01;
  localparam RD_EXP_KER     = 2'b10;
  reg  [1:0]    _rd_exp_state;
  reg  [1:0]    _rd_exp_state_next;
  
  reg  [29:0]                _rd_exp_addr;
  reg  [EXP_WIDTH*64-1:0]    _rd_exp_ker_exp; //reg  [EXP_WIDTH*64-1:0]    _rd_exp_ker_exp;
  reg                        _rd_exp_next_burst; //whether to read next ddr burst
  reg                        _rd_exp_next_valid;
  reg  [3:0]                 _rd_exp_burst_cnt;
  reg  [3:0]                 _rd_exp_valid_cnt;
  wire                       _rd_exp_ker_valid;
  reg                        _rd_exp_ker_valid_reg;
  wire [(EXP_WIDTH+1)*64-1:0] _rd_exp_bias_exp; //increase 1bit to prevent upward overflow
  wire                       _rd_exp_last;
  wire                       _rd_exp_valid_last;
  reg                        _rd_exp_full;
 
  assign _rd_exp_last        = rd_exp_ker_only ? (_rd_exp_burst_cnt == rd_exp_ker_burst_num) : 
                                                 (_rd_exp_burst_cnt == rd_exp_ker_burst_num + 1'b1);
  assign _rd_exp_valid_last  = rd_exp_ker_only ? (_rd_exp_valid_cnt == rd_exp_ker_burst_num) : 
                                                 (_rd_exp_valid_cnt == rd_exp_ker_burst_num + 1'b1);
  assign _rd_exp_ker_valid   = rd_exp_ker_only ? rd_exp && ddr_rd_data_valid :
                                                 (ddr_rd_data_valid && (_rd_exp_valid_cnt != 4'd0));

  always@(posedge clk) begin
    _rd_exp_ker_valid_reg <= _rd_exp_ker_valid;
    rd_exp_bias_valid <= _rd_exp_ker_valid_reg;
    rd_exp_bias_valid_last <= _rd_exp_valid_last;
    rd_exp_full <= _rd_exp_full;
    rd_exp_bias_exp <= _rd_exp_bias_exp;
  end

 
  //FF
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_exp_state <= RD_EXP_RST;
    end else begin
      _rd_exp_state <= _rd_exp_state_next;
    end
  end
  //state transition
  always@(_rd_exp_state or rd_exp or ddr_rdy or _rd_exp_valid_last or rd_exp_ker_only) begin
    _rd_exp_state_next = RD_EXP_RST;
    case(_rd_exp_state)
      RD_EXP_RST: begin
        if(rd_exp) begin
          if(rd_exp_ker_only)
            _rd_exp_state_next = RD_EXP_KER;
          else
            _rd_exp_state_next = RD_EXP_BOTTOM;
        end else begin
          _rd_exp_state_next = RD_EXP_RST;
        end
      end
      RD_EXP_BOTTOM: begin
        if(ddr_rdy) 
          _rd_exp_state_next = RD_EXP_KER;
        else
          _rd_exp_state_next = RD_EXP_BOTTOM;
      end
      RD_EXP_KER: begin
        if(_rd_exp_valid_last) begin
          _rd_exp_state_next = RD_EXP_RST;
        end else begin
          _rd_exp_state_next = RD_EXP_KER;
        end
      end
    endcase
  end
  //logic
  always@(ddr_rdy or ddr_rd_data_valid or _rd_exp_state or _rd_exp_last or _rd_exp_valid_last or _rd_exp_addr) begin
    ddr_en    = 1'b0;
    ddr_addr  = 30'd0;
    ddr_cmd   = 3'd1;
    _rd_exp_next_burst = 1'b0;
    _rd_exp_next_valid = 1'b0;
    _rd_exp_full = 1'b0;
    case(_rd_exp_state)
      RD_EXP_RST: begin
        ddr_en = 1'b0;
      end
      RD_EXP_BOTTOM: begin
        if(ddr_rdy) begin
          ddr_en    = 1'b1;
          ddr_cmd   = 3'd1;
          ddr_addr  = _rd_exp_addr;
          _rd_exp_next_burst = 1'b1;
        end
        if(ddr_rd_data_valid) begin
          _rd_exp_next_valid = 1'b1;
        end
      end
      RD_EXP_KER: begin
        if(ddr_rdy) begin
          ddr_addr  = _rd_exp_addr;
          if(_rd_exp_last) begin
            ddr_en = 1'b0;
            ddr_cmd   = 3'd1;
            _rd_exp_next_burst = 1'b0;
          end else begin
            ddr_en = 1'b1;
            ddr_cmd   = 3'd1;
            _rd_exp_next_burst = 1'b1;
          end
        end
        if(ddr_rd_data_valid) begin
          _rd_exp_next_valid = 1'b1;
        end
        if(_rd_exp_valid_last) begin
          _rd_exp_full = 1'b1;
        end
      end
    endcase
  end
  
  //addr,burst_cnt
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_exp_addr <= 30'd0;
      _rd_exp_burst_cnt <= 4'd0;
      _rd_exp_valid_cnt <= 4'd0;
    end else begin
      if(rd_exp && (_rd_exp_state == RD_EXP_RST)) begin
        _rd_exp_addr <= rd_exp_addr;
        _rd_exp_burst_cnt <= 4'd0;
        _rd_exp_valid_cnt <= 4'd0;
      end
      if(_rd_exp_next_burst) begin
        _rd_exp_addr <= _rd_exp_addr + 4'd8;
        _rd_exp_burst_cnt <= _rd_exp_burst_cnt + 1'b1;
      end
      if(_rd_exp_next_valid) begin
        _rd_exp_valid_cnt <= _rd_exp_valid_cnt + 1'b1;
      end
      if(_rd_exp_valid_last) begin
        _rd_exp_addr <= 30'd0;
        _rd_exp_burst_cnt <= 4'd0;
        _rd_exp_valid_cnt <= 4'd0;
      end
    end
  end
  
  
  //rd_exp_bottom_exp
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      rd_exp_bottom_exp <= 5'b0;
//      rd_exp_bottom_exp <= 5'h17;
      rd_exp_bottom_exp_valid <= 1'b0;
    end else begin
//    if(rd_exp_ker_only) begin
      if(rd_exp_bottom_exp_in_valid) begin
        rd_exp_bottom_exp <= rd_exp_bottom_exp_in;
        rd_exp_bottom_exp_valid <= 1'b1;
      end
//    end
      else if((rd_exp_ker_only == 1'b0) && rd_exp && ddr_rd_data_valid && (_rd_exp_valid_cnt == 4'd0)) begin
        rd_exp_bottom_exp <= ddr_rd_data[4:0];
        rd_exp_bottom_exp_valid <= 1'b1;
      end else begin
        rd_exp_bottom_exp_valid <= 1'b0;
      end
    end
  end
  
  //rd_exp_bias_exp
  always@(posedge clk) begin
    if(_rd_exp_ker_valid) begin;
      _rd_exp_ker_exp[( 0+1)*EXP_WIDTH-1 :  0*EXP_WIDTH] <= ddr_rd_data[ 0*DATA_WIDTH+EXP_WIDTH-1 :  0*DATA_WIDTH];
      _rd_exp_ker_exp[( 1+1)*EXP_WIDTH-1 :  1*EXP_WIDTH] <= ddr_rd_data[ 1*DATA_WIDTH+EXP_WIDTH-1 :  1*DATA_WIDTH];
      _rd_exp_ker_exp[( 2+1)*EXP_WIDTH-1 :  2*EXP_WIDTH] <= ddr_rd_data[ 2*DATA_WIDTH+EXP_WIDTH-1 :  2*DATA_WIDTH];
      _rd_exp_ker_exp[( 3+1)*EXP_WIDTH-1 :  3*EXP_WIDTH] <= ddr_rd_data[ 3*DATA_WIDTH+EXP_WIDTH-1 :  3*DATA_WIDTH];
      _rd_exp_ker_exp[( 4+1)*EXP_WIDTH-1 :  4*EXP_WIDTH] <= ddr_rd_data[ 4*DATA_WIDTH+EXP_WIDTH-1 :  4*DATA_WIDTH];
      _rd_exp_ker_exp[( 5+1)*EXP_WIDTH-1 :  5*EXP_WIDTH] <= ddr_rd_data[ 5*DATA_WIDTH+EXP_WIDTH-1 :  5*DATA_WIDTH];
      _rd_exp_ker_exp[( 6+1)*EXP_WIDTH-1 :  6*EXP_WIDTH] <= ddr_rd_data[ 6*DATA_WIDTH+EXP_WIDTH-1 :  6*DATA_WIDTH];
      _rd_exp_ker_exp[( 7+1)*EXP_WIDTH-1 :  7*EXP_WIDTH] <= ddr_rd_data[ 7*DATA_WIDTH+EXP_WIDTH-1 :  7*DATA_WIDTH];
      _rd_exp_ker_exp[( 8+1)*EXP_WIDTH-1 :  8*EXP_WIDTH] <= ddr_rd_data[ 8*DATA_WIDTH+EXP_WIDTH-1 :  8*DATA_WIDTH];
      _rd_exp_ker_exp[( 9+1)*EXP_WIDTH-1 :  9*EXP_WIDTH] <= ddr_rd_data[ 9*DATA_WIDTH+EXP_WIDTH-1 :  9*DATA_WIDTH];
      _rd_exp_ker_exp[(10+1)*EXP_WIDTH-1 : 10*EXP_WIDTH] <= ddr_rd_data[10*DATA_WIDTH+EXP_WIDTH-1 : 10*DATA_WIDTH];
      _rd_exp_ker_exp[(11+1)*EXP_WIDTH-1 : 11*EXP_WIDTH] <= ddr_rd_data[11*DATA_WIDTH+EXP_WIDTH-1 : 11*DATA_WIDTH];
      _rd_exp_ker_exp[(12+1)*EXP_WIDTH-1 : 12*EXP_WIDTH] <= ddr_rd_data[12*DATA_WIDTH+EXP_WIDTH-1 : 12*DATA_WIDTH];
      _rd_exp_ker_exp[(13+1)*EXP_WIDTH-1 : 13*EXP_WIDTH] <= ddr_rd_data[13*DATA_WIDTH+EXP_WIDTH-1 : 13*DATA_WIDTH];
      _rd_exp_ker_exp[(14+1)*EXP_WIDTH-1 : 14*EXP_WIDTH] <= ddr_rd_data[14*DATA_WIDTH+EXP_WIDTH-1 : 14*DATA_WIDTH];
      _rd_exp_ker_exp[(15+1)*EXP_WIDTH-1 : 15*EXP_WIDTH] <= ddr_rd_data[15*DATA_WIDTH+EXP_WIDTH-1 : 15*DATA_WIDTH];
      _rd_exp_ker_exp[(16+1)*EXP_WIDTH-1 : 16*EXP_WIDTH] <= ddr_rd_data[16*DATA_WIDTH+EXP_WIDTH-1 : 16*DATA_WIDTH];
      _rd_exp_ker_exp[(17+1)*EXP_WIDTH-1 : 17*EXP_WIDTH] <= ddr_rd_data[17*DATA_WIDTH+EXP_WIDTH-1 : 17*DATA_WIDTH];
      _rd_exp_ker_exp[(18+1)*EXP_WIDTH-1 : 18*EXP_WIDTH] <= ddr_rd_data[18*DATA_WIDTH+EXP_WIDTH-1 : 18*DATA_WIDTH];
      _rd_exp_ker_exp[(19+1)*EXP_WIDTH-1 : 19*EXP_WIDTH] <= ddr_rd_data[19*DATA_WIDTH+EXP_WIDTH-1 : 19*DATA_WIDTH];
      _rd_exp_ker_exp[(20+1)*EXP_WIDTH-1 : 20*EXP_WIDTH] <= ddr_rd_data[20*DATA_WIDTH+EXP_WIDTH-1 : 20*DATA_WIDTH];
      _rd_exp_ker_exp[(21+1)*EXP_WIDTH-1 : 21*EXP_WIDTH] <= ddr_rd_data[21*DATA_WIDTH+EXP_WIDTH-1 : 21*DATA_WIDTH];
      _rd_exp_ker_exp[(22+1)*EXP_WIDTH-1 : 22*EXP_WIDTH] <= ddr_rd_data[22*DATA_WIDTH+EXP_WIDTH-1 : 22*DATA_WIDTH];
      _rd_exp_ker_exp[(23+1)*EXP_WIDTH-1 : 23*EXP_WIDTH] <= ddr_rd_data[23*DATA_WIDTH+EXP_WIDTH-1 : 23*DATA_WIDTH];
      _rd_exp_ker_exp[(24+1)*EXP_WIDTH-1 : 24*EXP_WIDTH] <= ddr_rd_data[24*DATA_WIDTH+EXP_WIDTH-1 : 24*DATA_WIDTH];
      _rd_exp_ker_exp[(25+1)*EXP_WIDTH-1 : 25*EXP_WIDTH] <= ddr_rd_data[25*DATA_WIDTH+EXP_WIDTH-1 : 25*DATA_WIDTH];
      _rd_exp_ker_exp[(26+1)*EXP_WIDTH-1 : 26*EXP_WIDTH] <= ddr_rd_data[26*DATA_WIDTH+EXP_WIDTH-1 : 26*DATA_WIDTH];
      _rd_exp_ker_exp[(27+1)*EXP_WIDTH-1 : 27*EXP_WIDTH] <= ddr_rd_data[27*DATA_WIDTH+EXP_WIDTH-1 : 27*DATA_WIDTH];
      _rd_exp_ker_exp[(28+1)*EXP_WIDTH-1 : 28*EXP_WIDTH] <= ddr_rd_data[28*DATA_WIDTH+EXP_WIDTH-1 : 28*DATA_WIDTH];
      _rd_exp_ker_exp[(29+1)*EXP_WIDTH-1 : 29*EXP_WIDTH] <= ddr_rd_data[29*DATA_WIDTH+EXP_WIDTH-1 : 29*DATA_WIDTH];
      _rd_exp_ker_exp[(30+1)*EXP_WIDTH-1 : 30*EXP_WIDTH] <= ddr_rd_data[30*DATA_WIDTH+EXP_WIDTH-1 : 30*DATA_WIDTH];
      _rd_exp_ker_exp[(31+1)*EXP_WIDTH-1 : 31*EXP_WIDTH] <= ddr_rd_data[31*DATA_WIDTH+EXP_WIDTH-1 : 31*DATA_WIDTH];
      _rd_exp_ker_exp[(32+1)*EXP_WIDTH-1 : 32*EXP_WIDTH] <= ddr_rd_data[32*DATA_WIDTH+EXP_WIDTH-1 : 32*DATA_WIDTH];
      _rd_exp_ker_exp[(33+1)*EXP_WIDTH-1 : 33*EXP_WIDTH] <= ddr_rd_data[33*DATA_WIDTH+EXP_WIDTH-1 : 33*DATA_WIDTH];
      _rd_exp_ker_exp[(34+1)*EXP_WIDTH-1 : 34*EXP_WIDTH] <= ddr_rd_data[34*DATA_WIDTH+EXP_WIDTH-1 : 34*DATA_WIDTH];
      _rd_exp_ker_exp[(35+1)*EXP_WIDTH-1 : 35*EXP_WIDTH] <= ddr_rd_data[35*DATA_WIDTH+EXP_WIDTH-1 : 35*DATA_WIDTH];
      _rd_exp_ker_exp[(36+1)*EXP_WIDTH-1 : 36*EXP_WIDTH] <= ddr_rd_data[36*DATA_WIDTH+EXP_WIDTH-1 : 36*DATA_WIDTH];
      _rd_exp_ker_exp[(37+1)*EXP_WIDTH-1 : 37*EXP_WIDTH] <= ddr_rd_data[37*DATA_WIDTH+EXP_WIDTH-1 : 37*DATA_WIDTH];
      _rd_exp_ker_exp[(38+1)*EXP_WIDTH-1 : 38*EXP_WIDTH] <= ddr_rd_data[38*DATA_WIDTH+EXP_WIDTH-1 : 38*DATA_WIDTH];
      _rd_exp_ker_exp[(39+1)*EXP_WIDTH-1 : 39*EXP_WIDTH] <= ddr_rd_data[39*DATA_WIDTH+EXP_WIDTH-1 : 39*DATA_WIDTH];
      _rd_exp_ker_exp[(40+1)*EXP_WIDTH-1 : 40*EXP_WIDTH] <= ddr_rd_data[40*DATA_WIDTH+EXP_WIDTH-1 : 40*DATA_WIDTH];
      _rd_exp_ker_exp[(41+1)*EXP_WIDTH-1 : 41*EXP_WIDTH] <= ddr_rd_data[41*DATA_WIDTH+EXP_WIDTH-1 : 41*DATA_WIDTH];
      _rd_exp_ker_exp[(42+1)*EXP_WIDTH-1 : 42*EXP_WIDTH] <= ddr_rd_data[42*DATA_WIDTH+EXP_WIDTH-1 : 42*DATA_WIDTH];
      _rd_exp_ker_exp[(43+1)*EXP_WIDTH-1 : 43*EXP_WIDTH] <= ddr_rd_data[43*DATA_WIDTH+EXP_WIDTH-1 : 43*DATA_WIDTH];
      _rd_exp_ker_exp[(44+1)*EXP_WIDTH-1 : 44*EXP_WIDTH] <= ddr_rd_data[44*DATA_WIDTH+EXP_WIDTH-1 : 44*DATA_WIDTH];
      _rd_exp_ker_exp[(45+1)*EXP_WIDTH-1 : 45*EXP_WIDTH] <= ddr_rd_data[45*DATA_WIDTH+EXP_WIDTH-1 : 45*DATA_WIDTH];
      _rd_exp_ker_exp[(46+1)*EXP_WIDTH-1 : 46*EXP_WIDTH] <= ddr_rd_data[46*DATA_WIDTH+EXP_WIDTH-1 : 46*DATA_WIDTH];
      _rd_exp_ker_exp[(47+1)*EXP_WIDTH-1 : 47*EXP_WIDTH] <= ddr_rd_data[47*DATA_WIDTH+EXP_WIDTH-1 : 47*DATA_WIDTH];
      _rd_exp_ker_exp[(48+1)*EXP_WIDTH-1 : 48*EXP_WIDTH] <= ddr_rd_data[48*DATA_WIDTH+EXP_WIDTH-1 : 48*DATA_WIDTH];
      _rd_exp_ker_exp[(49+1)*EXP_WIDTH-1 : 49*EXP_WIDTH] <= ddr_rd_data[49*DATA_WIDTH+EXP_WIDTH-1 : 49*DATA_WIDTH];
      _rd_exp_ker_exp[(50+1)*EXP_WIDTH-1 : 50*EXP_WIDTH] <= ddr_rd_data[50*DATA_WIDTH+EXP_WIDTH-1 : 50*DATA_WIDTH];
      _rd_exp_ker_exp[(51+1)*EXP_WIDTH-1 : 51*EXP_WIDTH] <= ddr_rd_data[51*DATA_WIDTH+EXP_WIDTH-1 : 51*DATA_WIDTH];
      _rd_exp_ker_exp[(52+1)*EXP_WIDTH-1 : 52*EXP_WIDTH] <= ddr_rd_data[52*DATA_WIDTH+EXP_WIDTH-1 : 52*DATA_WIDTH];
      _rd_exp_ker_exp[(53+1)*EXP_WIDTH-1 : 53*EXP_WIDTH] <= ddr_rd_data[53*DATA_WIDTH+EXP_WIDTH-1 : 53*DATA_WIDTH];
      _rd_exp_ker_exp[(54+1)*EXP_WIDTH-1 : 54*EXP_WIDTH] <= ddr_rd_data[54*DATA_WIDTH+EXP_WIDTH-1 : 54*DATA_WIDTH];
      _rd_exp_ker_exp[(55+1)*EXP_WIDTH-1 : 55*EXP_WIDTH] <= ddr_rd_data[55*DATA_WIDTH+EXP_WIDTH-1 : 55*DATA_WIDTH];
      _rd_exp_ker_exp[(56+1)*EXP_WIDTH-1 : 56*EXP_WIDTH] <= ddr_rd_data[56*DATA_WIDTH+EXP_WIDTH-1 : 56*DATA_WIDTH];
      _rd_exp_ker_exp[(57+1)*EXP_WIDTH-1 : 57*EXP_WIDTH] <= ddr_rd_data[57*DATA_WIDTH+EXP_WIDTH-1 : 57*DATA_WIDTH];
      _rd_exp_ker_exp[(58+1)*EXP_WIDTH-1 : 58*EXP_WIDTH] <= ddr_rd_data[58*DATA_WIDTH+EXP_WIDTH-1 : 58*DATA_WIDTH];
      _rd_exp_ker_exp[(59+1)*EXP_WIDTH-1 : 59*EXP_WIDTH] <= ddr_rd_data[59*DATA_WIDTH+EXP_WIDTH-1 : 59*DATA_WIDTH];
      _rd_exp_ker_exp[(60+1)*EXP_WIDTH-1 : 60*EXP_WIDTH] <= ddr_rd_data[60*DATA_WIDTH+EXP_WIDTH-1 : 60*DATA_WIDTH];
      _rd_exp_ker_exp[(61+1)*EXP_WIDTH-1 : 61*EXP_WIDTH] <= ddr_rd_data[61*DATA_WIDTH+EXP_WIDTH-1 : 61*DATA_WIDTH];
      _rd_exp_ker_exp[(62+1)*EXP_WIDTH-1 : 62*EXP_WIDTH] <= ddr_rd_data[62*DATA_WIDTH+EXP_WIDTH-1 : 62*DATA_WIDTH];
      _rd_exp_ker_exp[(63+1)*EXP_WIDTH-1 : 63*EXP_WIDTH] <= ddr_rd_data[63*DATA_WIDTH+EXP_WIDTH-1 : 63*DATA_WIDTH];
    end
  end
  
  genvar i;
  generate 
    for(i=0; i<64; i=i+1) begin
      assign _rd_exp_bias_exp[(i+1)*(EXP_WIDTH+1)-1:i*(EXP_WIDTH+1)] = _rd_exp_ker_exp[(i+1)*EXP_WIDTH-1:i*EXP_WIDTH] + {1'b0, rd_exp_bottom_exp}; //with an offset of 30
    end
  endgenerate
 
    
endmodule
