// ---------------------------------------------------
// File       : readFile.v
//
// Description: read data from file
//
// Version    : 1.0
// ---------------------------------------------------

`define NULL 0
`timescale 1ns/1ps
module readFile;

  integer     fd_data;
  integer     fd_write;
  integer     char_count;
  integer     total_count;
  reg [31:0]  data1;

  initial begin
    total_count = 0;
    fd_data     = $fopen("weight.txt","rb");
    fd_write    = $fopen("weight.output.txt","wb");
    if(fd_data == `NULL || fd_write == `NULL) begin
      $display("fd_data handle was NULL\n");
      $finish;
    end else begin
      $display("fd_data read\n");
      while(!$feof(fd_data)) begin
        char_count  = $fread(data1, fd_data);
        total_count = total_count + char_count;
        $display("read count: %d, data: %h\n", char_count, data1);
        $fwrite(fd_write, "%h\n", data1);
      end
      $display("total count: %d\n", total_count);
    end
    $fclose(fd_data);
  end

  /*
  always@(posedge clk) begin
    char_count = $fscanf(fd_data, "%h", data1);
    if(!$feof(fd_data)) begin
      // transform type of data1
    end
  end
  */

endmodule
