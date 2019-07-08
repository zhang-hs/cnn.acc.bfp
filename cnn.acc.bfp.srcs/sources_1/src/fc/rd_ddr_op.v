/* 
  //--read data from ddr
  //--This module just a simple control module to control
  //--rd_wr_path in rd_wr_interface
*/
module rd_ddr_op
#(
    parameter FW = 16,
    parameter WL = 32,
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512,
    parameter DATA_NUM_BITS = 20
)
(
    input                           clk_i,
    input                           rstn_i,
    //-- ddr status
    input                           init_calib_complete_i,
    //--read 
    input                           rd_en_i,
    input                           rd_ddr_done_i,
    input                           arbitor_ack_i,
    input                           ip_done_i,
    output reg                      rd_ddr_en_o,
    output reg [DATA_NUM_BITS-1:0]  rd_burst_num_o,
    output reg [ADDR_WIDTH-1:0]     rd_start_addr_o
);

    localparam PACKAGE_LEN = DATA_WIDTH / FW; //32
    localparam PACKAGE_NUM = WL / PACKAGE_LEN;  //1
    localparam RD_BURSTS = PACKAGE_NUM; //PACKAGE_NUM - 1;
    localparam RD_ADDR_STRIDE = PACKAGE_NUM * 8;

    localparam IDLE    = 3'd0;
    localparam RD_WAIT = 3'd1;
    localparam RD_PROC = 3'd2;
    localparam DONE    = 3'd3;
   /*(*mark_debug="TRUE"*)*/reg [3-1:0] _cs_;
  //localparam RD_START_ADDR = 30'h3821D0 + {3'b10, 26'd0};
//    localparam RD_START_ADDR = 30'h83821D0;
//  localparam RD_START_ADDR = 30'h1c12f8;
    localparam RD_START_ADDR = 30'h81c12f8; //30'h1c12f8 + {{4'd2}, {(ADDR_WIDTH-4){1'b0}}};

    always @(negedge rstn_i or posedge clk_i) begin
        if(~rstn_i) begin
            _cs_ <= IDLE;

            rd_start_addr_o <= RD_START_ADDR;
            rd_burst_num_o  <= {DATA_NUM_BITS{1'b0}};
        end
        else if(init_calib_complete_i) begin
            case(_cs_)
            IDLE: begin
                if(rd_en_i) begin
                    _cs_ <= RD_WAIT;

                    rd_start_addr_o <= RD_START_ADDR;
                    rd_burst_num_o  <= {DATA_NUM_BITS{1'b0}};
                end
                else begin
                    _cs_ <= IDLE;

                    rd_start_addr_o <= RD_START_ADDR;
                    rd_burst_num_o  <= {DATA_NUM_BITS{1'b0}};
                end
            end
            RD_WAIT: begin
                if(arbitor_ack_i) begin
                    _cs_ <= RD_PROC;

                    //rd_start_addr_o <= {ADDR_WIDTH{1'b0}};
                    rd_burst_num_o  <= RD_BURSTS;
                end
                else begin
                    _cs_ <= RD_WAIT;

                    rd_burst_num_o  <= {DATA_NUM_BITS{1'b0}};
                end
            end
            RD_PROC: begin
                if(rd_ddr_done_i) begin
                    _cs_ <= DONE;
                end
                else begin
                    _cs_ <= RD_PROC;
                end
            end
            DONE: begin
                if(rd_en_i && ~ip_done_i) begin
                    _cs_ <= RD_WAIT;

                    rd_burst_num_o  <= RD_BURSTS;
                    rd_start_addr_o <= rd_start_addr_o + RD_ADDR_STRIDE;
                end
                else if(~ip_done_i) begin
                    _cs_ <= DONE;

                    rd_burst_num_o <= {DATA_NUM_BITS{1'b0}};
                end
                else begin
                    _cs_ <= IDLE;

                    rd_start_addr_o <= RD_START_ADDR;
                    rd_burst_num_o <= {DATA_NUM_BITS{1'b0}};
                end
            end
            endcase
        end
    end

    always @(_cs_ or rd_ddr_done_i) begin
        case(_cs_)
        RD_PROC: begin
            if(rd_ddr_done_i) begin
                rd_ddr_en_o = 1'b0;
            end
            else begin
                rd_ddr_en_o = 1'b1;
            end
        end
        default: begin
            rd_ddr_en_o = 1'b0;
        end
        endcase
    end


endmodule
