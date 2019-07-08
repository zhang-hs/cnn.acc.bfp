`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/05 19:44:17
// Design Name: mem_patch_update
// Description: Rearrange the burst data read in DDR to store it in patch bram.
//              2 register buffers of 7*7 are used.
// 
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module mem_patch_update#(
  parameter DATA_WIDTH = 8,
  parameter IM_C = 8
)(
  input  wire                                  clk,
  input  wire                                  rst_n,
 
  input  wire [255:0]                          mem_patch_ddr_i,
//  input  wire [29:0]                           mem_patch_addr,  //for debug 
  input  wire [4:0]                            mem_patch_ddr_grp,
  input  wire                                  mem_patch_ddr_valid,
  input  wire [3:0]                            mem_patch_x,
  input  wire [3:0]                            mem_patch_y,
  input  wire [8:0]                            mem_patch_ith_fm,
  input  wire [7:0]                            mem_patch_bottom_fm_width,
  input  wire                                  mem_patch_cache_idx, //index of the cache used to storage ddr burst data.
  output reg                                   mem_patch_bram_done,
  
  output reg  [IM_C-1:0]                       mem_patch_bram_ith_valid,
  output reg  [DATA_WIDTH*7-1:0]               mem_patch_bram_o,
  output reg  [4:0]                            mem_patch_bram_en, //{a_upper, a, b, c_upper, c}
  output reg  [10:0]                           mem_patch_bram_addr  
);  
//  localparam NUM_OF_DATA_IN_BURST = 32;
  //location
  wire                     mem_patch_y_eq_zero;
  wire                     mem_patch_y_is_odd; //y[0] is 1 
  //bram
  reg  [3:0]               _mem_patch_bram_addr_base; //21-7
  reg  [7:0]               _mem_patch_bram_addr_start; //224-7
  reg  [10:0]              _mem_patch_bram_addr_ith;  //1792-14
  reg  [2:0]               _mem_patch_bram_addr_offset;   //7. the address of current pixel within one 7x7 block.

  //mem_patch control options
  reg  [DATA_WIDTH-1:0]    _mem_patch_0[0:7*7-1];
  reg  [DATA_WIDTH-1:0]    _mem_patch_1[0:7*7-1];
  reg                      _mem_patch_idx;    //index of cache that is being exported to bram.
  //holding corresponding 7*7 block parameters
  reg                      _mem_patch_full[0:1]; 
  reg  [4:0]               _mem_patch_grp[0:1]; //0~17
  reg                      _mem_patch_y_eq_zero[0:1];
  reg                      _mem_patch_y_is_odd[0:1];
  reg  [3:0]               _mem_patch_x[0:1];
  reg  [8:0]               _mem_patch_ith_fm[0:1];
  
  assign mem_patch_y_eq_zero            = mem_patch_y == 4'd0;
  assign mem_patch_y_is_odd             = mem_patch_y[0] == 1'b1; //input directly can lighten the timing burden.
  
  always@(posedge clk) begin
    mem_patch_bram_addr = _mem_patch_bram_addr_ith + {3'b0, _mem_patch_bram_addr_start} + {7'b0, _mem_patch_bram_addr_base} 
                          + {8'b0, _mem_patch_bram_addr_offset};
  end
  
  //caching ddr3 data
  always@(posedge clk) begin
    if(mem_patch_ddr_valid) begin
      if(mem_patch_ddr_grp[0] == 1'b0) begin
        if(mem_patch_cache_idx) begin
          {_mem_patch_1[31],_mem_patch_1[30],_mem_patch_1[29],_mem_patch_1[28],_mem_patch_1[27],_mem_patch_1[26],_mem_patch_1[25],_mem_patch_1[24],
           _mem_patch_1[23],_mem_patch_1[22],_mem_patch_1[21],_mem_patch_1[20],_mem_patch_1[19],_mem_patch_1[18],_mem_patch_1[17],_mem_patch_1[16],
           _mem_patch_1[15],_mem_patch_1[14],_mem_patch_1[13],_mem_patch_1[12],_mem_patch_1[11],_mem_patch_1[10],_mem_patch_1[9],_mem_patch_1[8],
           _mem_patch_1[7],_mem_patch_1[6],_mem_patch_1[5],_mem_patch_1[4],_mem_patch_1[3],_mem_patch_1[2],_mem_patch_1[1],_mem_patch_1[0]} <= mem_patch_ddr_i; 
        end else begin
          {_mem_patch_0[31],_mem_patch_0[30],_mem_patch_0[29],_mem_patch_0[28],_mem_patch_0[27],_mem_patch_0[26],_mem_patch_0[25],_mem_patch_0[24],
           _mem_patch_0[23],_mem_patch_0[22],_mem_patch_0[21],_mem_patch_0[20],_mem_patch_0[19],_mem_patch_0[18],_mem_patch_0[17],_mem_patch_0[16],
           _mem_patch_0[15],_mem_patch_0[14],_mem_patch_0[13],_mem_patch_0[12],_mem_patch_0[11],_mem_patch_0[10],_mem_patch_0[9],_mem_patch_0[8],
           _mem_patch_0[7],_mem_patch_0[6],_mem_patch_0[5],_mem_patch_0[4],_mem_patch_0[3],_mem_patch_0[2],_mem_patch_0[1],_mem_patch_0[0]} <= mem_patch_ddr_i; 
        end
      end else begin
        if(mem_patch_cache_idx) begin
          {_mem_patch_1[48],_mem_patch_1[47],_mem_patch_1[46],_mem_patch_1[45],_mem_patch_1[44],_mem_patch_1[43],_mem_patch_1[42],_mem_patch_1[41],
           _mem_patch_1[40],_mem_patch_1[39],_mem_patch_1[38],_mem_patch_1[37],_mem_patch_1[36],_mem_patch_1[35],_mem_patch_1[34],_mem_patch_1[33],
           _mem_patch_1[32]} <= mem_patch_ddr_i[17*DATA_WIDTH-1:0]; 
        end else begin
          {_mem_patch_0[48],_mem_patch_0[47],_mem_patch_0[46],_mem_patch_0[45],_mem_patch_0[44],_mem_patch_0[43],_mem_patch_0[42],_mem_patch_0[41],
           _mem_patch_0[40],_mem_patch_0[39],_mem_patch_0[38],_mem_patch_0[37],_mem_patch_0[36],_mem_patch_0[35],_mem_patch_0[34],_mem_patch_0[33],
           _mem_patch_0[32]} <= mem_patch_ddr_i[17*DATA_WIDTH-1:0]; 
        end
      end
    end
  end

  always@(posedge clk) begin
    if(mem_patch_ddr_valid && (mem_patch_ddr_grp[0] == 1'b0)) begin
      if(mem_patch_cache_idx) begin
        _mem_patch_grp[1]         <= mem_patch_ddr_grp;
        _mem_patch_y_eq_zero[1]   <= mem_patch_y_eq_zero;
        _mem_patch_y_is_odd[1]    <= mem_patch_y_is_odd;
        _mem_patch_x[1]           <= mem_patch_x;
        _mem_patch_ith_fm[1]      <= mem_patch_ith_fm;
      end else begin
        _mem_patch_grp[0]         <= mem_patch_ddr_grp;
        _mem_patch_y_eq_zero[0]   <= mem_patch_y_eq_zero;
        _mem_patch_y_is_odd[0]    <= mem_patch_y_is_odd;
        _mem_patch_x[0]           <= mem_patch_x;
        _mem_patch_ith_fm[0]      <= mem_patch_ith_fm;
      end
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_patch_idx <= 1'b0;
    end else if(_mem_patch_bram_addr_offset == 3'd6) begin
      _mem_patch_idx <= _mem_patch_idx + 1'b1;
    end
  end
  
  always@(posedge clk) begin
    if(mem_patch_ddr_valid) begin
      if(mem_patch_ddr_grp[0] == 1'b0) begin
        _mem_patch_full[mem_patch_cache_idx] <= 1'b1;
      end
    end
    if(_mem_patch_bram_addr_offset == 3'd6) begin
      _mem_patch_full[_mem_patch_idx] <= 1'b0; 
    end
  end
    
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n)  begin
      mem_patch_bram_done <= 1'b0;
    end else begin
      if(_mem_patch_bram_addr_offset == 3'd6) begin
        mem_patch_bram_done <= 1'b1;
      end else begin
        mem_patch_bram_done <= 1'b0;
      end
    end
  end
  
  wire [5:0]               _mem_patch_ith_fm_hpos;
  wire [2:0]               _mem_patch_ith_fm_lpos;
  assign _mem_patch_ith_fm_hpos = _mem_patch_ith_fm[_mem_patch_idx][8:3];
  assign _mem_patch_ith_fm_lpos = _mem_patch_ith_fm[_mem_patch_idx][2:0];
  
  //bram_ith_valid
  always@(posedge clk) begin
    mem_patch_bram_ith_valid = 8'b0000_0001 << _mem_patch_ith_fm_lpos;
  end
    
  //bram_addr_ith
  reg [10:0]      _mem_patch_bram_addr_ith_reg;
  always@(_mem_patch_ith_fm_hpos or mem_patch_bottom_fm_width) begin
    if(_mem_patch_ith_fm_hpos == 6'd0) begin
      _mem_patch_bram_addr_ith = 11'd0;
    end
    _mem_patch_bram_addr_ith = _mem_patch_bram_addr_ith_reg + mem_patch_bottom_fm_width;
  end
  always@(posedge clk) begin
    _mem_patch_bram_addr_ith_reg <= _mem_patch_bram_addr_ith;
  end
//  assign _mem_patch_bram_addr_ith =_mem_patch_ith_fm_hpos * mem_patch_bottom_fm_width; 
  
  //bram_addr_offset  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _mem_patch_bram_addr_offset <= 3'd0;
    end else begin
      if(_mem_patch_full[_mem_patch_idx]) begin
        if(_mem_patch_bram_addr_offset == 3'd6) begin
          _mem_patch_bram_addr_offset <= 3'd0;
        end else begin
          _mem_patch_bram_addr_offset <= _mem_patch_bram_addr_offset + 1'b1;
        end
      end
    end
  end
  
  //bram_addr_base
  wire [3:0]    _mem_patch_cur_grp_block;
  assign _mem_patch_cur_grp_block = _mem_patch_grp[_mem_patch_idx] >> 1;
  always@(_mem_patch_cur_grp_block) begin
    case(_mem_patch_cur_grp_block)
      0,3,6: begin
        _mem_patch_bram_addr_base = 4'd0;
      end
      1,4,7: begin
        _mem_patch_bram_addr_base = 4'd7;
      end
      2,5,8: begin
        _mem_patch_bram_addr_base = 4'd14;
      end
    endcase
  end
  
  //bram_addr_start
  wire [7:0]      _mem_patch_cur_x;
  assign _mem_patch_cur_x = {4'b0, _mem_patch_x[_mem_patch_idx]};
  always@(_mem_patch_cur_x) begin
    if(_mem_patch_cur_x == 8'd0) begin
      _mem_patch_bram_addr_start = 8'd0;
    end else begin
      _mem_patch_bram_addr_start = 8'd7 + (_mem_patch_cur_x<<4) - (_mem_patch_cur_x<<1);  //x*14=x*16-x*2
    end
  end
  
 //bram enable
  always@(posedge clk) begin
    if(_mem_patch_full[_mem_patch_idx]) begin
      if(_mem_patch_y_eq_zero[_mem_patch_idx]) begin //a,b,c.
        if( (_mem_patch_cur_grp_block==4'd0) || (_mem_patch_cur_grp_block==4'd1) || (_mem_patch_cur_grp_block==4'd2) ) begin
          mem_patch_bram_en <= 5'b01000;
        end else if( (_mem_patch_cur_grp_block==4'd3) || (_mem_patch_cur_grp_block==4'd4) || (_mem_patch_cur_grp_block==4'd5) ) begin
          mem_patch_bram_en <= 5'b00110;
        end else begin
          mem_patch_bram_en <= 5'b00001;
        end
      end else if(_mem_patch_y_is_odd[_mem_patch_idx]) begin //c,b,a
        if( (_mem_patch_cur_grp_block==4'd0) || (_mem_patch_cur_grp_block==4'd1) || (_mem_patch_cur_grp_block==4'd2) ) begin
          mem_patch_bram_en <= 5'b10100;
        end else begin
          mem_patch_bram_en <= 5'b01000;
        end
      end else begin//a,b,c
        if( (_mem_patch_cur_grp_block==4'd0) || (_mem_patch_cur_grp_block==4'd1) || (_mem_patch_cur_grp_block==4'd2) ) begin
          mem_patch_bram_en <= 5'b00110;
        end else begin
          mem_patch_bram_en <= 5'b00001;
        end
      end
    end else begin
      mem_patch_bram_en <= 5'b00000;
    end
  end

  //data <--mark
  always@(posedge clk) begin
    if(_mem_patch_idx) begin
      case( _mem_patch_bram_addr_offset)  //synopsys full_case parallel_case
        3'd0: begin
          mem_patch_bram_o <= {_mem_patch_1[48],_mem_patch_1[41],_mem_patch_1[34],_mem_patch_1[27], _mem_patch_1[20],_mem_patch_1[13],_mem_patch_1[6]};
        end
        3'd1: begin
          mem_patch_bram_o <= {_mem_patch_1[47],_mem_patch_1[40],_mem_patch_1[33],_mem_patch_1[26], _mem_patch_1[19],_mem_patch_1[12],_mem_patch_1[5]};
        end
        3'd2: begin
          mem_patch_bram_o <= {_mem_patch_1[46],_mem_patch_1[39],_mem_patch_1[32],_mem_patch_1[25], _mem_patch_1[18],_mem_patch_1[11],_mem_patch_1[4]};
        end
        3'd3: begin
          mem_patch_bram_o <= {_mem_patch_1[45],_mem_patch_1[38],_mem_patch_1[31],_mem_patch_1[24], _mem_patch_1[17],_mem_patch_1[10],_mem_patch_1[3]};
        end
        3'd4: begin
          mem_patch_bram_o <= {_mem_patch_1[44],_mem_patch_1[37],_mem_patch_1[30],_mem_patch_1[23], _mem_patch_1[16],_mem_patch_1[9],_mem_patch_1[2]};
        end
        3'd5: begin
          mem_patch_bram_o <= {_mem_patch_1[43],_mem_patch_1[36],_mem_patch_1[29],_mem_patch_1[22], _mem_patch_1[15],_mem_patch_1[8],_mem_patch_1[1]};
        end
        3'd6: begin
          mem_patch_bram_o <= {_mem_patch_1[42],_mem_patch_1[35],_mem_patch_1[28],_mem_patch_1[21], _mem_patch_1[14],_mem_patch_1[7],_mem_patch_1[0]};
        end
      endcase
    end else begin
      case( _mem_patch_bram_addr_offset)  //synopsys full_case parallel_case
        3'd0: begin
          mem_patch_bram_o <= {_mem_patch_0[48],_mem_patch_0[41],_mem_patch_0[34],_mem_patch_0[27], _mem_patch_0[20],_mem_patch_0[13],_mem_patch_0[6]};
        end
        3'd1: begin
          mem_patch_bram_o <= {_mem_patch_0[47],_mem_patch_0[40],_mem_patch_0[33],_mem_patch_0[26], _mem_patch_0[19],_mem_patch_0[12],_mem_patch_0[5]};
        end
        3'd2: begin
          mem_patch_bram_o <= {_mem_patch_0[46],_mem_patch_0[39],_mem_patch_0[32],_mem_patch_0[25], _mem_patch_0[18],_mem_patch_0[11],_mem_patch_0[4]};
        end
        3'd3: begin
          mem_patch_bram_o <= {_mem_patch_0[45],_mem_patch_0[38],_mem_patch_0[31],_mem_patch_0[24], _mem_patch_0[17],_mem_patch_0[10],_mem_patch_0[3]};
        end
        3'd4: begin
          mem_patch_bram_o <= {_mem_patch_0[44],_mem_patch_0[37],_mem_patch_0[30],_mem_patch_0[23], _mem_patch_0[16],_mem_patch_0[9],_mem_patch_0[2]};
        end
        3'd5: begin
          mem_patch_bram_o <= {_mem_patch_0[43],_mem_patch_0[36],_mem_patch_0[29],_mem_patch_0[22], _mem_patch_0[15],_mem_patch_0[8],_mem_patch_0[1]};
        end
        3'd6: begin
          mem_patch_bram_o <= {_mem_patch_0[42],_mem_patch_0[35],_mem_patch_0[28],_mem_patch_0[21], _mem_patch_0[14],_mem_patch_0[7],_mem_patch_0[0]};
        end
      endcase
    end
  end 
 
endmodule
