`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/03/22 21:35:27
// Design Name: 
// Module Name: prepare_ip_data_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define FP16

  extern pointer  getFileDescriptor(input string fileName);
  extern int      read16bitNum(input pointer fileDescriptor, input bit[10:0] num, output bit[64*16-1:0] data);//num:number of fp16
  
module prepare_ip_data_sim
#(
    parameter FW = 16,
    parameter CDW = 64*16,
    parameter iNN = 25088
)
(
    input                 tb_clk_i,
    input                 tb_rstn_i,
    input                 tb_en_i,

    output reg            tb_done_o,
    output reg [CDW-1:0]  tb_data_o,
    output reg [12-1:0]   tb_addr_o,
    output reg            tb_data_valid_o
);
    localparam PACKAGE_LEN =  CDW / FW;
    localparam RD_TOTAL = iNN / (PACKAGE_LEN); //392=49*8

    reg [12-1:0] rd_count;
    reg [CDW-1:0] tb_data_reg;
    
    //addr_o
//    reg [3:0]  _o_channel_set; //i ith 64*49 pixels,0~7
//    reg [5:0]  _pixel_pos;  //offset of current pixel in 7*7 tile, 0~48
    always@(rd_count) begin
      if(rd_count < 49) begin //0~48, idx:0
        tb_addr_o = rd_count;
      end else if(rd_count < 98) begin
        tb_addr_o = rd_count + 12'd49; //98 + rd_count - 49;, idx:1
      end else if(rd_count < 147) begin
        tb_addr_o = rd_count + 12'd98; //196 + rd_count - 98, idx:2
      end else if(rd_count < 196) begin
        tb_addr_o = rd_count + 12'd147;
      end else if(rd_count < 245) begin
        tb_addr_o = rd_count + 12'd196;
      end else if(rd_count < 294) begin
        tb_addr_o = rd_count + 12'd245;
      end else if(rd_count < 343) begin
        tb_addr_o = rd_count + 12'd294;
      end else if(rd_count < 392) begin
        tb_addr_o = rd_count + 12'd343;
      end else begin
        tb_addr_o = 12'd0;
      end
    end
    
  integer fd_data;
  integer data_count;
  initial begin
      fd_data = getFileDescriptor("../../../../../data/fc/fc6_1_bottom_64.txt");
      data_count = 0;
      if(fd_data == 0) begin
        $display("fd handle is NULL\n");
        $finish;
      end
  end
  
    always @(negedge tb_rstn_i or posedge tb_clk_i) begin
        if(!tb_rstn_i) begin
            rd_count   <= 12'd0;
            tb_done_o  <= 1'b0;

            tb_data_reg     <= {CDW{1'b0}};
            tb_data_valid_o <= 1'b0;
        end
        else if (tb_en_i==1'b1 && tb_done_o == 1'b0) begin
            if(rd_count==RD_TOTAL-1) begin
                tb_data_reg     <= {CDW{1'b0}};
                tb_data_valid_o <= 1'b0;
                rd_count        <= 12'd0;

                tb_done_o        <= 1'b1;

                //r = $fclose(file_handle);
            end
            else begin
                data_count = read16bitNum(fd_data, CDW/16, tb_data_reg); 
                tb_data_valid_o <= 1'b1;

                tb_done_o <= 1'b0;
            end
            if(tb_data_valid_o==1'b1)
                rd_count  <= rd_count + 1'b1;
        end
    end
//    generate
//        genvar i;
//        for(i=0; i < PACKAGE_LEN; i = i+1) begin
//            always @(tb_data_reg) begin
//`ifdef FP16
//                tb_data_o[i*FW+15:i*FW+8]    = tb_data_reg[(PACKAGE_LEN-i-1)*FW+7:(PACKAGE_LEN-i-1)*FW];
//                tb_data_o[i*FW+7:i*FW+0]     = tb_data_reg[(PACKAGE_LEN-i-1)*FW+15:(PACKAGE_LEN-i-1)*FW+8];
//`else
//                tb_data_o[i*FW+FW-1:i*FW+24] = tb_data_reg[(PACKAGE_LEN-i-1)*FW+7:(PACKAGE_LEN-i-1)*FW];
//                tb_data_o[i*FW+23:i*FW+16]   = tb_data_reg[(PACKAGE_LEN-i-1)*FW+15:(PACKAGE_LEN-i-1)*FW+8];
//                tb_data_o[i*FW+15:i*FW+8]    = tb_data_reg[(PACKAGE_LEN-i-1)*FW+23:(PACKAGE_LEN-i-1)*FW+16];
//                tb_data_o[i*FW+7:i*FW+0]     = tb_data_reg[(PACKAGE_LEN-i-1)*FW+31:(PACKAGE_LEN-i-1)*FW+23];
//`endif
//            end
//        end
//    endgenerate

  always@(tb_data_reg) begin
    tb_data_o = tb_data_reg;
  end

endmodule
