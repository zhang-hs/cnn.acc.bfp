//`define SIM

module ip_param_buf
#(
    parameter FW = 16,
    parameter DW = 512,
    parameter WL = 32
)
(
    input  clk_i,
    input  rstn_i,
    //--write into buf
    input            en_i,
    input            wr_buf_sel_i,
    input  [2-1:0]   param_buf_full_i,
    input  [DW-1:0]  param_i,
    //--read from buf
    input  [2-1:0]   param_buf_busy_i,
    input  [9-1:0]   ip_buf_addr_i,
    output           wr_buf_done_o,
    output [FW-1:0]  ip_param_o    
);
    localparam  PACKAGE_LEN = DW / FW; //32
    localparam  PACKAGE_NUM = WL / PACKAGE_LEN; //1

    // internel register array
    reg [FW-1:0] _param0_[0:WL-1];
    reg [FW-1:0] _param1_[0:WL-1];

    reg [5-1:0] rd_count;

`ifdef SIM
   initial begin
     $vcdplusmemon(_param0_);
     $vcdplusmemon(_param1_);
   end 
`endif
    // receive data
    assign wr_buf_done_o = rd_count == PACKAGE_NUM;
    always @(posedge clk_i or negedge rstn_i) begin
        if(rstn_i==1'b0) begin
            rd_count <= 5'd0;
        end
        else if(en_i == 1'b1) begin
            if(rd_count != PACKAGE_NUM) begin
                rd_count <= rd_count + 1'b1;
            end 
            else begin
                rd_count <= 5'd0;
            end
        end
        else if(rd_count == PACKAGE_NUM) begin
            rd_count <= 5'd0;
        end
    end

    genvar i;
    genvar j;
    generate
        for(j = 0; j < PACKAGE_LEN; j = j + 1)
        begin: receive_data
            always @(negedge rstn_i or posedge clk_i) begin
                if(rstn_i==1'b0) begin
                    _param0_[j] <= {FW{1'b0}};
                    _param1_[j] <= {FW{1'b0}};
                end
                else if(en_i==1'b1) begin
                    if (param_buf_full_i[0]==1'b0 && wr_buf_sel_i==1'b0)
                        // _param0_[j] <= param_i[(PACKAGE_LEN-j)*FW-1:
                                               // (PACKAGE_LEN-1-j)*FW];
                        _param0_[j] <= param_i[(j+1)*FW-1:j*FW];
                    else if(param_buf_full_i[1]==1'b0 && wr_buf_sel_i==1'b1)
                        // _param1_[j] <= param_i[(PACKAGE_LEN-j)*FW-1:
                        //                        (PACKAGE_LEN-1-j)*FW];
                        _param1_[j] <= param_i[(j+1)*FW-1:j*FW];
                end
            end
        end
    endgenerate
    
//    generate //???, unvalid?
//        for(i = PACKAGE_NUM-1; i > 0; i = i - 1)
//        begin: shift_data
//            for(j = 0; j < PACKAGE_LEN; j = j + 1)
//            begin
//                always @(negedge rstn_i or posedge clk_i) begin
//                    if(rstn_i==1'b0) begin
//                        _param0_[i*PACKAGE_LEN+j] <= {FW{1'b0}};
//                        _param1_[i*PACKAGE_LEN+j] <= {FW{1'b0}};
//                    end
//                    else if(en_i==1'b1 && wr_buf_sel_i==1'b0) begin
//                        if(param_buf_full_i[0]==1'b0)
//                            _param0_[i*PACKAGE_LEN+j] <= 
//                            _param0_[(i-1)*PACKAGE_LEN+j];
//                        else if(param_buf_full_i[1]==1'b0 && wr_buf_sel_i==1'b1)
//                            _param1_[i*PACKAGE_LEN+j] <= 
//                            _param1_[(i-1)*PACKAGE_LEN+j];
//                    end
//                end
//            end
//        end
//    endgenerate

    // output data
    assign ip_param_o = param_buf_busy_i[0]==1'b1 
                        ? _param0_[ip_buf_addr_i]
                        : (param_buf_busy_i[1]==1'b1
                          ? _param1_[ip_buf_addr_i]
                          : {FW{1'b0}});
endmodule
