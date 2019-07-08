/*
 * This is a signal generate module for feature_in_reg_matrix.v.
 * It is simulated read_op module.
*/
`timescale 1 ns/1 ns
module read_op_sim
#(
	parameter EW = 8,
	parameter MW = 23,
	parameter FW = 32,
	parameter US = 7,
	parameter DW = 512
 )
 (
	// {{{
 	// input port 
	input						clk_i,
	input						rstn_i,

	// interface with top_ram
	input		[ (2*US+2)*FW-1:0 ]	data_top_i,
	output reg						en_top_o,
	output reg	[ 10-1:0 ]			addr_top_o,
	// interface with side_ram
	input		[ (2*US+1)*FW-1:0 ]	data_side_i,
	output reg						en_side_o,
	output reg	[ 12-1:0 ]			addr_side_o,
 	// output port to feature_in_reg_matrix.v
	output reg						start_trigger_o,
	output reg						en_o,

	output reg						first_shot_o,
	output reg						sel_w_o,

	output reg						sel_top_o,
	output reg	[ (2*US+2)*FW-1:0 ]	data_top_o,
	
	output reg						sel_side_o,
	output reg	[ (2*US+1)*FW-1:0 ]	data_side_o,

	output reg						sel_ddr_o,
	output reg						ddr_last_o,
	output reg						data_last_o,
	output reg						col_last_o,
	output reg						row_last_o,
	output reg	[ 32-1:0 ]			data_valid_num_o,
	output reg	[ DW-1:0 ]			data_ddr_o,
	output reg						feature_index_o,
	output reg						conv_layer_index_o,	
	output		[ 5-1:0 ] 			x_pos_o,	

	output		[ 32-1:0 ]			X_pos_ddr_o,
	output		[ 32-1:0 ]			Y_pos_ddr_o,
	output 							read_finish_o
	// }}}
 );
	// {{{
 	localparam	X_MAX = 31;
	localparam	Y_MAX = 31;
	localparam	DDR_PACKAGE_LEN 					= DW / FW; // data number in one input data data_ddr_i
	localparam	DDR_ONLY_PACKAGE_COUNT 				= 6*US*US/DDR_PACKAGE_LEN+1+3;
	localparam	DDR_ONLY_LAST_ROW_PACKAGE_COUNT		= 6*US*US/DDR_PACKAGE_LEN+1;
	localparam	DDR_PART_PACKAGE_COUNT 				= 4*US*US/DDR_PACKAGE_LEN+1+2;
	localparam	DDR_PART_LAST_ROW_PACKAGE_COUNT	 	= 4*US*US/DDR_PACKAGE_LEN+1;
	localparam	DDR_PART_LAST_COL_PACKAGE_COUNT 	= 2*US*US/DDR_PACKAGE_LEN+1+1;
	localparam	DDR_PART_LAST_ROW_COL_PACKAGE_COUNT	= 2*US*US/DDR_PACKAGE_LEN+1;
	localparam	SIDE_PART_PACKAGE_COUNT 			= US+1;
	localparam 	TOP_PART_PACKAGE_COUNT 				= 1;
	localparam	OFFSET1								= (2*US*US) % DDR_PACKAGE_LEN;
	localparam	OFFSET2								= (4*US*US) % DDR_PACKAGE_LEN;
	localparam	OFFSET3								= (6*US*US) % DDR_PACKAGE_LEN;
	localparam	OFFSET4								= US;
	localparam	OFFSET5								= DDR_PACKAGE_LEN;

	localparam	READ_IDLE 	  = 4'b0000;
	localparam	READ_DDR_ONLY = 4'b0001;
	localparam	READ_DDR_BRAM = 4'b0010;
	localparam	READ_FINISH	  = 4'b0011;
	// }}}
	`define SEEK_SET 0
	`define SEEK_CUR 1
	`define	SEEK_END 2

	integer	ddr_read_count;
	integer	top_read_count;
	integer side_read_count;
	integer	X_pos_ddr;
	integer Y_pos_ddr;
	reg		read_op_act_;
	reg		read_op_fin_; // one read_op finish;
	/*
	 * internel control signal
	 * */
	assign read_finish_o = read_op_fin_;
	assign x_pos_o		 = X_pos_ddr;
	assign X_pos_ddr_o	 = X_pos_ddr;
	assign Y_pos_ddr_o	 = Y_pos_ddr;
	always @( negedge rstn_i or posedge clk_i )
	begin
		if( rstn_i == 1'b0 )
		begin
			X_pos_ddr	<= 0;
			Y_pos_ddr	<= 0;

			read_op_act_	<= 1'b0;
		end
		else
		begin
			if( read_op_fin_ == 1'b1 )	
			begin
				if( X_pos_ddr < X_MAX-1 )
					X_pos_ddr	<= X_pos_ddr + 2;
				else
				begin
					X_pos_ddr	<= 0;
					Y_pos_ddr	<= Y_pos_ddr + 2;
				end
				read_op_act_	<= 1'b0;
				#70	read_op_act_	<= 1'b1;
			end
			else if( read_op_act_ == 1'b0 )
				#50 read_op_act_	<= 1'b1;
		end
	end


	/*
	 * FSM
	 * */
	reg	[ 4-1:0 ]	state;
	reg	[ DW-1:0 ]	data_ddr_buf;
	integer	file_id;
	integer r;
	
	always @( negedge rstn_i or posedge clk_i )
	begin
		if( rstn_i == 1'b0 )
		begin // {{{
			sel_w_o			<= 1'b1;
			start_trigger_o	<= 1'b0;

			ddr_read_count	<= 0;

			en_side_o		<= 1'b0;
			addr_side_o		<= 12'd0;
			side_read_count	<= 0;

			en_top_o		<= 1'b0;
			addr_top_o		<= 10'd0;
			top_read_count	<= 0;

			read_op_fin_	<= 1'b0;

			state	<= READ_IDLE;
		end // }}}
		case( state )
			READ_IDLE:
			begin // {{{
				if( read_op_act_ == 1'b1 )
				begin
					if( X_pos_ddr == 0 )
					begin // {{{
						en_o			<= 1'b1;
						first_shot_o	<= 1'b1;
						start_trigger_o	<= 1'b1;
						sel_w_o			<= ~sel_w_o;

						if( Y_pos_ddr == 0 )
						begin
							sel_top_o		<= 1'b0;
							data_top_o		<= {(2*US+2)*FW{1'b0}};
						end
						else if( Y_pos_ddr != 0 )
						begin
							sel_top_o		<= 1'b0;
							en_top_o		<= 1'b1;
							addr_top_o		<= 10'd0;
						end

						sel_side_o		<= 1'b0;
						data_side_o		<= {(2*US+1)*FW{1'b0}};

						sel_ddr_o		<= 1'b1;
						ddr_last_o		<= 1'b0;
						data_last_o		<= 1'b0;
						col_last_o		<= 1'b0;
						if( Y_pos_ddr==Y_MAX-1 )
							row_last_o	<= 1'b1;
						else
							row_last_o	<= 1'b0;

						file_id			= $fopen( "/home/niuyue/focus/2-test/2-data/feature_map_bend.bin", "r" );
						r				= $fseek( file_id, Y_pos_ddr*(X_MAX+1)*US*US*FW/8, `SEEK_SET );
						r				= $fread( data_ddr_buf, file_id );
						data_ddr_o			<= data_ddr_buf;
						data_valid_num_o	<= 32'd16;
						ddr_read_count		<= ddr_read_count + 1;

						read_op_fin_	<= 1'b0;
						state				<= READ_DDR_ONLY;
					end // }}}
					else
					begin // {{{
						en_o			<= 1'b1;
						first_shot_o	<= 1'b0;
						start_trigger_o	<= 1'b1;
						sel_w_o			<= ~sel_w_o;

						// read top_ram data
						if( Y_pos_ddr == 0 )
						begin
							sel_top_o		<= 1'b0;
							data_top_o		<= {(2*US+2)*FW{1'b0}};
						end
						else if( Y_pos_ddr != 0 )
						begin
							sel_top_o		<= 1'b0;
							en_top_o		<= 1'b1;
							addr_top_o		<= X_pos_ddr>>1;
						end
	
						// read side_ram data
						sel_side_o			<= 1'b0;
						en_side_o			<= 1'b1;
						addr_side_o			<= 12'd0;

						// read ddr data
						sel_ddr_o		<= 1'b1;
						ddr_last_o		<= 1'b0;
						data_last_o		<= 1'b0;
						if( X_pos_ddr==X_MAX-1 )
							col_last_o	<= 1'b1;
						else
							col_last_o	<= 1'b0;

						if( Y_pos_ddr==Y_MAX-1 )
							row_last_o	<= 1'b1;
						else
							row_last_o	<= 1'b0;

						file_id				= $fopen( "/home/niuyue/focus/2-test/2-data/feature_map_bend.bin", "r" ); 
						r 					= $fseek( file_id, Y_pos_ddr*(X_MAX+1)*US*US*FW/8 + (2*X_pos_ddr+2)*US*US*FW/8, `SEEK_SET ); 
						r					= $fread( data_ddr_buf, file_id );
						data_ddr_o			<= data_ddr_buf;
						data_valid_num_o	<= 32'd16;
						ddr_read_count		<= ddr_read_count + 1;
						
						read_op_fin_		<= 1'b0;
						state	<= READ_DDR_BRAM;
					end // }}}
				end
				else
				begin // {{{
					en_o			<= 1'b0;
					first_shot_o	<= 1'b0;
					start_trigger_o	<= 1'b0;
					
					sel_top_o		<= 1'b0;
					data_top_o		<= {(2*US+2)*FW{1'b0}};

					sel_side_o		<= 1'b0;
					data_side_o		<= {(2*US+1)*FW{1'b0}};

					sel_ddr_o		<= 1'b0;
					ddr_last_o		<= 1'b0;
					data_last_o		<= 1'b0;
					col_last_o		<= 1'b0;
					row_last_o		<= 1'b0;
					data_ddr_o		<= {DW{1'b0}};
					data_valid_num_o	<= 32'd0;

					ddr_read_count	<= 0;
					side_read_count	<= 0;
					top_read_count	<= 0;

					read_op_fin_	<= 1'b0;

					state	<= READ_IDLE;
				end // }}}
			end // }}}
			READ_DDR_ONLY:
			begin // {{{
				// top_ram read
				en_top_o			<= 1'b0;
				sel_top_o			<= 1'b1;
				data_top_o			<= data_top_i;

				// ddr read
				if( (
					 row_last_o == 1'b0 && ddr_read_count < DDR_ONLY_PACKAGE_COUNT
					) ||
					(
					 row_last_o == 1'b1 && ddr_read_count < DDR_ONLY_LAST_ROW_PACKAGE_COUNT
					)
				  )
					ddr_read_count	<= ddr_read_count + 1;
				if( ( 
					 row_last_o == 1'b0 && ddr_read_count == DDR_ONLY_PACKAGE_COUNT
					) ||
					(
					 row_last_o == 1'b1 && ddr_read_count == DDR_ONLY_LAST_ROW_PACKAGE_COUNT
					)
				  )
				begin // {{{
					ddr_read_count <= 0;

					en_o			<= 1'b0;
					start_trigger_o	<= 1'b0;
					first_shot_o	<= 1'b1;
					
					sel_top_o		<= 1'b0;
					data_top_o		<= {(2*US+2)*FW{1'b0}};

					sel_side_o		<= 1'b0;
					data_side_o		<= {(2*US+1)*FW{1'b0}};

					sel_ddr_o		<= 1'b0;
					ddr_last_o		<= 1'b0;
					data_last_o		<= 1'b0;
					col_last_o		<= 1'b0;
					row_last_o		<= 1'b0;
					data_ddr_o		<= {DW{1'b0}};
					data_valid_num_o	<= 32'd0;

					ddr_read_count	<= 0;
					side_read_count	<= 0;
					top_read_count	<= 0;

					read_op_fin_	<= 1'b0;
					state			<= READ_FINISH;
				end // }}}
				else
				begin // {{{
					if( row_last_o == 1'b0 )
					begin // {{{
						en_o			<= 1'b1;
						start_trigger_o	<= 1'b0;
						first_shot_o	<= 1'b1;
						sel_ddr_o		<= 1'b1;
						col_last_o		<= 1'b0;
						if( Y_pos_ddr == Y_MAX-1 )
							row_last_o	<= 1'b1;
						else
							row_last_o	<= 1'b0;
						if( ddr_read_count == DDR_ONLY_PACKAGE_COUNT-4 )
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET3; 
						end
						else if( ddr_read_count == DDR_ONLY_PACKAGE_COUNT-3 )
						begin
							r = $fseek( file_id, (Y_pos_ddr+2)*(X_MAX+1)*US*US*FW/8, `SEEK_SET );
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET4;
						end
						else if( ddr_read_count == DDR_ONLY_PACKAGE_COUNT-2 )
						begin
							r = $fseek( file_id, ( (Y_pos_ddr+2)*(X_MAX+1)*US*US + 2*US*US )*FW/8, `SEEK_SET );
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET4;
						end
						else if( ddr_read_count == DDR_ONLY_PACKAGE_COUNT-1 )
						begin
							r = $fseek( file_id, ( (Y_pos_ddr+2)*(X_MAX+1)*US*US + 4*US*US )*FW/8, `SEEK_SET );
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b1;
							data_last_o	<= 1'b1;
							data_valid_num_o	<= OFFSET4;
						end
						else
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET5;
						end
					end // }}}
					else if( row_last_o == 1'b1 )
					begin // {{{
						en_o			<= 1'b1;
						start_trigger_o	<= 1'b0;
						first_shot_o	<= 1'b1;
						sel_ddr_o		<= 1'b1;
						col_last_o		<= 1'b0;
						if( ddr_read_count == DDR_ONLY_LAST_ROW_PACKAGE_COUNT-1 )
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b1;
							data_last_o	<= 1'b1;
							data_valid_num_o	<= OFFSET3;
						end
						else
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET5;
						end
					end // }}}
					

					read_op_fin_	<= 1'b0;
					state			<= READ_DDR_ONLY;
				end // }}}
			end // }}}
			READ_DDR_BRAM:
			begin // {{{
				if( col_last_o == 1'b0 && row_last_o == 1'b0 )
				begin
					if( ddr_read_count < DDR_PART_PACKAGE_COUNT )
						ddr_read_count	<= ddr_read_count + 1;
				end
				else if( col_last_o == 1'b1  && row_last_o == 1'b0 )
				begin
					if( ddr_read_count < DDR_PART_LAST_COL_PACKAGE_COUNT )
						ddr_read_count <= ddr_read_count + 1;
				end
				else if( col_last_o == 1'b0 && row_last_o == 1'b1 )
				begin
					if( ddr_read_count < DDR_PART_LAST_ROW_PACKAGE_COUNT )
						ddr_read_count <= ddr_read_count + 1;
				end
				else if( col_last_o == 1'b1 && row_last_o == 1'b1 )
				begin
					if( ddr_read_count < DDR_PART_LAST_ROW_COL_PACKAGE_COUNT )
						ddr_read_count <= ddr_read_count + 1;
				end
				if( side_read_count == SIDE_PART_PACKAGE_COUNT && 
					(
					 ( ddr_read_count == DDR_PART_PACKAGE_COUNT && col_last_o == 1'b0 && row_last_o == 1'b0 ) ||
					 ( ddr_read_count == DDR_PART_LAST_COL_PACKAGE_COUNT && col_last_o == 1'b1 && row_last_o == 1'b0 ) ||
					 ( ddr_read_count == DDR_PART_LAST_ROW_PACKAGE_COUNT && col_last_o == 1'b0 && row_last_o == 1'b1 ) ||
					 ( ddr_read_count == DDR_PART_LAST_ROW_COL_PACKAGE_COUNT && col_last_o == 1'b1 && row_last_o == 1'b1 )
					) 
				  )
				begin // {{{
					ddr_read_count <= 0;

					en_o			<= 1'b0;
					start_trigger_o	<= 1'b0;
					first_shot_o	<= 1'b0;
					
					en_top_o		<= 1'b0;
					addr_top_o		<= 10'd0;
					sel_top_o		<= 1'b0;
					data_top_o		<= {(2*US+2)*FW{1'b0}};

					en_side_o		<= 1'b0;
					addr_side_o		<= 12'd0;
					sel_side_o		<= 1'b0;
					data_side_o		<= {(2*US+1)*FW{1'b0}};

					sel_ddr_o		<= 1'b0;
					ddr_last_o		<= 1'b0;
					data_last_o		<= 1'b0;
					col_last_o		<= 1'b0;
					row_last_o		<= 1'b0;
					data_ddr_o		<= {DW{1'b0}};
					data_valid_num_o	<= 32'd0;

					ddr_read_count	<= 0;
					side_read_count	<= 0;
					top_read_count	<= 0;

					read_op_fin_	<= 1'b0;
					state			<= READ_FINISH;
				end // }}}
				else
				begin // {{{
					en_o			<= 1'b1;
					start_trigger_o	<= 1'b0;
					first_shot_o	<= 1'b0;
					sel_ddr_o		<= 1'b1;
					//col_last_o		<= 1'b0;
					if( Y_pos_ddr == Y_MAX-1 )
						row_last_o	<= 1'b1;
					else
						row_last_o	<= 1'b0;

					if( col_last_o == 1'b0 && row_last_o == 1'b0 )
					begin // {{{
						if( ( ddr_read_count == DDR_PART_PACKAGE_COUNT-1 && side_read_count == SIDE_PART_PACKAGE_COUNT ) ||
							( ddr_read_count == DDR_PART_PACKAGE_COUNT && side_read_count == SIDE_PART_PACKAGE_COUNT-1 )
						  )
							data_last_o	<= 1'b1;
						else
							data_last_o	<= 1'b0;
						if( ddr_read_count == DDR_PART_PACKAGE_COUNT-3 )
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							//data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET2; 
						end
						else if( ddr_read_count == DDR_PART_PACKAGE_COUNT-2 )
						begin
							r = $fseek( file_id, ( (Y_pos_ddr+2)*(X_MAX+1)*US*US + (2*X_pos_ddr+2)*US*US )*FW/8, `SEEK_SET );
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							//data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET4;
						end
						else if( ddr_read_count == DDR_PART_PACKAGE_COUNT-1 )
						begin
							r = $fseek( file_id, ( (Y_pos_ddr+2)*(X_MAX+1)*US*US + (2*X_pos_ddr+4)*US*US )*FW/8, `SEEK_SET );
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b1;
							//data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET4;
						end
						else if( ddr_read_count == DDR_PART_PACKAGE_COUNT )
						begin
							data_ddr_o			<= {FW{1'b0}};
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= 0;
							sel_ddr_o			<= 1'b0;
						end
						else
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b0;
							//data_last_o	<= 1'b0;
							data_valid_num_o	<= OFFSET5;
						end
					end // }}}
					else if( col_last_o == 1'b1 && row_last_o == 1'b0 )
					begin // {{{
						if( ( ddr_read_count == DDR_PART_LAST_COL_PACKAGE_COUNT-1 && side_read_count == SIDE_PART_PACKAGE_COUNT ) ||
							( ddr_read_count == DDR_PART_LAST_COL_PACKAGE_COUNT && side_read_count == SIDE_PART_PACKAGE_COUNT-1 )
						  )
						 	data_last_o <= 1'b1;
						else
							data_last_o <= 1'b0;
						if( ddr_read_count == DDR_PART_LAST_COL_PACKAGE_COUNT-2 )
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o			<= data_ddr_buf;
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= OFFSET1;
						end
						else if( ddr_read_count == DDR_PART_LAST_COL_PACKAGE_COUNT-1 )
						begin
							r = $fseek( file_id, ( (Y_pos_ddr+2)*(X_MAX+1)*US*US + (2*X_pos_ddr+2)*US*US )*FW/8, `SEEK_SET );
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o			<= data_ddr_buf;
							ddr_last_o			<= 1'b1;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= OFFSET4;
						end
						else if( ddr_read_count == DDR_PART_LAST_COL_PACKAGE_COUNT )
						begin
							data_ddr_o			<= {FW{1'b0}};
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= 0;
							sel_ddr_o			<= 1'b0;
						end
						else
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o			<= data_ddr_buf;
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= OFFSET5;
						end
					end // }}}
					else if( col_last_o == 1'b0 && row_last_o == 1'b1 )
					begin // {{{
						if( ( ddr_read_count == DDR_PART_LAST_ROW_PACKAGE_COUNT-1 && side_read_count == SIDE_PART_PACKAGE_COUNT ) ||
							( ddr_read_count == DDR_PART_LAST_ROW_PACKAGE_COUNT && side_read_count == SIDE_PART_PACKAGE_COUNT-1 )
						  )
						  	data_last_o <= 1'b1;
						else
							data_last_o	<= 1'b0;
						if( ddr_read_count == DDR_PART_LAST_ROW_PACKAGE_COUNT-1 )
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b1;
							//data_last_o	<= 1'b1;
							data_valid_num_o	<= OFFSET2; 
						end
						else if( ddr_read_count == DDR_PART_LAST_ROW_PACKAGE_COUNT )
						begin
							data_ddr_o			<= {FW{1'b0}};
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= 0;
							sel_ddr_o			<= 1'b0;
						end
						else
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o			<= data_ddr_buf;
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= OFFSET5;
						end
					end // }}}
					else if( col_last_o == 1'b1 && row_last_o == 1'b1 )
					begin // {{{
						if( ( ddr_read_count == DDR_PART_LAST_ROW_COL_PACKAGE_COUNT-1 && side_read_count == SIDE_PART_PACKAGE_COUNT ) ||
							( ddr_read_count == DDR_PART_LAST_ROW_COL_PACKAGE_COUNT && side_read_count == SIDE_PART_PACKAGE_COUNT-1 )
						  )
						  	data_last_o	<= 1'b1;
						else
							data_last_o	<= 1'b0;
						if( ddr_read_count == DDR_PART_LAST_ROW_COL_PACKAGE_COUNT-1 )
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o	<= data_ddr_buf;
							ddr_last_o	<= 1'b1;
							//data_last_o	<= 1'b1;
							data_valid_num_o	<= OFFSET1; 
						end
						else if( ddr_read_count == DDR_PART_LAST_ROW_COL_PACKAGE_COUNT )
						begin
							data_ddr_o			<= {FW{1'b0}};
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= 0;
							sel_ddr_o			<= 1'b0;
						end
						else
						begin
							r = $fread( data_ddr_buf, file_id );
							data_ddr_o			<= data_ddr_buf;
							ddr_last_o			<= 1'b0;
							//data_last_o			<= 1'b0;
							data_valid_num_o	<= OFFSET5;
						end
					end // }}}

					// receive top_ram data
					en_top_o		<= 1'b0;
					addr_top_o		<= 10'd0;
					sel_top_o		<= 1'b1;
					data_top_o		<= data_top_i;

					top_read_count	<= top_read_count + 1;

					// receive side_ram data
					if( side_read_count == SIDE_PART_PACKAGE_COUNT )
					begin
						en_side_o		<= 1'b0;
						addr_side_o		<= 12'd0;
						sel_side_o		<= 1'b0;
						data_side_o		<= {(2*US+1)*FW{1'b0}};
					end
					if( side_read_count < SIDE_PART_PACKAGE_COUNT )
					begin
						sel_side_o		<= 1'b1;
						en_side_o		<= 1'b1;
						addr_side_o		<= addr_side_o + 12'd1;
						data_side_o		<= data_side_i;

						if( sel_side_o == 1'b1 )
							side_read_count	<= side_read_count + 1;
					end

					state	<= READ_DDR_BRAM;
				end // }}}
			end // }}}
			READ_FINISH:
			begin
				data_last_o		<= 1'b0;

				read_op_fin_	<= 1'b1;
				start_trigger_o	<= 1'b0;
				if( read_op_act_ == 1'b1 )
					state		<= READ_FINISH;
				else
					state			<= READ_IDLE;
			end
			default:
			begin
				state	<= READ_IDLE;
			end
		endcase
	end
	
	/* 
	 * read top row data
	 * */

	/*
	 * read left ram data
	 * */

	/* 
	 * initial some control signal
	 * */
	initial
	begin
		// test first feature map and first conv layer only
		feature_index_o 	<= 9'd0;
		conv_layer_index_o	<= 3'd0; 
	end


endmodule
