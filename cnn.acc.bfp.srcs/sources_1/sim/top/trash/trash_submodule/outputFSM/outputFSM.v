// submodule of cnn_conv_op.v
// output fsm
module outputfsm(
        input  wire       clk,
        input  wire       cnn_conv_rst_n,
        input  wire       _output_valid,
        output reg [3:0]  cnn_conv_x,
        output reg [3:0]  cnn_conv_y,
        output wire       _last_output_pos
       );

  // output FSM -- lag num_of_false_output clock behind convolution FSM
  localparam  CONV_OUTPUT_RST = 1'b0;
  localparam  CONV_OUTPUT     = 1'b1;
  reg      _conv_out_state;
  reg      _next_out_state;
  reg      _next_output;

  assign  _last_output_pos = (cnn_conv_x == 4'd13) && (cnn_conv_y == 4'd13);
  // FF
  always@(posedge clk or negedge cnn_conv_rst_n) begin
    if(!cnn_conv_rst_n) begin
      _conv_out_state <= CONV_OUTPUT_RST;
    end else begin
      _conv_out_state <= _next_out_state;
    end
  end

  // state transition
  always@(_conv_out_state or _output_valid or _last_output_pos) begin
    _next_out_state = CONV_OUTPUT_RST;
    case(_conv_out_state)
      CONV_OUTPUT_RST: begin
        if(_output_valid) // output valid
          _next_out_state = CONV_OUTPUT;
        else
          _next_out_state = CONV_OUTPUT_RST;
      end
      CONV_OUTPUT: begin
        if( _last_output_pos  && (!_output_valid)) // last output position && next set of output is not valid
          _next_out_state = CONV_OUTPUT_RST;
        else
          _next_out_state = CONV_OUTPUT;
      end
    endcase
  end

  // logic
  always@(_conv_out_state or _output_valid) begin
    _next_output = 1'b0;
    case(_conv_out_state)
      CONV_OUTPUT_RST: begin
        if(_output_valid)
          _next_output = 1'b1;
        else
          _next_output = 1'b0;
      end
      CONV_OUTPUT: begin
        _next_output = 1'b1;
      end
    endcase
  end

  // output position
  always@(posedge clk or negedge cnn_conv_rst_n) begin
    if(!cnn_conv_rst_n) begin
      cnn_conv_x <= 4'b0;
      cnn_conv_y <= 4'b0;
    end else begin
      // output valid or convolution tail
      if(_next_output) begin
        // row
        if(cnn_conv_y!=4'd13) begin
          cnn_conv_y <= cnn_conv_y+1'b1;
        end else begin
          cnn_conv_y <= 4'h0;
        end
        // col
        if(cnn_conv_x!=4'd13) begin
          if(cnn_conv_y == 4'd13)
            cnn_conv_x <= cnn_conv_x + 1'b1;
        end else begin
          if(cnn_conv_y == 4'd13)
            cnn_conv_x <= 4'd0;
        end
      end else begin
        cnn_conv_x <= 4'd0;
        cnn_conv_y <= 4'd0;
      end
    end
  end

endmodule
