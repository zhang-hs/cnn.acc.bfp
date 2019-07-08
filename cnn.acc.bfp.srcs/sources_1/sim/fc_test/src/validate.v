`include "common.v"
`include "sim_tb.inc"
module validate
#(
    parameter FW = 32,
    parameter WL = 32
)
(
    input sim_clk_i,
    input sim_rstn_i,
    //--necessary sim signal
    input  sim_ip_done_i,
    input  sim_batch_done_i,
    input  sim_exp_done_i,
    input  sim_ip_data_in_valid_i,
    input  sim_ip_bias_valid_i,
    input  sim_ip_weight_valid_i,
    input  sim_ip_out_valid_i,
    input  sim_ip_out_en_i,
    input  sim_rd_buf_done_i,
    input  sim_ip_layer_done_i,
    input  [12-1:0] sim_pixel_pos_i,
    input  [5-1:0]  sim_channel_pos_i,
    input  [4-1:0]  sim_sec_pos_i,
    input  [FW-1:0] sim_ip_data_in_i,
    input  [FW-1:0] sim_ip_bias_i,
    input  [FW-1:0] sim_ip_weight_i,
    input  [15-1:0] sim_ip_bram_addr_i,
    input  [FW-1:0] sim_accum_data_i,
    input  [FW-1:0] sim_ip_data_out_i,
    input  [12-1:0] sim_ip_addr_out_i,
    input  [3-1:0]  sim_cur_layer_index_i,
    input  [9-1:0]  sim_ip_buf_addr_i
);

    integer r;
    //integer file_handle = 0;
    reg  [15-1:0] ip_data_pos; 
    reg  [32-1:0] block_pos;
    reg  [32-1:0] file_pos;
    reg  [12-1:0] pixel_pos_sim;
    reg  [10-1:0] channel_pos_sim;
    reg  [4-1:0]  sec_pos_sim;
    reg  [12-1:0] pixel_pos_reg_sim;
    reg  [10-1:0] channel_pos_reg_sim;
    reg  [4-1:0]  sec_pos_reg_sim;

    reg  err_out_flag;
    reg  out_flag;
    reg  in_flag;
    reg  param_flag;
    reg  nsr_flag;
    reg  [32-1:0] err_energy_sim;
    reg  [32-1:0] sig_energy_sim;
    reg  [32-1:0] ip_data_fp32_sim;
    reg  [32-1:0] sim_ip_data_in_fp32; 

    //--record process
    always @(posedge sim_clk_i or negedge sim_rstn_i) begin
        if(sim_ip_out_valid_i)
            $display("%t] %dth layer: %dth neuron finished.", $time, 
                     sim_cur_layer_index_i, sim_ip_addr_out_i);
    end

    always @(sim_ip_buf_addr_i or block_pos) begin
        file_pos = block_pos + WL-1 - {23'd0, sim_ip_buf_addr_i};
    end
    
    //--transfer to float32
    `ifdef FP16
    always @(sim_ip_data_out_i or sim_ip_data_in_i) begin
        to_float32(sim_ip_data_out_i, ip_data_fp32_sim);
        to_float32(sim_ip_data_in_i, sim_ip_data_in_fp32);
    end
    `endif
    always @(negedge sim_rstn_i or posedge sim_clk_i) begin
        if(~sim_rstn_i) begin
            block_pos           <= 32'd0;
            ip_data_pos         <= 15'd0;
            pixel_pos_sim       <= 12'd0;
            channel_pos_sim     <= 5'd0;
            sec_pos_sim         <= 4'd0;
            pixel_pos_reg_sim   <= 12'd0;
            channel_pos_reg_sim <= 5'd0;
            sec_pos_reg_sim     <= 4'd0;

            err_energy_sim  <= {32{1'b0}};
            sig_energy_sim <= {32{1'b0}};
        end
        else begin
            ip_data_pos         <= sim_ip_bram_addr_i;
            pixel_pos_sim       <= sim_pixel_pos_i;
            sec_pos_sim         <= sim_sec_pos_i;
            channel_pos_sim     <= sim_channel_pos_i;
            pixel_pos_reg_sim   <= pixel_pos_sim;
            channel_pos_reg_sim <= channel_pos_sim + (sec_pos_sim * 32);
            // if(output_en) begin
            //     block_pos <= 32'd0;
            // end
            if(sim_rd_buf_done_i) begin
                block_pos <= block_pos + WL; 
            end

            // check read in param
            if(sim_ip_bias_valid_i || 
               (sim_ip_weight_valid_i && sim_ip_data_in_valid_i)) begin
                param_flag = param_in_check(sim_ip_weight_valid_i, sim_ip_weight_i, sim_ip_bias_i, file_pos);
                // directC_test();
            end

            if(sim_ip_data_in_valid_i && (sim_cur_layer_index_i==3'd0)) begin
                in_flag = data_in_check(sim_ip_data_in_fp32, ip_data_pos, pixel_pos_reg_sim, channel_pos_reg_sim);
            end

            /*
            if(sim_ip_bias_valid_i || 
              (sim_ip_weight_valid_i && ip_data_valid_sim_i)) begin
                increment_out_check(sim_ip_weight_valid_i, sim_ip_weight_i, 
                                    sim_ip_bias_i, sim_ip_data_in_i, accum_data_sim, file_pos);
            end
            */

            // check each output for current fully-connected layer
            if(sim_ip_out_valid_i) begin
                out_check(sim_cur_layer_index_i, sim_ip_addr_out_i, 
                          `ifdef FP16 ip_data_fp32_sim `else sim_ip_data_out_i `endif, 
                          sig_energy_sim, err_energy_sim, err_out_flag);
            end

            // show final noise to signal ratio(nsr) for current layer
            if(sim_ip_layer_done_i) begin
                nsr_flag = error_status(sim_cur_layer_index_i, sig_energy_sim, err_energy_sim);
            end
        end
    end
    always @(err_out_flag or in_flag or  param_flag or nsr_flag) begin
        if(err_out_flag) begin
            $display("Out Data... \n\tOpen out or Check failed.");
            $finish;
        end
        if(in_flag) begin
            $display("Input Data... \n\tOpen data or log file failed.");
            $finish;
        end
        if(param_flag) begin
            $display("Input Param... \n\tOpen param or log file failed.");
            $finish;
        end
        if(nsr_flag) begin
            $display("Output Nsr... \n\tOpen nsr log file failed.");
            $finish;
        end
    end

    always @(sim_batch_done_i) begin
        if(sim_batch_done_i) begin
             #1500 $finish;
        end
    end
endmodule
