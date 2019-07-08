// ---------------------------------------------------
// File       : ddr_mem.v
//
// Description: simulate ddr memory behavior
//
// Version    : 1.2
// ---------------------------------------------------

module ddr_mem(
      input   wire          clk,
      input   wire[29:0]    ddr_addr,
      input   wire[2:0]     ddr_cmd,
      input   wire          ddr_en,
      output  reg [511:0]   ddr_rd_data,
      output  reg           ddr_rd_data_end,
      output  reg           ddr_rd_data_valid,
      output  reg           ddr_rdy,
            
      input   wire[511:0]   ddr_wdf_data,
      input   wire[63:0]    ddr_wdf_mask,
      input   wire          ddr_wdf_end,
      input   wire          ddr_wdf_wren,
      output  reg           ddr_wdf_rdy
  );
  reg [63:0]  ker_[7357344]; // 
  reg [63:0]  img_[2097152]; // 64*16*16*4*64
  reg [63:0]  fm1_[2097152]; // 64*16*16*4*64
  reg [63:0]  fm2_[2097152]; // 64*16*16*4*64
  reg [63:0]  out_[32000]; // 64*16*16*4*64
  reg [511:0] fm_data;

  task TSK_OUT_WR;
    input  [25:0]   out_addr;
    input  [511:0]  out_data;
    begin
      $display("%t: write param data @ %.26x", $realtime, out_addr[25:0]);
      {out_[out_addr+7], out_[out_addr+6], out_[out_addr+5], out_[out_addr+4],
       out_[out_addr+3], out_[out_addr+2], out_[out_addr+1], out_[out_addr+0]}
        = out_data;
    end
  endtask
  task TSK_OUT_RD;
    input  [25:0]   out_addr;
    output [511:0]  out_data;
    begin
      $display("%t: read param data @ %.26x", $realtime, out_addr[25:0]);
      assign out_data =
      {out_[out_addr+7], out_[out_addr+6], out_[out_addr+5], out_[out_addr+4],
       out_[out_addr+3], out_[out_addr+2], out_[out_addr+1], out_[out_addr+0]};
    end
  endtask


  task TSK_KER_WR;
    input  [25:0]   ker_addr;
    input  [511:0]  ker_data;
    begin
      $display("%t: write param data @ %.26x", $realtime, ker_addr[25:0]);
      {ker_[ker_addr+7], ker_[ker_addr+6], ker_[ker_addr+5], ker_[ker_addr+4],
       ker_[ker_addr+3], ker_[ker_addr+2], ker_[ker_addr+1], ker_[ker_addr+0]}
        = ker_data;
    end
  endtask
  task TSK_KER_RD;
    input  [25:0]   ker_addr;
    output [511:0]  ker_data;
    begin
      $display("%t: read param data @ %.26x", $realtime, ker_addr[25:0]);
      assign ker_data =
      {ker_[ker_addr+7], ker_[ker_addr+6], ker_[ker_addr+5], ker_[ker_addr+4],
       ker_[ker_addr+3], ker_[ker_addr+2], ker_[ker_addr+1], ker_[ker_addr+0]};
    end
  endtask

  task TSK_IMG_WR;
    input  [25:0]   img_addr;
    input  [511:0]  img_data;
    begin
      $display("%t: write img data @ %.26x", $realtime, img_addr[25:0]);
      {img_[img_addr+7], img_[img_addr+6], img_[img_addr+5], img_[img_addr+4],
       img_[img_addr+3], img_[img_addr+2], img_[img_addr+1], img_[img_addr+0]}
        = img_data;
    end
  endtask
  task TSK_IMG_RD;
    input  [25:0]   img_addr;
    output [511:0]  img_data;
    begin
      $display("%t: read img data @ %.26x", $realtime, img_addr[25:0]);
      assign img_data =
      {img_[img_addr+7], img_[img_addr+6], img_[img_addr+5], img_[img_addr+4],
       img_[img_addr+3], img_[img_addr+2], img_[img_addr+1], img_[img_addr+0]};
    end
  endtask

  task TSK_FM1_WR;
    input  [25:0]   fm1_addr;
    input  [511:0]  fm1_data;
    begin
      $display("%t: write fm1 data @ %.26x", $realtime, fm1_addr[25:0]);
      {fm1_[fm1_addr+7], fm1_[fm1_addr+6], fm1_[fm1_addr+5], fm1_[fm1_addr+4],
       fm1_[fm1_addr+3], fm1_[fm1_addr+2], fm1_[fm1_addr+1], fm1_[fm1_addr+0]}
        = fm1_data;
    end
  endtask
  task TSK_FM1_RD;
    input  [25:0]   fm1_addr;
    output [511:0]  fm1_data;
    begin
      $display("%t: read fm1 data @ %.26x", $realtime, fm1_addr[25:0]);
      assign fm1_data =
      {fm1_[fm1_addr+7], fm1_[fm1_addr+6], fm1_[fm1_addr+5], fm1_[fm1_addr+4],
       fm1_[fm1_addr+3], fm1_[fm1_addr+2], fm1_[fm1_addr+1], fm1_[fm1_addr+0]};
    end
  endtask

  task TSK_FM2_WR;
    input  [25:0]   fm2_addr;
    input  [511:0]  fm2_data;
    begin
      $display("%t: write fm2 data @ %.26x", $realtime, fm2_addr[25:0]);
      {fm2_[fm2_addr+7], fm2_[fm2_addr+6], fm2_[fm2_addr+5], fm2_[fm2_addr+4],
       fm2_[fm2_addr+3], fm2_[fm2_addr+2], fm2_[fm2_addr+1], fm2_[fm2_addr+0]}
        = fm2_data;
    end
  endtask
  task TSK_FM2_RD;
    input  [25:0]   fm2_addr;
    output [511:0]  fm2_data;
    begin
      $display("%t: read fm2 data @ %.26x", $realtime, fm2_addr[25:0]);
      assign fm2_data =
      {fm2_[fm2_addr+7], fm2_[fm2_addr+6], fm2_[fm2_addr+5], fm2_[fm2_addr+4],
       fm2_[fm2_addr+3], fm2_[fm2_addr+2], fm2_[fm2_addr+1], fm2_[fm2_addr+0]};
    end
  endtask

  always@(posedge clk) begin
    ddr_rdy         <= 1'b1;
    ddr_wdf_rdy     <= 1'b1;
    ddr_rd_data_end <= 1'b1;
    if(ddr_en) begin
      if(ddr_cmd == 3'b1) begin // read
        if(ddr_addr[28:26] == 3'd2) begin // param
          TSK_KER_RD(ddr_addr[25:0], fm_data);
          ddr_rd_data       <= fm_data;
          ddr_rd_data_valid <= 1'b1;
        end else if(ddr_addr[28:26] == 3'd3) begin // fm2
          TSK_FM2_RD(ddr_addr[25:0], fm_data);
          ddr_rd_data       <= fm_data;
          ddr_rd_data_valid <= 1'b1;
        end else if(ddr_addr[28:26] == 3'd1) begin // fm1
          TSK_FM1_RD(ddr_addr[25:0], fm_data);
          ddr_rd_data       <= fm_data;
          ddr_rd_data_valid <= 1'b1;
        end else if(ddr_addr[28:26] == 3'd0) begin
          TSK_IMG_RD(ddr_addr[25:0], fm_data);
          ddr_rd_data       <= fm_data;
          ddr_rd_data_valid <= 1'b1;
        end else if(ddr_addr[28:26] == 3'd4) begin
          TSK_OUT_RD(ddr_addr[25:0], fm_data);
          ddr_rd_data       <= fm_data;
          ddr_rd_data_valid <= 1'b1;
        end else begin
          $display("%t: reading address output of simulation range in ddr_mem.v", $realtime);
          #100 $finish;
          ddr_rd_data <= {512{1'b1}};
        end
      end else if(ddr_cmd == 3'b0) begin // write
        if(ddr_wdf_wren) begin
          if(ddr_addr[28:26] == 3'd2) begin // param
            TSK_KER_WR(ddr_addr[25:0], ddr_wdf_data);
          end else if(ddr_addr[28:26] == 3'd3) begin // fm2
            TSK_FM2_WR(ddr_addr[25:0], ddr_wdf_data);
          end else if(ddr_addr[28:26] == 3'd1) begin // fm1
            TSK_FM1_WR(ddr_addr[25:0], ddr_wdf_data);
          end else if(ddr_addr[28:26] == 3'd0) begin // img
            TSK_IMG_WR(ddr_addr[25:0], ddr_wdf_data);
          end else if(ddr_addr[28:26] == 3'd4) begin // img
            TSK_OUT_WR(ddr_addr[25:0], ddr_wdf_data);
          end else begin
            $display("%t: writing address output of simulation range in ddr_mem.v", $realtime);
            #100 $finish;
          end
        end else begin
          $display("%t: ddr_wdf_wren != 1'b1, detected in ddr_mem.v", $realtime);
          #100 $finish;
        end
        if(ddr_wdf_mask!={64{1'b0}}) begin
          $display("%t: ddr_wdf_mask != 64'hfff..f, detected in ddr_mem.v", $realtime);
          #100 $finish;
        end
        if(!ddr_wdf_end) begin
          $display("%t: ddr_wdf_end != 1'b1, detected in ddr_mem.v", $realtime);
          #100 $finish;
        end
      end
    end else begin
      ddr_rd_data       <= {512{1'b1}};
      ddr_rd_data_valid <= 1'b0;
    end
  end

endmodule
