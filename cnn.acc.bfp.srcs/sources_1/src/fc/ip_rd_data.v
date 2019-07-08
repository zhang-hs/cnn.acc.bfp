/* 
  --read inner product input data from bram
*/
//`define SIM

module ip_rd_data
#(
    parameter FW = 16,
    parameter MS = 32
)
(
    `ifdef SIM
    output [12-1:0] pixel_pos_sim_o,
    output [5-1:0]  channel_pos_sim_o,
    output [4-1:0]  sec_pos_sim_o,
    `endif
    input             clk_i,
    input             rstn_i,
    input             rd_bram_start_i,
//    input             ip_oneuron_start_i,
    input  [3-1:0]    cur_layer_index_i,
    output            rd_en_o,
    output reg        switch_block_o, //block: 32 output channels, only valid in fc6_1
    output reg        ip_data_valid_o,
    output [15-1:0]   rd_addr_o,
    input  [FW-1:0]   rd_data_i,
    output reg [FW-1:0] ip_data_o
);

    //--pixel position in one output channel of 7x7
    reg [12-1:0] pixel_pos;   
    //--output channel position from 0 to 31 in one sector
    reg [5-1:0] channel_pos; 
    //--sector position from 0 to 15
    reg [4-1:0] sec_pos;     
    reg [12-1:0] pixel_end;
    wire [5-1:0] channel_end;
    wire [4-1:0] sec_end;
    reg ip_data_valid;
    
    always @(cur_layer_index_i) begin
        case(cur_layer_index_i)
            3'd0: pixel_end = 12'd48;
            3'd1: pixel_end = 12'd255;
            3'd2: pixel_end = 12'd4095;
            3'd3: pixel_end = 12'd255;
            3'd4: pixel_end = 12'd4095;
            3'd5: pixel_end = 12'd999;
            default: pixel_end = 12'd0;
        endcase
    end
    assign channel_end = (cur_layer_index_i==3'd0) ? 5'd31 : 5'd0;
    assign sec_end = (cur_layer_index_i==3'd0) ? 4'd15: 4'd0; //512 = sec_end*channel_end
    
    //--calculate pixel, channel, sector position
    //--reg rd_en; // bram enbale with bias situation
    assign rd_en_o = rd_bram_start_i;
    always @(negedge rstn_i or posedge clk_i) begin
        if (~rstn_i) begin
            // reset
            //rd_en <= 1'b0;
            pixel_pos   <= 12'd0;
            channel_pos <= 5'd0;
            sec_pos     <= 4'd0;
    
            switch_block_o  <= 1'b0;
            ip_data_valid   <= 1'b0;
        end
        else begin 
            /*
            if (rd_bram_start_i == 1'b1) begin
                //rd_en <= 1'b1;
            end
            else begin
               //rd_en <= 1'b0;
            end
            */
            if (rd_bram_start_i==1'b1) begin
                ip_data_valid  <= 1'b1;
                // data is process in pixel-wise within one 7x7 unit
                if (pixel_pos != pixel_end) begin
                    pixel_pos <= pixel_pos + 1'b1;
    
                    switch_block_o <= 1'b0;
                end
                else begin
                    if(cur_layer_index_i != 3'd0) begin
                        switch_block_o <= 1'b1;
    
                        pixel_pos   <= 12'd0;
                        sec_pos     <= 4'd0;
                        channel_pos <= 5'd0;
                    end
                    else begin
                        if (channel_pos != channel_end) begin
                            channel_pos <= channel_pos + 1'b1;
                            pixel_pos   <= 12'd0;
    
                            switch_block_o <= 1'b0;
                        end
                        else begin
                            if(sec_pos != sec_end) begin
                            sec_pos <= sec_pos + 1'b1;
                            end
                            else begin
                                sec_pos <= 4'd0;
                            end
                            pixel_pos   <= 12'd0;
                            channel_pos <= 5'd0;
    
                            switch_block_o <= 1'b1;
                        end
                    end
                end
            end
            else
                ip_data_valid <= 1'b0;
        end
    end
    
    //decide read bram address
    wire [15-1:0] pixel_offset;
    wire [15-1:0] channel_offset;
    wire [15-1:0] sec_offset;
    
    //--in first ip layer, 
    //--pixel_offset = pixel_pos * 32
    //--in following ip layer,
    //--pixel_offset = pixel_pos
    assign pixel_offset = (cur_layer_index_i==3'd0) 
                          ? {4'd0, pixel_pos[5:0], 5'd0}
                          : {3'd0, pixel_pos};
    assign channel_offset = {10'd0, channel_pos};
    //--sec_offset = sec_pos*(49*32)
    //--           = sec_pos * (32*32) +
    //--             sec_pos * (16*32) +
    //--             sec_pos * (1*32)
    assign sec_offset = {1'b0, sec_pos, 10'd0} + //--x1024 
                        {2'd0, sec_pos, 9'd0}  + //--x512
                        {6'd0, sec_pos, 5'd0};   //--x32
    assign rd_addr_o = (cur_layer_index_i==3'd0) 
                       ? pixel_offset + channel_offset + sec_offset
                       : pixel_offset;
    
    always @(negedge rstn_i or posedge clk_i) begin
        if(~rstn_i) begin
            ip_data_valid_o <= 1'b0;
            ip_data_o       <= {FW{1'b0}};
        end
        else begin
            if(ip_data_valid) begin
                ip_data_valid_o <= 1'b1;
                ip_data_o       <= rd_data_i;
            end
            else begin
                ip_data_valid_o <= 1'b0;
                ip_data_o       <= {FW{1'b0}};
            end
        end
    end

    `ifdef SIM
    assign pixel_pos_sim_o   = pixel_pos;
    assign channel_pos_sim_o = channel_pos;
    assign sec_pos_sim_o     = sec_pos;
    `endif

endmodule
