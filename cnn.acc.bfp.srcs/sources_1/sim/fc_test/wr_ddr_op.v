// write data to ddr
//`define FP16
//`timescale 1 ns / 1 ps
`include "common.v"
module wr_ddr_op
#(
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512,
    parameter DATA_NUM_BITS = 16
)
(
    input clk_i,
    input rst_i,
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

    integer FILE_HANDLE;
    integer r;

    always @(posedge rst_i or posedge clk_i) begin
        if(rst_i || ~init_calib_complete_i) begin
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
                wr_burst_num_o  <= 20'd854623;
                //wr_burst_num_o  <= 20'd1600;

                `ifdef FP16
                FILE_HANDLE = $fopen("./../test/data/ip_param_fp16.bin", "r");
                `else
                FILE_HANDLE = $fopen("./../test/data/ip_param.bin", "r");
                `endif
            end
            WR_PROC: begin
                if(wr_ddr_done_i) begin
                    _cs_ <= DONE;
                end
                else begin
                    _cs_ <= WR_PROC;

                    if(fetch_data_en_i) begin
                        r = $fread(wr_data_o, FILE_HANDLE);
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
                wr_en_o <= 1'b0;
            end
            else begin
                wr_en_o <= 1'b1;
            end
        end
        default: begin
            wr_en_o <= 1'b0;
        end
        endcase
    end

endmodule
