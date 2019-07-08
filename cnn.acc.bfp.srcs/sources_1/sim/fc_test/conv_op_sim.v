/*----------------------------------------------
 * conv_op simulated module
----------------------------------------------*/
module conv_op_sim
#(
	parameter EW = 8,
	parameter MW = 23,
	parameter FW = 32
 )
 (
 	input		clk_i,
	input		rstn_i,
 	input		conv_en_i,
 	output reg	conv_finish_o
 );

	localparam	IDLE 	  = 4'd0;
	localparam	CONV_STAG = 4'd1;
	reg	[ 4-1:0 ] STATE;

	reg [ 8-1:0 ] conv_count;
	always @( negedge rstn_i or posedge clk_i )
	begin
		if( rstn_i == 1'b0 )
		begin
			STATE	<= IDLE;

			conv_count		<= 8'd0;
			conv_finish_o	<= 1'b0;
		end
		else
		begin
			case( STATE )
				IDLE:
				begin
					if( conv_en_i == 1'b1 )
					begin
						STATE	<= CONV_STAG;
					end
					else
					begin
						conv_count		<= 8'd0;
						conv_finish_o	<= 1'b0;
					end
				end
				CONV_STAG:
				begin
					if( conv_count == 8'd196)
					begin
						STATE	<= IDLE;

						conv_count		<= 8'd0;
						conv_finish_o	<= 1'b1;
					end
					else
					begin
						STATE	<= CONV_STAG;

						conv_count		<= conv_count + 8'd1;
						conv_finish_o	<= 1'b0;
					end
				end
			endcase
		end
	end

endmodule
