// write data to ddr
`define FP16
`timescale 1 ns / 1 ps

  extern pointer  getFileDescriptor(input string fileName);
  extern int      read16bitNum(input pointer fileDescriptor, input bit[10:0] num, output bit[64*16-1:0] data); //num:number of fp16

module wr_ddr_op
#(
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512,
    parameter DATA_NUM_BITS = 16
)
(
    input clk_i,
    input rst_n,
    //--ddr status
    input init_calib_complete_i,
    //--write
    input  wr_ddr_done_i,
    input  fetch_data_en_i,
    output reg wr_en_o,
    output reg [DATA_NUM_BITS-1:0] wr_burst_num_o,
    output reg [ADDR_WIDTH-1:0] wr_start_addr_o,
    output reg [DATA_WIDTH-1:0] wr_data_o
);
    `define SEEK_SET 0
    `define SEEK_CUR 1
    `define SEEK_END 2

    localparam IDLE    = 3'd0;
    localparam WR_PROC = 3'd1;
    localparam DONE    = 3'd2;
    reg [3-1:0] _cs_;

    integer fd_data;
    integer data_count;
    initial begin
        fd_data = getFileDescriptor("../../../../../data/fc/param_16f.txt");
        data_count = 0;
        if(fd_data == 0) begin
          $display("param handle is NULL\n");
          $finish;
        end
    end
    always @(negedge rst_n or posedge clk_i) begin
        if(~rst_n || ~init_calib_complete_i) begin
            _cs_ <= IDLE;

            wr_start_addr_o <= {ADDR_WIDTH{1'b0}};
            wr_data_o       <= {DATA_WIDTH{1'b0}};
            wr_burst_num_o  <= {DATA_NUM_BITS{1'b0}};
        end
        else if(init_calib_complete_i) begin
            case(_cs_)
            IDLE: begin
                _cs_ <= WR_PROC;

                wr_start_addr_o <= {{4'd2}, {(ADDR_WIDTH-4){1'b0}}};
                //wr_start_addr_o <= {ADDR_WIDTH{1'b0}};
//                wr_burst_num_o  <= 20'd854623;
                wr_burst_num_o  <= 20'd427312; //20'h68530, addr:30'h342879
            end
            WR_PROC: begin
                if(wr_ddr_done_i) begin
                    _cs_ <= DONE;
                end
                else begin
                    _cs_ <= WR_PROC;

                    if(fetch_data_en_i) begin
                      data_count = read16bitNum(fd_data, DATA_WIDTH/16, wr_data_o); 
                    end
                end
            end
            DONE: begin
                _cs_ <= DONE;
            end
            endcase
        end
    end

    always @(_cs_ or wr_ddr_done_i) begin
        case(_cs_)
        WR_PROC: begin
            if(wr_ddr_done_i) begin
                wr_en_o = 1'b0;
            end else begin
              wr_en_o = 1'b1;
            end
        end
        default: begin
            wr_en_o = 1'b0;
        end
        endcase
    end

endmodule
