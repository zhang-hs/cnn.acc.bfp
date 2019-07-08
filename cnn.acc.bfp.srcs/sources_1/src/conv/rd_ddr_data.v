`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/08/29 20:47:57
// Module Name: rd_ddr_data
// Module Name: rd_ddr_param
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: Read bottom data from DDR.
//              read out a CW data in burst form.
//              2 register buffers of 7*7 are used.
//
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module rd_ddr_data #(
  parameter FP_WIDTH  = 16,
  parameter DATA_WIDTH       = 8,
  parameter DDR_DATA_WIDTH   = 64,
  parameter DDR_BURST_LEN    = 8 // ddr data burst length
)(
    input  wire           clk,
    input  wire           rst_n,
    
    input  wire           ddr_rdy,
    output reg  [29:0]    ddr_addr,
    output reg  [2:0]     ddr_cmd,
    /*(*mark_debug="TRUE"*)*/output reg            ddr_en,
    input  wire [4:0]     input_exp,
    input  wire [511:0]   ddr_rd_data,
    input  wire           ddr_rd_data_valid,
    //read control
    input  wire           rd_data_bottom,     // read bottom data enable
    input  wire [29:0]    rd_data_bottom_addr,// read bottom data address, start address of bottom data
    input  wire [4:0]     rd_data_end_of_x,
    input  wire [4:0]     rd_data_end_of_y,
    input  wire [4:0]     rd_data_x,          // column index of the patch, stable till end
    input  wire [4:0]     rd_data_y,          // row index of the patch
    input  wire           rd_data_first_fm,   // first input feature map, update base address
    input  wire [29:0]    rd_data_bottom_ith_offset,  // ith bottom feature map size, stable till end
    input  wire [29:0]    rd_data_bar_offset, // 14*rd_data_max_x*float_num_width/ddr_data_width
    input  wire [29:0]    rd_data_half_bar_offset, // 7*rd_data_max_x*float_num_width/ddr_data_width
//    input  wire           rd_data_cache_release_done, //finished release
    input  wire           rd_data_cache_full,
    
    output wire [255:0]   rd_data_data, // rearranged ddr data
//    output wire           rd_data_cache_idx,  //index of reg cache for current busrt 
    /*(*mark_debug="TRUE"*)*/output reg  [4:0]     rd_data_grp, //0~9x2-1
    /*(*mark_debug="TRUE"*)*/output reg            rd_data_valid,
    output reg            rd_data_full
  );
 
//   (*mark_debug="TRUE"*)wire [DATA_WIDTH-1:0] _rd_data_data_h;
//  assign _rd_data_data_h = rd_data_data[DATA_WIDTH-1:0]; 
 
 //read stride
 localparam RD_MINI_1_SIZE = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*DDR_BURST_LEN;
 localparam RD_MINI_2_SIZE = 2*RD_MINI_1_SIZE;
 localparam RD_MINI_3_SIZE = 3*RD_MINI_1_SIZE;
 localparam RD_HALF_0Y_CNT = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*3 - 1; // 2*3-1
 localparam RD_HALF_XY_CNT = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*2 - 1; // 2*2-1
 localparam RD_HALF_EY_CNT = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*1 - 1; // 2*1-1
 localparam RD_PADDING_0Y_CNT = 2*3;
 localparam RD_PADDING_XY_CNT = 2*2;
 localparam RD_PADDING_EY_CNT = 2*1;
 localparam RD_TOTAL_0Y_CNT= 2*RD_HALF_0Y_CNT+1 +RD_PADDING_0Y_CNT;
 localparam RD_TOTAL_XY_CNT= 2*RD_HALF_XY_CNT+1 +RD_PADDING_XY_CNT;
 localparam RD_TOTAL_EY_CNT= 2*RD_HALF_EY_CNT+1 +RD_PADDING_EY_CNT;
 //states
 localparam RD_DATA_RST        = 4'd0;
 localparam RD_DATA_UPPER_PATCH= 4'd1;
 localparam RD_DATA_LOWER_PATCH= 4'd2;
 localparam RD_DATA_PADDING    = 4'd3;

 reg [3:0]     _rd_data_state;
 reg [3:0]     _rd_data_next_state;
 
 reg           _rd_data_upper_last;
 reg           _rd_data_lower_last;
 reg           _rd_data_padding_stop;
 reg           _rd_data_upper_stop;
 reg  [2:0]    _rd_data_upper_cnt;
 reg  [2:0]    _rd_data_lower_cnt;
 reg  [4:0]    _rd_data_valid_cnt;
 reg  [2:0]    _rd_data_padding_cnt;
 reg           _rd_data_cnt;
// reg  [8:0]    _rd_data_ith_fm;
 reg  [29:0]   _rd_data_upper_offset;
 reg  [29:0]   _rd_data_lower_offset;
 reg  [29:0]   _rd_data_padding_offset;
 reg  [29:0]   _rd_data_upper_addr;
 reg  [29:0]   _rd_data_lower_addr;
 reg  [29:0]   _rd_data_padding_addr;
 reg           _rd_data_upper_next;
 reg           _rd_data_lower_next;
 reg           _rd_data_padding_next;

 /*(*mark_debug="TRUE"*)*/reg           _rd_data_cache_valid;
 reg           _rd_data_full;
 reg  [4:0]    _rd_data_grp;
 wire          _rd_data_valid_first;
 reg           _rd_data_patch_valid_last;
 reg           _rd_data_upper_valid_last;
 
 // cache valid
 reg  _rd_data_cache_full_reg;
 wire _rd_data_cache_full_falling_edge;
 always@(posedge clk) begin
   _rd_data_cache_full_reg <= rd_data_cache_full;
 end
 assign _rd_data_cache_full_falling_edge = (!rd_data_cache_full) && _rd_data_cache_full_reg;
 always@(posedge clk or negedge rst_n) begin
   if(!rst_n) begin
     _rd_data_cache_valid <= 1'b1;
   end else begin
     if(_rd_data_cache_full_falling_edge) begin
       _rd_data_cache_valid <= 1'b1;
     end else if(ddr_rdy && _rd_data_cnt == 1'b1)begin
       _rd_data_cache_valid <= 1'b0;
     end
   end
 end
  
 //output
// assign rd_data_cache_idx  = ~_next_cache_idx;
 always@(posedge clk or negedge rst_n) begin
   if(!rst_n) begin
     rd_data_valid             <= 1'b0;
     rd_data_full              <= 1'b0;
     rd_data_grp               <= 5'd0;
   end else begin
     rd_data_valid             <= (rd_data_bottom && ddr_rd_data_valid && _rd_data_state!=RD_DATA_RST);
     rd_data_full              <= _rd_data_full;
     rd_data_grp               <= _rd_data_grp;
   end
 end
 
 //translate float data to fixed dat
 reg [511:0]  _ddr_rd_data;
 always@(posedge clk) begin
   _ddr_rd_data <= ddr_rd_data;
 end
 genvar i;
 generate
  for(i=0;i<32;i=i+1)
    begin:a
      float_to_fixed fp2fixed_bottom(
        .clk(clk),
//        .rst_n(rst_n),
        .datain(ddr_rd_data[15+i*FP_WIDTH:i*FP_WIDTH]),
        .expin(input_exp),
//        .datain_valid(ddr_rd_data_valid),
//        .dataout_valid(),
        .dataout(rd_data_data[7+i*DATA_WIDTH:i*DATA_WIDTH])
      );
    end
  endgenerate
  
 
 //3-stage fsm
 //---------------------------------------------------------------
 // FF
 always@(posedge clk or negedge rst_n) begin
   if(!rst_n) begin
     _rd_data_state <= RD_DATA_RST;
   end else begin
     _rd_data_state <= _rd_data_next_state;
   end
 end
 // transition
 always@(_rd_data_state or rd_data_bottom or _rd_data_upper_last or
         _rd_data_lower_last or _rd_data_full) begin
   _rd_data_next_state = RD_DATA_RST;
   case(_rd_data_state)
     RD_DATA_RST: begin
       if(rd_data_bottom) begin
         if(_rd_data_upper_last)begin
           _rd_data_next_state = RD_DATA_LOWER_PATCH; //reduce one clk delay
         end else begin
           _rd_data_next_state = RD_DATA_UPPER_PATCH;
         end
       end else begin
         _rd_data_next_state = RD_DATA_RST;
       end
     end
     RD_DATA_UPPER_PATCH: begin
       if(_rd_data_upper_last) begin
         _rd_data_next_state = RD_DATA_LOWER_PATCH;
       end else begin
         _rd_data_next_state = RD_DATA_UPPER_PATCH;
       end
     end
     RD_DATA_LOWER_PATCH: begin
       if(_rd_data_lower_last) begin
         _rd_data_next_state = RD_DATA_PADDING;
       end else begin
         _rd_data_next_state = RD_DATA_LOWER_PATCH;
       end
     end
     RD_DATA_PADDING: begin
       if(_rd_data_full) begin
         _rd_data_next_state = RD_DATA_RST;
       end else begin
         _rd_data_next_state = RD_DATA_PADDING;
       end
     end
   endcase
 end
 // logic
 always@(_rd_data_state or _rd_data_upper_addr or _rd_data_upper_offset or
         _rd_data_lower_addr or _rd_data_lower_offset or _rd_data_padding_addr or _rd_data_cache_valid or
         _rd_data_padding_offset or ddr_rdy or _rd_data_padding_stop or _rd_data_upper_stop) begin
   ddr_en    = 1'b0;
   ddr_cmd   = 3'h1;
   ddr_addr  = 30'h0;
   _rd_data_upper_next = 1'b0;
   _rd_data_lower_next = 1'b0;
   _rd_data_padding_next = 1'b0;
   case(_rd_data_state)
     RD_DATA_RST: begin
       ddr_en = 1'b0;
     end
     RD_DATA_UPPER_PATCH: begin
       if(_rd_data_upper_stop) begin
         ddr_en    = 1'b0;
         ddr_cmd   = 3'h1;
         ddr_addr  = _rd_data_upper_addr + _rd_data_upper_offset;
       end else begin
         if(ddr_rdy && _rd_data_cache_valid) begin //ddr_en keeps 1 to reduce request latency
           ddr_en    = 1'b1;
           ddr_cmd   = 3'h1;
           ddr_addr  = _rd_data_upper_addr + _rd_data_upper_offset;
           _rd_data_upper_next = 1'b1;
         end else begin
           ddr_en    = 1'b0;
           ddr_cmd   = 3'h1;
           ddr_addr  = _rd_data_upper_addr + _rd_data_upper_offset;
           _rd_data_upper_next = 1'b0;
         end
       end
     end
     RD_DATA_LOWER_PATCH: begin
       if(ddr_rdy && _rd_data_cache_valid) begin
         ddr_en    = 1'b1;
         ddr_cmd   = 3'h1;
         ddr_addr  = _rd_data_lower_addr + _rd_data_lower_offset;
         _rd_data_lower_next = 1'b1;
       end else begin
         ddr_en    = 1'b0;
         ddr_cmd   = 3'h1;
         ddr_addr  = _rd_data_lower_addr + _rd_data_lower_offset;
         _rd_data_lower_next = 1'b0;
       end
     end
     RD_DATA_PADDING: begin
       if(_rd_data_padding_stop) begin
         ddr_en    = 1'b0;
         ddr_cmd   = 3'h1;
         ddr_addr  = _rd_data_padding_addr + _rd_data_padding_offset;
       end else begin
         if(ddr_rdy && _rd_data_cache_valid) begin
           ddr_en  = 1'b1;
           ddr_cmd = 3'h1;
           ddr_addr= _rd_data_padding_addr + _rd_data_padding_offset;
           _rd_data_padding_next = 1'b1;
         end else begin
           ddr_en  = 1'b0;
           ddr_cmd = 3'h1;
           ddr_addr= _rd_data_padding_addr + _rd_data_padding_offset;
           _rd_data_padding_next = 1'b0;
         end
       end
     end
   endcase
 end
//----------------------------------------------------------------------

  // patch address and padding address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_upper_addr <= 30'h0;
      _rd_data_lower_addr <= 30'h0;
      _rd_data_padding_addr <= 30'h0;
    end else begin
      if(rd_data_bottom && rd_data_first_fm && (_rd_data_state == RD_DATA_RST)) begin
        if(rd_data_x == 5'h0) begin
          if(rd_data_y == 5'h0) begin
            _rd_data_upper_addr <= rd_data_bottom_addr;
            _rd_data_lower_addr <= rd_data_bottom_addr + rd_data_half_bar_offset; //+2 * bottom_width * FP_WIDTH
            _rd_data_padding_addr <= rd_data_bottom_addr + rd_data_bar_offset;  ////+4 * bottom_width * FP_WIDTH
          end else begin
            _rd_data_upper_addr <= _rd_data_upper_addr + rd_data_half_bar_offset + RD_MINI_1_SIZE;//useless,there is no upper_patch when y！=0.
            _rd_data_lower_addr <= _rd_data_lower_addr + rd_data_half_bar_offset + RD_MINI_1_SIZE;
            _rd_data_padding_addr <= _rd_data_padding_addr + rd_data_half_bar_offset + RD_MINI_1_SIZE;
          end
        end else if(rd_data_x == 5'h1) begin
          _rd_data_upper_addr <= _rd_data_upper_addr + RD_MINI_3_SIZE; //right_patch occupies one RD_MINI_1_SIZE
          _rd_data_lower_addr <= _rd_data_lower_addr + RD_MINI_3_SIZE;
          _rd_data_padding_addr <= _rd_data_padding_addr + RD_MINI_3_SIZE;
        end else begin
          _rd_data_upper_addr <= _rd_data_upper_addr + RD_MINI_2_SIZE;
          _rd_data_lower_addr <= _rd_data_lower_addr + RD_MINI_2_SIZE;
          _rd_data_padding_addr <= _rd_data_padding_addr + RD_MINI_2_SIZE;
        end
      end
    end
  end
  // patch offset and padding offset
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
//      _rd_data_ith_fm <= 9'h0;
      _rd_data_upper_offset <= 30'h0;
      _rd_data_lower_offset <= 30'h0;
      _rd_data_padding_offset <= 30'h0;
    end else begin
      if(rd_data_bottom && (_rd_data_state==RD_DATA_RST)) begin
      // reset
//        _rd_data_ith_fm <= rd_data_bottom_ith_fm;
        _rd_data_upper_offset <= rd_data_bottom_ith_offset;
        _rd_data_lower_offset <= rd_data_bottom_ith_offset;
        _rd_data_padding_offset <= rd_data_bottom_ith_offset;
      end else begin
      // increment
        if(_rd_data_upper_next) begin
          _rd_data_upper_offset <= _rd_data_upper_offset + DDR_BURST_LEN;
        end
        if(_rd_data_lower_next) begin
          _rd_data_lower_offset <= _rd_data_lower_offset + DDR_BURST_LEN;
        end
        if(_rd_data_padding_next) begin
          _rd_data_padding_offset <= _rd_data_padding_offset + DDR_BURST_LEN;
        end
      end
    end
  end
  // patch counter, padding counter and valid counter
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_cnt <= 1'b0;
      _rd_data_upper_cnt <= 3'h0;
      _rd_data_lower_cnt <= 3'h0;
      _rd_data_valid_cnt <= 5'h0;
      _rd_data_padding_cnt <= 3'h0;
    end else begin
      if(rd_data_bottom && (_rd_data_state==RD_DATA_RST)) begin //set to 0, eliminate the influence of rd_exp and rd_data_param
      // reset
        _rd_data_cnt <= 1'b0;
        _rd_data_upper_cnt <= 3'h0;
        _rd_data_lower_cnt <= 3'h0;
        _rd_data_valid_cnt <= 5'h0;
        _rd_data_padding_cnt <= 3'h0;
      end else begin
      // increment
        if(_rd_data_upper_next) begin
          _rd_data_upper_cnt <= _rd_data_upper_cnt + 1'b1;
        end
        if(_rd_data_lower_next) begin
          _rd_data_lower_cnt <= _rd_data_lower_cnt + 1'b1;
        end
        if(_rd_data_padding_next) begin
          _rd_data_padding_cnt <= _rd_data_padding_cnt + 1'b1;
        end
        if(_rd_data_upper_next || _rd_data_lower_next || _rd_data_padding_next) begin
          _rd_data_cnt <= _rd_data_cnt + 1'b1;
        end
        if(ddr_rd_data_valid && (_rd_data_state!=RD_DATA_RST)) begin
          _rd_data_valid_cnt <= _rd_data_valid_cnt + 1'b1;
        end
        // reset
        if(_rd_data_full) begin
          _rd_data_cnt <= 1'b0;
          _rd_data_upper_cnt <= 3'h0;
          _rd_data_lower_cnt <= 3'h0;
          _rd_data_valid_cnt <= 5'h0;
          _rd_data_padding_cnt <= 3'h0;
        end
      end
    end
  end
  // 'last' signal
  always@(rst_n or _rd_data_upper_cnt or _rd_data_lower_cnt or ddr_rd_data_valid or
          _rd_data_padding_cnt or _rd_data_valid_cnt or rd_data_x or ddr_rdy or
          rd_data_y or rd_data_end_of_x or rd_data_end_of_y or _rd_data_state) begin
      if(rd_data_x == 5'h0) begin
        // (0,y)
        if(rd_data_x == rd_data_end_of_x) begin //modify to write 14x14 fm
          _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_XY_CNT));
          _rd_data_upper_stop = 1'b0;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
          _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST); //no padding
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - RD_PADDING_XY_CNT)));
          _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_XY_CNT));
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - RD_PADDING_XY_CNT))); //no padding
        end else begin // >14x14
          if(rd_data_y == 5'h0) begin
            _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_0Y_CNT));
            _rd_data_upper_stop = 1'b0;
            _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_0Y_CNT));
            _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_0Y_CNT));
            _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - RD_PADDING_0Y_CNT)));
            _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_0Y_CNT));
            _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_0Y_CNT));
          end else if(rd_data_y == rd_data_end_of_y) begin
            _rd_data_upper_last = 1'b1;
            _rd_data_upper_stop = 1'b1;
            _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_0Y_CNT));
            _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST);
            _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1) -RD_PADDING_0Y_CNT)));
            _rd_data_upper_valid_last = 1'b0;
            _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1) - RD_PADDING_0Y_CNT)));
          end else begin
            _rd_data_upper_last = 1'b1;
            _rd_data_upper_stop = 1'b1;
            _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_0Y_CNT));
            _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_0Y_CNT));
            _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1) - RD_PADDING_0Y_CNT)));
            _rd_data_upper_valid_last = 1'b0;
            _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1)));
          end
        end
      end else if(rd_data_x == rd_data_end_of_x) begin
        // (e,y)
        if(rd_data_y == rd_data_end_of_y) begin
          _rd_data_upper_last = 1'b1;
          _rd_data_upper_stop = 1'b1;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_EY_CNT));
          _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST);
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1) - RD_PADDING_EY_CNT)));
          _rd_data_upper_valid_last = 1'b0;
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1) -RD_PADDING_EY_CNT)));
        end else if(rd_data_y == 5'h0) begin
          _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_EY_CNT));
          _rd_data_upper_stop = 1'b0;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_EY_CNT));
          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_EY_CNT));
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - RD_PADDING_EY_CNT)));
          _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_EY_CNT));
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_EY_CNT));
        end else begin
          _rd_data_upper_last = 1'b1;
          _rd_data_upper_stop = 1'b1;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_EY_CNT));
          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_EY_CNT));
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1) - RD_PADDING_EY_CNT)));
          _rd_data_upper_valid_last = 1'b0;
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1)));
        end
      end else begin
        // (x,y)
        if(rd_data_y == rd_data_end_of_y) begin
          _rd_data_upper_last = 1'b1;
          _rd_data_upper_stop = 1'b1;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
          _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST);
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1) - RD_PADDING_XY_CNT)));
          _rd_data_upper_valid_last = 1'b0;
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1) - RD_PADDING_XY_CNT)));
        end else if(rd_data_y == 5'h0) begin
          _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_XY_CNT));
          _rd_data_upper_stop = 1'b0;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_XY_CNT));
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - RD_PADDING_XY_CNT)));
          _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_XY_CNT));
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_XY_CNT));
        end else begin
          _rd_data_upper_last = 1'b1;
          _rd_data_upper_stop = 1'b1;
          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_XY_CNT));
          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1) - RD_PADDING_XY_CNT)));
          _rd_data_upper_valid_last = 1'b0;
          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1)));
        end
      end
//    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_grp <= 5'd0;
    end else begin
      if(rd_data_bottom && ddr_rd_data_valid) begin
        if(/*_rd_data_valid_first || */_rd_data_full) begin
          _rd_data_grp <= 5'd0;
        end else begin
          if(_rd_data_upper_stop) begin
            if(_rd_data_patch_valid_last) begin
              _rd_data_grp <= 5'd6;
            end else begin
              _rd_data_grp <= _rd_data_grp + 1'd1;
            end
          end else begin
            if(_rd_data_upper_valid_last) begin
              _rd_data_grp <= 5'd6;
            end else if(_rd_data_patch_valid_last) begin
              _rd_data_grp <= 5'd12;
            end else begin
              _rd_data_grp <= _rd_data_grp + 1'b1;
            end
          end
        end
      end
    end
  end    
    
endmodule



//ping-pong asscess
//module rd_ddr_data #(
//  parameter FP_WIDTH  = 16,
//  parameter DATA_WIDTH       = 8,
//  parameter DDR_DATA_WIDTH   = 64,
//  parameter DDR_BURST_LEN    = 8 // ddr data burst length
//)(
//    input  wire           clk,
//    input  wire           rst_n,
    
//    input  wire           ddr_rdy,
//    output reg  [29:0]    ddr_addr,
//    output reg  [2:0]     ddr_cmd,
//    output reg            ddr_en,
//    input  wire [4:0]     input_exp,
//    input  wire [511:0]   ddr_rd_data,
//    input  wire           ddr_rd_data_valid,
//    //read control
//    input  wire           rd_data_bottom,     // read bottom data enable
//    input  wire [29:0]    rd_data_bottom_addr,// read bottom data address, start address of bottom data
//    input  wire [4:0]     rd_data_end_of_x,
//    input  wire [4:0]     rd_data_end_of_y,
//    input  wire [4:0]     rd_data_x,          // column index of the patch, stable till end
//    input  wire [4:0]     rd_data_y,          // row index of the patch
//    input  wire           rd_data_first_fm,   // first input feature map, update base address
//    input  wire [29:0]    rd_data_bottom_ith_offset,  // ith bottom feature map size, stable till end
//    input  wire [29:0]    rd_data_bar_offset, // 14*rd_data_max_x*float_num_width/ddr_data_width
//    input  wire [29:0]    rd_data_half_bar_offset, // 7*rd_data_max_x*float_num_width/ddr_data_width
//    input  wire           rd_data_cache_release_done, //finished release
    
//    output wire [255:0]   rd_data_data, // rearranged ddr data
//    output wire           rd_data_cache_idx,  //index of reg cache for current busrt 
//    (*mark_debug="TRUE"*)output reg  [4:0]     rd_data_grp, //0~9x2-1
//    (*mark_debug="TRUE"*)output reg            rd_data_valid,
//    output reg            rd_data_full
//  );
 
//   (*mark_debug="TRUE"*)wire [DATA_WIDTH-1:0] _rd_data_data_h;
//  assign _rd_data_data_h = rd_data_data[DATA_WIDTH-1:0]; 
 
// //read stride
// localparam RD_MINI_1_SIZE = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*DDR_BURST_LEN;
// localparam RD_MINI_2_SIZE = 2*RD_MINI_1_SIZE;
// localparam RD_MINI_3_SIZE = 3*RD_MINI_1_SIZE;
// localparam RD_HALF_0Y_CNT = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*3 - 1; // 2*3-1
// localparam RD_HALF_XY_CNT = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*2 - 1; // 2*2-1
// localparam RD_HALF_EY_CNT = (7*7*FP_WIDTH/DDR_DATA_WIDTH/DDR_BURST_LEN + 1)*1 - 1; // 2*1-1
// localparam RD_PADDING_0Y_CNT = 2*3;
// localparam RD_PADDING_XY_CNT = 2*2;
// localparam RD_PADDING_EY_CNT = 2*1;
// localparam RD_TOTAL_0Y_CNT= 2*RD_HALF_0Y_CNT+1 +RD_PADDING_0Y_CNT;
// localparam RD_TOTAL_XY_CNT= 2*RD_HALF_XY_CNT+1 +RD_PADDING_XY_CNT;
// localparam RD_TOTAL_EY_CNT= 2*RD_HALF_EY_CNT+1 +RD_PADDING_EY_CNT;
// //states
// localparam RD_DATA_RST        = 4'd0;
// localparam RD_DATA_UPPER_PATCH= 4'd1;
// localparam RD_DATA_LOWER_PATCH= 4'd2;
// localparam RD_DATA_PADDING    = 4'd3;

// reg [3:0]     _rd_data_state;
// reg [3:0]     _rd_data_next_state;
 
// reg           _rd_data_upper_last;
// reg           _rd_data_lower_last;
// reg           _rd_data_padding_stop;
// reg           _rd_data_upper_stop;
// reg  [2:0]    _rd_data_upper_cnt;
// reg  [2:0]    _rd_data_lower_cnt;
// reg  [4:0]    _rd_data_valid_cnt;
// reg  [2:0]    _rd_data_padding_cnt;
//// reg  [8:0]    _rd_data_ith_fm;
// reg  [29:0]   _rd_data_upper_offset;
// reg  [29:0]   _rd_data_lower_offset;
// reg  [29:0]   _rd_data_padding_offset;
// reg  [29:0]   _rd_data_upper_addr;
// reg  [29:0]   _rd_data_lower_addr;
// reg  [29:0]   _rd_data_padding_addr;
// reg           _rd_data_upper_next;
// reg           _rd_data_lower_next;
// reg           _rd_data_padding_next;
// // lead by 1 clk
// reg           _rd_data_cache_idx;
// reg           _next_cache_idx;
// reg           _cur_cache_idx; //
// reg           _cache_full[0:1];
// wire          _rd_data_cache_valid;
// reg           _rd_data_full;
// reg  [4:0]    _rd_data_grp;
// wire          _rd_data_valid_first;
// reg           _rd_data_patch_valid_last;
// reg           _rd_data_upper_valid_last;
 
  
// //output
//// assign rd_data_cache_idx  = ~_next_cache_idx;
// always@(posedge clk or negedge rst_n) begin
//   if(!rst_n) begin
//     rd_data_valid             <= 1'b0;
//     rd_data_full              <= 1'b0;
//     rd_data_grp               <= 5'd0;
//   end else begin
//     rd_data_valid             <= (rd_data_bottom && ddr_rd_data_valid && _rd_data_state!=RD_DATA_RST);
//     rd_data_full              <= _rd_data_full;
//     rd_data_grp               <= _rd_data_grp;
//   end
// end
 
// //translate float data to fixed dat
// reg [511:0]  _ddr_rd_data;
// always@(posedge clk) begin
//   _ddr_rd_data <= ddr_rd_data;
// end
// genvar i;
// generate
//  for(i=0;i<32;i=i+1)
//    begin:a
//      float_to_fixed fp2fixed_bottom(
//        .clk(clk),
////        .rst_n(rst_n),
//        .datain(ddr_rd_data[15+i*FP_WIDTH:i*FP_WIDTH]),
//        .expin(input_exp),
////        .datain_valid(ddr_rd_data_valid),
////        .dataout_valid(),
//        .dataout(rd_data_data[7+i*DATA_WIDTH:i*DATA_WIDTH])
//      );
//    end
//  endgenerate
  
// assign _rd_data_cache_valid = !_cache_full[_next_cache_idx]; //|| rd_data_cache_release_done;ss
// always@(posedge clk or negedge rst_n) begin
//   if(!rst_n) begin
//     _next_cache_idx  <= 1'b0;
//     _cur_cache_idx   <= 1'b0;
//   end else begin
//     if(rd_data_bottom && ddr_rd_data_valid && (_rd_data_grp[0] == 1'b0)) begin
//       _next_cache_idx  <= _next_cache_idx + 1'b1;
//     end
//     if(rd_data_cache_release_done) begin
//       _cur_cache_idx <= _cur_cache_idx + 1'b1;
//     end
//   end
// end
 
// always@(posedge clk or negedge rst_n) begin
//   if(!rst_n) begin
//     _cache_full[0] <= 1'b0;
//     _cache_full[1] <= 1'b0;
//   end else begin
//     if(rd_data_bottom && ddr_rd_data_valid && (_rd_data_grp[0] == 1'b0)) begin
//       _cache_full[_next_cache_idx] <= 1'b1;
//     end
//     if(rd_data_cache_release_done) begin
//       _cache_full[_cur_cache_idx] <= 1'b0;
//     end
//   end
// end
 
// //3-stage fsm
// //---------------------------------------------------------------
// // FF
// always@(posedge clk or negedge rst_n) begin
//   if(!rst_n) begin
//     _rd_data_state <= RD_DATA_RST;
//   end else begin
//     _rd_data_state <= _rd_data_next_state;
//   end
// end
// // transition
// always@(_rd_data_state or rd_data_bottom or _rd_data_upper_last or
//         _rd_data_lower_last or _rd_data_full) begin
//   _rd_data_next_state = RD_DATA_RST;
//   case(_rd_data_state)
//     RD_DATA_RST: begin
//       if(rd_data_bottom) begin
//         if(_rd_data_upper_last)begin
//           _rd_data_next_state = RD_DATA_LOWER_PATCH; //reduce one clk delay
//         end else begin
//           _rd_data_next_state = RD_DATA_UPPER_PATCH;
//         end
//       end else begin
//         _rd_data_next_state = RD_DATA_RST;
//       end
//     end
//     RD_DATA_UPPER_PATCH: begin
//       if(_rd_data_upper_last) begin
//         _rd_data_next_state = RD_DATA_LOWER_PATCH;
//       end else begin
//         _rd_data_next_state = RD_DATA_UPPER_PATCH;
//       end
//     end
//     RD_DATA_LOWER_PATCH: begin
//       if(_rd_data_lower_last) begin
//         _rd_data_next_state = RD_DATA_PADDING;
//       end else begin
//         _rd_data_next_state = RD_DATA_LOWER_PATCH;
//       end
//     end
//     RD_DATA_PADDING: begin
//       if(_rd_data_full) begin
//         _rd_data_next_state = RD_DATA_RST;
//       end else begin
//         _rd_data_next_state = RD_DATA_PADDING;
//       end
//     end
//   endcase
// end
// // logic
// always@(_rd_data_state or _rd_data_upper_addr or _rd_data_upper_offset or
//         _rd_data_lower_addr or _rd_data_lower_offset or _rd_data_padding_addr or _rd_data_cache_valid or
//         _rd_data_padding_offset or ddr_rdy or _rd_data_padding_stop or _rd_data_upper_stop) begin
//   ddr_en    = 1'b0;
//   ddr_cmd   = 3'h1;
//   ddr_addr  = 30'h0;
//   _rd_data_upper_next = 1'b0;
//   _rd_data_lower_next = 1'b0;
//   _rd_data_padding_next = 1'b0;
//   case(_rd_data_state)
//     RD_DATA_RST: begin
//       ddr_en = 1'b0;
//     end
//     RD_DATA_UPPER_PATCH: begin
//       if(_rd_data_upper_stop) begin
//         ddr_en    = 1'b0;
//         ddr_cmd   = 3'h1;
//         ddr_addr  = _rd_data_upper_addr + _rd_data_upper_offset;
//       end else begin
//         if(ddr_rdy && _rd_data_cache_valid) begin
//           ddr_en    = 1'b1;
//           ddr_cmd   = 3'h1;
//           ddr_addr  = _rd_data_upper_addr + _rd_data_upper_offset;
//           _rd_data_upper_next = 1'b1;
//         end else begin
//           ddr_en    = 1'b0;
//           ddr_cmd   = 3'h1;
//           ddr_addr  = _rd_data_upper_addr + _rd_data_upper_offset;
//           _rd_data_upper_next = 1'b0;
//         end
//       end
//     end
//     RD_DATA_LOWER_PATCH: begin
//       if(ddr_rdy && _rd_data_cache_valid) begin
//         ddr_en    = 1'b1;
//         ddr_cmd   = 3'h1;
//         ddr_addr  = _rd_data_lower_addr + _rd_data_lower_offset;
//         _rd_data_lower_next = 1'b1;
//       end else begin
//         ddr_en    = 1'b0;
//         ddr_cmd   = 3'h1;
//         ddr_addr  = _rd_data_lower_addr + _rd_data_lower_offset;
//       end
//     end
//     RD_DATA_PADDING: begin
//       if(_rd_data_padding_stop) begin
//         ddr_en    = 1'b0;
//         ddr_cmd   = 3'h1;
//         ddr_addr  = _rd_data_padding_addr + _rd_data_padding_offset;
//       end else begin
//         if(ddr_rdy && _rd_data_cache_valid) begin
//           ddr_en  = 1'b1;
//           ddr_cmd = 3'h1;
//           ddr_addr= _rd_data_padding_addr + _rd_data_padding_offset;
//           _rd_data_padding_next = 1'b1;
//         end else begin
//           ddr_en  = 1'b0;
//           ddr_cmd = 3'h1;
//           ddr_addr= _rd_data_padding_addr + _rd_data_padding_offset;
//           _rd_data_padding_next = 1'b0;
//         end
//       end
//     end
//   endcase
// end
////----------------------------------------------------------------------

//  // patch address and padding address
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _rd_data_upper_addr <= 30'h0;
//      _rd_data_lower_addr <= 30'h0;
//      _rd_data_padding_addr <= 30'h0;
//    end else begin
//      if(rd_data_bottom && rd_data_first_fm && (_rd_data_state == RD_DATA_RST)) begin
//        if(rd_data_x == 5'h0) begin
//          if(rd_data_y == 5'h0) begin
//            _rd_data_upper_addr <= rd_data_bottom_addr;
//            _rd_data_lower_addr <= rd_data_bottom_addr + rd_data_half_bar_offset; //+2 * bottom_width * FP_WIDTH
//            _rd_data_padding_addr <= rd_data_bottom_addr + rd_data_bar_offset;  ////+4 * bottom_width * FP_WIDTH
//          end else begin
//            _rd_data_upper_addr <= _rd_data_upper_addr + rd_data_half_bar_offset + RD_MINI_1_SIZE;//useless,there is no upper_patch when y！=0.
//            _rd_data_lower_addr <= _rd_data_lower_addr + rd_data_half_bar_offset + RD_MINI_1_SIZE;
//            _rd_data_padding_addr <= _rd_data_padding_addr + rd_data_half_bar_offset + RD_MINI_1_SIZE;
//          end
//        end else if(rd_data_x == 5'h1) begin
//          _rd_data_upper_addr <= _rd_data_upper_addr + RD_MINI_3_SIZE; //right_patch occupies one RD_MINI_1_SIZE
//          _rd_data_lower_addr <= _rd_data_lower_addr + RD_MINI_3_SIZE;
//          _rd_data_padding_addr <= _rd_data_padding_addr + RD_MINI_3_SIZE;
//        end else begin
//          _rd_data_upper_addr <= _rd_data_upper_addr + RD_MINI_2_SIZE;
//          _rd_data_lower_addr <= _rd_data_lower_addr + RD_MINI_2_SIZE;
//          _rd_data_padding_addr <= _rd_data_padding_addr + RD_MINI_2_SIZE;
//        end
//      end
//    end
//  end
//  // patch offset and padding offset
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
////      _rd_data_ith_fm <= 9'h0;
//      _rd_data_upper_offset <= 30'h0;
//      _rd_data_lower_offset <= 30'h0;
//      _rd_data_padding_offset <= 30'h0;
//    end else begin
//      if(rd_data_bottom && (_rd_data_state==RD_DATA_RST)) begin
//      // reset
////        _rd_data_ith_fm <= rd_data_bottom_ith_fm;
//        _rd_data_upper_offset <= rd_data_bottom_ith_offset;
//        _rd_data_lower_offset <= rd_data_bottom_ith_offset;
//        _rd_data_padding_offset <= rd_data_bottom_ith_offset;
//      end else begin
//      // increment
//        if(_rd_data_upper_next) begin
//          _rd_data_upper_offset <= _rd_data_upper_offset + DDR_BURST_LEN;
//        end
//        if(_rd_data_lower_next) begin
//          _rd_data_lower_offset <= _rd_data_lower_offset + DDR_BURST_LEN;
//        end
//        if(_rd_data_padding_next) begin
//          _rd_data_padding_offset <= _rd_data_padding_offset + DDR_BURST_LEN;
//        end
//      end
//    end
//  end
//  // patch counter, padding counter and valid counter
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _rd_data_upper_cnt <= 3'h0;
//      _rd_data_lower_cnt <= 3'h0;
//      _rd_data_valid_cnt <= 5'h0;
//      _rd_data_padding_cnt <= 3'h0;
//    end else begin
//      if(rd_data_bottom && (_rd_data_state==RD_DATA_RST)) begin //set to 0, eliminate the influence of rd_exp and rd_data_param
//      // reset
//        _rd_data_upper_cnt <= 3'h0;
//        _rd_data_lower_cnt <= 3'h0;
//        _rd_data_valid_cnt <= 5'h0;
//        _rd_data_padding_cnt <= 3'h0;
//      end else begin
//      // increment
//        if(_rd_data_upper_next) begin
//          _rd_data_upper_cnt <= _rd_data_upper_cnt + 1'b1;
//        end
//        if(_rd_data_lower_next) begin
//          _rd_data_lower_cnt <= _rd_data_lower_cnt + 1'b1;
//        end
//        if(_rd_data_padding_next) begin
//          _rd_data_padding_cnt <= _rd_data_padding_cnt + 1'b1;
//        end
//        if(ddr_rd_data_valid && (_rd_data_state!=RD_DATA_RST)) begin
//          _rd_data_valid_cnt <= _rd_data_valid_cnt + 1'b1;
//        end
//        // reset
//        if(_rd_data_full) begin
//          _rd_data_upper_cnt <= 3'h0;
//          _rd_data_lower_cnt <= 3'h0;
//          _rd_data_valid_cnt <= 5'h0;
//          _rd_data_padding_cnt <= 3'h0;
//        end
//      end
//    end
//  end
//  // 'last' signal
//  always@(rst_n or _rd_data_upper_cnt or _rd_data_lower_cnt or ddr_rd_data_valid or
//          _rd_data_padding_cnt or _rd_data_valid_cnt or rd_data_x or ddr_rdy or
//          rd_data_y or rd_data_end_of_x or rd_data_end_of_y or _rd_data_state) begin
//      if(rd_data_x == 5'h0) begin
//        // (0,y)
//        if(rd_data_x == rd_data_end_of_x) begin //modify to write 14x14 fm
//          _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_XY_CNT));
//          _rd_data_upper_stop = 1'b0;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
//          _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST); //no padding
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - RD_PADDING_XY_CNT)));
//          _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_XY_CNT));
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - RD_PADDING_XY_CNT))); //no padding
//        end else begin // >14x14
//          if(rd_data_y == 5'h0) begin
//            _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_0Y_CNT));
//            _rd_data_upper_stop = 1'b0;
//            _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_0Y_CNT));
//            _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_0Y_CNT));
//            _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - RD_PADDING_0Y_CNT)));
//            _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_0Y_CNT));
//            _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_0Y_CNT));
//          end else if(rd_data_y == rd_data_end_of_y) begin
//            _rd_data_upper_last = 1'b1;
//            _rd_data_upper_stop = 1'b1;
//            _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_0Y_CNT));
//            _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST);
//            _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1) -RD_PADDING_0Y_CNT)));
//            _rd_data_upper_valid_last = 1'b0;
//            _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1) - RD_PADDING_0Y_CNT)));
//          end else begin
//            _rd_data_upper_last = 1'b1;
//            _rd_data_upper_stop = 1'b1;
//            _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_0Y_CNT));
//            _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_0Y_CNT));
//            _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1) - RD_PADDING_0Y_CNT)));
//            _rd_data_upper_valid_last = 1'b0;
//            _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_0Y_CNT - (RD_HALF_0Y_CNT+1)));
//          end
//        end
//      end else if(rd_data_x == rd_data_end_of_x) begin
//        // (e,y)
//        if(rd_data_y == rd_data_end_of_y) begin
//          _rd_data_upper_last = 1'b1;
//          _rd_data_upper_stop = 1'b1;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_EY_CNT));
//          _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST);
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1) - RD_PADDING_EY_CNT)));
//          _rd_data_upper_valid_last = 1'b0;
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1) -RD_PADDING_EY_CNT)));
//        end else if(rd_data_y == 5'h0) begin
//          _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_EY_CNT));
//          _rd_data_upper_stop = 1'b0;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_EY_CNT));
//          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_EY_CNT));
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - RD_PADDING_EY_CNT)));
//          _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_EY_CNT));
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_EY_CNT));
//        end else begin
//          _rd_data_upper_last = 1'b1;
//          _rd_data_upper_stop = 1'b1;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_EY_CNT));
//          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_EY_CNT));
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1) - RD_PADDING_EY_CNT)));
//          _rd_data_upper_valid_last = 1'b0;
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_EY_CNT - (RD_HALF_EY_CNT+1)));
//        end
//      end else begin
//        // (x,y)
//        if(rd_data_y == rd_data_end_of_y) begin
//          _rd_data_upper_last = 1'b1;
//          _rd_data_upper_stop = 1'b1;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
//          _rd_data_padding_stop = (_rd_data_state!=RD_DATA_RST);
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1) - RD_PADDING_XY_CNT)));
//          _rd_data_upper_valid_last = 1'b0;
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1) - RD_PADDING_XY_CNT)));
//        end else if(rd_data_y == 5'h0) begin
//          _rd_data_upper_last = (ddr_rdy && (_rd_data_upper_cnt == RD_HALF_XY_CNT));
//          _rd_data_upper_stop = 1'b0;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
//          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_XY_CNT));
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - RD_PADDING_XY_CNT)));
//          _rd_data_upper_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_HALF_XY_CNT));
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_XY_CNT));
//        end else begin
//          _rd_data_upper_last = 1'b1;
//          _rd_data_upper_stop = 1'b1;
//          _rd_data_lower_last = (ddr_rdy && (_rd_data_lower_cnt == RD_HALF_XY_CNT));
//          _rd_data_padding_stop = ((_rd_data_state!=RD_DATA_RST) && (_rd_data_padding_cnt == RD_PADDING_XY_CNT));
//          _rd_data_patch_valid_last = (ddr_rd_data_valid && (_rd_data_valid_cnt == (RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1) - RD_PADDING_XY_CNT)));
//          _rd_data_upper_valid_last = 1'b0;
//          _rd_data_full  = (ddr_rd_data_valid && (_rd_data_valid_cnt == RD_TOTAL_XY_CNT - (RD_HALF_XY_CNT+1)));
//        end
//      end
////    end
//  end
  
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _rd_data_grp <= 5'd0;
//    end else begin
//      if(rd_data_bottom && ddr_rd_data_valid) begin
//        if(/*_rd_data_valid_first || */_rd_data_full) begin
//          _rd_data_grp <= 5'd0;
//        end else begin
//          if(_rd_data_upper_stop) begin
//            if(_rd_data_patch_valid_last) begin
//              _rd_data_grp <= 5'd6;
//            end else begin
//              _rd_data_grp <= _rd_data_grp + 1'd1;
//            end
//          end else begin
//            if(_rd_data_upper_valid_last) begin
//              _rd_data_grp <= 5'd6;
//            end else if(_rd_data_patch_valid_last) begin
//              _rd_data_grp <= 5'd12;
//            end else begin
//              _rd_data_grp <= _rd_data_grp + 1'b1;
//            end
//          end
//        end
//      end
//    end
//  end    
    
//endmodule
