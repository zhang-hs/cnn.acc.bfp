// faster ddr model
`define SIM
`timescale 1 ns / 1 ps
module ddr_model
#(
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512
)
(
    output reg                  init_calib_complete_o,
    output reg                  app_rdy_o,
    input                       app_en_i,
    input [3-1:0]               app_cmd_i, 
    input [ADDR_WIDTH-1:0]      app_addr_i,
    output reg                  app_wdf_rdy_o,
    input                       app_wdf_wren_i,
    input                       app_wdf_end_i,
    input  [DATA_WIDTH-1:0]     app_wdf_data_i,
    output reg                  app_rd_data_valid_o,
    output reg [DATA_WIDTH-1:0] app_rd_data_o,
    output reg                  app_rd_data_end_o,
    output reg                  ui_clk,
    output reg                  ui_rst
);
`define SEEK_SET 0
`define SEEK_CUR 1
`define SEEK_END 2
//`define _display_

    localparam BYTE_LEN = DATA_WIDTH / 8;

    localparam IDLE     = 3'd0;
    localparam WR_PROC  = 3'd1;
    localparam RD_PROC  = 3'd2;
    localparam CMD_WAIT = 3'd3;
    reg [3-1:0] _cs_;

    reg [ADDR_WIDTH-1:0] _addr_fifo_[0:512-1];
    reg                  _addr_fifo_full_;
    reg                  _addr_fifo_empty_;
    reg [DATA_WIDTH-1:0] _data_fifo_[0:512-1];
    reg                  _data_fifo_full_;
    reg                  _data_fifo_empty_;
    reg [9-1:0] push_addr_fifo_addr;
    reg [9-1:0] pop_addr_fifo_addr;
    reg [9-1:0] push_data_fifo_addr;
    reg [9-1:0] pop_data_fifo_addr;

    // generate clock and rst signal
    initial begin
      #0 ui_clk <= 1'b0;
         ui_rst <= 1'b0;
      #5 ui_rst <= 1'b1; 
      #5 ui_rst <= 1'b0;
      forever
        #10 ui_clk <= ~ui_clk;
    end
    // init_calib_complete signal
    initial begin
      #0  init_calib_complete_o <= 1'b0;
      #50 init_calib_complete_o <= 1'b1;
    end

    wire [DATA_WIDTH-1:0] app_wdf_data_ld; // little endian
    generate
    genvar i;
      for(i = 0; i < BYTE_LEN; i = i + 1) begin: big2little
        assign app_wdf_data_ld[(i+1)*8-1:i*8] = app_wdf_data_i[(BYTE_LEN-i)*8-1:(BYTE_LEN-1-i)*8];
      end
    endgenerate

    // ddr read and write state
    integer DDR_OBJ;
    integer r;
    integer re;

    always @(posedge ui_rst) begin
      $display("open ddr mem file...");
      DDR_OBJ <= $fopen("ddr_mem.bin", "wb+");
    end

    always @(posedge ui_rst or posedge ui_clk) begin
        if(ui_rst) begin
            _cs_ <= IDLE;

            app_rdy_o     <= 1'b0;
            app_wdf_rdy_o <= 1'b0;
            app_rd_data_valid_o <= 1'b0;
            app_rd_data_o       <= {DATA_WIDTH{1'b1}};
            app_rd_data_end_o   <= 1'b0;

            pop_addr_fifo_addr  <= 9'd0;
            pop_data_fifo_addr  <= 9'd0;
        end
        else begin 
            if(init_calib_complete_o) begin
                case(_cs_)
                IDLE: begin
                    if(app_cmd_i == 3'd0 && app_en_i) begin
                        _cs_ <= WR_PROC;

                        app_rdy_o <= 1'b1;
                        app_wdf_rdy_o <= 1'b1;

                        pop_addr_fifo_addr  <= 9'd0;
                        pop_data_fifo_addr  <= 9'd0;

                        `ifdef SIM
                        $display("Write param to ddr...");
                        `endif
                    end
                    else if(app_cmd_i == 3'd1 && app_en_i) begin
                        _cs_ <= RD_PROC;

                        app_rdy_o  <= 1'b1;
                        app_rd_data_valid_o <= 1'b0;
                        app_rd_data_o       <= {DATA_WIDTH{1'b1}};
                        app_rd_data_end_o   <= 1'b0;
            
                        pop_addr_fifo_addr  <= 9'd0;
                    end
                    else begin
                        _cs_ <= IDLE;
            
                        app_rdy_o     <= 1'b1;
                        app_wdf_rdy_o <= 1'b1;
                        app_rd_data_valid_o <= 1'b0;
                        app_rd_data_o       <= {DATA_WIDTH{1'b1}};
                        app_rd_data_end_o   <= 1'b0;
                        pop_addr_fifo_addr  <= 9'd0;
                        pop_data_fifo_addr  <= 9'd0;
                    end
                end
                WR_PROC: begin
                    if(~app_en_i) begin
                        _cs_ <= CMD_WAIT;

                        app_rdy_o <= 1'b1;
                        end
                        else begin
                            _cs_ <= WR_PROC;

                        if(_addr_fifo_full_) begin
                            app_rdy_o <= 1'b0;
                        end
                        else begin
                            app_rdy_o <= 1'b1;
                        end
                        if(_data_fifo_full_) begin
                            app_wdf_rdy_o <= 1'b0;
                        end
                        else begin
                            app_wdf_rdy_o <= 1'b1;
                        end
                    end
                    if(~_addr_fifo_empty_ && ~_data_fifo_empty_) begin
                        r <= $fseek(DDR_OBJ, _addr_fifo_[pop_addr_fifo_addr]*8, `SEEK_SET);
                        $fwrite(DDR_OBJ, "%U", _data_fifo_[pop_data_fifo_addr]);
                        pop_addr_fifo_addr <= pop_addr_fifo_addr + 1'b1;
                        pop_data_fifo_addr <= pop_data_fifo_addr + 1'b1;

                        `ifdef _display_
                         $display("%t], WRITE: data---->%x, addr---->%x.", $time, 
                                  _data_fifo_[pop_data_fifo_addr],
                                  _addr_fifo_[pop_addr_fifo_addr]);
                        `endif
                    end
                    app_rd_data_valid_o <= 1'b0;
                    app_rd_data_end_o   <= 1'b0;
                end
                RD_PROC: begin
                    if(~app_en_i) begin
                        _cs_ <= CMD_WAIT;

                        app_rdy_o <= 1'b0;
                    end
                    else begin
                        _cs_ <= RD_PROC;

                        if(_addr_fifo_full_) begin
                            app_rdy_o <= 1'b0;
                        end
                        else begin
                            app_rdy_o <= 1'b1;
                        end
                    end
                    if(~_addr_fifo_empty_) begin
                        app_rd_data_valid_o <= 1'b1;
                        app_rd_data_end_o   <= 1'b1;
                        pop_addr_fifo_addr  <= pop_addr_fifo_addr + 1'b1;
                        #1
                        re <= $fseek(DDR_OBJ, _addr_fifo_[pop_addr_fifo_addr]*8, `SEEK_SET);
                        r  <= $fread(app_rd_data_o, DDR_OBJ);
                        `ifdef _display_
                         $display("%t], READ: data---->%x, addr---->%x.", $time, 
                                  app_rd_data_o,
                                  _addr_fifo_[pop_addr_fifo_addr]);
                        `endif
                    end
                    else begin
                        app_rd_data_valid_o <= 1'b0;
                        app_rd_data_end_o   <= 1'b0;
                    end
                end
                CMD_WAIT: begin
                    if(app_en_i && app_cmd_i==3'd0) begin
                        _cs_ <= WR_PROC;
                    end
                    if(app_en_i && app_cmd_i==3'd1) begin
                        _cs_ <= RD_PROC;
                    end
          
                    app_rdy_o <= 1'b1;
                    if(app_cmd_i == 3'd0) begin
                        if(~_addr_fifo_empty_ && _data_fifo_empty_) begin
                            re <= $fseek(DDR_OBJ, _addr_fifo_[pop_addr_fifo_addr]*8, `SEEK_SET);
                            $fwrite(DDR_OBJ, "%U", _data_fifo_[pop_data_fifo_addr]);
                            pop_addr_fifo_addr <= pop_addr_fifo_addr + 1'b1;
                            pop_data_fifo_addr <= pop_data_fifo_addr + 1'b1;
                            `ifdef _display_
                            $display("%t], WRITE: data---->%x, addr---->%x.", $time, 
                                     _data_fifo_[pop_data_fifo_addr],
                                     _addr_fifo_[pop_addr_fifo_addr]);
                            `endif
                        end
                        app_rd_data_valid_o <= 1'b0;
                        app_rd_data_end_o   <= 1'b0;
                    end
                    else if(app_cmd_i == 3'd1) begin
                        if(~_addr_fifo_empty_) begin
                            app_rd_data_valid_o <= 1'b1;
                            app_rd_data_end_o   <= 1'b1;
                            #1
                            re <= $fseek(DDR_OBJ, _addr_fifo_[pop_addr_fifo_addr]*8, `SEEK_SET);
                            r  <= $fread(app_rd_data_o, DDR_OBJ);
                            `ifdef _display_
                             $display("%t], READ: data---->%x, addr---->%x.", $time, 
                                      app_rd_data_o,
                                      _addr_fifo_[pop_addr_fifo_addr]);
                             `endif
                        end
                        else begin
                            app_rd_data_valid_o <= 1'b0;
                            app_rd_data_end_o   <= 1'b0;
                        end
                    end
                end
                endcase
            end
        end
    end

    // address fifo state
    always @(push_addr_fifo_addr or pop_addr_fifo_addr) begin
      if(push_addr_fifo_addr - pop_addr_fifo_addr == 9'd1) begin
        _addr_fifo_empty_ = 1'b1;
      end
      else begin
        _addr_fifo_empty_ = 1'b0;
      end
      if(pop_addr_fifo_addr - push_addr_fifo_addr == 9'd1) begin
        _addr_fifo_full_ = 1'b1;
      end
      else begin
        _addr_fifo_full_ = 1'b0;
      end
    end
    
    // data fifo state
    always @(push_data_fifo_addr or pop_data_fifo_addr) begin
      if(push_data_fifo_addr - pop_data_fifo_addr == 9'd1) begin
        _data_fifo_empty_ = 1'b1;
      end
      else begin
        _data_fifo_empty_ = 1'b0;
      end
      if(pop_data_fifo_addr - push_data_fifo_addr == 9'd1) begin
        _data_fifo_full_ = 1'b1;
      end
      else begin
        _data_fifo_full_ = 1'b0;
      end
    end

    always @(posedge ui_rst or posedge ui_clk) begin
      if(ui_rst) begin
        push_addr_fifo_addr <= 9'd0;
        push_data_fifo_addr <= 9'd0;
      end
      else begin
        if(app_cmd_i == 3'd0) begin
          if(app_rdy_o && app_en_i) begin
             _addr_fifo_[push_addr_fifo_addr] <= app_addr_i;
             push_addr_fifo_addr <= push_addr_fifo_addr + 1'b1;
          end
          if(app_wdf_rdy_o && app_en_i && app_wdf_wren_i && app_wdf_end_i) begin
            _data_fifo_[push_data_fifo_addr] <= app_wdf_data_ld;
	    push_data_fifo_addr <= push_data_fifo_addr + 1'b1;
          end
        end
        else begin
          if(app_rdy_o && app_en_i) begin
            _addr_fifo_[push_addr_fifo_addr] <= app_addr_i;
            push_addr_fifo_addr <= push_addr_fifo_addr + 1'b1;
          end
        end
      end
    end
endmodule
