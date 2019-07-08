// submodule of cnn_conv_op.v
// position
module position(
        input  wire       clk,
        input  wire       cnn_conv_rst_n,
        input  wire       _next_pos,
        output reg [3:0]  _row,
        output reg [3:0]  _col,
        output reg        _end_pos
       );

  always@(posedge clk) begin
    if(!cnn_conv_rst_n) begin
      _col <= 4'b0;
      _row <= 4'b0;
      _end_pos <= 1'b0;
    end else begin
      if(_next_pos) begin
        // row
        if(_row!=4'd13) begin
          _row <= _row+1'b1;
        end else begin
          _row <= 4'b0;
        end
        // column
        if(_col!=4'd13) begin
          if(_row == 4'd13)
            _col <= _col + 1'b1;
        end else begin
          if(_row == 4'd12)
            _end_pos <= 1'b1;
          if(_row == 4'd13)
            _col <= 4'b0;
        end
      end else begin
        _end_pos <= 1'b0;
      end
    end
  end
endmodule
