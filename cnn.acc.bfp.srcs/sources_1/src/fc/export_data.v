/*
  --write ip out data into ddr memory
*/
//`define SIM

module export_data
#(
    parameter iDW = 16,
    parameter oDW = 512,
    parameter oAW = 30
)
(
    `ifdef SIM
    input  sim_rd_ddr_done_i,
    output reg sim_rd_ddr_en_o,
    output reg [6-1:0] sim_rd_burst_num_o,
    output reg [oAW-1:0] sim_rd_start_addr_o,
    `endif
    input                           clk_i,
    input                           rstn_i,
    //--export status
    input                           ip_done_i,
    input                           exp_ack_i,
    /*(*mark_debug="TRUE"*)*/output reg exp_active_o,
    /*(*mark_debug="TRUE"*)*/output reg exp_done_o,
    //--featch data
    output reg                      rd_en_o,
    input  [iDW-1:0]                bram_data_i,
    output reg [10-1:0]             rd_addr_o,
    //--write data to ddr
    /*(*mark_debug="TRUE"*)*/input      wr_ddr_done_i,
    input                           fetch_data_en_i,
    /*(*mark_debug="TRUE"*)*/output reg wr_ddr_en_o,
    output reg [5-1:0]              wr_burst_num_o,
    output reg [oAW-1:0]            wr_start_addr_o,
    output reg [oDW-1:0]            wr_data_o
);

    localparam PACKAGE_LEN = oDW / iDW;
    //--state definition
    localparam EXP_IDLE        = 3'd0;
    localparam EXP_FETCH_READY = 3'd1;
    localparam EXP_FETCH_DATA  = 3'd2;
    localparam EXP_WRITE_DATA  = 3'd3;
    localparam EXP_DONE        = 3'd4;
    `ifdef SIM
    localparam EXP_CHECK_DDR   = 3'd5;
    `endif
    localparam WR_START_ADDR   = {4'd4, {26'd0}};
    /*(*mark_debug="TRUE"*)*/reg  [3-1:0] _cs_;

    //--data buffer
    /*(*mark_debug="TRUE"*)*/reg  _buf_full_;
    reg  [iDW-1:0] _exp_buf_[0:PACKAGE_LEN];
    //--exp write status
    /*(*mark_debug="TRUE"*)*/reg  _exp_done_;
    /*(*mark_debug="TRUE"*)*/reg  [6-1:0] fetch_cnt;
    //--read bram
    /*(*mark_debug="TRUE"*)*/reg  [10-1:0] rd_bram_addr;
    //--write ddr
    reg  [oAW-1:0] wr_ddr_addr;


    //--state transition;
    always @(negedge rstn_i or posedge clk_i) begin
        if(~rstn_i) begin
            _cs_ <= EXP_IDLE;

            _buf_full_   <= 1'b0;
            _exp_done_   <= 1'b0;
            fetch_cnt    <= 6'd0;
            exp_active_o <= 1'b0;
            exp_done_o   <= 1'b0;
            //--read bram
            rd_en_o      <= 1'b0;
            rd_addr_o    <= 10'd0;
            rd_bram_addr <= 10'd0;
            //--write ddr
            wr_ddr_en_o     <= 1'b0;
            wr_burst_num_o  <= 5'd0;
            wr_start_addr_o <= 30'd0;
            wr_data_o       <= {oDW{1'b0}};
            //this need to be revised in the future
            wr_ddr_addr     <= WR_START_ADDR; 
        end
        else begin
            case(_cs_)
            EXP_IDLE: begin
                if(ip_done_i) begin
                    _cs_ <= EXP_FETCH_READY;

                    //--export status
                    exp_active_o <= 1'b1;
                    _exp_done_   <= 1'b0;
                    exp_done_o   <= 1'b0;
                    //--read bram
                    rd_en_o <= 1'b1;
                    rd_addr_o <= 10'd0;
                end
                else begin
                    _cs_ <= EXP_IDLE;
                end
            end
            EXP_FETCH_READY: begin
                _cs_ <= EXP_FETCH_DATA;

                //--export status
                exp_active_o <= 1'b1;
                //--read bram
                rd_en_o   <= 1'b1;
                rd_addr_o <= rd_addr_o + 1'b1;
            end
            EXP_FETCH_DATA: begin
                if(_buf_full_) begin
                    if(exp_ack_i) begin
                        _cs_ <= EXP_WRITE_DATA;

                        //--read bram
                        fetch_cnt       <= 6'd0;
                        rd_en_o         <= 1'b0;
                        wr_ddr_en_o     <= 1'b1;
                        wr_start_addr_o <= wr_ddr_addr; 
                    end
                    else begin
                        _cs_ <= EXP_FETCH_DATA;
                    end
                end
                else begin
                    _cs_ <= EXP_FETCH_DATA;

                    //--count fetch data
                    if(fetch_cnt != 6'd32)
                        fetch_cnt   <= fetch_cnt + 1'b1;
                    if(fetch_cnt != 6'd31) begin
                        _buf_full_  <= 1'b0;
                    end
                    else begin
                        _buf_full_   <= 1'b1;
                        rd_bram_addr <= rd_addr_o;
                    end
                    //--read bram
                    rd_en_o   <= 1'b1;
                    if(rd_addr_o == 10'd1000) begin
                        _exp_done_ <= 1'b1;
                    end
                    else if(fetch_cnt != 6'd31) begin
                        rd_addr_o <= rd_addr_o + 1'b1;
                        _exp_done_ <= 1'b0;
                    end
                    if(_exp_done_ && fetch_cnt != 6'd31) begin
                        _exp_buf_[fetch_cnt] <= {iDW{1'b0}};
                    end
                    else if(rd_en_o) begin
                        _exp_buf_[fetch_cnt] <= bram_data_i;
                    end
                end
            end
            EXP_WRITE_DATA: begin
                if(wr_ddr_done_i) begin
                    if(_exp_done_) begin
                        `ifdef SIM
                        _cs_ <= EXP_CHECK_DDR;

                        sim_rd_start_addr_o <= {oAW{1'b0}};
                        sim_rd_start_addr_o <= WR_START_ADDR;
                        sim_rd_burst_num_o  <= 6'd32;
                        `else
                        _cs_ <= EXP_DONE;
                        
                        exp_done_o <= 1'b1;
                        `endif
                    end
                    else begin
                        _cs_ <= EXP_FETCH_READY;

                        //--read bram
                        rd_en_o     <= 1'b1;
                        _buf_full_  <= 1'b0;
                        rd_addr_o   <= rd_bram_addr;
                        //--disable ddr write
                        wr_ddr_en_o <= 1'b0;
                        wr_ddr_addr <= wr_ddr_addr + 4'd8;
                    end
                    //--write ddr
                    wr_ddr_en_o    <= 1'b0;
                    wr_burst_num_o <= 5'd0;
                    wr_data_o      <= {oDW{1'b0}};
                end
                else begin
                    _cs_ <= EXP_WRITE_DATA;
                    
                    //--write ddr
                    if(fetch_data_en_i) begin
                        wr_burst_num_o  <= 5'd1;
                        wr_data_o       <= 
//                          {_exp_buf_[0],  _exp_buf_[1],  _exp_buf_[2],  _exp_buf_[3], 
//                           _exp_buf_[4],  _exp_buf_[5],  _exp_buf_[6],  _exp_buf_[7], 
//                           _exp_buf_[8],  _exp_buf_[9],  _exp_buf_[10], _exp_buf_[11], 
//                           _exp_buf_[12], _exp_buf_[13], _exp_buf_[14], _exp_buf_[15], 
//                           _exp_buf_[16], _exp_buf_[17], _exp_buf_[18], _exp_buf_[19], 
//                           _exp_buf_[20], _exp_buf_[21], _exp_buf_[22], _exp_buf_[23],
//                           _exp_buf_[24], _exp_buf_[25], _exp_buf_[26], _exp_buf_[27], 
//                           _exp_buf_[28], _exp_buf_[29], _exp_buf_[30], _exp_buf_[31]
//                          };
                          {_exp_buf_[31],  _exp_buf_[30],  _exp_buf_[29],  _exp_buf_[28], 
                           _exp_buf_[27],  _exp_buf_[26],  _exp_buf_[25],  _exp_buf_[24], 
                           _exp_buf_[23],  _exp_buf_[22],  _exp_buf_[21], _exp_buf_[20], 
                           _exp_buf_[19],  _exp_buf_[18],  _exp_buf_[17], _exp_buf_[16], 
                           _exp_buf_[15],  _exp_buf_[14],  _exp_buf_[13], _exp_buf_[12], 
                           _exp_buf_[11],  _exp_buf_[10],  _exp_buf_[9],  _exp_buf_[8],
                           _exp_buf_[7],   _exp_buf_[6],   _exp_buf_[5],  _exp_buf_[4], 
                           _exp_buf_[3],   _exp_buf_[2],   _exp_buf_[1],  _exp_buf_[0]
                          };
                    end
                    else begin
                        wr_data_o       <= {oDW{1'b0}};
                    end
                end
            end
            EXP_DONE: begin
                _cs_ <= EXP_IDLE;

                //--internal status
                _buf_full_   <= 1'b0;
                _exp_done_   <= 1'b0;
                exp_done_o   <= 1'b0;
                fetch_cnt    <= 6'd0;
                exp_active_o <= 1'b0;
                //--read bram
                rd_en_o      <= 1'b0;
                rd_addr_o    <= 10'd0;
                rd_bram_addr <= 10'd0;
                //--write ddr
                wr_ddr_en_o     <= 1'b0;
                wr_burst_num_o  <= 5'd0;
                wr_start_addr_o <= 30'd0;
                wr_data_o       <= {oDW{1'b0}};
                wr_ddr_addr     <= WR_START_ADDR; 
            end
            `ifdef SIM
            EXP_CHECK_DDR: begin
                if(sim_rd_ddr_done_i) begin
                    _cs_ <= EXP_IDLE;
                    //--internal status
                    _buf_full_   <= 1'b0;
                    _exp_done_   <= 1'b0;
                    exp_done_o   <= 1'b1;
                    fetch_cnt    <= 6'd0;
                    exp_active_o <= 1'b0;
                    //--read bram
                    rd_en_o      <= 1'b0;
                    rd_addr_o    <= 10'd0;
                    rd_bram_addr <= 10'd0;
                    //--write ddr
                    wr_ddr_en_o     <= 1'b0;
                    wr_burst_num_o  <= 5'd0;
                    wr_start_addr_o <= 30'd0;
                    wr_data_o       <= {oDW{1'b0}};
                    wr_ddr_addr     <= WR_START_ADDR; 
                end
                else begin
                    _cs_ <= EXP_CHECK_DDR;
                end
            end
            `endif
            default: begin
                _cs_ <= EXP_IDLE;

                //--internal status
                _buf_full_ <= 1'b0;
                _exp_done_ <= 1'b0;
                fetch_cnt  <= 6'd0;
                //--read bram
                rd_en_o     <= 1'b0;
                rd_addr_o   <= 10'd0;
                rd_bram_addr <= 10'd0;
                //--write ddr
                wr_ddr_en_o     <= 1'b0;
                wr_burst_num_o  <= 5'd0;
                wr_start_addr_o <= 30'd0;
                wr_data_o       <= {oDW{1'b0}};
                wr_ddr_addr     <= WR_START_ADDR; 
            end
            endcase
        end
    end

    `ifdef SIM
    always @(_cs_ or sim_rd_ddr_done_i) begin
        case(_cs_)
        EXP_CHECK_DDR: begin
            if(sim_rd_ddr_done_i) begin
                sim_rd_ddr_en_o = 1'b0;
            end
            else begin
                sim_rd_ddr_en_o = 1'b1;
            end
        end
        default: begin
            sim_rd_ddr_en_o = 1'b0;
        end
        endcase
    end
    `endif
endmodule
