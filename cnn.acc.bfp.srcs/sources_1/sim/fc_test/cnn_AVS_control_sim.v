/*
 * This is a temporary top control module for cnn_AVS_top module
 * It is just a simulated module.
 *
 * ports:
 * tb_load_done_i:						write data to ddr done.
 * rd_data_full_i:						read data to feature in buffer finish
 * rd_data_load_ddr_done_rising_edge_i:	write data to ddr done rising edge	
*/
module cnn_AVS_control_sim
#(
 )
 (
 	// port definition {{{
	input		clk_i,
	input		rstn_i,

	input					tb_load_done_i,
	input					rd_data_full_i,
	input 					rd_data_load_ddr_done_rising_edge_i,

	output	reg				rd_data_bottom_o,
	output	reg	[ 9-1:0 ]	rd_data_x_o,
	output	reg	[ 9-1:0 ]	rd_data_y_o,

	output	reg				rd_top_en_o,
	output	reg	[ 13-1:0 ]	rd_top_offset_o,	

	output	reg				rd_side_en_o,
	output	reg	[ 13-1:0 ]	rd_side_offset_o,

	output	reg	[ 9-1:0 ]	feature_index_o,
	output	reg	[ 3-1:0 ]	conv_layer_index_o
	// }}}
 );

localparam	ENDOFX = 16-1;
localparam	ENDOFY = 16-1;

	always@(posedge clk_i or negedge rstn_i) 
	begin
		if(!rstn_i) 
		begin
			rd_data_x_o <= 9'h0;
			rd_data_y_o <= 9'h0;
			rd_data_bottom_o <= 1'b0;
		end 
		else 
		begin
			if(tb_load_done_i) 
			begin // {{{
				if(rd_data_full_i) 
				begin // {{{
					if(rd_data_x_o == ENDOFX) 
					begin
						rd_data_x_o <= 9'h0;
					end 
					else 
					begin
						rd_data_x_o <= rd_data_x_o + 1'b1;
					end
					if(rd_data_y_o == ENDOFY) 
					begin
						rd_data_y_o <= 9'h0;
					end 
					else 
					begin
						if(rd_data_x_o == ENDOFX) 
						begin
							rd_data_y_o <= rd_data_y_o + 1'b1;
						end
					end
				end // }}}
				if(rd_data_load_ddr_done_rising_edge_i || rd_data_full_i) 
				begin
					rd_data_bottom_o <= 1'b1;
				end 
				else 
				begin
					rd_data_bottom_o <= 1'b0;
				end
			end // }}} 
			else 
			begin
				rd_data_bottom_o <= 1'b0;
			end
		end
	end

	/* 
	 * initial some control signal
	 * */
	initial
	begin
		rd_top_en_o			<= 1'b0;
		rd_top_offset_o		<= 13'd0;

		rd_side_en_o		<= 1'b0;
		rd_side_offset_o	<= 13'd0;
		// test first feature map and first conv layer only
		feature_index_o 	<= 9'd0;
		conv_layer_index_o	<= 3'd0; 
	end
endmodule
