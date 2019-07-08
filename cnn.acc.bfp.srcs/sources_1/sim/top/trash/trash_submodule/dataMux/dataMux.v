// submodule of cnn_conv_op.v
// dataMux
module data_multiplexer#(
        parameter   EXP = 8,
        parameter   MAN = 23,
        parameter   K_W = 3,
        parameter   DATA_H = 16,
        parameter   DATA_W = 16
       )(
        input  wire                      clk,
        input  wire                      cnn_conv_rst_n,
        input  wire                      _next_pos,
        output reg [3:0]                 _col,
        output reg [3:0]                 _row,
        output reg [(EXP+MAN+1)*K_W-1:0] _data0,
        output reg [(EXP+MAN+1)*K_W-1:0] _data1
       );
  // memory(reg array)
  reg [EXP+MAN:0]    _bottom00[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom01[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom02[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom03[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom04[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom05[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom06[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom07[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom08[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom09[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom10[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom11[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom12[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom13[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom14[0:DATA_H-1];
  reg [EXP+MAN:0]    _bottom15[0:DATA_H-1];

  initial begin
    reg [MAN+EXP:0] i;
    for(i={(MAN+EXP){1'b0}}; i<DATA_H; i=i+1'b1) begin
      _bottom00[i] = 15'd 0+i*15'd16;
      _bottom01[i] = 15'd 1+i*15'd16;
      _bottom02[i] = 15'd 2+i*15'd16;
      _bottom03[i] = 15'd 3+i*15'd16;
      _bottom04[i] = 15'd 4+i*15'd16;
      _bottom05[i] = 15'd 5+i*15'd16;
      _bottom06[i] = 15'd 6+i*15'd16;
      _bottom07[i] = 15'd 7+i*15'd16;
      _bottom08[i] = 15'd 8+i*15'd16;
      _bottom09[i] = 15'd 9+i*15'd16;
      _bottom10[i] = 15'd10+i*15'd16;
      _bottom11[i] = 15'd11+i*15'd16;
      _bottom12[i] = 15'd12+i*15'd16;
      _bottom13[i] = 15'd13+i*15'd16;
      _bottom14[i] = 15'd14+i*15'd16;
      _bottom15[i] = 15'd15+i*15'd16;
    end
  end

  // position
  always@(posedge clk) begin
    if(!cnn_conv_rst_n) begin
      _col <= 4'b0;
      _row <= 4'b0;
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
          if(_row == 4'd13)
            _col <= 4'b0;
        end
      end
    end
  end

  // data multiplexer
  always@(_row or _col or _bottom00 or _bottom01 or _bottom02 or _bottom03 or
          _bottom04 or _bottom05 or _bottom06 or _bottom07 or _bottom08 or _bottom09 or
          _bottom10 or _bottom11 or _bottom12 or _bottom13 or _bottom14 or _bottom15) begin
    _data0 = {((EXP+MAN+1)*K_W){1'b0}};
    _data1 = {((EXP+MAN+1)*K_W){1'b0}};
    case(_col)
      4'd0:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom13[4'd14],_bottom14[4'd14],_bottom15[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom13[4'd15],_bottom14[4'd15],_bottom15[4'd15]};
        end
        _data0 = {_bottom00[_row],_bottom01[_row],_bottom02[_row]};
      end
      4'd1:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom00[4'd14],_bottom01[4'd14],_bottom02[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom00[4'd15],_bottom01[4'd15],_bottom02[4'd15]};
        end
        _data0 = {_bottom01[_row],_bottom02[_row],_bottom03[_row]};
      end
      4'd2:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom01[4'd14],_bottom02[4'd14],_bottom03[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom01[4'd15],_bottom02[4'd15],_bottom03[4'd15]};
        end
        _data0 = {_bottom02[_row],_bottom03[_row],_bottom04[_row]};
      end
      4'd3:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom02[4'd14],_bottom03[4'd14],_bottom04[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom02[4'd15],_bottom03[4'd15],_bottom04[4'd15]};
        end
        _data0 = {_bottom03[_row],_bottom04[_row],_bottom05[_row]};
      end
      4'd4:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom03[4'd14],_bottom04[4'd14],_bottom05[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom03[4'd15],_bottom04[4'd15],_bottom05[4'd15]};
        end
        _data0 = {_bottom04[_row],_bottom05[_row],_bottom06[_row]};
      end
      4'd5:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom04[4'd14],_bottom05[4'd14],_bottom06[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom04[4'd15],_bottom05[4'd15],_bottom06[4'd15]};
        end
        _data0 = {_bottom05[_row],_bottom06[_row],_bottom07[_row]};
      end
      4'd6:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom05[4'd14],_bottom06[4'd14],_bottom07[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom05[4'd15],_bottom06[4'd15],_bottom07[4'd15]};
        end
        _data0 = {_bottom06[_row],_bottom07[_row],_bottom08[_row]};
      end
      4'd7:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom06[4'd14],_bottom07[4'd14],_bottom08[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom06[4'd15],_bottom07[4'd15],_bottom08[4'd15]};
        end
        _data0 = {_bottom07[_row],_bottom08[_row],_bottom09[_row]};
      end
      4'd8:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom07[4'd14],_bottom08[4'd14],_bottom09[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom07[4'd15],_bottom08[4'd15],_bottom09[4'd15]};
        end
        _data0 = {_bottom08[_row],_bottom09[_row],_bottom10[_row]};
      end
      4'd9:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom08[4'd14],_bottom09[4'd14],_bottom10[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom08[4'd15],_bottom09[4'd15],_bottom10[4'd15]};
        end
        _data0 = {_bottom09[_row],_bottom10[_row],_bottom11[_row]};
      end
      4'd10:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom09[4'd14],_bottom10[4'd14],_bottom11[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom09[4'd15],_bottom10[4'd15],_bottom11[4'd15]};
        end
        _data0 = {_bottom10[_row],_bottom11[_row],_bottom12[_row]};
      end
      4'd11:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom10[4'd14],_bottom11[4'd14],_bottom12[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom10[4'd15],_bottom11[4'd15],_bottom12[4'd15]};
        end
        _data0 = {_bottom11[_row],_bottom12[_row],_bottom13[_row]};
      end
      4'd12:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom11[4'd14],_bottom12[4'd14],_bottom13[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom11[4'd15],_bottom12[4'd15],_bottom13[4'd15]};
        end
        _data0 = {_bottom12[_row],_bottom13[_row],_bottom14[_row]};
      end
      4'd13:begin
        if(_row == 4'd0) begin
          _data1 = {_bottom12[4'd14],_bottom13[4'd14],_bottom14[4'd14]};
        end else if(_row == 4'd1) begin
          _data1 = {_bottom12[4'd15],_bottom13[4'd15],_bottom14[4'd15]};
        end
        _data0 = {_bottom13[_row],_bottom14[_row],_bottom15[_row]};
      end
    endcase
  end

endmodule
