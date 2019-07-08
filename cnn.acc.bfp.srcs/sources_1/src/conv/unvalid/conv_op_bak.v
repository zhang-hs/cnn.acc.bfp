`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/22 18:58:25
// Module Name: conv_op
// Description: convolution operation top module.
//              3*3 ppmac is used.
//              Fixed point multiplier is used.
//
// Revision 0.01 - File Created
//////////////////////////////////////////////////////////////////////////////////

module conv_op#(
  parameter K_C         = 1, //kernel channels
  parameter K_H         = 3, //kernel height
  parameter K_W         = 3, //kernel width
  parameter CW_H        = 16, //convolution window data height
  parameter CW_W        = 16, //convolution window data width
  parameter DATA_WIDTH  = 8,
  parameter EXP_WIDTH   = 5,
  parameter MID_WIDTH   = 29 //9*512*16'b = (16+log2(9*512))'b = 29'b.
)(
  input  wire                                   conv_rst_n,
  input  wire                                   conv_clk,
  input  wire                                   conv_start,  // at current clock, last data is writen, convolution starts at next clock
  input  wire [DATA_WIDTH*K_C*K_H*K_W-1:0]      conv_ker,    // shape: k_c k_h k_w
  input  wire [DATA_WIDTH*CW_H*CW_W-1:0]        conv_bottom, // shape: data_h data_w
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
  output reg                                    conv_busy
);

  localparam CONV_RST      = 2'b00;
  localparam CONV_CONV     = 2'b01;
  localparam CONV_TAIL     = 2'b10;
  
  // wire to reg array
  wire [DATA_WIDTH-1:0]            _bottom00[0:CW_H-1]; // column-wise
  wire [DATA_WIDTH-1:0]            _bottom01[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom02[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom03[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom04[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom05[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom06[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom07[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom08[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom09[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom10[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom11[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom12[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom13[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom14[0:CW_H-1];
  wire [DATA_WIDTH-1:0]            _bottom15[0:CW_H-1];

  wire [DATA_WIDTH-1:0]            _ker[0:K_C*K_H*K_W-1];
  wire [DATA_WIDTH-1:0]            _top[0:K_C*CW_H*CW_W-1];
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

  // convolution FSM
  // FF
  always@(posedge conv_clk) begin
    if(!conv_rst_n)
      _conv_state <= CONV_RST;
    else
      _conv_state <= _next_state;
  end

  // state transition
  always@(_conv_state or _end_pos or conv_start or _tail_last // or conv_next_ker_valid_at_next_clk
          )begin
    // default next state
    _next_state = CONV_RST;
    case(_conv_state)
      CONV_RST: begin
        if(conv_start) begin
          _next_state = CONV_CONV;
        end else begin
          _next_state = CONV_RST;
        end
      end

      CONV_CONV: begin
        // convolve to the last position
        if(_end_pos) begin
        //if(conv_next_ker_valid_at_next_clk) begin
        //  _next_state = CONV_CONV;
        //end else begin
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
  always@(_conv_state or conv_start or conv_rd_data_partial_sum or
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
        if(conv_start) begin
          conv_first_pos = 1'b1;
        end
      end

      CONV_CONV: begin
        conv_busy  = 1'b1;
      //if(conv_rd_data_partial_sum) begin
          _next_pos= 1'b1;
      //end else begin
      //  _next_pos= 1'b0;
      //end
        // pa1,pa2 data mux
        if(_row == 4'b0) begin
          _pa1_sel0 = 1'b0; // select _data1
          _pa2_sel0 = 1'b0; // select _data1
        end else if(_row == 4'b1) begin
          _pa2_sel0 = 1'b0; // select _data1
        end
        if(_col == 4'd0) begin
          if(_row == 4'd0) begin
            _pa0_data_valid = 1'b1;
            _pa1_data_valid = 1'b0;
            _pa2_data_valid = 1'b0;
          end else if(_row == 4'd1) begin
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
      //if(conv_rd_data_partial_sum) begin
          _next_pos= 1'b1;
      //end else begin
      //  _next_pos= 1'b0;
      //end
        // pa1,pa2 data mux
        if(_row == 4'b0) begin
          _pa1_sel0 = 1'b0; // select _data1
          _pa2_sel0 = 1'b0; // select _data1
          _pa0_data_valid = 1'b0;
          _pa1_data_valid = 1'b1;
          _pa2_data_valid = 1'b1;
        end else if(_row == 4'b1) begin
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
  
  // pa1,pa2 data mux
  assign _pa0_data = _data0;
  assign _pa1_data = (_pa1_sel0 == 1'b1) ? _data0 : _data1;
  assign _pa2_data = (_pa2_sel0 == 1'b1) ? _data0 : _data1;
  
  // convolute position
  assign _end_pos = (_row == 4'd13) && (_col == 4'd13);
  assign _tail_last = (_row == 4'd1) && (_col==4'd0); //recount after _end_pos is valid.
  always@(posedge conv_clk) begin
    if(!conv_rst_n) begin
      _col <= 4'b0;
      _row <= 4'b0;
    end else begin
      if(_next_pos) begin
        // row
        if(_row!=4'd13) begin // DATA_H-1 - K_H + 1
          _row <= _row+1'b1;
        end else begin
          _row <= 4'b0;
        end
        // column
        if(_col!=4'd13) begin // DATA_W-1 - K_W + 1
          if(_row == 4'd13)
            _col <= _col + 1'b1;
        end else begin
          if(_row == 4'd13)
            _col <= 4'b0;
        end
      end else if(conv_start) begin
        _row <= 4'd0;
        _col <= 4'd0;
      end
    end
  end

  // bias position
  always@(posedge conv_clk) begin
    if(!conv_rst_n) begin
      conv_to_x <= 4'd0;
      conv_to_y <= 4'd0;
    end else begin
      if(conv_rd_data_partial_sum) begin
        // to_y
        if(conv_to_y!=4'd13) begin
          conv_to_y <= conv_to_y + 1'b1;
        end else begin
          conv_to_y <= 4'd0;
        end
        // to_x
        if(conv_to_x!=4'd13) begin
          if(conv_to_y==4'd13)
            conv_to_x <= conv_to_x + 1'b1;
        end else begin
          if(conv_to_y==4'd13)
            conv_to_x <= 4'd0;
        end
      end else if(conv_start) begin
        conv_to_x <= 4'd0;
        conv_to_y <= 4'd0;
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
        // row
        if(conv_y!=4'd13) begin
          conv_y <= conv_y+1'b1;
        end else begin
          conv_y <= 4'h0;
        end
        // col
        if(conv_x!=4'd13) begin
          if(conv_y == 4'd13)
            conv_x <= conv_x + 1'b1;
        end else begin
          if(conv_y == 4'd13)
            conv_x <= 4'd0;
        end
      end else begin
        conv_x <= 4'd0;
        conv_y <= 4'd0;
      end
    end
  end

  // data multiplexer
  always@(_row or _col or _bottom00 or _bottom01 or _bottom02 or _bottom03 or
          _bottom04 or _bottom05 or _bottom06 or _bottom07 or _bottom08 or _bottom09 or
          _bottom10 or _bottom11 or _bottom12 or _bottom13 or _bottom14 or _bottom15) begin
    //_data0 = {((EXPONENT+MANTISSA+1)*K_W){1'b0}};
    //_data1 = {((EXPONENT+MANTISSA+1)*K_W){1'b0}};
    case(_col) //synopsys full_case parallel_case
      4'd0:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom13[4'd14],_bottom14[4'd14],_bottom15[4'd14]};
        end else begin
          _data1 = {_bottom13[4'd15],_bottom14[4'd15],_bottom15[4'd15]};
        end
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom00[0],_bottom01[0],_bottom02[0]};
          end
          4'd1:begin
            _data0 = {_bottom00[1],_bottom01[1],_bottom02[1]};
          end
          4'd2:begin
            _data0 = {_bottom00[2],_bottom01[2],_bottom02[2]};
          end
          4'd3:begin
            _data0 = {_bottom00[3],_bottom01[3],_bottom02[3]};
          end
          4'd4:begin
            _data0 = {_bottom00[4],_bottom01[4],_bottom02[4]};
          end
          4'd5:begin
            _data0 = {_bottom00[5],_bottom01[5],_bottom02[5]};
          end
          4'd6:begin
            _data0 = {_bottom00[6],_bottom01[6],_bottom02[6]};
          end
          4'd7:begin
            _data0 = {_bottom00[7],_bottom01[7],_bottom02[7]};
          end
          4'd8:begin
            _data0 = {_bottom00[8],_bottom01[8],_bottom02[8]};
          end
          4'd9:begin
            _data0 = {_bottom00[9],_bottom01[9],_bottom02[9]};
          end
          4'd10:begin
            _data0 = {_bottom00[10],_bottom01[10],_bottom02[10]};
          end
          4'd11:begin
            _data0 = {_bottom00[11],_bottom01[11],_bottom02[11]};
          end
          4'd12:begin
            _data0 = {_bottom00[12],_bottom01[12],_bottom02[12]};
          end
          4'd13:begin
            _data0 = {_bottom00[13],_bottom01[13],_bottom02[13]};
          end
        endcase
      end
      4'd1:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom00[4'd14],_bottom01[4'd14],_bottom02[4'd14]};
        end else begin
          _data1 = {_bottom00[4'd15],_bottom01[4'd15],_bottom02[4'd15]};
        end
        //_data0 = {_bottom01[_row],_bottom02[_row],_bottom03[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom01[0],_bottom02[0],_bottom03[0]};
          end
          4'd1:begin
            _data0 = {_bottom01[1],_bottom02[1],_bottom03[1]};
          end
          4'd2:begin
            _data0 = {_bottom01[2],_bottom02[2],_bottom03[2]};
          end
          4'd3:begin
            _data0 = {_bottom01[3],_bottom02[3],_bottom03[3]};
          end
          4'd4:begin
            _data0 = {_bottom01[4],_bottom02[4],_bottom03[4]};
          end
          4'd5:begin
            _data0 = {_bottom01[5],_bottom02[5],_bottom03[5]};
          end
          4'd6:begin
            _data0 = {_bottom01[6],_bottom02[6],_bottom03[6]};
          end
          4'd7:begin
            _data0 = {_bottom01[7],_bottom02[7],_bottom03[7]};
          end
          4'd8:begin
            _data0 = {_bottom01[8],_bottom02[8],_bottom03[8]};
          end
          4'd9:begin
            _data0 = {_bottom01[9],_bottom02[9],_bottom03[9]};
          end
          4'd10:begin
            _data0 = {_bottom01[10],_bottom02[10],_bottom03[10]};
          end
          4'd11:begin
            _data0 = {_bottom01[11],_bottom02[11],_bottom03[11]};
          end
          4'd12:begin
            _data0 = {_bottom01[12],_bottom02[12],_bottom03[12]};
          end
          4'd13:begin
            _data0 = {_bottom01[13],_bottom02[13],_bottom03[13]};
          end
        endcase        

      end
      4'd2:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom01[4'd14],_bottom02[4'd14],_bottom03[4'd14]};
        end else begin
          _data1 = {_bottom01[4'd15],_bottom02[4'd15],_bottom03[4'd15]};
        end
        //_data0 = {_bottom02[_row],_bottom03[_row],_bottom04[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom02[0],_bottom03[0],_bottom04[0]};
          end
          4'd1:begin
            _data0 = {_bottom02[1],_bottom03[1],_bottom04[1]};
          end
          4'd2:begin
            _data0 = {_bottom02[2],_bottom03[2],_bottom04[2]};
          end
          4'd3:begin
            _data0 = {_bottom02[3],_bottom03[3],_bottom04[3]};
          end
          4'd4:begin
            _data0 = {_bottom02[4],_bottom03[4],_bottom04[4]};
          end
          4'd5:begin
            _data0 = {_bottom02[5],_bottom03[5],_bottom04[5]};
          end
          4'd6:begin
            _data0 = {_bottom02[6],_bottom03[6],_bottom04[6]};
          end
          4'd7:begin
            _data0 = {_bottom02[7],_bottom03[7],_bottom04[7]};
          end
          4'd8:begin
            _data0 = {_bottom02[8],_bottom03[8],_bottom04[8]};
          end
          4'd9:begin
            _data0 = {_bottom02[9],_bottom03[9],_bottom04[9]};
          end
          4'd10:begin
            _data0 = {_bottom02[10],_bottom03[10],_bottom04[10]};
          end
          4'd11:begin
            _data0 = {_bottom02[11],_bottom03[11],_bottom04[11]};
          end
          4'd12:begin
            _data0 = {_bottom02[12],_bottom03[12],_bottom04[12]};
          end
          4'd13:begin
            _data0 = {_bottom02[13],_bottom03[13],_bottom04[13]};
          end
        endcase  
      end
      4'd3:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom02[4'd14],_bottom03[4'd14],_bottom04[4'd14]};
        end else begin
          _data1 = {_bottom02[4'd15],_bottom03[4'd15],_bottom04[4'd15]};
        end
        //_data0 = {_bottom03[_row],_bottom04[_row],_bottom05[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom03[0],_bottom04[0],_bottom05[0]};
          end
          4'd1:begin
            _data0 = {_bottom03[1],_bottom04[1],_bottom05[1]};
          end
          4'd2:begin
            _data0 = {_bottom03[2],_bottom04[2],_bottom05[2]};
          end
          4'd3:begin
            _data0 = {_bottom03[3],_bottom04[3],_bottom05[3]};
          end
          4'd4:begin
            _data0 = {_bottom03[4],_bottom04[4],_bottom05[4]};
          end
          4'd5:begin
            _data0 = {_bottom03[5],_bottom04[5],_bottom05[5]};
          end
          4'd6:begin
            _data0 = {_bottom03[6],_bottom04[6],_bottom05[6]};
          end
          4'd7:begin
            _data0 = {_bottom03[7],_bottom04[7],_bottom05[7]};
          end
          4'd8:begin
            _data0 = {_bottom03[8],_bottom04[8],_bottom05[8]};
          end
          4'd9:begin
            _data0 = {_bottom03[9],_bottom04[9],_bottom05[9]};
          end
          4'd10:begin
            _data0 = {_bottom03[10],_bottom04[10],_bottom05[10]};
          end
          4'd11:begin
            _data0 = {_bottom03[11],_bottom04[11],_bottom05[11]};
          end
          4'd12:begin
            _data0 = {_bottom03[12],_bottom04[12],_bottom05[12]};
          end
          4'd13:begin
            _data0 = {_bottom03[13],_bottom04[13],_bottom05[13]};
          end
        endcase 
      end
      4'd4:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom03[4'd14],_bottom04[4'd14],_bottom05[4'd14]};
        end else begin
          _data1 = {_bottom03[4'd15],_bottom04[4'd15],_bottom05[4'd15]};
        end
        //_data0 = {_bottom04[_row],_bottom05[_row],_bottom06[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom04[0],_bottom05[0],_bottom06[0]};
          end
          4'd1:begin
            _data0 = {_bottom04[1],_bottom05[1],_bottom06[1]};
          end
          4'd2:begin
            _data0 = {_bottom04[2],_bottom05[2],_bottom06[2]};
          end
          4'd3:begin
            _data0 = {_bottom04[3],_bottom05[3],_bottom06[3]};
          end
          4'd4:begin
            _data0 = {_bottom04[4],_bottom05[4],_bottom06[4]};
          end
          4'd5:begin
            _data0 = {_bottom04[5],_bottom05[5],_bottom06[5]};
          end
          4'd6:begin
            _data0 = {_bottom04[6],_bottom05[6],_bottom06[6]};
          end
          4'd7:begin
            _data0 = {_bottom04[7],_bottom05[7],_bottom06[7]};
          end
          4'd8:begin
            _data0 = {_bottom04[8],_bottom05[8],_bottom06[8]};
          end
          4'd9:begin
            _data0 = {_bottom04[9],_bottom05[9],_bottom06[9]};
          end
          4'd10:begin
            _data0 = {_bottom04[10],_bottom05[10],_bottom06[10]};
          end
          4'd11:begin
            _data0 = {_bottom04[11],_bottom05[11],_bottom06[11]};
          end
          4'd12:begin
            _data0 = {_bottom04[12],_bottom05[12],_bottom06[12]};
          end
          4'd13:begin
            _data0 = {_bottom04[13],_bottom05[13],_bottom06[13]};
          end
        endcase       
      end
      4'd5:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom04[4'd14],_bottom05[4'd14],_bottom06[4'd14]};
        end else begin
          _data1 = {_bottom04[4'd15],_bottom05[4'd15],_bottom06[4'd15]};
        end
        //_data0 = {_bottom05[_row],_bottom06[_row],_bottom07[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom05[0],_bottom06[0],_bottom07[0]};
          end
          4'd1:begin
            _data0 = {_bottom05[1],_bottom06[1],_bottom07[1]};
          end
          4'd2:begin
            _data0 = {_bottom05[2],_bottom06[2],_bottom07[2]};
          end
          4'd3:begin
            _data0 = {_bottom05[3],_bottom06[3],_bottom07[3]};
          end
          4'd4:begin
            _data0 = {_bottom05[4],_bottom06[4],_bottom07[4]};
          end
          4'd5:begin
            _data0 = {_bottom05[5],_bottom06[5],_bottom07[5]};
          end
          4'd6:begin
            _data0 = {_bottom05[6],_bottom06[6],_bottom07[6]};
          end
          4'd7:begin
            _data0 = {_bottom05[7],_bottom06[7],_bottom07[7]};
          end
          4'd8:begin
            _data0 = {_bottom05[8],_bottom06[8],_bottom07[8]};
          end
          4'd9:begin
            _data0 = {_bottom05[9],_bottom06[9],_bottom07[9]};
          end
          4'd10:begin
            _data0 = {_bottom05[10],_bottom06[10],_bottom07[10]};
          end
          4'd11:begin
            _data0 = {_bottom05[11],_bottom06[11],_bottom07[11]};
          end
          4'd12:begin
            _data0 = {_bottom05[12],_bottom06[12],_bottom07[12]};
          end
          4'd13:begin
            _data0 = {_bottom05[13],_bottom06[13],_bottom07[13]};
          end
        endcase
      end
      4'd6:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom05[4'd14],_bottom06[4'd14],_bottom07[4'd14]};
        end else begin
          _data1 = {_bottom05[4'd15],_bottom06[4'd15],_bottom07[4'd15]};
        end
        //_data0 = {_bottom06[_row],_bottom07[_row],_bottom08[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom06[0],_bottom07[0],_bottom08[0]};
          end
          4'd1:begin
            _data0 = {_bottom06[1],_bottom07[1],_bottom08[1]};
          end
          4'd2:begin
            _data0 = {_bottom06[2],_bottom07[2],_bottom08[2]};
          end
          4'd3:begin
            _data0 = {_bottom06[3],_bottom07[3],_bottom08[3]};
          end
          4'd4:begin
            _data0 = {_bottom06[4],_bottom07[4],_bottom08[4]};
          end
          4'd5:begin
            _data0 = {_bottom06[5],_bottom07[5],_bottom08[5]};
          end
          4'd6:begin
            _data0 = {_bottom06[6],_bottom07[6],_bottom08[6]};
          end
          4'd7:begin
            _data0 = {_bottom06[7],_bottom07[7],_bottom08[7]};
          end
          4'd8:begin
            _data0 = {_bottom06[8],_bottom07[8],_bottom08[8]};
          end
          4'd9:begin
            _data0 = {_bottom06[9],_bottom07[9],_bottom08[9]};
          end
          4'd10:begin
            _data0 = {_bottom06[10],_bottom07[10],_bottom08[10]};
          end
          4'd11:begin
            _data0 = {_bottom06[11],_bottom07[11],_bottom08[11]};
          end
          4'd12:begin
            _data0 = {_bottom06[12],_bottom07[12],_bottom08[12]};
          end
          4'd13:begin
            _data0 = {_bottom06[13],_bottom07[13],_bottom08[13]};
          end
        endcase
      end
      4'd7:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom06[4'd14],_bottom07[4'd14],_bottom08[4'd14]};
        end else begin
          _data1 = {_bottom06[4'd15],_bottom07[4'd15],_bottom08[4'd15]};
        end
        //_data0 = {_bottom07[_row],_bottom08[_row],_bottom09[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom07[0],_bottom08[0],_bottom09[0]};
          end
          4'd1:begin
            _data0 = {_bottom07[1],_bottom08[1],_bottom09[1]};
          end
          4'd2:begin
            _data0 = {_bottom07[2],_bottom08[2],_bottom09[2]};
          end
          4'd3:begin
            _data0 = {_bottom07[3],_bottom08[3],_bottom09[3]};
          end
          4'd4:begin
            _data0 = {_bottom07[4],_bottom08[4],_bottom09[4]};
          end
          4'd5:begin
            _data0 = {_bottom07[5],_bottom08[5],_bottom09[5]};
          end
          4'd6:begin
            _data0 = {_bottom07[6],_bottom08[6],_bottom09[6]};
          end
          4'd7:begin
            _data0 = {_bottom07[7],_bottom08[7],_bottom09[7]};
          end
          4'd8:begin
            _data0 = {_bottom07[8],_bottom08[8],_bottom09[8]};
          end
          4'd9:begin
            _data0 = {_bottom07[9],_bottom08[9],_bottom09[9]};
          end
          4'd10:begin
            _data0 = {_bottom07[10],_bottom08[10],_bottom09[10]};
          end
          4'd11:begin
            _data0 = {_bottom07[11],_bottom08[11],_bottom09[11]};
          end
          4'd12:begin
            _data0 = {_bottom07[12],_bottom08[12],_bottom09[12]};
          end
          4'd13:begin
            _data0 = {_bottom07[13],_bottom08[13],_bottom09[13]};
          end
        endcase
      end
      4'd8:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom07[4'd14],_bottom08[4'd14],_bottom09[4'd14]};
        end else begin
          _data1 = {_bottom07[4'd15],_bottom08[4'd15],_bottom09[4'd15]};
        end
        //_data0 = {_bottom08[_row],_bottom09[_row],_bottom10[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom08[0],_bottom09[0],_bottom10[0]};
          end
          4'd1:begin
            _data0 = {_bottom08[1],_bottom09[1],_bottom10[1]};
          end
          4'd2:begin
            _data0 = {_bottom08[2],_bottom09[2],_bottom10[2]};
          end
          4'd3:begin
            _data0 = {_bottom08[3],_bottom09[3],_bottom10[3]};
          end
          4'd4:begin
            _data0 = {_bottom08[4],_bottom09[4],_bottom10[4]};
          end
          4'd5:begin
            _data0 = {_bottom08[5],_bottom09[5],_bottom10[5]};
          end
          4'd6:begin
            _data0 = {_bottom08[6],_bottom09[6],_bottom10[6]};
          end
          4'd7:begin
            _data0 = {_bottom08[7],_bottom09[7],_bottom10[7]};
          end
          4'd8:begin
            _data0 = {_bottom08[8],_bottom09[8],_bottom10[8]};
          end
          4'd9:begin
            _data0 = {_bottom08[9],_bottom09[9],_bottom10[9]};
          end
          4'd10:begin
            _data0 = {_bottom08[10],_bottom09[10],_bottom10[10]};
          end
          4'd11:begin
            _data0 = {_bottom08[11],_bottom09[11],_bottom10[11]};
          end
          4'd12:begin
            _data0 = {_bottom08[12],_bottom09[12],_bottom10[12]};
          end
          4'd13:begin
            _data0 = {_bottom08[13],_bottom09[13],_bottom10[13]};
          end
        endcase

      end
      4'd9:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom08[4'd14],_bottom09[4'd14],_bottom10[4'd14]};
        end else begin
          _data1 = {_bottom08[4'd15],_bottom09[4'd15],_bottom10[4'd15]};
        end
        //_data0 = {_bottom09[_row],_bottom10[_row],_bottom11[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom09[0],_bottom10[0],_bottom11[0]};
          end
          4'd1:begin
            _data0 = {_bottom09[1],_bottom10[1],_bottom11[1]};
          end
          4'd2:begin
            _data0 = {_bottom09[2],_bottom10[2],_bottom11[2]};
          end
          4'd3:begin
            _data0 = {_bottom09[3],_bottom10[3],_bottom11[3]};
          end
          4'd4:begin
            _data0 = {_bottom09[4],_bottom10[4],_bottom11[4]};
          end
          4'd5:begin
            _data0 = {_bottom09[5],_bottom10[5],_bottom11[5]};
          end
          4'd6:begin
            _data0 = {_bottom09[6],_bottom10[6],_bottom11[6]};
          end
          4'd7:begin
            _data0 = {_bottom09[7],_bottom10[7],_bottom11[7]};
          end
          4'd8:begin
            _data0 = {_bottom09[8],_bottom10[8],_bottom11[8]};
          end
          4'd9:begin
            _data0 = {_bottom09[9],_bottom10[9],_bottom11[9]};
          end
          4'd10:begin
            _data0 = {_bottom09[10],_bottom10[10],_bottom11[10]};
          end
          4'd11:begin
            _data0 = {_bottom09[11],_bottom10[11],_bottom11[11]};
          end
          4'd12:begin
            _data0 = {_bottom09[12],_bottom10[12],_bottom11[12]};
          end
          4'd13:begin
            _data0 = {_bottom09[13],_bottom10[13],_bottom11[13]};
          end
        endcase
      end
      4'd10:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom09[4'd14],_bottom10[4'd14],_bottom11[4'd14]};
        end else begin
          _data1 = {_bottom09[4'd15],_bottom10[4'd15],_bottom11[4'd15]};
        end
        //_data0 = {_bottom10[_row],_bottom11[_row],_bottom12[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom10[0],_bottom11[0],_bottom12[0]};
          end
          4'd1:begin
            _data0 = {_bottom10[1],_bottom11[1],_bottom12[1]};
          end
          4'd2:begin
            _data0 = {_bottom10[2],_bottom11[2],_bottom12[2]};
          end
          4'd3:begin
            _data0 = {_bottom10[3],_bottom11[3],_bottom12[3]};
          end
          4'd4:begin
            _data0 = {_bottom10[4],_bottom11[4],_bottom12[4]};
          end
          4'd5:begin
            _data0 = {_bottom10[5],_bottom11[5],_bottom12[5]};
          end
          4'd6:begin
            _data0 = {_bottom10[6],_bottom11[6],_bottom12[6]};
          end
          4'd7:begin
            _data0 = {_bottom10[7],_bottom11[7],_bottom12[7]};
          end
          4'd8:begin
            _data0 = {_bottom10[8],_bottom11[8],_bottom12[8]};
          end
          4'd9:begin
            _data0 = {_bottom10[9],_bottom11[9],_bottom12[9]};
          end
          4'd10:begin
            _data0 = {_bottom10[10],_bottom11[10],_bottom12[10]};
          end
          4'd11:begin
            _data0 = {_bottom10[11],_bottom11[11],_bottom12[11]};
          end
          4'd12:begin
            _data0 = {_bottom10[12],_bottom11[12],_bottom12[12]};
          end
          4'd13:begin
            _data0 = {_bottom10[13],_bottom11[13],_bottom12[13]};
          end
        endcase
      end
      4'd11:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom10[4'd14],_bottom11[4'd14],_bottom12[4'd14]};
        end else begin
          _data1 = {_bottom10[4'd15],_bottom11[4'd15],_bottom12[4'd15]};
        end
        //_data0 = {_bottom11[_row],_bottom12[_row],_bottom13[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom11[0],_bottom12[0],_bottom13[0]};
          end
          4'd1:begin
            _data0 = {_bottom11[1],_bottom12[1],_bottom13[1]};
          end
          4'd2:begin
            _data0 = {_bottom11[2],_bottom12[2],_bottom13[2]};
          end
          4'd3:begin
            _data0 = {_bottom11[3],_bottom12[3],_bottom13[3]};
          end
          4'd4:begin
            _data0 = {_bottom11[4],_bottom12[4],_bottom13[4]};
          end
          4'd5:begin
            _data0 = {_bottom11[5],_bottom12[5],_bottom13[5]};
          end
          4'd6:begin
            _data0 = {_bottom11[6],_bottom12[6],_bottom13[6]};
          end
          4'd7:begin
            _data0 = {_bottom11[7],_bottom12[7],_bottom13[7]};
          end
          4'd8:begin
            _data0 = {_bottom11[8],_bottom12[8],_bottom13[8]};
          end
          4'd9:begin
            _data0 = {_bottom11[9],_bottom12[9],_bottom13[9]};
          end
          4'd10:begin
            _data0 = {_bottom11[10],_bottom12[10],_bottom13[10]};
          end
          4'd11:begin
            _data0 = {_bottom11[11],_bottom12[11],_bottom13[11]};
          end
          4'd12:begin
            _data0 = {_bottom11[12],_bottom12[12],_bottom13[12]};
          end
          4'd13:begin
            _data0 = {_bottom11[13],_bottom12[13],_bottom13[13]};
          end
        endcase

      end
      4'd12:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom11[4'd14],_bottom12[4'd14],_bottom13[4'd14]};
        end else begin
          _data1 = {_bottom11[4'd15],_bottom12[4'd15],_bottom13[4'd15]};
        end
        //_data0 = {_bottom12[_row],_bottom13[_row],_bottom14[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom12[0],_bottom13[0],_bottom14[0]};
          end
          4'd1:begin
            _data0 = {_bottom12[1],_bottom13[1],_bottom14[1]};
          end
          4'd2:begin
            _data0 = {_bottom12[2],_bottom13[2],_bottom14[2]};
          end
          4'd3:begin
            _data0 = {_bottom12[3],_bottom13[3],_bottom14[3]};
          end
          4'd4:begin
            _data0 = {_bottom12[4],_bottom13[4],_bottom14[4]};
          end
          4'd5:begin
            _data0 = {_bottom12[5],_bottom13[5],_bottom14[5]};
          end
          4'd6:begin
            _data0 = {_bottom12[6],_bottom13[6],_bottom14[6]};
          end
          4'd7:begin
            _data0 = {_bottom12[7],_bottom13[7],_bottom14[7]};
          end
          4'd8:begin
            _data0 = {_bottom12[8],_bottom13[8],_bottom14[8]};
          end
          4'd9:begin
            _data0 = {_bottom12[9],_bottom13[9],_bottom14[9]};
          end
          4'd10:begin
            _data0 = {_bottom12[10],_bottom13[10],_bottom14[10]};
          end
          4'd11:begin
            _data0 = {_bottom12[11],_bottom13[11],_bottom14[11]};
          end
          4'd12:begin
            _data0 = {_bottom12[12],_bottom13[12],_bottom14[12]};
          end
          4'd13:begin
            _data0 = {_bottom12[13],_bottom13[13],_bottom14[13]};
          end
        endcase
      end
      4'd13:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom12[4'd14],_bottom13[4'd14],_bottom14[4'd14]};
        end else begin
          _data1 = {_bottom12[4'd15],_bottom13[4'd15],_bottom14[4'd15]};
        end
        //_data0 = {_bottom13[_row],_bottom14[_row],_bottom15[_row]};
        case(_row) //synopsys full_case parallel_case
          4'd0:begin
            _data0 = {_bottom13[0],_bottom14[0],_bottom15[0]};
          end
          4'd1:begin
            _data0 = {_bottom13[1],_bottom14[1],_bottom15[1]};
          end
          4'd2:begin
            _data0 = {_bottom13[2],_bottom14[2],_bottom15[2]};
          end
          4'd3:begin
            _data0 = {_bottom13[3],_bottom14[3],_bottom15[3]};
          end
          4'd4:begin
            _data0 = {_bottom13[4],_bottom14[4],_bottom15[4]};
          end
          4'd5:begin
            _data0 = {_bottom13[5],_bottom14[5],_bottom15[5]};
          end
          4'd6:begin
            _data0 = {_bottom13[6],_bottom14[6],_bottom15[6]};
          end
          4'd7:begin
            _data0 = {_bottom13[7],_bottom14[7],_bottom15[7]};
          end
          4'd8:begin
            _data0 = {_bottom13[8],_bottom14[8],_bottom15[8]};
          end
          4'd9:begin
            _data0 = {_bottom13[9],_bottom14[9],_bottom15[9]};
          end
          4'd10:begin
            _data0 = {_bottom13[10],_bottom14[10],_bottom15[10]};
          end
          4'd11:begin
            _data0 = {_bottom13[11],_bottom14[11],_bottom15[11]};
          end
          4'd12:begin
            _data0 = {_bottom13[12],_bottom14[12],_bottom15[12]};
          end
          4'd13:begin
            _data0 = {_bottom13[13],_bottom14[13],_bottom15[13]};
          end
        endcase
      end
    endcase
  end

//  //reverse order
//  // convert from/to 1-dim array
//  genvar c, w, h;
//  generate
//    for(c=0; c<K_C; c=c+1) begin
//      for(h=0; h<K_H; h=h+1) begin
//        for(w=0; w<K_W; w=w+1)begin
//          assign _ker[K_C*K_H*K_W-1-(w+h*K_W+c*K_H*K_W)] = conv_ker[DATA_WIDTH*(1+w+h*K_W+c*K_H*K_W)-1 : DATA_WIDTH*(w+h*K_W+c*K_H*K_W)];
//        end
//      end
//    end
//    for(h=0; h<CW_H; h=h+1)begin // column-wise
//      assign _bottom00[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+15+h*CW_W)-1 : DATA_WIDTH*(15+h*CW_W)];
//      assign _bottom01[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+14+h*CW_W)-1 : DATA_WIDTH*(14+h*CW_W)];
//      assign _bottom02[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+13+h*CW_W)-1 : DATA_WIDTH*(13+h*CW_W)];
//      assign _bottom03[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+12+h*CW_W)-1 : DATA_WIDTH*(12+h*CW_W)];
//      assign _bottom04[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+11+h*CW_W)-1 : DATA_WIDTH*(11+h*CW_W)];
//      assign _bottom05[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+10+h*CW_W)-1 : DATA_WIDTH*(10+h*CW_W)];
//      assign _bottom06[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 9+h*CW_W)-1 : DATA_WIDTH*( 9+h*CW_W)];
//      assign _bottom07[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 8+h*CW_W)-1 : DATA_WIDTH*( 8+h*CW_W)];
//      assign _bottom08[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 7+h*CW_W)-1 : DATA_WIDTH*( 7+h*CW_W)];
//      assign _bottom09[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 6+h*CW_W)-1 : DATA_WIDTH*( 6+h*CW_W)];
//      assign _bottom10[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 5+h*CW_W)-1 : DATA_WIDTH*( 5+h*CW_W)];
//      assign _bottom11[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 4+h*CW_W)-1 : DATA_WIDTH*( 4+h*CW_W)];
//      assign _bottom12[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 3+h*CW_W)-1 : DATA_WIDTH*( 3+h*CW_W)];
//      assign _bottom13[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 2+h*CW_W)-1 : DATA_WIDTH*( 2+h*CW_W)];
//      assign _bottom14[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 1+h*CW_W)-1 : DATA_WIDTH*( 1+h*CW_W)];
//      assign _bottom15[CW_H-1-h] = conv_bottom[DATA_WIDTH*(1+ 0+h*CW_W)-1 : DATA_WIDTH*( 0+h*CW_W)];
//    end
//  endgenerate

  // convert from/to 1-dim array
  genvar c, w, h;
  generate
    for(c=0; c<K_C; c=c+1) begin
      for(h=0; h<K_H; h=h+1) begin
        for(w=0; w<K_W; w=w+1)begin
          assign _ker[w+h*K_W+c*K_H*K_W] = conv_ker[DATA_WIDTH*(1+w+h*K_W+c*K_H*K_W)-1 : DATA_WIDTH*(w+h*K_W+c*K_H*K_W)];
        end
      end
    end
    for(h=0; h<CW_H; h=h+1)begin // column-wise
      assign _bottom00[h] = conv_bottom[DATA_WIDTH*(1+ 0+h*CW_W)-1 : DATA_WIDTH*( 0+h*CW_W)];
      assign _bottom01[h] = conv_bottom[DATA_WIDTH*(1+ 1+h*CW_W)-1 : DATA_WIDTH*( 1+h*CW_W)];
      assign _bottom02[h] = conv_bottom[DATA_WIDTH*(1+ 2+h*CW_W)-1 : DATA_WIDTH*( 2+h*CW_W)];
      assign _bottom03[h] = conv_bottom[DATA_WIDTH*(1+ 3+h*CW_W)-1 : DATA_WIDTH*( 3+h*CW_W)];
      assign _bottom04[h] = conv_bottom[DATA_WIDTH*(1+ 4+h*CW_W)-1 : DATA_WIDTH*( 4+h*CW_W)];
      assign _bottom05[h] = conv_bottom[DATA_WIDTH*(1+ 5+h*CW_W)-1 : DATA_WIDTH*( 5+h*CW_W)];
      assign _bottom06[h] = conv_bottom[DATA_WIDTH*(1+ 6+h*CW_W)-1 : DATA_WIDTH*( 6+h*CW_W)];
      assign _bottom07[h] = conv_bottom[DATA_WIDTH*(1+ 7+h*CW_W)-1 : DATA_WIDTH*( 7+h*CW_W)];
      assign _bottom08[h] = conv_bottom[DATA_WIDTH*(1+ 8+h*CW_W)-1 : DATA_WIDTH*( 8+h*CW_W)];
      assign _bottom09[h] = conv_bottom[DATA_WIDTH*(1+ 9+h*CW_W)-1 : DATA_WIDTH*( 9+h*CW_W)];
      assign _bottom10[h] = conv_bottom[DATA_WIDTH*(1+10+h*CW_W)-1 : DATA_WIDTH*(10+h*CW_W)];
      assign _bottom11[h] = conv_bottom[DATA_WIDTH*(1+11+h*CW_W)-1 : DATA_WIDTH*(11+h*CW_W)];
      assign _bottom12[h] = conv_bottom[DATA_WIDTH*(1+12+h*CW_W)-1 : DATA_WIDTH*(12+h*CW_W)];
      assign _bottom13[h] = conv_bottom[DATA_WIDTH*(1+13+h*CW_W)-1 : DATA_WIDTH*(13+h*CW_W)];
      assign _bottom14[h] = conv_bottom[DATA_WIDTH*(1+14+h*CW_W)-1 : DATA_WIDTH*(14+h*CW_W)];
      assign _bottom15[h] = conv_bottom[DATA_WIDTH*(1+15+h*CW_W)-1 : DATA_WIDTH*(15+h*CW_W)];
    end
  endgenerate

  reg [DATA_WIDTH*K_W-1:0]  _pa0_data_0;
  reg [DATA_WIDTH*K_W-1:0]  _pa1_data_0;
  reg [DATA_WIDTH*K_W-1:0]  _pa2_data_0;
  reg                       _pa0_data_valid_0;
  reg                       _pa1_data_valid_0;
  reg                       _pa2_data_valid_0;
  reg                       _conv_partial_sum_valid;
  reg [K_C*MID_WIDTH-1:0]   _conv_partial_sum;

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
       .pe3_array0_ker3({_ker[0*K_H*K_W  ],_ker[0*K_H*K_W+1],_ker[0*K_H*K_W+2]}),
       .pe3_array1_ker3({_ker[0*K_H*K_W+3],_ker[0*K_H*K_W+4],_ker[0*K_H*K_W+5]}),
       .pe3_array2_ker3({_ker[0*K_H*K_W+6],_ker[0*K_H*K_W+7],_ker[0*K_H*K_W+8]}),
       .pe3_array0_data3(_pa0_data_0),
       .pe3_array1_data3(_pa1_data_0),
       .pe3_array2_data3(_pa2_data_0),
       .pe3_array0_valid(_pa0_data_valid_0),
       .pe3_array1_valid(_pa1_data_valid_0),
       .pe3_array2_valid(_pa2_data_valid_0),
       .pe3_partial_value(_conv_partial_sum[(K_C-1-0+1)*MID_WIDTH-1:(K_C-1-0)*MID_WIDTH]),
       .pe3_o(conv_top[MID_WIDTH*(K_C-1-0+1)-1:MID_WIDTH*(K_C-1-0)]),
       .pe3_valid(conv_output_valid),
       .pe3_next_partial_sum(conv_rd_data_partial_sum) // next partial sum data
    );
  
//  generate
//    for(c=1; c<K_C; c=c+1) 
//    begin:array
//      pe_array3x3 #(
//        .DATA_WIDTH(DATA_WIDTH),
//        .MID_WIDTH(MID_WIDTH)
//      )pe_arry(
//        .clk(conv_clk),
//        .pe3_array0_ker3({_ker[c*K_H*K_W  ],_ker[c*K_H*K_W+1],_ker[c*K_H*K_W+2]}),
//        .pe3_array1_ker3({_ker[c*K_H*K_W+3],_ker[c*K_H*K_W+4],_ker[c*K_H*K_W+5]}),
//        .pe3_array2_ker3({_ker[c*K_H*K_W+6],_ker[c*K_H*K_W+7],_ker[c*K_H*K_W+8]}),
//        .pe3_array0_data3(_pa0_data_0),
//        .pe3_array1_data3(_pa1_data_0),
//        .pe3_array2_data3(_pa2_data_0),
//        .pe3_array0_valid(_pa0_data_valid_0),
//        .pe3_array1_valid(_pa1_data_valid_0),
//        .pe3_array2_valid(_pa2_data_valid_0),
//        .pe3_o(conv_top[MID_WIDTH*(K_C-1-c+1)-1:MID_WIDTH*(K_C-1-c)]),
//        .pe3_partial_value(_conv_partial_sum[(K_C-1-c+1)*MID_WIDTH-1:(K_C-1-c)*MID_WIDTH]),
//        .pe3_next_partial_sum(), // next partial sum data
//        .pe3_valid()
//      );
//    end
//  endgenerate

endmodule
