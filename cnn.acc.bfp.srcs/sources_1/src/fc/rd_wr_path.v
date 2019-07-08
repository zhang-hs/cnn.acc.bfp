// read and write interface with mig

module rd_wr_path
#(
    parameter ADDR_WIDTH = 30,
    parameter DATA_WIDTH = 512,
    parameter DATA_NUM_BITS = 20
)
(
    input                         clk_i,
    input                         rst_i,
    //-- control
    input                         wr_en_i,
    input                         rd_en_i,
    input                         init_calib_complete_i,
    input                         app_rdy_i,
    input                         app_wdf_rdy_i,
    output reg                    app_en_o,
    output reg [3-1:0]            app_cmd_o,
    output reg [64-1:0]           app_wdf_mask_o,
    output reg [ADDR_WIDTH-1:0]   app_addr_o,
    //-- write
    input  [DATA_NUM_BITS-1:0]    wr_burst_num_i,
    input  [ADDR_WIDTH-1:0]       wr_start_addr_i,
    input  [DATA_WIDTH-1:0]       wr_data_i,
    output reg                    app_wdf_wren_o,
    output reg [DATA_WIDTH-1:0]   app_wdf_data_o,
    output reg                    app_wdf_end_o,
    output reg                    fetch_data_en_o,
    output reg                    wr_ddr_done_o,
    //-- read
    input  [DATA_NUM_BITS-1:0]    rd_burst_num_i,
    input  [ADDR_WIDTH-1:0]       rd_start_addr_i,
    input                         app_rd_data_valid_i,
    input  [DATA_WIDTH-1:0]       app_rd_data_i,
    input                         app_rd_data_end_i,
    output reg                    rd_ddr_done_o,
    output                        rd_data_valid_o,
    output [DATA_WIDTH-1:0]       rd_data_o
);

    localparam IDLE      = 3'd0;
    localparam WR_READY  = 3'd1;
    localparam WR_PROC   = 3'd2;
    localparam RD_PROC   = 3'd3;
    localparam CMD_WAIT  = 3'd4;

    reg [3-1:0] _cs_;
    reg [3-1:0] _cs_next;

    reg [ADDR_WIDTH-1:0]      wr_addr;
    reg [ADDR_WIDTH-1:0]      rd_addr;

    reg   [DATA_NUM_BITS-1:0]    wr_data_burst_cnt;
    reg   [DATA_NUM_BITS-1:0]    wr_addr_burst_cnt;
    reg   [DATA_NUM_BITS-1:0]    rd_addr_burst_cnt;
    wire  [DATA_NUM_BITS-1:0]    addr_data_cnt_diff;

    assign addr_data_cnt_diff = wr_addr_burst_cnt - wr_data_burst_cnt;
    assign rd_data_valid_o = app_rd_data_valid_i;
    assign rd_data_o       = app_rd_data_i;


  reg _wr_addr_next;
  reg _rd_addr_next;
  reg _fetch_next_data;

  always@(posedge clk_i or posedge rst_i) begin
    if(rst_i || ~init_calib_complete_i) begin
      _cs_ <= IDLE;
    end else begin
      _cs_ <= _cs_next;
    end
  end

  always@(_cs_ or app_rdy_i or rd_en_i or wr_en_i or
          wr_ddr_done_o or rd_ddr_done_o) begin
    _cs_next = IDLE;
    case(_cs_)
      IDLE: begin
        if(app_rdy_i) begin
          if(wr_en_i) begin
            _cs_next = WR_PROC;
          end else if(rd_en_i) begin
            _cs_next = RD_PROC;
          end
        end else begin
          _cs_next = IDLE;
        end
      end
      WR_PROC: begin
        if(wr_ddr_done_o) begin
          _cs_next = IDLE;
        end else begin
          _cs_next = WR_PROC;
        end
      end
      RD_PROC: begin
        if(rd_ddr_done_o) begin
          _cs_next = IDLE;
        end else begin
          _cs_next = RD_PROC;
        end
      end
    endcase
  end

  always@(_cs_ or app_rdy_i or wr_en_i or wr_start_addr_i or wr_addr or
          wr_burst_num_i or rd_burst_num_i or wr_data_burst_cnt or
          wr_addr_burst_cnt or addr_data_cnt_diff or app_wdf_rdy_i or
          rd_addr_burst_cnt or rd_addr or rd_start_addr_i or wr_data_i) begin

    app_en_o    = 1'b0;
    app_cmd_o   = 3'd2;
    app_addr_o  = {ADDR_WIDTH{1'b0}};

    app_wdf_mask_o = 64'd0;
    app_wdf_wren_o = 1'b0;
    app_wdf_end_o  = 1'b0;
    app_wdf_data_o = {DATA_WIDTH{1'b0}};

    _wr_addr_next = 1'b0;
    wr_ddr_done_o = 1'b0;
    _rd_addr_next = 1'b0;
    rd_ddr_done_o = 1'b0;

    fetch_data_en_o = 1'b0;
    _fetch_next_data= 1'b0;

    case(_cs_)
      IDLE: begin
        if(app_rdy_i && wr_en_i) begin // to WR_PROC
          fetch_data_en_o = 1'b1;
        end
      end

      WR_PROC: begin
        app_cmd_o   = 3'd0; // write
        app_addr_o  = wr_start_addr_i + wr_addr;

        if(wr_data_burst_cnt == wr_burst_num_i &&
           wr_addr_burst_cnt == wr_burst_num_i) begin
          app_en_o      = 1'b0;
          wr_ddr_done_o = 1'b1;
        end else begin
          if(app_rdy_i) begin // write address
            if(addr_data_cnt_diff[DATA_NUM_BITS-1] == 1'b1 ||
               addr_data_cnt_diff == {{(DATA_NUM_BITS-2){1'b0}}, 2'b00} ||
               addr_data_cnt_diff == {{(DATA_NUM_BITS-2){1'b0}}, 2'b01}) begin
              app_en_o      = 1'b1;
              _wr_addr_next = 1'b1;
            end else begin
              app_en_o      = 1'b0;
              _wr_addr_next = 1'b0;
            end
          end else begin
            app_en_o      = 1'b0;
            _wr_addr_next = 1'b0;
          end
          if(app_wdf_rdy_i) begin // write data
            if(wr_data_burst_cnt==wr_burst_num_i) begin
              app_wdf_wren_o  = 1'b0;
              app_wdf_data_o  = wr_data_i;
            end else begin
              app_wdf_wren_o  = 1'b1;
              app_wdf_end_o   = 1'b1;
              fetch_data_en_o = 1'b1;
              _fetch_next_data= 1'b1;
              app_wdf_data_o  = wr_data_i;
            end
          end else begin
            app_wdf_wren_o  = 1'b0;
            app_wdf_end_o   = 1'b0;
            fetch_data_en_o = 1'b0;
            _fetch_next_data= 1'b0;
            app_wdf_data_o  = wr_data_i;
          end
        end
      end

      RD_PROC: begin
        app_cmd_o   = 3'd1; // read
        app_addr_o  = rd_start_addr_i + rd_addr;
        if(rd_addr_burst_cnt == rd_burst_num_i) begin
          app_en_o      = 1'b0;
          rd_ddr_done_o = 1'b1;
        end else begin
          if(app_rdy_i) begin
            app_en_o      = 1'b1;
            _rd_addr_next = 1'b1;
          end else begin
            app_en_o      = 1'b0;
            _rd_addr_next = 1'b0;
          end
        end
      end
    endcase
  end

  // address and counter
  // read address and read counter
  always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      rd_addr_burst_cnt <= {DATA_NUM_BITS{1'b0}};
      rd_addr           <= {ADDR_WIDTH{1'b0}};
    end else begin
      if(_rd_addr_next) begin
        rd_addr_burst_cnt <= rd_addr_burst_cnt + 1'd1;
        rd_addr           <= rd_addr + 4'd8; // <------- address offset
      end else if(rd_ddr_done_o) begin
        rd_addr_burst_cnt <= {DATA_NUM_BITS{1'b0}};
        rd_addr           <= {ADDR_WIDTH{1'b0}};
      end
    end
  end
  // write address and address burst counter
  always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      wr_addr_burst_cnt <= {DATA_NUM_BITS{1'b0}};
      wr_addr           <= {ADDR_WIDTH{1'b0}};
    end else begin
      if(_wr_addr_next) begin
        wr_addr_burst_cnt <= wr_addr_burst_cnt + 1'd1;
        wr_addr           <= wr_addr + 4'd8; // <------- address offset
      end else if(wr_ddr_done_o) begin
        wr_addr_burst_cnt <= {DATA_NUM_BITS{1'b0}};
        wr_addr           <= {ADDR_WIDTH{1'b0}};
      end
    end
  end
  // write data counter
  always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
      wr_data_burst_cnt <= {DATA_NUM_BITS{1'b0}};
    end else begin
      if(_fetch_next_data) begin
        wr_data_burst_cnt <= wr_data_burst_cnt + 1'd1;
      end else if(wr_ddr_done_o) begin
        wr_data_burst_cnt <= {DATA_NUM_BITS{1'b0}};
      end
    end
  end

endmodule
