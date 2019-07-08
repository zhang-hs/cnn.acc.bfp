`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/08/31 10:44:59
// Module Name: mem_patch_bram
// Description: read and write interface of patch_bram
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module mem_patch_bram #(
  parameter DATA_WIDTH    = 8,
  parameter IM_C          = 8
)(
  input  wire                                  clk,
  // bram write_in options
  input  wire [IM_C-1:0]                       mem_patch_bram_wr_ith_valid,
  input  wire [DATA_WIDTH*7-1:0]               mem_patch_bram_in,
  input  wire [4:0]                            mem_patch_bram_wr_en, //{a_upper, a, b, c_upper, c}
  input  wire [10:0]                           mem_patch_bram_wr_addr,
  // bram read_out options
  input  wire [IM_C-1:0]                       mem_patch_bram_rd_ith_valid,
  input  wire [2:0]                            mem_patch_bram_rd_ith,
  input  wire                                  mem_patch_bram_rd_y_eq_zero,
  input  wire                                  mem_patch_bram_rd_y_eq_end,
  input  wire                                  mem_patch_bram_rd_y_is_odd,
  input  wire [10:0]                           mem_patch_bram_rd_addr, //224                               
  output wire [18*DATA_WIDTH-1:0]              mem_patch_bram_o //maybe 
);
  //wr_op_op

  wire                                  _bram_wr_en_a;
  wire                                  _bram_wr_en_b;
  wire                                  _bram_wr_en_c;
  wire [8:0]                            _bram_wr_we_a;
  wire [8:0]                            _bram_wr_we_c;
  assign _bram_wr_en_a     = mem_patch_bram_wr_en[4] || mem_patch_bram_wr_en[3];
  assign _bram_wr_en_b     = mem_patch_bram_wr_en[2];
  assign _bram_wr_en_c     = mem_patch_bram_wr_en[0] || mem_patch_bram_wr_en[1];
  assign _bram_wr_we_a     = mem_patch_bram_wr_en[4]? 9'h3 : (mem_patch_bram_wr_en[3]? 9'h1fc : 9'h0);
  assign _bram_wr_we_c     = mem_patch_bram_wr_en[1]? 9'h3 : (mem_patch_bram_wr_en[0]? 9'h1fc : 9'h0);
  //bram_wr_in_data
  reg [DATA_WIDTH*9-1:0]               _bram_in_a;
  reg [DATA_WIDTH*5-1:0]               _bram_in_b;
  reg [DATA_WIDTH*9-1:0]               _bram_in_c;
  always@(mem_patch_bram_wr_en or mem_patch_bram_in) begin
    if(mem_patch_bram_wr_en[4])
      _bram_in_a = {{7*DATA_WIDTH*{1'b0}}, mem_patch_bram_in[DATA_WIDTH*7-1:DATA_WIDTH*5]};
    else if(mem_patch_bram_wr_en[3])
      _bram_in_a = mem_patch_bram_in << (2*DATA_WIDTH); //{mem_patch_bram_in, {(2*DATA_WIDTH){1'b0}}}; ????  
    else
      _bram_in_a = {9*DATA_WIDTH*{1'b0}};
    
    if(mem_patch_bram_wr_en[2])
      _bram_in_b = mem_patch_bram_in[DATA_WIDTH*5-1 : 0];
    else
      _bram_in_b = {5*DATA_WIDTH*{1'b0}};
    
    if(mem_patch_bram_wr_en[1])
      _bram_in_c = {{7*DATA_WIDTH*{1'b0}}, mem_patch_bram_in[DATA_WIDTH*7-1:DATA_WIDTH*5]};
    else if(mem_patch_bram_wr_en[0])
      _bram_in_c = mem_patch_bram_in << (2*DATA_WIDTH); //{mem_patch_bram_in, {2*DATA_WIDTH*{1'b0}}};
    else
      _bram_in_c = {9*DATA_WIDTH*{1'b0}};
  end
  
  //rd_op
  wire [DATA_WIDTH*9-1:0]               _bram_o_a[IM_C-1:0];
  wire [DATA_WIDTH*5-1:0]               _bram_o_b[IM_C-1:0];
  wire [DATA_WIDTH*9-1:0]               _bram_o_c[IM_C-1:0];
  reg  [DATA_WIDTH*23-1:0]              _bram_o;
  reg         _bram_rd_valid;
  reg  [2:0]  _bram_rd_ith_reg;
  reg         _bram_rd_y_eq_zero_reg;
  reg         _bram_rd_y_eq_end_reg;
  reg         _bram_rd_y_is_odd_reg;
  always@(posedge clk) begin
    if(mem_patch_bram_rd_ith_valid) begin
      _bram_rd_valid <= 1'b1;
    end else begin
      _bram_rd_valid <= 1'b0;
    end
    _bram_rd_ith_reg <= mem_patch_bram_rd_ith;
    _bram_rd_y_eq_zero_reg <= mem_patch_bram_rd_y_eq_zero;
    _bram_rd_y_eq_end_reg <= mem_patch_bram_rd_y_eq_end;
    _bram_rd_y_is_odd_reg <= mem_patch_bram_rd_y_is_odd;
  end
  always@(_bram_rd_valid or _bram_rd_ith_reg or _bram_rd_y_is_odd_reg or _bram_rd_y_eq_end_reg or _bram_rd_y_eq_zero_reg or _bram_o_a or _bram_o_b or _bram_o_c) begin
    if(_bram_rd_valid) begin
        if(_bram_rd_y_eq_end_reg) begin
          if(_bram_rd_y_eq_zero_reg) begin //can be omitted
           _bram_o = {{(7*DATA_WIDTH){1'b0}}, _bram_o_c[_bram_rd_ith_reg][DATA_WIDTH*2-1:0], _bram_o_b[_bram_rd_ith_reg], _bram_o_a[_bram_rd_ith_reg][DATA_WIDTH*9-1:DATA_WIDTH*2], {(2*DATA_WIDTH){1'b0}}};
          end else begin //(_bram_rd_y_eq_end_reg && _bram_rd_y_is_odd_reg)
           _bram_o = {{(7*DATA_WIDTH){1'b0}}, _bram_o_a[_bram_rd_ith_reg][DATA_WIDTH*2-1:0], _bram_o_b[_bram_rd_ith_reg], _bram_o_c[_bram_rd_ith_reg]}; //C+B+A_UPPER+2'b0
          end
        end 
        else if(_bram_rd_y_eq_zero_reg) begin
          _bram_o = {_bram_o_c[_bram_rd_ith_reg], _bram_o_b[_bram_rd_ith_reg], _bram_o_a[_bram_rd_ith_reg][DATA_WIDTH*9-1:DATA_WIDTH*2], {(2*DATA_WIDTH){1'b0}}};
        end
        else if(_bram_rd_y_is_odd_reg)
          _bram_o = {_bram_o_a[_bram_rd_ith_reg], _bram_o_b[_bram_rd_ith_reg], _bram_o_c[_bram_rd_ith_reg]}; //C+B+A 
        else
          _bram_o = {_bram_o_c[_bram_rd_ith_reg], _bram_o_b[_bram_rd_ith_reg], _bram_o_a[_bram_rd_ith_reg]}; //A+B+C  
    end else begin
      _bram_o = {(23*DATA_WIDTH){1'b0}};
    end
  end
  assign mem_patch_bram_o = _bram_o[DATA_WIDTH*18-1 : 0];
  
  //bram A,B,C
  //ena
  reg [IM_C-1:0]    _a_ena;
  reg [IM_C-1:0]    _b_ena;
  reg [IM_C-1:0]    _c_ena;  
  always@(_bram_wr_en_a or _bram_wr_en_b or _bram_wr_en_c or mem_patch_bram_wr_ith_valid) begin
    if(_bram_wr_en_a) begin
      _a_ena = mem_patch_bram_wr_ith_valid;
    end else begin
      _a_ena = {(IM_C){1'b0}};
    end
    if(_bram_wr_en_b) begin
      _b_ena = mem_patch_bram_wr_ith_valid;
    end else begin
      _b_ena = {(IM_C){1'b0}};
    end
    if(_bram_wr_en_c) begin
      _c_ena = mem_patch_bram_wr_ith_valid;
    end else begin
      _c_ena = {(IM_C){1'b0}};
    end
  end
  
  genvar a_i,b_i,c_i;
  generate
    for(a_i=0; a_i<IM_C; a_i=a_i+1) 
      begin:A
        bram_A bram_patch_A(
          .clka(clk),
          .ena(_a_ena[a_i]),
          .wea(_bram_wr_we_a),
          .addra(mem_patch_bram_wr_addr),
          .dina(_bram_in_a),
          .douta(),
          .clkb(clk),
          .enb(mem_patch_bram_rd_ith_valid[a_i]),
          .web(9'b0),
          .addrb(mem_patch_bram_rd_addr),
          .dinb(72'd0),
          .doutb(_bram_o_a[a_i])
        );
      end
  endgenerate
  generate
    for(b_i=0; b_i<IM_C; b_i=b_i+1) 
      begin:B
        bram_B bram_patch_B(
          .clka(clk),
          .ena(_b_ena[b_i]),
          .wea(1'b1),
          .addra(mem_patch_bram_wr_addr),
          .dina(_bram_in_b),
          .douta(),
          .clkb(clk),
          .enb(mem_patch_bram_rd_ith_valid[b_i]),
          .web(1'b0),
          .addrb(mem_patch_bram_rd_addr),
          .dinb(40'd0),
          .doutb(_bram_o_b[b_i])
        );
      end
  endgenerate
  generate
    for(c_i=0; c_i<IM_C; c_i=c_i+1) 
      begin:C
        bram_A bram_patch_C(
          .clka(clk),
          .ena(_c_ena[c_i]),
          .wea(_bram_wr_we_c),
          .addra(mem_patch_bram_wr_addr),
          .dina(_bram_in_c),
          .douta(),
          .clkb(clk),
          .enb(mem_patch_bram_rd_ith_valid[c_i]),
          .web(9'b0),
          .addrb(mem_patch_bram_rd_addr),
          .dinb(72'd0),
          .doutb(_bram_o_c[c_i])
        );
      end
  endgenerate
    
endmodule