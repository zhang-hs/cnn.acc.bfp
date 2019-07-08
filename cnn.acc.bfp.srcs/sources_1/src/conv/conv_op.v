`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/22 18:58:25
// Module Name: conv_op
// Module Name: rd_ddr_param
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: convolution operation top module.
//              kernal size:3x3, convolution window size:16x16.
//              3*3 ppmac is used.
//              Fixed point multiplier is used.
//              To meet Bram storage mode:
//              data control strategy is Modified.
//              PEs in ppmac are changed from row to column.
//              The convolution order changed from "N" type to "Z" type. i.e. from "conv_y=end --> conv_x+1" to "conv_x=end --> conv_y+1".
//
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////
//`define sim_

module conv_op#(
  parameter K_C         = 64, //ppmac kernel channels
  parameter K_H         = 3, //ppmac kernel height
  parameter K_W         = 3, //ppmac kernel width
  parameter DATA_WIDTH  = 8,
  parameter MID_WIDTH   = 29 //9*512*16'b = (16+log2(9*512))'b = 29'b.
)(
  input  wire                                   conv_rst_n,
  input  wire                                   conv_clk,
  input  wire                                   conv_start,  // at current clock, last data is writen, convolution starts at next clock
//  input  wire [2:0]                             conv_ker_size,    //cnn kernal size:1 or 3 or 5.
  input  wire [DATA_WIDTH*K_C*K_H*K_W-1:0]      conv_ker,    // shape: k_c k_h k_w
  input  wire [DATA_WIDTH*16-1:0]               conv_bottom, // shape: data_h data_w
  input  wire                                   conv_bottom_valid,
  input  wire                                   conv_partial_sum_valid, // partial sum data valid
  input  wire [K_C*MID_WIDTH-1:0]               conv_partial_sum, // partial sum from output buffer (512x14x14)
  output wire                                   conv_rd_data_partial_sum, // need to read partial sum data
  output wire [MID_WIDTH*K_C-1:0]               conv_top,    // shape: k_c, no output buffer reg
  output reg                                    conv_first_pos, // <-x added on Oct.31 conv started
  output reg                                    conv_last_pos, // <-x added on Oct.31 conv at the last position
  output wire                                   conv_output_valid,
  output wire                                   conv_output_last, // last output, convolution done
  output reg  [3:0]                             conv_x,      // ceil(log(14))
  output reg  [3:0]                             conv_y,      // ceil(log(14))
  output reg  [3:0]                             conv_to_x,   // ceil(log(14))
  output reg  [3:0]                             conv_to_y,   // ceil(log(14))
  output wire [4:0]                             conv_rd_col,
  output wire                                   conv_patch_bram_rd_en,
  output reg                                    conv_busy
);

  localparam CONV_RST      = 2'b00;
  localparam CONV_CONV     = 2'b01;
  localparam CONV_TAIL     = 2'b10;
  //ker_size
  localparam CONV_KER_SIZE  = 3'd3;
  
  // wire to reg array
  reg                              _conv_op_start; //convolution FSM start, valid at the previous clk of conv_bottom_valid is true, so it takes 2 clk after conv_start is valid
  reg  [DATA_WIDTH-1:0]            _bottom_col_0[0:16-1];
  reg  [DATA_WIDTH-1:0]            _bottom_col_1[0:16-1];
  wire [DATA_WIDTH-1:0]            _bottom[0:16-1];
  wire [DATA_WIDTH-1:0]            _ker[0:K_C*K_H*K_W-1];
  reg  [1:0]                       _conv_state;
  reg  [1:0]                       _next_state;
  reg  [DATA_WIDTH*K_W-1:0]        _data0;
  reg  [DATA_WIDTH*K_W-1:0]        _data1;
  reg                              _pa1_sel0;
  reg                              _pa2_sel0;
  reg                              _pa0_data_valid;
  reg                              _pa1_data_valid;
  reg                              _pa2_data_valid;
  wire [DATA_WIDTH*K_W-1:0]        _pa0_data;
  wire [DATA_WIDTH*K_W-1:0]        _pa1_data;
  wire [DATA_WIDTH*K_W-1:0]        _pa2_data;
  reg                              _next_pos; // move to next position
  wire                             _end_pos; // end of a 16x16 patch convolution position
  wire                             _tail_last; // end of 16x16 patch data feeding
  reg [4:0]                        _col; // log(DATA_W)
  reg [4:0]                        _row; // log(DATA_H)
  wire [4:0]                       _cw_size;
  
  assign _cw_size = {2'b0, CONV_KER_SIZE} + 5'd13;
  
  //wait for conv_bottom readed from bram
  reg     _conv_start_reg;
  always@(posedge conv_clk) begin
    _conv_start_reg <= conv_start;
    _conv_op_start <= _conv_start_reg;
  end

  // convolution FSM
  // FF
  always@(posedge conv_clk) begin
    if(!conv_rst_n)
      _conv_state <= CONV_RST;
    else
      _conv_state <= _next_state;
  end

  // state transition
  always@(_conv_state or _end_pos or _conv_op_start or _tail_last // or conv_next_ker_valid_at_next_clk
          )begin
    // default next state
    _next_state = CONV_RST;
    case(_conv_state)
      CONV_RST: begin
        if(_conv_op_start) begin  //start conv process
          _next_state = CONV_CONV;
        end else begin
          _next_state = CONV_RST;
        end
      end

      CONV_CONV: begin
        // convolve to the last position
        if(_end_pos) begin
            _next_state = CONV_TAIL;
        //end
        end else begin
          _next_state = CONV_CONV;
        end
      end

      CONV_TAIL: begin
        if(_tail_last) begin
          _next_state = CONV_RST;
        end else begin
          _next_state = CONV_TAIL;
        end
      end
    endcase
  end

  // logic
  always@(_conv_state or _conv_op_start or /*conv_rd_data_partial_sum or*/
          _tail_last or _row or _col) begin
  //_pa0_sel0  = 1'b1;
    _pa1_sel0  = 1'b1;
    _pa2_sel0  = 1'b1;
    _next_pos  = 1'b0;
    _pa0_data_valid = 1'b0;
    _pa1_data_valid = 1'b0;
    _pa2_data_valid = 1'b0;
    conv_busy = 1'b0;
    conv_first_pos = 1'b0;
    conv_last_pos = 1'b0;

    case(_conv_state)
      CONV_RST: begin
        conv_busy = 1'b0;
        if(_conv_op_start) begin
          conv_first_pos = 1'b1;
        end
      end

      CONV_CONV: begin
        conv_busy  = 1'b1;
        _next_pos= 1'b1;
        if(_col == 4'b0) begin
          _pa1_sel0 = 1'b0; // select _data1
          _pa2_sel0 = 1'b0; // select _data1
        end else if(_col == 4'b1) begin
          _pa2_sel0 = 1'b0; // select _data1
        end
        if(_row == 4'd0) begin
          if(_col == 4'd0) begin
            _pa0_data_valid = 1'b1;
            _pa1_data_valid = 1'b0;
            _pa2_data_valid = 1'b0;
          end else if(_col == 4'd1) begin
            _pa0_data_valid = 1'b1;
            _pa1_data_valid = 1'b1;
            _pa2_data_valid = 1'b0;
          end else begin
            _pa0_data_valid = 1'b1;
            _pa1_data_valid = 1'b1;
            _pa2_data_valid = 1'b1;
          end
        end else begin
          _pa0_data_valid = 1'b1;
          _pa1_data_valid = 1'b1;
          _pa2_data_valid = 1'b1;
        end
      end
      CONV_TAIL: begin //last two 3*1
        conv_busy  = 1'b1;
        _next_pos= 1'b1;
        if(_col == 4'b0) begin
          _pa1_sel0 = 1'b0; // select _data1
          _pa2_sel0 = 1'b0; // select _data1
          _pa0_data_valid = 1'b0;
          _pa1_data_valid = 1'b1;
          _pa2_data_valid = 1'b1;
        end else if(_col == 4'b1) begin
          _pa2_sel0 = 1'b0; // select _data1
          _pa0_data_valid = 1'b0;
          _pa1_data_valid = 1'b0;
          _pa2_data_valid = 1'b1;
        end
        if(_tail_last) begin
          conv_last_pos = 1'b1;
        end
      end
    endcase
  end
 
  //read patch from bram: addr_offset 
  reg  [4:0]    _rd_col;
  reg  [4:0]    _rd_row;
  assign conv_rd_col = _rd_col;
  assign conv_patch_bram_rd_en = conv_start || (_next_state != 2'b0); //conv_start turns to 0 when conv_busy is true
  always@(posedge conv_clk or negedge conv_rst_n) begin
    if(!conv_rst_n) begin
      _rd_col <= 5'b0;
      _rd_row <= 5'b0;
    end else begin
      if(conv_patch_bram_rd_en) begin
        // column
        if(_rd_col != _cw_size-1'b1) begin // DATA_H-1 - K_H + 1
          _rd_col <= _rd_col+1'b1;
        end else begin
          //row
          _rd_col <= CONV_KER_SIZE - 1'b1;
          if(_rd_row != 5'd13) begin
            _rd_row <= _rd_row + 1'b1;
          end else begin
            _rd_row <= 5'd0;
          end
        end
      end else if(conv_last_pos) begin //conv_at_last_pos
        _rd_col <= 5'd0;
        _rd_row <= 5'd0;
      end
    end
  end
  
  // convolute position
  assign _end_pos = (_col == 4'd13) && (_row == 4'd13);
  assign _tail_last = (_col == 4'd1) && (_row==4'd0); //recount after _end_pos is valid. 
  always@(posedge conv_clk) begin
    if(!conv_rst_n) begin
      _col <= 4'b0;
      _row <= 4'b0;
    end else begin
      if(_next_pos) begin
        if(_col == 4'd13) begin
          _col <= 4'b0;
          if(_row == 4'd13) begin
            _row <= 4'b0;
          end else begin
            _row <= _row + 1'b1;
          end
        end else begin
          _col <= _col + 1'b1;
        end
      end else if(conv_start) begin //better be conv_start
        _col <= 4'b0;
        _row <= 4'b0;
      end
    end
  end

  // read bias position
  always@(posedge conv_clk) begin
    if(!conv_rst_n) begin
      conv_to_x <= 4'b0;
      conv_to_y <= 4'b0;
    end else begin
      if(conv_rd_data_partial_sum) begin
        if(conv_to_x == 4'd13) begin
          conv_to_x <= 4'd0;
          if(conv_to_y == 4'd13) begin
            conv_to_y <= 4'b0;
          end else begin
            conv_to_y <= conv_to_y + 1'b1;
          end
        end else begin
          conv_to_x <= conv_to_x + 1'b1;
        end
      end else if(conv_start) begin //better be conv_start
        conv_to_x <= 4'b0;
        conv_to_y <= 4'b0;
      end
    end
  end

  // --------------------------- output ----------------------------------------
  wire     _next_output;
  wire     _last_output_pos;

  assign  _next_output = conv_output_valid;
  assign  conv_output_last = (conv_x == 4'd13) && (conv_y == 4'd13);

  // output position
  always@(posedge conv_clk) begin
    if(!conv_rst_n) begin
      conv_x <= 4'b0;
      conv_y <= 4'b0;
    end else begin
      // output valid or convolution tail
      if(_next_output) begin
        if(conv_x ==4'd13) begin
          conv_x <= 4'b0;
          if(conv_y == 4'd13) begin
            conv_y <= 4'b0;
          end else begin
            conv_y <= conv_y + 1'b1;
          end
        end else begin
          conv_x <= conv_x + 1'b1;
        end
      end else begin
        conv_x <= 4'd0;
        conv_y <= 4'd0;
      end
    end
  end

  // data multiplexer
  reg  [DATA_WIDTH*16-1:0]    _conv_bottom_0_0; //conv_bottom of row_0 and col_0
  reg  [DATA_WIDTH*16-1:0]    _conv_bottom_0_1; //conv_bottom of row_0 and col_1
  always@(posedge conv_clk) begin
    if(_row == 4'd0) begin
      if(_col == 4'd0) begin
        _conv_bottom_0_0 <= conv_bottom;
      end else if(_col == 4'd1) begin
        _conv_bottom_0_1 <= conv_bottom;
      end
    end
  end
  
  always@(_row or _col or conv_bottom or _conv_bottom_0_0) begin
    if((_row == 4'd0) && (_col == 4'd0)) begin
      {_bottom_col_0[15],_bottom_col_0[14],_bottom_col_0[13],_bottom_col_0[12],_bottom_col_0[11],_bottom_col_0[10],
       _bottom_col_0[9], _bottom_col_0[8], _bottom_col_0[7], _bottom_col_0[6], _bottom_col_0[5], _bottom_col_0[4],
       _bottom_col_0[3], _bottom_col_0[2], _bottom_col_0[1], _bottom_col_0[0]} = conv_bottom;
      end else begin
       {_bottom_col_0[15],_bottom_col_0[14],_bottom_col_0[13],_bottom_col_0[12],_bottom_col_0[11],_bottom_col_0[10],
        _bottom_col_0[9], _bottom_col_0[8], _bottom_col_0[7], _bottom_col_0[6], _bottom_col_0[5], _bottom_col_0[4],
        _bottom_col_0[3], _bottom_col_0[2], _bottom_col_0[1], _bottom_col_0[0]} = _conv_bottom_0_0;
    end
  end
  always@(_row or _col or conv_bottom or _conv_bottom_0_1) begin
    if((_row == 4'd0) && (_col == 4'd1)) begin
      {_bottom_col_1[15],_bottom_col_1[14],_bottom_col_1[13],_bottom_col_1[12],_bottom_col_1[11],_bottom_col_1[10],
       _bottom_col_1[9], _bottom_col_1[8], _bottom_col_1[7], _bottom_col_1[6], _bottom_col_1[5], _bottom_col_1[4],
       _bottom_col_1[3], _bottom_col_1[2], _bottom_col_1[1], _bottom_col_1[0]} = conv_bottom;
      end else begin
       {_bottom_col_1[15],_bottom_col_1[14],_bottom_col_1[13],_bottom_col_1[12],_bottom_col_1[11],_bottom_col_1[10],
        _bottom_col_1[9], _bottom_col_1[8], _bottom_col_1[7], _bottom_col_1[6], _bottom_col_1[5], _bottom_col_1[4],
        _bottom_col_1[3], _bottom_col_1[2], _bottom_col_1[1], _bottom_col_1[0]} = _conv_bottom_0_1;
    end
  end 
  assign {_bottom[15],_bottom[14],_bottom[13],_bottom[12],_bottom[11],_bottom[10],
          _bottom[9], _bottom[8], _bottom[7], _bottom[6], _bottom[5], _bottom[4],
          _bottom[3], _bottom[2], _bottom[1], _bottom[0]} = conv_bottom;
  
  always@(_row or _col or _bottom or _bottom_col_0 or _bottom_col_1 /*or conv_ker_size*/) begin
    if(_col == 4'd0) begin
      _data0 = {_bottom_col_0[_row], _bottom_col_0[_row+1], _bottom_col_0[_row+2]};
    end else if(_col == 4'd1) begin
      _data0 = {_bottom_col_1[_row], _bottom_col_1[_row+1], _bottom_col_1[_row+2]};
    end else begin
      _data0 = {_bottom[_row], _bottom[_row+1], _bottom[_row+2]};
    end
  end
  always@(_row or _col or _bottom /*or conv_ker_size*/) begin
    if(_row == 4'd0) begin
      _data1 = {_bottom[13], _bottom[14], _bottom[15]};
    end else begin
      _data1 = {_bottom[_row-1], _bottom[_row], _bottom[_row+1]};
    end
  end

  // pa1,pa2 data mux
  assign _pa0_data = _data0;
  assign _pa1_data = (_pa1_sel0 == 1'b1) ? _data0 : _data1;
  assign _pa2_data = (_pa2_sel0 == 1'b1) ? _data0 : _data1;

  // arrange kernals, convert from/to 1-dim array
  genvar c, w, h;
  generate
    for(c=0; c<K_C; c=c+1) begin
      for(h=0; h<K_H; h=h+1) begin
        for(w=0; w<K_W; w=w+1)begin
          assign _ker[w+h*K_W+c*K_H*K_W] = conv_ker[DATA_WIDTH*(1+w+h*K_W+c*K_H*K_W)-1 : DATA_WIDTH*(w+h*K_W+c*K_H*K_W)];
        end
      end
    end
  endgenerate

  reg [DATA_WIDTH*K_W-1:0]  _pa0_data_0;
  reg [DATA_WIDTH*K_W-1:0]  _pa1_data_0;
  reg [DATA_WIDTH*K_W-1:0]  _pa2_data_0;
  /*(*mark_debug="TRUE"*)*/reg                       _pa0_data_valid_0;
  /*(*mark_debug="TRUE"*)*/reg                       _pa1_data_valid_0;
  /*(*mark_debug="TRUE"*)*/reg                       _pa2_data_valid_0;
  reg                       _conv_partial_sum_valid;
  reg [K_C*MID_WIDTH-1:0]   _conv_partial_sum;
  
//  (*mark_debug="TRUE"*) wire [DATA_WIDTH-1:0] _data0_h;
//  (*mark_debug="TRUE"*) wire [DATA_WIDTH-1:0] _data1_h;  
//  assign _data0_h = _data0[DATA_WIDTH*K_W-1:DATA_WIDTH*2];
//  assign _data1_h = _data1[DATA_WIDTH*K_W-1:DATA_WIDTH*2];
  
//  (*mark_debug="TRUE"*) wire [DATA_WIDTH-1:0] _pa0_data_0_h;
//  (*mark_debug="TRUE"*) wire [DATA_WIDTH-1:0] _pa1_data_0_h;
//  (*mark_debug="TRUE"*) wire [DATA_WIDTH-1:0] _pa2_data_0_h;
//  assign _pa0_data_0_h = _pa0_data_0[DATA_WIDTH-1:0];
//  assign _pa1_data_0_h = _pa1_data_0[DATA_WIDTH-1:0];
//  assign _pa2_data_0_h = _pa2_data_0[DATA_WIDTH-1:0];

  always@(posedge conv_clk) begin
    _pa0_data_0               <= _pa0_data;
    _pa1_data_0               <= _pa1_data;
    _pa2_data_0               <= _pa2_data;
    _pa0_data_valid_0         <= _pa0_data_valid;
    _pa1_data_valid_0         <= _pa1_data_valid;
    _pa2_data_valid_0         <= _pa2_data_valid;
    _conv_partial_sum         <= conv_partial_sum;
    _conv_partial_sum_valid   <= conv_partial_sum_valid;
  end
  
  
  // generate PE3x3
  pe_array3x3#(
    .DATA_WIDTH(DATA_WIDTH),
    .MID_WIDTH(MID_WIDTH)
    )pe_array0(
       .clk(conv_clk),
       .pe3_array0_ker3({_ker[0*K_H*K_W  ],_ker[0*K_H*K_W+3],_ker[0*K_H*K_W+6]}), //3 column of PEs
       .pe3_array1_ker3({_ker[0*K_H*K_W+1],_ker[0*K_H*K_W+4],_ker[0*K_H*K_W+7]}),
       .pe3_array2_ker3({_ker[0*K_H*K_W+2],_ker[0*K_H*K_W+5],_ker[0*K_H*K_W+8]}),
       .pe3_array0_data3(_pa0_data_0),  //3 column of bottom
       .pe3_array1_data3(_pa1_data_0),
       .pe3_array2_data3(_pa2_data_0),
       .pe3_array0_valid(_pa0_data_valid_0), //3 valid flags corresponding to 3 column of bottom, respectively
       .pe3_array1_valid(_pa1_data_valid_0),
       .pe3_array2_valid(_pa2_data_valid_0),
       .pe3_partial_value(_conv_partial_sum[MID_WIDTH-1:0]),
       .pe3_next_partial_sum(conv_rd_data_partial_sum), // next partial sum data
       .pe3_o(conv_top[MID_WIDTH-1:0]),
       .pe3_valid(conv_output_valid)
    );
  
  generate
    for(c=1; c<K_C; c=c+1) 
    begin:pe_array
      pe_array3x3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .MID_WIDTH(MID_WIDTH)
      )pe_arry(
        .clk(conv_clk),
        .pe3_array0_ker3({_ker[c*K_H*K_W  ],_ker[c*K_H*K_W+3],_ker[c*K_H*K_W+6]}),
        .pe3_array1_ker3({_ker[c*K_H*K_W+1],_ker[c*K_H*K_W+4],_ker[c*K_H*K_W+7]}),
        .pe3_array2_ker3({_ker[c*K_H*K_W+2],_ker[c*K_H*K_W+5],_ker[c*K_H*K_W+8]}),
        .pe3_array0_data3(_pa0_data_0),
        .pe3_array1_data3(_pa1_data_0),
        .pe3_array2_data3(_pa2_data_0),
        .pe3_array0_valid(_pa0_data_valid_0),
        .pe3_array1_valid(_pa1_data_valid_0),
        .pe3_array2_valid(_pa2_data_valid_0),
        .pe3_partial_value(_conv_partial_sum[(c+1)*MID_WIDTH-1:c*MID_WIDTH]),
        .pe3_next_partial_sum(), // next partial sum data
        .pe3_o(conv_top[MID_WIDTH*(c+1)-1:MID_WIDTH*c]),
        .pe3_valid()
      );
    end
  endgenerate

endmodule
