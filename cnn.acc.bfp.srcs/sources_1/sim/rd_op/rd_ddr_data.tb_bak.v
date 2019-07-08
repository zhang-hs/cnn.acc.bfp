`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/08/29 20:48:48 
// Module Name: rd_ddr_data.tb
//
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define NULL 0
 
//  extern pointer  getFileDescriptor(input string fileName);
//  extern void     closeFile(input pointer fileDescriptor);
//  extern int      readFloatNum(input pointer fileDescriptor, output bit[31:0]);
//  extern void     readProcRam(input pointer fileDescriptor, input bit readBottomData,
//                              input bit[8:0] xPos, input bit[8:0] yPos, input bit[8:0] xEndPos,
//                              input bit[8:0] yEndPos, input bit[29:0] barOffset,
//                              input bit[29:0] ithOffset, output bit[15*21*32-1:0] procRam);
//                                                      // procRamHeight*procRamWidth*floatNum -1 : 0
  
//  extern bit      cmpFloatNum(input bit dataValid, input bit[4:0] numOfValidData,
//                              input bit[511:0] data, input bit[15*21*32-1:0] Ram,
//                              input bit[8:0] cnt,  input bit[8:0] xPos,
//                              input bit[8:0] yPos, input bit[9:0] ithFM); // compare float num data
  
//  //extern void     readControl(input bit dataFullOrLoadingDone, output bit readBottomData,
//  //                            inout bit[29:0] bottomDataAddr, inout bit[8:0] xEndPos,
//  //                            inout bit[8:0] yEndPos, inout bit[8:0] xPos, inout bit[8:0] yPos,
//  //                            output bit isFirstFM, inout bit[29:0] ithOffset, inout bit[9:0] ithFM,
//  //                            output bit readEnd); // control reading process
//  extern void     readControl(input bit loadingDone, input bit dataFull, output bit readBottomData,
//                              inout bit[29:0] bottomDataAddr, input bit[8:0] xEndPos,
//                              input bit[8:0] yEndPos, inout bit[8:0] xPos, inout bit[8:0] yPos,
//                              output bit isFirstFM, inout bit[29:0] ithOffset, inout bit[29:0] barOffset,
//                              inout bit[9:0] ithFM, output bit readEnd); // control reading process

module top_rd_ddr_data(
  input  wire           clk,
  input  wire           rst_n,
  // ddr request
  output wire           rd_data_req,
  input  wire           rd_data_grant,
  // ddr interface
  input  wire           ddr_rd_data_valid,
  input  wire           ddr_rdy,
  input  wire           ddr_wdf_rdy,
  input  wire [511:0]   ddr_rd_data,
  input  wire           ddr_rd_data_end,
  input  wire           tb_load_done, // image data and kernel parameters are loaded
  
  output wire [29:0]    rd_data_addr,
  output wire [2:0]     rd_data_cmd,
  output wire           rd_data_en
);

  localparam DDR_BANK_IMAGE     = 4'b0000;
  localparam DDR_BANK_BOTTOM    = 4'b0001;
  localparam DDR_BANK_PARAM     = 4'b0010;
  localparam DDR_BANK_TOP       = 4'b0011;
  localparam DDR_BANK_EXP       = 4'b0101;
  localparam DDR_ROW            = 16'h0;
  localparam DDR_COL            = 10'h0;
  localparam BOTTOM_START_ADDR  = {DDR_BANK_BOTTOM, DDR_ROW, DDR_COL};
  localparam TOP_START_ADDR     = {DDR_BANK_TOP, DDR_ROW, DDR_COL};
  localparam KER_START_ADDR     = {DDR_BANK_PARAM, DDR_ROW, DDR_COL};
  localparam IMG_DATA_ADDR      = {DDR_BANK_IMAGE, DDR_ROW, DDR_COL};

  localparam CHANNELS         = 10'd3;
  localparam FM_SIZE          = 30'd16384;
  localparam BAR_SIZE         = 30'd1024;
  localparam HALF_BAR_SIZE    = 30'd512;
  localparam END_OF_X         = 4'd15;
  localparam END_OF_Y         = 4'd15;
  localparam EXP_FM           = 5'h16;
  
  //read control
  reg               _rd_data_bottom;
  reg               _rd_data_first_fm;
  reg  [29:0]       _rd_data_bottom_addr;
  reg  [4:0]        _rd_data_x;
  reg  [4:0]        _rd_data_y;
  wire              _rd_data_x_eq_zero;
  wire              _rd_data_x_eq_end;
  wire              _rd_data_y_eq_zero;
  wire              _rd_data_y_eq_end;
  wire              _rd_data_y_is_odd;
  reg  [29:0]       _rd_data_bottom_ith_offset;
  reg  [29:0]       _rd_data_bar_offset;
  reg  [29:0]       _rd_data_half_bar_offset;
  wire [255:0]      _rd_data_data;
  wire [5:0]        _rd_data_num_valid; // num of valid float data(32 bits) in rd_data_data
  wire              _rd_data_valid;
  wire              _rd_data_patch_valid_last;
  wire              _rd_data_upper_valid_last;
  wire              _rd_data_valid_first;
  wire              _rd_data_full;
  reg  [9:0]        _ithFM;
  reg               _readEnd;
  wire              _loadingDone;
  wire              _rd_data_load_ddr_done_rising_edge;
  reg               _rd_data_load_ddr_done_reg;
  reg               start_next;
  //mem_top
  wire              _rd_data_cache_release_done;
  wire              _rd_data_cache_idx;
  reg [29:0]        _rd_data_addr;
  reg [29:0]        _rd_data_addr_reg;
  
  initial start_next = 1'b0;
  assign _loadingDone                         = _rd_data_load_ddr_done_rising_edge;
  assign _rd_data_load_ddr_done_rising_edge   = ((!_rd_data_load_ddr_done_reg) && tb_load_done);
  assign rd_data_req                          = _rd_data_bottom;// && _rd_patch_cache_valid;
  assign _rd_data_x_eq_zero                   = _rd_data_x == 4'h0;
  assign _rd_data_y_eq_zero                   = _rd_data_y == 4'h0;
  assign _rd_data_x_eq_end                    = _rd_data_x == END_OF_X;
  assign _rd_data_y_eq_end                    = _rd_data_y == END_OF_Y; 
  assign _rd_data_y_is_odd                    = _rd_data_y[0] == 1'b1;

  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_load_ddr_done_reg <= 1'b0;
    end else begin
      _rd_data_load_ddr_done_reg <= tb_load_done;
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_bottom            <= 1'b0;
      _rd_data_bottom_addr       <= 30'h0;
      _rd_data_x                 <= 4'h0;
      _rd_data_y                 <= 4'h0;
      _rd_data_first_fm          <= 1'b0;
      _rd_data_bottom_ith_offset <= 30'h0;
      _rd_data_bar_offset        <= BAR_SIZE;
      _rd_data_half_bar_offset   <= HALF_BAR_SIZE;
      _ithFM                     <= 10'h0;
      _readEnd                   <= 1'b0;
      //start_next                 <= 1'b0;
    end else begin
      if(tb_load_done) begin
        if(start_next || _loadingDone) begin 
          if(_loadingDone) begin
            _rd_data_x <= 4'h0;
            _rd_data_y <= 4'h0;
            _rd_data_first_fm <= 1'b1;
            _rd_data_bottom_ith_offset <= 30'h0;
            _ithFM <= 1'b0;
            _rd_data_bottom <= 1'b1;
          end else if(start_next) begin
            if(_ithFM == (CHANNELS - 1'b1)) begin
              if(_rd_data_x == END_OF_X) begin
                _rd_data_x <= 4'h0;
              end else begin
                _rd_data_x <= _rd_data_x + 1'b1;
              end
              if(_rd_data_x == END_OF_X) begin
                if(_rd_data_y == END_OF_Y) begin
                  _readEnd <= 1'b1;
                  _rd_data_y <= 4'h0;
                end else begin
                  _rd_data_y <= _rd_data_y + 1'b1;
                end
              end
              _ithFM <= 1'b0;
              _rd_data_bottom_ith_offset <= 30'h0;
              _rd_data_first_fm <= 1'b1;
            end else begin
              _ithFM <= _ithFM + 1'b1;
              _rd_data_bottom_ith_offset <= _rd_data_bottom_ith_offset + FM_SIZE;
              _rd_data_first_fm <= 1'b0;
            end
            _rd_data_bottom <= 1'b1;
          end
        end else begin
          //_rd_data_bottom <= 1'b0;
        end
      end
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_addr <= 29'd0;
    end else begin
      _rd_data_addr <= rd_data_addr;
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _rd_data_addr_reg <= 29'd0;
    end else begin
      _rd_data_addr_reg <= _rd_data_addr;
    end
  end
  
  //read next cw
  always@(_rd_data_full) begin
    if(_rd_data_full) begin
      _rd_data_bottom = 1'b0;
      #200 start_next = 1'b1;
      #20 start_next = 1'b0;
    end
  end
  
  always@(_rd_data_bottom_addr or/* _rd_data_bottom or*/ _rd_data_x or _rd_data_y or 
          _rd_data_first_fm or _rd_data_bottom_ith_offset or _ithFM or _readEnd) 
  begin
    $write("reading info: \n");
    $write("bottomDataAddr:%08x, ",_rd_data_bottom_addr);
    $write("readDataBottom:%08x, ",_rd_data_bottom);
    $write("xPos:%08x, ", _rd_data_x);
    $write("yPos:%08x\n", _rd_data_y);
    $write("isFirstFM:%08x, ", _rd_data_first_fm);
    $write("ithOffset:%08x, ", _rd_data_bottom_ith_offset);
    $write("ithFM:%08x, ", _ithFM);
    $write("readEnd:%08x\n", _readEnd);
  end      
  
  always@(_readEnd) begin
    if(_readEnd) begin
      $finish;
    end
  end
  
  rd_ddr_data rd_ddr_data_u(
    .clk(clk),
    .rst_n(rst_n),
   
    .ddr_rd_data_valid(ddr_rd_data_valid),
    .ddr_rdy(ddr_rdy),
    .input_exp(EXP_FM),
    .ddr_rd_data(ddr_rd_data),
    .ddr_addr(rd_data_addr),
    .ddr_cmd(rd_data_cmd),
    .ddr_en(rd_data_en),
  
    .rd_data_bottom(_rd_data_bottom),
    .rd_data_bottom_addr(_rd_data_bottom_addr),
    .rd_data_end_of_x(END_OF_X),
    .rd_data_end_of_y(END_OF_Y),
    .rd_data_x(_rd_data_x),
    .rd_data_y(_rd_data_y),
    .rd_data_first_fm(_rd_data_first_fm),
    .rd_data_bottom_ith_offset(_rd_data_bottom_ith_offset),
    .rd_data_bar_offset(_rd_data_bar_offset),
    .rd_data_half_bar_offset(_rd_data_half_bar_offset),
    .rd_data_cache_release_done(_rd_data_cache_release_done),
    
    .rd_data_data(_rd_data_data),
    .rd_data_cache_idx(_rd_data_cache_idx),
    .rd_data_grp(_rd_data_grp),
    .rd_data_valid(_rd_data_valid),
    .rd_data_patch_valid_last(_rd_data_patch_valid_last),
    .rd_data_upper_valid_last(_rd_data_upper_valid_last),
    .rd_data_valid_first(_rd_data_valid_first),
    .rd_data_full(_rd_data_full)
  );

///*
  mem_top #(
    .DATA_WIDTH(8),
    .IM_C(8)
 )mem_top_u(
    .clk(clk),
    .rst_n(rst_n),
    .mem_top_rd_ddr_data_valid(_rd_data_valid),
    .mem_top_rd_ddr_data_num_valid(_rd_data_num_valid),
    .mem_top_rd_ddr_data_x(_rd_data_x),
    .mem_top_rd_ddr_data_y(_rd_data_y),
    .mem_top_rd_ddr_data_addr(_rd_data_addr_reg),
    .mem_top_rd_ddr_data_ith_fm(_ithFM),
    .mem_top_rd_ddr_data_bottom_width(5'd16),
    .mem_top_rd_ddr_data_y_eq_end(_rd_data_y_eq_end),

    .mem_top_rd_ddr_data_valid_first(_rd_data_valid_first),
    .mem_top_rd_ddr_data_valid_last(_rd_data_full), 
    .mem_top_rd_ddr_data_patch_last(_rd_data_patch_valid_last), 
    .mem_top_rd_ddr_data_upper_last(_rd_data_upper_valid_last), 
    .mem_top_rd_ddr_data_i(_rd_data_data),
    .mem_top_rd_ddr_data_cache_idx(_rd_data_cache_idx),
    .mem_top_rd_ddr_data_cache_done(_rd_data_cache_release_done)
  );
// */
endmodule
