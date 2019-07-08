`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/10/15 16:49:39
// Module Name: mem_patch_rd 
// Description: Generate read control options for patch_bram.
//              it takes 3 clks from mem_patch_rd_en to mem_patch_rd_o_valid
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module mem_patch_rd #(
  parameter DATA_WIDTH    = 8,
  parameter IM_C          = 8
)(
  input  wire                       clk,
  input  wire                       rst_n,
//  input  wire [2:0]                 ker_size,
  
//  input  wire                       mem_patch_rd_conv_start, //start reading, need to remain valid during read operation.
//  input  wire                       mem_patch_rd_conv_busy,
input  wire [4:0]                 mem_patch_rd_layer_index,
  input  wire                       mem_patch_rd_en,
  /*(*mark_debug="TRUE"*)*/input  wire [8:0]                 mem_patch_rd_ith_fm,
  input  wire [4:0]                 mem_patch_rd_x,
  input  wire                       mem_patch_rd_x_eq_end,
  input  wire                       mem_patch_rd_y_eq_zero,
  input  wire                       mem_patch_rd_y_eq_end,
  input  wire                       mem_patch_rd_y_is_odd,
//  input  wire [7:0]                 mem_patch_rd_bottom_fm_width,
  /*(*mark_debug="TRUE"*)*/input  wire [4:0]                 mem_patch_rd_col, //addr_offset
  input  wire [18*DATA_WIDTH-1:0 ]  mem_patch_rd_bram_o,
                         
  /*(*mark_debug="TRUE"*)*/output reg  [IM_C-1:0]            mem_patch_rd_ith_valid,
  /*(*mark_debug="TRUE"*)*/output reg  [2:0]                 mem_patch_rd_ith,
  /*(*mark_debug="TRUE"*)*/output reg  [10:0]                mem_patch_rd_addr,
  /*(*mark_debug="TRUE"*)*/output reg                        mem_patch_rd_y_eq_zero_valid,
  /*(*mark_debug="TRUE"*)*/output reg                        mem_patch_rd_y_eq_end_valid,                      
  /*(*mark_debug="TRUE"*)*/output reg                        mem_patch_rd_y_is_odd_valid, 
  output reg  [18*DATA_WIDTH-1:0]   mem_patch_rd_o,
  /*(*mark_debug="TRUE"*)*/output reg                        mem_patch_rd_o_valid
);
//  (*mark_debug="TRUE"*)wire [DATA_WIDTH-1:0] mem_patch_rd_bram_o_h;
//  (*mark_debug="TRUE"*)wire [DATA_WIDTH-1:0] mem_patch_rd_o_h;
//  assign mem_patch_rd_bram_o_h = mem_patch_rd_bram_o[DATA_WIDTH*18-1:DATA_WIDTH*17];
//  assign mem_patch_rd_o_h = mem_patch_rd_o[DATA_WIDTH*18-1:DATA_WIDTH*17];
  //ker_size
  localparam KER_SIZE = 3'd3;
  
  //mem_patch_bram read control
  wire [IM_C-1:0]            _mem_patch_rd_ith_valid;
  wire [2:0]                 _mem_patch_rd_ith;
  wire [10:0]                _mem_patch_rd_addr;                      
  reg  [18*DATA_WIDTH-1:0]   _mem_patch_rd_o;
  
  wire [4:0]       _cw_size;
  reg  [10:0]      _rd_addr_ith;
  reg  [7:0]       _rd_addr;
  wire [5:0]       _rd_ith_fm_hpos;
  wire [2:0]       _rd_ith_fm_lpos; 
  reg  [4:0]       _rd_col_valid;
  reg              _rd_en_valid;
  reg  [4:0]       _rd_x_valid;
  reg              _rd_x_eq_end_valid;
  
  always@(posedge clk) begin
    mem_patch_rd_ith_valid <= _mem_patch_rd_ith_valid;
    mem_patch_rd_ith <= _mem_patch_rd_ith;
    mem_patch_rd_addr <= _mem_patch_rd_addr;
    mem_patch_rd_y_eq_zero_valid <= mem_patch_rd_y_eq_zero;
    mem_patch_rd_y_eq_end_valid <= mem_patch_rd_y_eq_end;
    mem_patch_rd_y_is_odd_valid <= mem_patch_rd_y_is_odd;
    mem_patch_rd_o <= _mem_patch_rd_o;
    mem_patch_rd_o_valid <= _rd_en_valid;
  end     
  
  assign _cw_size        = {2'b0, KER_SIZE} + 5'd13;
  assign _rd_ith_fm_hpos = mem_patch_rd_ith_fm[8:3];
  assign _rd_ith_fm_lpos = mem_patch_rd_ith_fm[2:0];
  
  //bram_ith_valid
  assign _mem_patch_rd_ith_valid = {7'b0, mem_patch_rd_en} << _rd_ith_fm_lpos;
  assign _mem_patch_rd_ith = _rd_ith_fm_lpos;
  
  //rd_addr
  assign _mem_patch_rd_addr = _rd_addr_ith + {3'b0, _rd_addr};

  //addr_ith
  always@(_rd_ith_fm_hpos or mem_patch_rd_layer_index) begin
  case(mem_patch_rd_layer_index)
    5'd0, 5'd1: begin //224, layer 0,1
      _rd_addr_ith = {_rd_ith_fm_hpos[2:0],8'b0} - {3'b0,_rd_ith_fm_hpos[2:0],5'b0};//224 * _rd_ith_fm_hpos[2:0];
    end
    5'd2, 5'd3: begin //112, layer 2,3
      _rd_addr_ith = {_rd_ith_fm_hpos[3:0],7'b0} - {3'b0,_rd_ith_fm_hpos[3:0],4'b0};//112 * _rd_ith_fm_hpos[3:0];
    end
    5'd4, 5'd5, 5'd6: begin //56, layer 3,4,5
      _rd_addr_ith = {_rd_ith_fm_hpos[4:0],6'b0} - {3'b0,_rd_ith_fm_hpos[4:0],3'b0};//56 * _rd_ith_fm_hpos[4:0];
    end
    5'd7, 5'd8, 5'd9: begin //28, layer 6,7,8
      _rd_addr_ith = {_rd_ith_fm_hpos[5:0],5'b0} - {3'b0,_rd_ith_fm_hpos[5:0],2'b0};//28 * _rd_ith_fm_hpos[5:0];
    end
    5'd10, 5'd11, 5'd12: begin //14, layer 9,10,11
      _rd_addr_ith = {1'b0,_rd_ith_fm_hpos[5:0],4'b0} - {4'b0,_rd_ith_fm_hpos[5:0],1'b0};//14 * _rd_ith_fm_hpos[5:0];
    end
    default: begin
      _rd_addr_ith = 11'd0;
    end
  endcase      
end
  
  //addr_start
  always@(mem_patch_rd_x or mem_patch_rd_x_eq_end or mem_patch_rd_col or KER_SIZE) begin
    if((mem_patch_rd_x == 5'd0) && (mem_patch_rd_col < (KER_SIZE>>1)) || 
       (mem_patch_rd_x_eq_end && (mem_patch_rd_col > (13+(KER_SIZE>>1)))) ) begin
      _rd_addr = 8'd0;
    end else begin
      _rd_addr =  (mem_patch_rd_x<<4) - (mem_patch_rd_x<<1) + mem_patch_rd_col - (KER_SIZE>>1);
    end
  end
  
  //rd_o
  //waiting to read data from bram
  reg  [4:0]    _rd_col_reg;
  reg           _rd_en_reg;
  reg  [4:0]    _rd_x_reg;
  reg           _rd_x_eq_end_reg;
  always@(posedge clk) begin //addr valid
    _rd_col_reg <= mem_patch_rd_col;
    _rd_en_reg <= mem_patch_rd_en;
    _rd_x_reg <= mem_patch_rd_x;
    _rd_x_eq_end_reg <= mem_patch_rd_x_eq_end;
  end
  always@(posedge clk) begin //bram data valid
    _rd_col_valid <= _rd_col_reg;
    _rd_en_valid <= _rd_en_reg;
    _rd_x_valid <= _rd_x_reg;
    _rd_x_eq_end_valid <= _rd_x_eq_end_reg;
  end
  always@(_rd_x_valid or _rd_x_eq_end_valid or _rd_col_valid or _rd_en_valid or mem_patch_rd_bram_o or KER_SIZE) begin
    if(_rd_en_valid) begin
      if( ((_rd_x_valid == 5'd0) && (_rd_col_valid < (KER_SIZE>>1))) || 
         (_rd_x_eq_end_valid && (_rd_col_valid > (13+(KER_SIZE>>1)))) )
        _mem_patch_rd_o = {(18*DATA_WIDTH)*{1'b0}};
      else
        _mem_patch_rd_o = mem_patch_rd_bram_o; //unvalid at rising edge of mem_patch_rd_en
    end else begin
      _mem_patch_rd_o = {(18*DATA_WIDTH)*{1'b0}};
    end
  end

endmodule
