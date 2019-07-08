/* 
  --top model for inner product 
*/

// `timescale 1 ns / 1 ps
//`define SIM

module inner_product
#(
    parameter EW = 5,   //expoent width
    parameter MW = 10,  //mantissa width
    parameter FW = 16,  //float16 width
    parameter MS = 32,  //
    parameter WL = 32,  
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512,
    parameter DATA_NUM_BITS = 20
)
(
    input                     clk_i,
    input                     rstn_i,
    input                     init_calib_complete_i,
    input                     wr_ddr_done_i,
    `ifdef SIM
    output [12-1:0]           pixel_pos_sim_o,
    output [5-1:0]            channel_pos_sim_o,
    output [4-1:0]            sec_pos_sim_o,
    output [FW-1:0]           ip_data_sim_o,
    output                    ip_data_valid_sim_o,
    output reg [15-1:0]       ip_bram_addr_sim_o,
    output [FW-1:0]           ip_weight_sim_o,
    output                    ip_weight_valid_sim_o,
    output [FW-1:0]           ip_bias_sim_o,
    output                    ip_bias_valid_sim_o,
    output reg                rd_buf_done_sim_o,
    output [FW-1:0]           accum_data_sim_o,
    `endif
    input                     ip_en_i,  //data from conv are valid
    input                     exp_done_i,
    output [3-1:0]            cur_layer_index_o,
    output                    ip_layer_done_o,
    output                    ip_proc_o,
    output                    ip_done_o,
    output                    batch_done_o, //disabled
    //--interface with SRAM
    output                    rd_bram_en_o,
    output [15-1:0]           rd_bram_addr_o,
    input  [FW-1:0]           rd_bram_data_i,
    //--enable read ddr
    input                     arbitor_ack_i,
    input                     rd_ddr_done_i,
    output                    arbitor_rd_en_o,
    output                    rd_ddr_en_o,
    output [DATA_NUM_BITS-1:0]rd_burst_num_o,
    output [ADDR_WIDTH-1:0]   rd_start_addr_o,
    input                     wr_buf_done_i,
    //--interface with param buffer
    output                    wr_buf_sel_o,
    output                    conv_buf_free_o,
    output [2-1:0]            param_buf_full_o,
    output [2-1:0]            param_buf_busy_o,
    output [9-1:0]            ip_buf_addr_o,
    input  [FW-1:0]           ip_param_i,
    //--interface with output buffer
    output                    output_valid_o,
    output                    output_en_o,
    //--output [NN-1:0] neuron_en_o,
    output [12-1:0]           ip_addr_o,
    output [FW-1:0]           ip_data_o
);

    wire              ip_oneuron_start;
    wire              ip_oneuron_done;
    wire [2-1:0]      param_buf_full;
    wire              rd_bram_start;
    wire              rd_buf_en;
    wire              rd_buf_done;
    wire [3-1:0]      cur_layer_index;
    wire [13-1:0]     onn;
    wire              relu_en;
    wire              block_en;
    wire              rd_ddr_op_en;
    wire              fma_data_ready;
    
    assign cur_layer_index_o = cur_layer_index;
    
    //====================================
    //  inner_product controller
    //====================================
    ip_control
    #(
        .LAYER_NUM(2'b10),
        .WL       (WL)
    )
    ip_control_U
    (
        .clk_i (clk_i ),
        .rstn_i(rstn_i),
        .ip_en_i           (ip_en_i         ),
        .exp_done_i        (exp_done_i      ),
        .wr_ddr_done_i     (wr_ddr_done_i   ),
        .wr_buf_done_i     (wr_buf_done_i   ),
        .param_buf_full_i  (param_buf_full  ),
        .rd_bram_start_o   (rd_bram_start   ),
        .rd_bram_en_i      (rd_bram_en_o    ),
        .rd_buf_done_i     (rd_buf_done     ),
        .ip_buf_addr_i     (ip_buf_addr_o   ),
        .output_en_i       (output_en_o     ),
        .rd_buf_en_o       (rd_buf_en       ),
        .rd_ddr_en_o       (rd_ddr_op_en    ),
        .arbitor_rd_en_o   (arbitor_rd_en_o ),
        .cur_layer_index_o (cur_layer_index ),
        .relu_en_o         (relu_en         ),
        .block_en_o        (block_en        ),
        .ip_oneuron_start_o(ip_oneuron_start),
        .ip_oneuron_done_o (ip_oneuron_done ),
        .onn_o             (onn             ),
        .ip_layer_done_o   (ip_layer_done_o ),
        .conv_buf_free_o   (conv_buf_free_o ),
        .ip_proc_o         (ip_proc_o       ),
        .ip_done_o         (ip_done_o       ),
        .batch_done_o      (batch_done_o    )
    );
    
    //====================================
    //  read input data from bram
    //====================================
    wire          ip_data_valid;
    wire [FW-1:0] ip_data_in;
    wire          rd_bram_en;
    wire          switch_block;
    wire          rd_bram_start_buf_done;
    assign rd_bram_start_buf_done = rd_bram_start&(~rd_buf_done);
    ip_rd_data
    #(
        .FW(FW),
        .MS(MS)
    )
    ip_rd_data_U
    (
        `ifdef SIM
        .pixel_pos_sim_o   (pixel_pos_sim_o             ),
        .channel_pos_sim_o (channel_pos_sim_o           ),
        .sec_pos_sim_o     (sec_pos_sim_o               ),
        `endif
        .clk_i (clk_i),
        .rstn_i(rstn_i),
        .rd_bram_start_i   (rd_bram_start_buf_done      ),
//        .ip_oneuron_start_i(ip_oneuron_start            ),
        .cur_layer_index_i (cur_layer_index             ),
        .rd_en_o           (rd_bram_en                  ),
        .rd_addr_o         (rd_bram_addr_o              ),
        .rd_data_i         (rd_bram_data_i              ),
        .switch_block_o    (switch_block                ),
        .ip_data_valid_o   (ip_data_valid               ),
        .ip_data_o         (ip_data_in                  )
    );
    
    //====================================
    //  read param from ddr
    //====================================
    rd_ddr_op
    #(
        .FW           (FW           ),
        .WL           (WL           ),
        .ADDR_WIDTH   (ADDR_WIDTH   ),
        .DATA_WIDTH   (DATA_WIDTH   ),
        .DATA_NUM_BITS(DATA_NUM_BITS)
    )
    rd_ddr_op_U
    (
        .clk_i (clk_i ),
        .rstn_i(rstn_i),
        .init_calib_complete_i(init_calib_complete_i),
        .rd_en_i              (rd_ddr_op_en),
        .arbitor_ack_i        (arbitor_ack_i),
        .rd_ddr_done_i        (rd_ddr_done_i),
        .ip_done_i            (ip_done_o),
        .rd_ddr_en_o          (rd_ddr_en_o),
        .rd_burst_num_o       (rd_burst_num_o),
        .rd_start_addr_o      (rd_start_addr_o)
    );
    
    //====================================
    //  param buf control
    //====================================
    wire [FW-1:0] ip_weight;
    wire          ip_weight_valid;
    wire [FW-1:0] ip_bias;
    wire          ip_bias_valid;
    ip_param_buf_control
    #(
        .FW(FW),
        .WL(WL) // weight number
    )
    ip_param_buf_control_U
    (
        .clk_i (clk_i ),
        .rstn_i(rstn_i),
        .rd_buf_en_i         (rd_buf_en       ),
        .wr_buf_done_i       (wr_buf_done_i   ),
        .ip_done_i           (ip_done_o       ),
        .ip_oneuron_start_i  (ip_oneuron_start),
        .ip_oneuron_done_i   (ip_oneuron_done ),
        .ip_param_i          (ip_param_i      ),
        .rd_buf_done_o       (rd_buf_done     ),
        .ip_buf_addr_o       (ip_buf_addr_o   ),
        .ip_weight_o         (ip_weight       ),
        .ip_weight_valid_o   (ip_weight_valid ),
        .wr_buf_sel_o        (wr_buf_sel_o    ),
        .param_buf_full_o    (param_buf_full  ),
        .param_buf_busy_o    (param_buf_busy_o),
        .ip_bias_o           (ip_bias         ),
        .ip_bias_valid_o     (ip_bias_valid   )
    );
    
    //====================================
    //  calculation unit
    //====================================
    ip_mul_add
    #(
        .EW(EW),
        .MW(MW),
        .FW(FW)
    )
    ip_mul_add_U
    (
        .clk_i (clk_i ),
        .rstn_i(rstn_i),
        `ifdef SIM
        .weight_valid_sim_o (ip_weight_valid_sim_o),
        .weight_sim_o       (ip_weight_sim_o      ),
        .bias_valid_sim_o   (ip_bias_valid_sim_o  ),
        .bias_sim_o         (ip_bias_sim_o        ),
        .data_valid_sim_o   (ip_data_valid_sim_o  ),
        .data_sim_o         (ip_data_sim_o        ),
        .accum_data_sim_o   (accum_data_sim_o     ),
        `endif
        .bend_i             (2'b11           ),
        .block_en_i         (block_en        ),
        .switch_block_i     (switch_block    ),
        .onn_i              (onn             ),
        .relu_en_i          (relu_en         ),
        .ip_data_i          (ip_data_in      ),
        .ip_data_valid_i    (ip_data_valid   ),
        .ip_weight_i        (ip_weight       ),
        .ip_weight_valid_i  (ip_weight_valid ),
        .ip_bias_i          (ip_bias         ),
        .ip_bias_valid_i    (ip_bias_valid   ),
        .ip_oneuron_done_i  (ip_oneuron_done ),
        .accum_data_o       (ip_data_o       ),
        .accum_addr_o       (ip_addr_o       ),
        .output_valid_o     (output_valid_o  ),
        .output_en_o        (output_en_o     )
    );
    
    assign param_buf_full_o = param_buf_full;
    assign rd_bram_en_o     = rd_bram_en & (~rd_buf_done);
    
    //====================================
    //  simulation port
    //====================================
    `ifdef SIM
      //--`ifdef FP16
        //--assign ip_data_sim_o[15:8]   = ip_data_in[7:0];
        //--assign ip_data_sim_o[7:0]    = ip_data_in[15:8];
        //--assign ip_data_valid_sim_o   = ip_data_valid;
        //--assign ip_weight_sim_o[15:8] = ip_weight[7:0];
        //--assign ip_weight_sim_o[7:0]  = ip_weight[15:8];
        //--assign ip_weight_valid_sim_o = ip_weight_valid;
        //--assign ip_bias_sim_o[15:8]   = ip_bias[7:0];
        //--assign ip_bias_sim_o[7:0]    = ip_bias[15:8];
        //--assign ip_bias_valid_sim_o   = ip_bias_valid;
      //--`else
        //--assign ip_data_sim_o[31:24] = ip_data_in[7:0];
        //--assign ip_data_sim_o[23:16] = ip_data_in[15:8];
        //--assign ip_data_sim_o[15:8]  = ip_data_in[23:16];
        //--assign ip_data_sim_o[7:0]   = ip_data_in[31:24];
        //--assign ip_data_valid_sim_o = ip_data_valid;
        //--assign ip_weight_sim_o[31:24] = ip_weight[7:0];
        //--assign ip_weight_sim_o[23:16] = ip_weight[15:8];
        //--assign ip_weight_sim_o[15:8]  = ip_weight[23:16];
        //--assign ip_weight_sim_o[7:0]   = ip_weight[31:24];
        // assign ip_weight_sim_o       = ip_weight;
        //--assign ip_weight_valid_sim_o = ip_weight_valid;
        //--assign ip_bias_sim_o[31:24] = ip_bias[7:0];
        //--assign ip_bias_sim_o[23:16] = ip_bias[15:8];
        //--assign ip_bias_sim_o[15:8]  = ip_bias[23:16];
        //--assign ip_bias_sim_o[7:0]   = ip_bias[31:24];
        // assign ip_bias_sim_o       = ip_bias;
        //--assign ip_bias_valid_sim_o = ip_bias_valid;
      //--`endif
    
        always @(negedge rstn_i or posedge clk_i) begin
            if(~rstn_i) begin
                ip_bram_addr_sim_o <= 15'd0;
                rd_buf_done_sim_o <= 1'b0;
            end
            else begin
                ip_bram_addr_sim_o <= rd_bram_addr_o;
                rd_buf_done_sim_o <= rd_buf_done;
            end
        end
    `endif
endmodule
