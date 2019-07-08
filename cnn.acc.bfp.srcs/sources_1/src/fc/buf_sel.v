// ip buffer selector for read and write

module buf_sel
#(
    parameter FW = 32
)
(
    input [3-1:0] cur_layer_index_i,

    // enable
    input               rd_bram_en_i,
    input               wr_bram_en_i,
    output reg          conv_buf_en_o, //conv_buf enable
    output reg          ip_buf_0_en_o, //ip_buf_0 enable
    output reg          ip_buf_1_en_o, //ip_buf_1 enable

    // read
    input  [FW-1:0]     conv_buf_data_i, //data read from conv_buf
    input  [FW-1:0]     ip_buf_0_data_i, //...ip_buf_0
    input  [FW-1:0]     ip_buf_1_data_i, //...ip_buf1
    output reg [FW-1:0] ip_data_in_o,    //output data read to module inner_product 

    // write
    input  [FW-1:0]     ip_data_out_i,    //data from module inner_product
    input               ip_data_valid_i,
    output reg          ip_buf_0_valid_o,
    output reg [FW-1:0] ip_buf_0_data_o,
    output reg          ip_buf_1_valid_o,
    output reg [FW-1:0] ip_buf_1_data_o,

    // address
    input  [15-1:0]     rd_bram_addr_i,
    input  [12-1:0]     wr_bram_addr_i,
    output reg [15-1:0] conv_buf_addr_o,
    output reg [12-1:0] ip_buf_0_addr_o,
    output reg [10-1:0] ip_buf_1_addr_o
);

    always @(cur_layer_index_i or rd_bram_en_i or rd_bram_addr_i or wr_bram_en_i or wr_bram_addr_i or 
             conv_buf_data_i or ip_buf_0_data_i or ip_buf_1_data_i or ip_data_out_i or ip_data_valid_i or ip_data_out_i) begin
        case(cur_layer_index_i)
        3'd0: begin
            // read
            conv_buf_en_o   = rd_bram_en_i;
            conv_buf_addr_o = rd_bram_addr_i;
            ip_data_in_o    = conv_buf_data_i;

            // write
            ip_buf_1_en_o    = wr_bram_en_i;
            ip_buf_1_addr_o  = wr_bram_addr_i[9:0];
            ip_buf_1_valid_o = ip_data_valid_i;
            ip_buf_1_data_o  = ip_data_out_i;

            // idle buffer
            ip_buf_0_en_o    = 1'b0;
            ip_buf_0_addr_o  = 12'd0;
            ip_buf_0_valid_o = 1'b0;
            ip_buf_0_data_o  = {FW{1'b0}};
        end
        3'd1: begin
            // read
            ip_buf_1_en_o    = rd_bram_en_i;
            ip_buf_1_addr_o  = rd_bram_addr_i[9:0];
            ip_buf_1_valid_o = 1'b0;
            ip_buf_1_data_o  = {FW{1'b0}};
            ip_data_in_o     = ip_buf_1_data_i;

            // write
            ip_buf_0_en_o    = wr_bram_en_i;
            ip_buf_0_addr_o  = wr_bram_addr_i;
            ip_buf_0_valid_o = ip_data_valid_i;
            ip_buf_0_data_o  = ip_data_out_i;

            // idle buffer
            conv_buf_en_o    = 1'b0;
            conv_buf_addr_o  = 15'd0;
        end
        3'd2: begin
            // read
            ip_buf_0_en_o    = rd_bram_en_i;
            ip_buf_0_addr_o  = rd_bram_addr_i[11:0];
            ip_buf_0_valid_o = 1'b0;
            ip_buf_0_data_o  = {FW{1'b0}};
            ip_data_in_o     = ip_buf_0_data_i;

            // write
            ip_buf_1_en_o    = wr_bram_en_i;
            ip_buf_1_addr_o  = wr_bram_addr_i[9:0];
            ip_buf_1_valid_o = ip_data_valid_i;
            ip_buf_1_data_o  = ip_data_out_i;

            // idle buffer
            conv_buf_en_o    = 1'b0;
            conv_buf_addr_o  = 15'd0;            
        end
        3'd3: begin
            // read
            ip_buf_1_en_o    = rd_bram_en_i;
            ip_buf_1_addr_o  = rd_bram_addr_i[9:0];
            ip_buf_1_valid_o = 1'b0;
            ip_buf_1_data_o  = {FW{1'b0}};
            ip_data_in_o     = ip_buf_1_data_i;

            // write
            ip_buf_0_en_o    = wr_bram_en_i;
            ip_buf_0_addr_o  = wr_bram_addr_i;
            ip_buf_0_valid_o = ip_data_valid_i;
            ip_buf_0_data_o  = ip_data_out_i;

            // idle buffer
            conv_buf_en_o    = 1'b0;
            conv_buf_addr_o  = 15'd0;            
        end
        3'd4: begin
            // read
            ip_buf_0_en_o    = rd_bram_en_i;
            ip_buf_0_addr_o  = rd_bram_addr_i[11:0];
            ip_buf_0_valid_o = 1'b0;
            ip_buf_0_data_o  = {FW{1'b0}};
            ip_data_in_o     = ip_buf_0_data_i;

            // write
            ip_buf_1_en_o    = wr_bram_en_i;
            ip_buf_1_addr_o  = wr_bram_addr_i[9:0];
            ip_buf_1_valid_o = ip_data_valid_i;
            ip_buf_1_data_o  = ip_data_out_i;

            // idle buffer
            conv_buf_en_o    = 1'b0;
            conv_buf_addr_o  = 15'd0;                    
        end
        default: begin
            // all are idle
             ip_buf_0_en_o   = 1'b0;
            ip_buf_0_addr_o  = 12'd0;
            ip_buf_0_valid_o = 1'b0;
            ip_buf_0_data_o  = {FW{1'b0}};
            ip_data_in_o     = {FW{1'b0}};

            ip_buf_1_en_o    = 1'b0;
            ip_buf_1_addr_o  = 10'd0;
            ip_buf_1_valid_o = 1'b0;
            ip_buf_1_data_o  = {FW{1'b0}};

            conv_buf_en_o    = 1'b0;
            conv_buf_addr_o  = 15'd0;                           
        end
        endcase
    end

endmodule
