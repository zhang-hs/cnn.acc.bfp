`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: zhanghs
// 
// Create Date: 2018/09/14 10:23:22
// Module Name: fsm
// Project Name: cnn.acc.bfp
// Target Devices: vc709
// Tool Versions: vivado 2018.1
// Description: finite state machine of convolution layer
//
// Revision 1.1 - init patch & fetch patch
//////////////////////////////////////////////////////////////////////////////////

//`define sim_
module fsm(
  input  wire             clk,
  input  wire             rst_n,
  output wire             fsm_ddr_req,  // read ddr data request
  //conv,top layer
  input  wire             fsm_data_ready, // bottom data and kernel data is ready on ddr
  input  wire             fsm_start,  // conv layer operation start signal
  /*(*mark_debug="TRUE"*)*/output reg              fsm_done, // conv layer operation have finished, write data to ddr sdram
  //pooling
  input  wire             fsm_pooling_en,
  input  wire             fsm_pooling_last_pos,
  //conv_op
  input  wire             fsm_conv_start_at_next_clk, // = fsm_conv_start
  input  wire             fsm_conv_at_last_pos,
  input  wire             fsm_conv_busy,
  input  wire             fsm_conv_last_valid,
  output reg              fsm_conv_start,
  output reg              fsm_conv_on_ker0, //operate on ker0
  output reg              fsm_conv_on_ker1, //operate on ker1
  output wire             fsm_conv_on_first_fm, //conv on first fm
  output wire             fsm_conv_on_last_fm,  //conv on last fm
  output reg [9:0]        fsm_conv_cur_ker_num, //current operation output kernel num
  //wr_ddr_op
  input  wire             fsm_wr_data_done, //wr operation done
  input  wire             fsm_last_layer,
  output reg              fsm_wr_data_top,  //start writing top data to ddr
  output reg              fsm_wr_data_sw_on,
  output wire             fsm_wr_data_x_eq_0,
  output wire             fsm_wr_data_y_eq_0,
  output wire             fsm_wr_data_x_eq_end,
  output wire             fsm_wr_data_y_eq_end,
  //rd_ddr_data
  input  wire             fsm_rd_data_full, //rd operation done
  input  wire [9:0]       fsm_rd_data_bottom_channels,
  input  wire [4:0]       fsm_rd_data_fm_width,
  input  wire [4:0]       fsm_rd_data_fm_height,
  input  wire [29:0]      fsm_rd_data_fm_size,
  output reg              fsm_rd_data_bottom,   //start reading bottom data from ddr
  /*(*mark_debug="TRUE"*)*/output reg  [4:0]       fsm_rd_data_x,
  /*(*mark_debug="TRUE"*)*/output reg  [4:0]       fsm_rd_data_y,
  output wire [4:0]       fsm_rd_data_end_of_x,
  output wire [4:0]       fsm_rd_data_end_of_y,
  output wire             fsm_rd_data_first_fm,
  output reg  [29:0]      fsm_rd_data_ith_offset,
  output reg  [8:0]       fsm_rd_data_ith_fm,
  output reg              fsm_rd_data_sw_on,
  //rd_ddr_param
  input  wire             fsm_rd_param_full,  //rd operation done
  input  wire [29:0]      fsm_rd_param_ker_ddr_addr,  // address of kernal data(skip bias)
  input  wire [9:0]       fsm_rd_param_bias_num,  //number of top channels
  input  wire [8:0]       fsm_rd_param_bias_offset, //address occupied by bias data
  output reg              fsm_rd_param, //start reading param from ddr
  output reg              fsm_rd_param_ker_only,
  output reg  [29:0]      fsm_rd_param_addr,
  output reg              fsm_rd_param_sw_on,
  output wire             fsm_rd_param_ker0,  //-->mem_ker
  output wire             fsm_rd_param_ker1,
  //rd_ddr_exp
  input  wire             fsm_rd_exp_full,  //rd operation done
  output reg              fsm_rd_exp,  //start reading exp from ddr
  output reg              fsm_rd_exp_sw_on,
  //mem_top
  output wire [8:0]       fsm_rd_patch_ith_fm,
  output wire [4:0]       fsm_rd_patch_x, //read bottom from patch_bram
  output wire             fsm_rd_patch_x_eq_end,
  output wire             fsm_rd_patch_y_eq_zero,
  output wire             fsm_rd_patch_y_eq_end,
  output wire             fsm_rd_patch_y_is_odd
);

  localparam ATOMIC_W         = 14;
  localparam ATOMIC_H         = 14;
  localparam DATA_WIDTH       = 8;
  localparam FP_WIDTH         = 16;
  localparam DDR_DATA_WIDTH   = 64;
  localparam K_C             = 64;
  localparam K_H              = 3;
  localparam K_W              = 3;
  localparam DDR_PARAM_OFFSET = K_C * K_H * K_W * DATA_WIDTH / DDR_DATA_WIDTH;
  
  //boundary
  assign fsm_rd_data_end_of_x = fsm_rd_data_fm_width - 5'b1;
  assign fsm_rd_data_end_of_y = fsm_rd_data_fm_height - 5'b1;
  reg  [4:0]        _fsm_x;
  reg  [4:0]        _fsm_y;
  reg               _fsm_end;   //current operation is on the last cw position
  reg  [9:0]        _fsm_cur_conv_out_ith;  //current operation output fm
  /*(*mark_debug="TRUE"*)*/reg  [9:0]        _fsm_cur_conv_ope_ith;  //current operation fm
  /*(*mark_debug="TRUE"*)*/reg  [9:0]        _fsm_cur_conv_ope_ker_num;  //current operation kernel num
  reg  [9:0]        _fsm_rd_param_bias_num;
  wire              _fsm_last_ker_set;  //last ker_set on current position, curent opearation output is on the last ker_set
  wire              _fsm_last_ope_fm;
  wire              _fsm_last_ope_ker_set;
  wire              _fsm_sec_last_ope_ker_set;
  assign _fsm_last_ker_set = (fsm_conv_cur_ker_num + 10'd64 == _fsm_rd_param_bias_num);
  assign _fsm_last_ope_fm = (_fsm_cur_conv_ope_ith + 10'd1 == fsm_rd_data_bottom_channels);
  assign _fsm_last_ope_ker_set = (_fsm_cur_conv_ope_ker_num + 10'd64 == _fsm_rd_param_bias_num);
  assign _fsm_sec_last_ope_ker_set = ((_fsm_cur_conv_ope_ker_num + 10'd128 == _fsm_rd_param_bias_num) || (fsm_rd_param_bias_num == 10'd64));
  
  //patch
  reg [29:0]        _fsm_ith_offset;  //ith bottom feature map adderss offset
  reg [8:0]         _fsm_ith_fm; //ith bottom feathure map index
  reg               _fsm_patch_full[0:1]; //indicating whether the next patch is written into bram
  reg               _fsm_next_conv_patch;
  reg               _fsm_rd_patch_index; // current patch index on reading, in simple fsm implementation, it's equivalent as _fsm_next_conv_patch
  reg               _fsm_conv_patch_index;
  //param
  reg [29:0]        _fsm_rd_ker_ith_offset;  //ith ker_set address offset
  reg               _fsm_ker_full[0:1];
  reg               _fsm_next_conv_ker;
  reg               _fsm_rd_ker_index;  //current ker index on reading, in sample fsm implementation
  reg               _fsm_conv_ker_index;
//  //mem
  /*(*mark_debug="TRUE"*)*/reg [4:0]         _fsm_rd_patch_x;
  /*(*mark_debug="TRUE"*)*/reg [4:0]         _fsm_rd_patch_y;
  reg [8:0]         _fsm_rd_patch_ith_fm;
  assign fsm_rd_patch_ith_fm   = _fsm_rd_patch_ith_fm;
  assign fsm_rd_patch_x        = _fsm_rd_patch_x;
  assign fsm_rd_patch_x_eq_end = (_fsm_rd_patch_x == (fsm_rd_data_fm_width - 5'b1)); 
  assign fsm_rd_patch_y_eq_zero = (_fsm_rd_patch_y == 5'b0);
  assign fsm_rd_patch_y_eq_end = (_fsm_rd_patch_y == (fsm_rd_data_fm_height - 5'b1)); 
  assign fsm_rd_patch_y_is_odd = (_fsm_rd_patch_y[0] == 1'b1);
  //wr_op
  reg [4:0]         _fsm_wr_x;  //current conv position x
  reg [4:0]         _fsm_wr_y;
  assign fsm_wr_data_x_eq_0    = (_fsm_wr_x == 5'd0);
  assign fsm_wr_data_y_eq_0    = (_fsm_wr_y == 5'd0);
  assign fsm_wr_data_x_eq_end  = (_fsm_wr_x == fsm_rd_data_end_of_x);
  assign fsm_wr_data_y_eq_end  = (_fsm_wr_y == fsm_rd_data_end_of_y);
  
  reg   _fsm_last_layer;  //current operation is on the last layer 
  always@(posedge clk) begin
    _fsm_rd_param_bias_num <= fsm_rd_param_bias_num;
    _fsm_last_layer        <= fsm_last_layer;
  end
  
  reg       _fsm_last_fm; //current operation is on the last bottom feature map
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_last_fm <= 1'b0;
    end else begin
      if(((_fsm_cur_conv_out_ith + 1'b1) == fsm_rd_data_bottom_channels) ||
         (((_fsm_cur_conv_out_ith + 2'd2) == fsm_rd_data_bottom_channels) && (_fsm_last_ker_set && fsm_conv_last_valid))
        ) begin
        _fsm_last_fm <= 1'b1;
      end else begin
        _fsm_last_fm <= 1'b0;
      end
    end
  end
  
  //ker_set selection
  wire    _fsm_conv_on_ker0;
  wire    _fsm_conv_on_ker1;
  assign _fsm_conv_on_ker0 = (_fsm_conv_ker_index == 1'b0) ? 1'b1 : 1'b0;
  assign _fsm_conv_on_ker1 = (_fsm_conv_ker_index == 1'b1) ? 1'b1 : 1'b0;
  assign fsm_rd_param_ker0 = (_fsm_rd_ker_index == 1'b0) ? 1'b1 : 1'b0;
  assign fsm_rd_param_ker1 = (_fsm_rd_ker_index == 1'b1) ? 1'b1: 1'b0;
  always@(posedge clk) begin
    fsm_conv_on_ker0 <= _fsm_conv_on_ker0;
    fsm_conv_on_ker1 <= _fsm_conv_on_ker1;
  end
  
  localparam FSM_RST          = 4'd0;
  localparam FSM_INIT_EXP     = 4'd1;
  localparam FSM_INIT_PATCH   = 4'd2;
  localparam FSM_INIT_PARAM   = 4'd3;
  localparam FSM_CONV_OP      = 4'd4;
  localparam FSM_FETCH_PATCH  = 4'd5;
  localparam FSM_FETCH_KER    = 4'd6;
  localparam FSM_WAIT         = 4'd7;
  localparam FSM_WR_DATA      = 4'd8;
  /*(*mark_debug="TRUE"*)*/reg [3:0]   _fsm_state;
  reg [3:0]   _fsm_next_state;
  
  assign fsm_rd_data_first_fm = (_fsm_last_fm || (_fsm_state == FSM_INIT_PATCH) ? 1'b1 : 1'b0);
  assign fsm_conv_on_first_fm = (_fsm_cur_conv_out_ith == 10'd0) ? 1'b1 : 1'b0;
  assign fsm_conv_on_last_fm  = _fsm_last_fm;

  //ddr request
  assign fsm_ddr_req = fsm_rd_exp || fsm_rd_data_bottom || fsm_rd_param || fsm_wr_data_top;
  
  reg       _fsm_conv_is_on_cur_clk;
  /*(*mark_debug="TRUE"*)*/reg               _fsm_need_wr_out; //current patch is the last channel, current ker_set is the last one
  /*(*mark_debug="TRUE"*)*/reg       _fsm_cur_patch_conv_done;
  /*(*mark_debug="TRUE"*)*/reg       _fsm_pooling_last_pos;
  //need wr_out
  always@(posedge clk) begin
    _fsm_conv_is_on_cur_clk <= fsm_conv_start_at_next_clk;
  end
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_need_wr_out <= 1'b0;
    end else begin
      if(fsm_done || (_fsm_state == FSM_WR_DATA)) begin
        _fsm_need_wr_out <= 1'b0;
      end else if(_fsm_last_ope_ker_set && _fsm_last_ope_fm && _fsm_conv_is_on_cur_clk && (!_fsm_last_layer)) begin
        _fsm_need_wr_out <= 1'b1;
      end
    end
  end
  //cur_patch_conv_done
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_cur_patch_conv_done <= 1'b0;
    end else begin
      if(fsm_done || (_fsm_state == FSM_WR_DATA)) begin
        _fsm_cur_patch_conv_done <= 1'b0;
      end else if(fsm_conv_last_valid && _fsm_last_ker_set && _fsm_last_fm) begin
        _fsm_cur_patch_conv_done <= 1'b1;
      end
    end
  end
  //pooling_last_pos
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_pooling_last_pos <= 1'b0;
    end else begin
      if(fsm_done || (_fsm_state == FSM_WR_DATA)) begin
        _fsm_pooling_last_pos <= 1'b0;
      end else if(fsm_pooling_last_pos) begin
        _fsm_pooling_last_pos <= 1'b1;
      end
    end
  end
//  assign _fsm_cur_patch_conv_done = (fsm_conv_last_valid && _fsm_last_ker_set && _fsm_last_fm); 
//  //fsm_need_wr_out:  current patch convolution finished, need to write data out
//  always@(posedge clk or negedge rst_n) begin
//    if(!rst_n) begin
//      _fsm_need_wr_out <= 1'b0;
//    end else begin
//      if(_fsm_last_ope_ker_set && _fsm_last_ope_fm && (_fsm_state==FSM_WAIT) && (!_fsm_last_layer)) begin
//      // should be out of CONV_OP state
//        _fsm_need_wr_out <= 1'b1;
//      end
//      if(fsm_wr_data_done && (_fsm_state == FSM_WR_DATA)) begin
//        _fsm_need_wr_out <= 1'b0;
//      end
//    end
//  end
  
  //flip-flop
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_state <= FSM_RST;
    end else begin
      _fsm_state <= _fsm_next_state;
    end
  end
  //state transition
  always@(_fsm_state or fsm_data_ready or fsm_start or fsm_rd_exp_full or _fsm_patch_full[0] or _fsm_patch_full[1] or 
          _fsm_ker_full[0] or _fsm_ker_full[1] or _fsm_next_conv_patch or _fsm_next_conv_ker or fsm_done or 
          _fsm_last_layer or fsm_conv_busy or fsm_wr_data_done or _fsm_cur_patch_conv_done or _fsm_last_ope_ker_set or
          _fsm_need_wr_out or fsm_pooling_en or _fsm_pooling_last_pos or _fsm_last_ope_fm or fsm_wr_data_x_eq_end or fsm_wr_data_y_eq_end
          )
  begin
    _fsm_next_state = FSM_RST;
    case(_fsm_state)
      FSM_RST: begin
        if(fsm_data_ready && fsm_start) begin
          _fsm_next_state = FSM_INIT_EXP;
        end else begin
          _fsm_next_state = FSM_RST;
        end
      end
      FSM_INIT_EXP: begin
        if(fsm_rd_exp_full) begin
          _fsm_next_state = FSM_INIT_PATCH;
        end else begin
          _fsm_next_state = FSM_INIT_EXP;
        end
      end
      FSM_INIT_PATCH: begin
        if(_fsm_patch_full[0]) begin
          _fsm_next_state = FSM_INIT_PARAM;
        end else begin
          _fsm_next_state = FSM_INIT_PATCH;
        end
      end
      FSM_INIT_PARAM: begin
        if(_fsm_ker_full[0]) begin
          _fsm_next_state = FSM_CONV_OP;
        end else begin
          _fsm_next_state = FSM_INIT_PARAM;
        end
      end
      FSM_CONV_OP: begin 
        if(fsm_done) begin
          _fsm_next_state = FSM_RST;
        end else if(!fsm_conv_busy) begin
          _fsm_next_state = FSM_CONV_OP;
        end else begin
          if(_fsm_last_ope_fm && _fsm_last_ope_ker_set && fsm_wr_data_x_eq_end && fsm_wr_data_y_eq_end) begin //the last conv_op round of currnet layer
            _fsm_next_state = FSM_WAIT;
          end else if(_fsm_last_ope_ker_set) begin  //conv on last ker set, read patch first
            _fsm_next_state = FSM_FETCH_PATCH;
          end else begin
            _fsm_next_state = FSM_FETCH_KER;
          end
        end
      end
      FSM_FETCH_PATCH: begin
        if(_fsm_patch_full[_fsm_next_conv_patch]) begin
          _fsm_next_state = FSM_FETCH_KER;
        end else begin
          _fsm_next_state = FSM_FETCH_PATCH;
        end
      end
      FSM_FETCH_KER: begin  // fetch ker data (without bias)
        if(_fsm_ker_full[_fsm_next_conv_ker]) begin
          _fsm_next_state = FSM_WAIT;
        end else begin
          _fsm_next_state = FSM_FETCH_KER;
        end
      end
      FSM_WAIT: begin // wait for current ker_set finishes convolution or data fectching
        if(_fsm_need_wr_out) begin
          if(_fsm_cur_patch_conv_done) begin
            if(fsm_pooling_en) begin
              if(_fsm_pooling_last_pos) begin
                _fsm_next_state = FSM_WR_DATA;
              end else begin
                _fsm_next_state = FSM_WAIT;
              end
            end else begin
              _fsm_next_state = FSM_WR_DATA;
            end
          end else begin
            _fsm_next_state = FSM_WAIT;
          end
        end else begin
          if(_fsm_last_layer && _fsm_cur_patch_conv_done) begin //next lasyer is fc, continues to calculate next pic
            _fsm_next_state = FSM_CONV_OP;
          end else if(!fsm_conv_busy) begin
            _fsm_next_state = FSM_CONV_OP;
          end else begin
            _fsm_next_state = FSM_WAIT;
          end
        end
      end
      FSM_WR_DATA: begin
        if(fsm_wr_data_done) begin
          _fsm_next_state = FSM_CONV_OP;
        end else begin
          _fsm_next_state = FSM_WR_DATA;
        end
      end
    endcase
  end
  //logic
  always@(_fsm_state or fsm_rd_exp_full or fsm_rd_data_full or fsm_rd_param_full or fsm_conv_busy or
          _fsm_x or _fsm_y or _fsm_ith_offset or _fsm_ith_fm or _fsm_next_conv_patch or _fsm_next_conv_ker or 
          fsm_rd_param_ker_ddr_addr or fsm_rd_param_bias_offset or _fsm_rd_ker_ith_offset
          ) 
  begin
    //default
    fsm_rd_exp = 1'b0;
    fsm_rd_exp_sw_on = 1'b0;
    fsm_rd_data_bottom = 1'b0;
    fsm_rd_data_x = 5'h0;
    fsm_rd_data_y = 5'h0;
    fsm_rd_data_sw_on = 1'b0;
    fsm_rd_data_ith_offset = 30'h0;
    fsm_rd_data_ith_fm = 9'h0;
    fsm_rd_param = 1'b0;
    fsm_rd_param_ker_only = 1'b1;
    fsm_rd_param_addr = 30'h0;
    fsm_rd_param_sw_on = 1'b0;
    fsm_conv_start = 1'b0;
    fsm_wr_data_top = 1'b0;
    fsm_wr_data_sw_on = 1'b0;
    
    case(_fsm_state)
      FSM_RST: begin
        fsm_rd_exp            = 1'b0;
        fsm_rd_data_bottom    = 1'b0;
        fsm_rd_param          = 1'b0;
        fsm_rd_param_ker_only = 1'b0;
      end
      FSM_INIT_EXP: begin
        if(fsm_rd_exp_full) begin
          fsm_rd_exp = 1'b0;
          fsm_rd_exp_sw_on = 1'b0;
        end else begin
          fsm_rd_exp = 1'b1;
          fsm_rd_exp_sw_on = 1'b1;
        end
      end
      FSM_INIT_PATCH: begin
        if(fsm_rd_data_full || _fsm_patch_full[_fsm_next_conv_patch]) begin
          fsm_rd_data_bottom = 1'b0;
          fsm_rd_data_x = 5'h0;
          fsm_rd_data_y = 5'h0;
        end else begin
          fsm_rd_data_bottom = 1'b1;
          fsm_rd_data_x = 5'h0;
          fsm_rd_data_y = 5'h0;
          fsm_rd_data_sw_on = 1'b1;
          fsm_rd_data_ith_offset = 30'h0;
          fsm_rd_data_ith_fm = 9'h0;
        end
      end
      FSM_INIT_PARAM: begin
        if(fsm_rd_param_full || _fsm_ker_full[_fsm_next_conv_ker]) begin
          fsm_rd_param = 1'b0;
          fsm_rd_param_addr = fsm_rd_param_ker_ddr_addr - {21'h0, fsm_rd_param_bias_offset};
          fsm_rd_param_ker_only = 1'b1;
        end else begin
          fsm_rd_param = 1'b1;
          fsm_rd_param_addr = fsm_rd_param_ker_ddr_addr - {21'h0, fsm_rd_param_bias_offset};
          fsm_rd_param_ker_only = 1'b0;
          fsm_rd_param_sw_on = 1'b1;
        end
      end
      FSM_CONV_OP: begin  //set or reset conv_start flag
        if(_fsm_patch_full[_fsm_next_conv_patch] && _fsm_ker_full[_fsm_next_conv_ker]) begin
          if(fsm_conv_busy) begin
            fsm_conv_start = 1'b0;
          end else begin
            fsm_conv_start = 1'b1;
          end
        end else begin
          fsm_conv_start = 1'b0;
        end
      end
      FSM_FETCH_PATCH: begin
        if(fsm_rd_data_full || _fsm_patch_full[_fsm_next_conv_patch]) begin
          fsm_rd_data_bottom = 1'b0;
          fsm_rd_data_x = _fsm_x;
          fsm_rd_data_y = _fsm_y;
        end
        else begin
          fsm_rd_data_bottom = 1'b1;
          fsm_rd_data_x = _fsm_x;
          fsm_rd_data_y = _fsm_y;
          fsm_rd_data_ith_offset = _fsm_ith_offset;
          fsm_rd_data_ith_fm = _fsm_ith_fm;
          fsm_rd_data_sw_on = 1'b1;
        end
      end
      FSM_FETCH_KER: begin
        if(fsm_rd_param_full || _fsm_ker_full[_fsm_next_conv_ker]) begin
          fsm_rd_param = 1'b0;
          fsm_rd_param_addr = fsm_rd_param_ker_ddr_addr + _fsm_rd_ker_ith_offset;
        end else begin
          fsm_rd_param = 1'b1;
          fsm_rd_param_addr = fsm_rd_param_ker_ddr_addr + _fsm_rd_ker_ith_offset;
          fsm_rd_param_sw_on = 1'b1;
        end
      end
//      FSM_WAIT: begin
//      end
      FSM_WR_DATA: begin
        fsm_wr_data_top = 1'b1;
        fsm_wr_data_sw_on = 1'b1;
      end
    endcase
  end
  
  //ker_set and fm counter, current convolution
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fsm_conv_cur_ker_num      <= 10'h0;
      _fsm_cur_conv_out_ith     <= 10'h0;
      _fsm_cur_conv_ope_ith     <= 10'h0;
      _fsm_cur_conv_ope_ker_num <= 10'h0;
    end else begin
      if(fsm_start && (_fsm_state == FSM_RST)) begin  //prepare data, initializing
        fsm_conv_cur_ker_num      <= 10'h0;
        _fsm_cur_conv_out_ith     <= 10'h0;
        _fsm_cur_conv_ope_ith     <= 10'h0;
        _fsm_cur_conv_ope_ker_num <= 10'h3c0; //10'd0 - 10'd64
      end else begin
        //ker_set
        if(fsm_conv_start_at_next_clk) begin
          if(_fsm_last_ope_ker_set) begin
            _fsm_cur_conv_ope_ker_num <= 10'h0; // <-x reset when last data has been writen into top data memory
          end else begin
            _fsm_cur_conv_ope_ker_num <= _fsm_cur_conv_ope_ker_num + 10'd64;
          end
        end
        if(fsm_conv_last_valid) begin
          if(_fsm_last_ker_set) begin
            fsm_conv_cur_ker_num <= 10'h0;
          end else begin
            fsm_conv_cur_ker_num <= fsm_conv_cur_ker_num + 10'd64;
          end
        end
        //fm counter
        if(fsm_conv_start_at_next_clk) begin
          if(_fsm_last_ope_ker_set) begin
            if(_fsm_last_ope_fm) begin
              _fsm_cur_conv_ope_ith <= 10'h0;
            end else begin
              _fsm_cur_conv_ope_ith <= _fsm_cur_conv_ope_ith + 10'h1;
//              $display("*%t current convolution operate on %d-th fm", $realtime, _fsm_cur_conv_ope_ith); //conv start at next clock, and last ker_set
            end
          end
        end
        if(fsm_conv_last_valid) begin
          if(_fsm_last_ker_set) begin
            if(_fsm_last_fm) begin
              _fsm_cur_conv_out_ith <= 10'h0;
            end else begin
              _fsm_cur_conv_out_ith <= _fsm_cur_conv_out_ith + 10'h1;
            end
          end
        end
      end
    end
  end

  // patch/ker_set next/conv/rd index
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_next_conv_patch  <= 1'b0;
      _fsm_next_conv_ker    <= 1'b0;
      _fsm_conv_patch_index <= 1'b0;
      _fsm_conv_ker_index   <= 1'b0;
      _fsm_rd_patch_index   <= 1'b0;
      _fsm_rd_ker_index     <= 1'b0;
    end else begin
      // reset all index
      if(_fsm_next_state==FSM_RST) begin
        _fsm_next_conv_patch  <= 1'b0;
        _fsm_next_conv_ker    <= 1'b0;
        _fsm_conv_patch_index <= 1'b0;
        _fsm_conv_ker_index   <= 1'b0;
        _fsm_rd_patch_index   <= 1'b0;
        _fsm_rd_ker_index     <= 1'b0;
      end
      if(fsm_conv_start_at_next_clk) begin
      // increase next conv patch/ker_set index after conv started
        _fsm_next_conv_ker <= _fsm_next_conv_ker + 1'b1;
        _fsm_rd_ker_index  <= _fsm_rd_ker_index + 1'b1;
        if(_fsm_sec_last_ope_ker_set) begin //or conv 1_1, conv1_2
        // operation is on second last ker_set, next clk it goes to last ker_set
          _fsm_next_conv_patch <= _fsm_next_conv_patch + 1'b1;
          _fsm_rd_patch_index  <= _fsm_rd_patch_index + 1'b1;
        end
      end
      // increase current conv patch/ker_set index after last valid output
      if(fsm_conv_last_valid) begin
        _fsm_conv_ker_index <= _fsm_conv_ker_index + 1'b1;
        if(_fsm_last_ker_set) begin
          _fsm_conv_patch_index <= _fsm_conv_patch_index + 1'b1;
        end
      end
    end
  end
  
  // patch/ker_set full flags
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_patch_full[0] <= 1'b0;
      _fsm_patch_full[1] <= 1'b0;
      _fsm_ker_full[0] <= 1'b0;
      _fsm_ker_full[1] <= 1'b0;
    end else begin
      if(fsm_rd_data_full) begin // last valid patch data
        _fsm_patch_full[_fsm_next_conv_patch] <= 1'b1;
      end
      if(fsm_rd_param_full) begin // last valid param data
        _fsm_ker_full[_fsm_next_conv_ker] <= 1'b1;
      end
      if(fsm_conv_at_last_pos) begin // last convolution position, or fsm_conv_last_valid ?
        _fsm_ker_full[_fsm_conv_ker_index] <= 1'b0; // clear flags
        if(_fsm_last_ker_set) begin
          _fsm_patch_full[_fsm_conv_patch_index] <= 1'b0; // clear flags
        end
      end
      // clear all flags
      if(_fsm_next_state==FSM_RST) begin
        _fsm_patch_full[0] <= 1'b0;
        _fsm_patch_full[1] <= 1'b0;
        _fsm_ker_full[0]   <= 1'b0;
        _fsm_ker_full[1]   <= 1'b0;
      end
    end
  end
  
  //patch bram read position(x,y)
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_rd_patch_x <= 5'h0;
      _fsm_rd_patch_y <= 5'h0;
    end else begin
      if(_fsm_state == FSM_INIT_PATCH) begin
        _fsm_rd_patch_x <= 5'h0;
        _fsm_rd_patch_y <= 5'h0;
      end else if(fsm_conv_last_valid && _fsm_last_ker_set) begin //update after current conv_op finished
        if(_fsm_last_fm) begin
          //x
          if(_fsm_rd_patch_x == fsm_rd_data_end_of_x) begin
            _fsm_rd_patch_x <= 5'h0;
          end else begin
            _fsm_rd_patch_x <= _fsm_rd_patch_x + 1'b1;
          end
          //y
          if(_fsm_rd_patch_x == fsm_rd_data_end_of_x) begin
            if(_fsm_rd_patch_y == fsm_rd_data_end_of_y) begin
              _fsm_rd_patch_y <= 5'h0;
            end else begin
              _fsm_rd_patch_y <= _fsm_rd_patch_y + 1'b1;
            end
          end
        end
      end
    end
  end
  //patach bram read address (ith fm)
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_rd_patch_ith_fm <= 9'h0;
    end else begin
      if(fsm_start && (_fsm_state == FSM_RST)) begin
        _fsm_rd_patch_ith_fm <= 9'h0;
      end else if(fsm_conv_last_valid && _fsm_last_ker_set) begin
        if(_fsm_last_fm) begin
          _fsm_rd_patch_ith_fm <= 9'h0;
        end else begin
          _fsm_rd_patch_ith_fm <= _fsm_rd_patch_ith_fm + 1'b1;
        end
      end
    end
  end
  
  //  patch position
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_x <= 5'h0;
      _fsm_y <= 5'h0;
      _fsm_wr_x <= 5'h0;
      _fsm_wr_y <= 5'h0;
    end else begin
      // update _fsm_x and _fsm_y immediately after the convolution started
      if(fsm_conv_start_at_next_clk && _fsm_sec_last_ope_ker_set) begin
        if(_fsm_last_fm) begin  // start conv operation of the last ker_set of last_fm at next clk
          // x coordinate
          if(_fsm_x == fsm_rd_data_end_of_x) begin
            _fsm_x <= 5'h0;
          end else begin
            _fsm_x <= _fsm_x + 1'b1;
          end
          // y coordinate
          if(_fsm_x == fsm_rd_data_end_of_x) begin
            if(_fsm_y == fsm_rd_data_end_of_y) begin
              _fsm_y <= 5'h0;
            end else begin
              _fsm_y <= _fsm_y + 1'b1;
            end
          end
          // convolution on the last patch
          if(_fsm_x == fsm_rd_data_end_of_x) begin
            if(_fsm_y == fsm_rd_data_end_of_y) begin
              _fsm_end <= 1'b1;
            end
          end else begin
            _fsm_end <= 1'b0;
          end
        end
      end
      // data writing, update position after last data has been written
      if(fsm_wr_data_done && (_fsm_state==FSM_WR_DATA)) begin
        // x coordinate
        if(_fsm_wr_x == fsm_rd_data_end_of_x) begin
          _fsm_wr_x <= 5'h0;
        end else begin
          _fsm_wr_x <= _fsm_wr_x + 1'b1;
        end
        // y coordinate
        if(_fsm_wr_x == fsm_rd_data_end_of_x) begin
          if(_fsm_wr_y == fsm_rd_data_end_of_y) begin
            _fsm_wr_y <= 5'h0;
          end else begin
            _fsm_wr_y <= _fsm_wr_y + 1'b1;
          end
        end
      end
    end
  end
  
  // patch address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_ith_offset <= 30'h0;
      _fsm_ith_fm <= 9'h0;
    end else begin
      if(fsm_start && (_fsm_state == FSM_RST)) begin
        _fsm_ith_offset <= 30'h0; //used in read 14x14 z-scanning order
        _fsm_ith_fm <= 9'h0;
      end else if(_fsm_sec_last_ope_ker_set && fsm_conv_start_at_next_clk) begin
        if(_fsm_last_fm) begin
          _fsm_ith_offset <= 30'h0; //used in read 14x14 z-scanning order
          _fsm_ith_fm <= 9'h0;
        end else begin
          _fsm_ith_offset <= _fsm_ith_offset + fsm_rd_data_fm_size;
          _fsm_ith_fm <= _fsm_ith_fm + 1'b1;
        end
      end
    end
  end
  
  // param address
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _fsm_rd_ker_ith_offset <= 30'h0;
    end else begin
      if(fsm_start && (_fsm_state == FSM_RST)) begin // initialization
        _fsm_rd_ker_ith_offset <= 30'h0;
      end else begin
        if(fsm_conv_start_at_next_clk) begin
          if(_fsm_sec_last_ope_ker_set && _fsm_last_fm) begin //<-- mark
            _fsm_rd_ker_ith_offset <= 30'h0;
          end else begin
            _fsm_rd_ker_ith_offset <= _fsm_rd_ker_ith_offset + DDR_PARAM_OFFSET;
          end
        end
      end
    end
  end
  
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      fsm_done <= 1'b0;
    end else begin
      if(_fsm_last_layer && (_fsm_state == FSM_WAIT) && (fsm_conv_last_valid && _fsm_last_ker_set && _fsm_last_fm)) begin
        fsm_done <= 1'b1;
      end else if(fsm_wr_data_done && (_fsm_state == FSM_WR_DATA)) begin
        if(fsm_wr_data_x_eq_end && fsm_wr_data_y_eq_end) begin
          fsm_done <= 1'b1;
        end else begin
          fsm_done <= 1'b0;
        end
      end else begin
        fsm_done <= 1'b0;
      end
    end
  end

endmodule
