// -----------------------------------------
// conv_op simulation top module
// -----------------------------------------

`define NULL 0
`timescale 1ns/1ps
//`define usingDirectC
//`ifdef usingDirectC
  extern pointer  getFileDescriptor(input string fileName);
  extern void     closeFile(input pointer fileDescriptor);
  extern void     readProcRam(input pointer fileDescriptor,output bit[8*16*16-1:0] procRam,output bit readFileDone);
  extern void     readProcKer(input pointer fileDescriptor,output bit[8*3*3-1:0] procKer,output bit readFileDone);
  extern void     readTopDirectC(input pointer fileDescriptor,output bit[32*14*14-1:0] procTop,output bit readFileDone);
  extern void     cmpCnnCorr(input bit[4:0] bottomExp, input bit[4:0] kerExp, input bit[3:0] convX, input bit[3:0] convY, 
                             input bit[32*14*14-1:0] topDirectC, input bit[16-1:0] convTopFp, inout bit[31:0] err);
//`endif
module top_conv_op;
  localparam K_C = 1;
  localparam K_H = 3;
  localparam K_W = 3;
  localparam IM_C = 1;
  localparam CW_H = 16;
  localparam CW_W = 16;
  localparam DATA_WIDTH = 8;
  localparam EXP_WIDTH = 5;
  localparam FP_WIDTH = 16;
  localparam MID_WIDTH = 29;
  localparam EXP_BOTTOM = 22;
  localparam EXP_KER = 14;
  
  // clocks
  reg                                   clk;
  reg                                   rst_n;
  reg                                   init_calib_complete;
  // convolution
  reg                                   conv_start;   
  reg  [DATA_WIDTH*K_C*K_H*K_W-1:0]     conv_ker;     
  reg  [DATA_WIDTH*CW_H*CW_W-1:0]       conv_bottom; 
  
  reg                                   conv_partial_sum_valid; 
  reg  [K_C*MID_WIDTH-1:0]              conv_partial_sum;
  wire [MID_WIDTH*K_C-1:0]              conv_top;
  wire                                  conv_rd_data_partial_sum;
  reg                                   conv_first_pos;
  reg                                   conv_last_pos;
  reg                                   conv_output_valid;
  wire                                  conv_output_last;
  reg  [3:0]                            conv_x;   
  reg  [3:0]                            conv_y;   
  reg  [3:0]                            conv_to_x;
  reg  [3:0]                            conv_to_y;
  reg                                   conv_busy;
  wire                                  conv_done;
  reg  [FP_WIDTH-1:0]                   conv_top_fp;
  //read from file
  //reg rd_data_file, rd_ker_file, rd_exp_file;
  reg           rd_data_full;
  reg           rd_ker_full;
  reg           rd_top_full;
  reg  [32*14*14-1:0] top_directC;

  initial begin
    rst_n           = 1'b0;
    init_calib_complete = 1'b0;
    #50  rst_n            = 1'b1;
    #100 init_calib_complete  = 1'b1;
  end
  initial clk = 1'b0;
  always #10 clk = ~clk;

  initial begin
    if ($test$plusargs ("dump_all")) begin
      `ifdef VCS //Synopsys VPD dump
        $vcdplusfile("top.vpd");
        $vcdpluson;
        $vcdplusglitchon;
      `endif
    end
  end
  
  integer fd_data, fd_ker, fd_top_c;
  initial begin
    fd_data = getFileDescriptor("../../../../../data/conv_op/conv_bottom_16x16_block_exp22.txt"); // bottom feature map file
    fd_ker = getFileDescriptor("../../../../../data/conv_op/conv_weight_3x3_block_exp14.txt");    // kernel weight file
    fd_top_c = getFileDescriptor("../../../../../data/conv_op/conv_top_14x14_fp32.txt");
    if(fd_data==`NULL || fd_ker==`NULL || fd_top_c==`NULL) begin
      $display("file handles are NULL, CAN NOT OPEN FILES\n");
      $finish;
    end
    conv_start                = 1'b0;
    conv_partial_sum_valid    = 1'b1; 
    conv_partial_sum          = {(K_C*MID_WIDTH){1'b0}};
    rd_data_full              = 1'b0;
    rd_ker_full               = 1'b0;
    rd_top_full               = 1'b0;
//    readProcRam(fd_data, conv_bottom, rd_data_full);
//    readProcKer(fd_ker, conv_ker, rd_ker_full);
//    readTopDirectC(fd_top_c, top_directC, rd_top_full);
  end
  
  always@(posedge rst_n) begin
    readProcRam(fd_data, conv_bottom, rd_data_full);
    readProcKer(fd_ker, conv_ker, rd_ker_full);
    readTopDirectC(fd_top_c, top_directC, rd_top_full);
  end
  
  always@(posedge clk) begin
    if(rd_data_full) begin
      rd_data_full <= 1'b0;
    end
    if(rd_ker_full) begin
      rd_ker_full <= 1'b0;
    end
    if(rd_top_full) begin
      rd_top_full <= 1'b0;
    end
  end
  
//  always@(posedge clk) begin
//    if((!rd_data_full) && rst_n) begin
//      readProcRam(fd_data, conv_bottom, rd_data_full);
      
//    end
//  end
//  always@(posedge clk) begin
//    if((!rd_ker_full) && rst_n) begin
//      readProcKer(fd_ker, conv_ker, rd_ker_full);
//    end
//  end
//  always@(posedge clk) begin
//    if((!rd_top_full) && rst_n) begin
//      readTopDirectC(fd_top_c, top_directC, rd_top_full);
//    end
//  end
  
  // start convolution
  always@(posedge clk) begin
    if(rd_ker_full && rd_data_full && rd_top_full) begin
      conv_start <= 1'b1;
    end else begin
      conv_start <= 1'b0;
    end
  end
  
  wire                              _rd_start;
  reg  [3:0]                        _row;
  reg  [3:0]                        _col;
  reg  [DATA_WIDTH*CW_H-1:0]        _conv_bottom; 
  
  assign _rd_start = conv_start || conv_busy;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      _col <= 4'b0;
      _row <= 4'b0;
    end else begin
      if(_rd_start) begin
        // column
        if(_col!=4'd15) begin // DATA_H-1 - K_H + 1
          _col <= _col+1'b1;
        end else begin
          _col <= 4'd2;
        end
        // row
        if(_row!=4'd13) begin // DATA_W-1 - K_W + 1
          if(_col == 4'd15)
            _row <= _row + 1'b1;
        end else begin
          if(_col == 4'd15)
            _row <= 4'b0;
        end
      end 
      else if(conv_start) begin
        _col <= 4'd0;
        _row <= 4'd0;
      end
    end
  end
  
  always@(posedge clk) begin
    if(_rd_start) begin
    case(_col) //synopsys full_case parallel_case
      4'd0: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*241-1:DATA_WIDTH*240],conv_bottom[DATA_WIDTH*225-1:DATA_WIDTH*224],conv_bottom[DATA_WIDTH*209-1:DATA_WIDTH*208],conv_bottom[DATA_WIDTH*193-1:DATA_WIDTH*192],
                        conv_bottom[DATA_WIDTH*177-1:DATA_WIDTH*176],conv_bottom[DATA_WIDTH*161-1:DATA_WIDTH*160],conv_bottom[DATA_WIDTH*145-1:DATA_WIDTH*144],conv_bottom[DATA_WIDTH*129-1:DATA_WIDTH*128],
                        conv_bottom[DATA_WIDTH*113-1:DATA_WIDTH*112],conv_bottom[DATA_WIDTH*97-1:DATA_WIDTH*96],  conv_bottom[DATA_WIDTH*81-1:DATA_WIDTH*80],  conv_bottom[DATA_WIDTH*65-1:DATA_WIDTH*64],
                        conv_bottom[DATA_WIDTH*49-1:DATA_WIDTH*48],  conv_bottom[DATA_WIDTH*33-1:DATA_WIDTH*32],  conv_bottom[DATA_WIDTH*17-1:DATA_WIDTH*16],  conv_bottom[DATA_WIDTH*1-1:DATA_WIDTH*0]};
      end
      4'd1: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*242-1:DATA_WIDTH*241],conv_bottom[DATA_WIDTH*226-1:DATA_WIDTH*225],conv_bottom[DATA_WIDTH*210-1:DATA_WIDTH*209],conv_bottom[DATA_WIDTH*194-1:DATA_WIDTH*193],
                        conv_bottom[DATA_WIDTH*178-1:DATA_WIDTH*177],conv_bottom[DATA_WIDTH*162-1:DATA_WIDTH*161],conv_bottom[DATA_WIDTH*146-1:DATA_WIDTH*145],conv_bottom[DATA_WIDTH*130-1:DATA_WIDTH*129],
                        conv_bottom[DATA_WIDTH*114-1:DATA_WIDTH*113],conv_bottom[DATA_WIDTH*98-1:DATA_WIDTH*97],  conv_bottom[DATA_WIDTH*82-1:DATA_WIDTH*81],  conv_bottom[DATA_WIDTH*66-1:DATA_WIDTH*65],
                        conv_bottom[DATA_WIDTH*50-1:DATA_WIDTH*49],  conv_bottom[DATA_WIDTH*34-1:DATA_WIDTH*33],  conv_bottom[DATA_WIDTH*18-1:DATA_WIDTH*17],  conv_bottom[DATA_WIDTH*2-1:DATA_WIDTH*1]};
      end
      4'd2: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*243-1:DATA_WIDTH*242],conv_bottom[DATA_WIDTH*227-1:DATA_WIDTH*226],conv_bottom[DATA_WIDTH*211-1:DATA_WIDTH*210],conv_bottom[DATA_WIDTH*195-1:DATA_WIDTH*194],
                        conv_bottom[DATA_WIDTH*179-1:DATA_WIDTH*178],conv_bottom[DATA_WIDTH*163-1:DATA_WIDTH*162],conv_bottom[DATA_WIDTH*147-1:DATA_WIDTH*146],conv_bottom[DATA_WIDTH*131-1:DATA_WIDTH*130],
                        conv_bottom[DATA_WIDTH*115-1:DATA_WIDTH*114],conv_bottom[DATA_WIDTH*99-1:DATA_WIDTH*98],  conv_bottom[DATA_WIDTH*83-1:DATA_WIDTH*82],  conv_bottom[DATA_WIDTH*67-1:DATA_WIDTH*66],
                        conv_bottom[DATA_WIDTH*51-1:DATA_WIDTH*50],  conv_bottom[DATA_WIDTH*35-1:DATA_WIDTH*34],  conv_bottom[DATA_WIDTH*19-1:DATA_WIDTH*18],  conv_bottom[DATA_WIDTH*3-1:DATA_WIDTH*2]};
      end
      4'd3: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*244-1:DATA_WIDTH*243],conv_bottom[DATA_WIDTH*228-1:DATA_WIDTH*227],conv_bottom[DATA_WIDTH*212-1:DATA_WIDTH*211],conv_bottom[DATA_WIDTH*196-1:DATA_WIDTH*195],
                        conv_bottom[DATA_WIDTH*180-1:DATA_WIDTH*179],conv_bottom[DATA_WIDTH*164-1:DATA_WIDTH*163],conv_bottom[DATA_WIDTH*148-1:DATA_WIDTH*147],conv_bottom[DATA_WIDTH*132-1:DATA_WIDTH*131],
                        conv_bottom[DATA_WIDTH*116-1:DATA_WIDTH*115],conv_bottom[DATA_WIDTH*100-1:DATA_WIDTH*99], conv_bottom[DATA_WIDTH*84-1:DATA_WIDTH*83],  conv_bottom[DATA_WIDTH*68-1:DATA_WIDTH*67],
                        conv_bottom[DATA_WIDTH*52-1:DATA_WIDTH*51],  conv_bottom[DATA_WIDTH*36-1:DATA_WIDTH*35],  conv_bottom[DATA_WIDTH*20-1:DATA_WIDTH*19],  conv_bottom[DATA_WIDTH*4-1:DATA_WIDTH*3]};
      end
      4'd4: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*245-1:DATA_WIDTH*244],conv_bottom[DATA_WIDTH*229-1:DATA_WIDTH*228],conv_bottom[DATA_WIDTH*213-1:DATA_WIDTH*212],conv_bottom[DATA_WIDTH*197-1:DATA_WIDTH*196],
                        conv_bottom[DATA_WIDTH*181-1:DATA_WIDTH*180],conv_bottom[DATA_WIDTH*165-1:DATA_WIDTH*164],conv_bottom[DATA_WIDTH*149-1:DATA_WIDTH*148],conv_bottom[DATA_WIDTH*133-1:DATA_WIDTH*132],
                        conv_bottom[DATA_WIDTH*117-1:DATA_WIDTH*116],conv_bottom[DATA_WIDTH*101-1:DATA_WIDTH*100],conv_bottom[DATA_WIDTH*85-1:DATA_WIDTH*84],  conv_bottom[DATA_WIDTH*69-1:DATA_WIDTH*68],
                        conv_bottom[DATA_WIDTH*53-1:DATA_WIDTH*52],  conv_bottom[DATA_WIDTH*37-1:DATA_WIDTH*36],  conv_bottom[DATA_WIDTH*21-1:DATA_WIDTH*20],  conv_bottom[DATA_WIDTH*5-1:DATA_WIDTH*4]};
      end
      4'd5: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*246-1:DATA_WIDTH*245],conv_bottom[DATA_WIDTH*230-1:DATA_WIDTH*229],conv_bottom[DATA_WIDTH*214-1:DATA_WIDTH*213],conv_bottom[DATA_WIDTH*198-1:DATA_WIDTH*197],
                        conv_bottom[DATA_WIDTH*182-1:DATA_WIDTH*181],conv_bottom[DATA_WIDTH*166-1:DATA_WIDTH*165],conv_bottom[DATA_WIDTH*150-1:DATA_WIDTH*149],conv_bottom[DATA_WIDTH*134-1:DATA_WIDTH*133],
                        conv_bottom[DATA_WIDTH*118-1:DATA_WIDTH*117],conv_bottom[DATA_WIDTH*102-1:DATA_WIDTH*101],conv_bottom[DATA_WIDTH*86-1:DATA_WIDTH*85],  conv_bottom[DATA_WIDTH*70-1:DATA_WIDTH*69],
                        conv_bottom[DATA_WIDTH*54-1:DATA_WIDTH*53],  conv_bottom[DATA_WIDTH*38-1:DATA_WIDTH*37],  conv_bottom[DATA_WIDTH*22-1:DATA_WIDTH*21],  conv_bottom[DATA_WIDTH*6-1:DATA_WIDTH*5]};
      end
      4'd6: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*247-1:DATA_WIDTH*246],conv_bottom[DATA_WIDTH*231-1:DATA_WIDTH*230],conv_bottom[DATA_WIDTH*215-1:DATA_WIDTH*214],conv_bottom[DATA_WIDTH*199-1:DATA_WIDTH*198],
                        conv_bottom[DATA_WIDTH*183-1:DATA_WIDTH*182],conv_bottom[DATA_WIDTH*167-1:DATA_WIDTH*166],conv_bottom[DATA_WIDTH*151-1:DATA_WIDTH*150],conv_bottom[DATA_WIDTH*135-1:DATA_WIDTH*134],
                        conv_bottom[DATA_WIDTH*119-1:DATA_WIDTH*118],conv_bottom[DATA_WIDTH*103-1:DATA_WIDTH*102],conv_bottom[DATA_WIDTH*87-1:DATA_WIDTH*86],  conv_bottom[DATA_WIDTH*71-1:DATA_WIDTH*70],
                        conv_bottom[DATA_WIDTH*55-1:DATA_WIDTH*54],  conv_bottom[DATA_WIDTH*39-1:DATA_WIDTH*38],  conv_bottom[DATA_WIDTH*23-1:DATA_WIDTH*22],  conv_bottom[DATA_WIDTH*7-1:DATA_WIDTH*6]};
      end
      4'd7: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*248-1:DATA_WIDTH*247],conv_bottom[DATA_WIDTH*232-1:DATA_WIDTH*231],conv_bottom[DATA_WIDTH*216-1:DATA_WIDTH*215],conv_bottom[DATA_WIDTH*200-1:DATA_WIDTH*199],
                        conv_bottom[DATA_WIDTH*184-1:DATA_WIDTH*183],conv_bottom[DATA_WIDTH*168-1:DATA_WIDTH*167],conv_bottom[DATA_WIDTH*152-1:DATA_WIDTH*151],conv_bottom[DATA_WIDTH*136-1:DATA_WIDTH*135],
                        conv_bottom[DATA_WIDTH*120-1:DATA_WIDTH*119],conv_bottom[DATA_WIDTH*104-1:DATA_WIDTH*103],conv_bottom[DATA_WIDTH*88-1:DATA_WIDTH*87],  conv_bottom[DATA_WIDTH*72-1:DATA_WIDTH*71],
                        conv_bottom[DATA_WIDTH*56-1:DATA_WIDTH*55],  conv_bottom[DATA_WIDTH*40-1:DATA_WIDTH*39],  conv_bottom[DATA_WIDTH*24-1:DATA_WIDTH*23],  conv_bottom[DATA_WIDTH*8-1:DATA_WIDTH*7]};
      end
      4'd8: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*249-1:DATA_WIDTH*248],conv_bottom[DATA_WIDTH*233-1:DATA_WIDTH*232],conv_bottom[DATA_WIDTH*217-1:DATA_WIDTH*216],conv_bottom[DATA_WIDTH*201-1:DATA_WIDTH*200],
                        conv_bottom[DATA_WIDTH*185-1:DATA_WIDTH*184],conv_bottom[DATA_WIDTH*169-1:DATA_WIDTH*168],conv_bottom[DATA_WIDTH*153-1:DATA_WIDTH*152],conv_bottom[DATA_WIDTH*137-1:DATA_WIDTH*136],
                        conv_bottom[DATA_WIDTH*121-1:DATA_WIDTH*120],conv_bottom[DATA_WIDTH*105-1:DATA_WIDTH*104],conv_bottom[DATA_WIDTH*89-1:DATA_WIDTH*88],  conv_bottom[DATA_WIDTH*73-1:DATA_WIDTH*72],
                        conv_bottom[DATA_WIDTH*57-1:DATA_WIDTH*56],  conv_bottom[DATA_WIDTH*41-1:DATA_WIDTH*40],  conv_bottom[DATA_WIDTH*25-1:DATA_WIDTH*24],  conv_bottom[DATA_WIDTH*9-1:DATA_WIDTH*8]};
      end
      4'd9: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*250-1:DATA_WIDTH*249],conv_bottom[DATA_WIDTH*234-1:DATA_WIDTH*233],conv_bottom[DATA_WIDTH*218-1:DATA_WIDTH*217],conv_bottom[DATA_WIDTH*202-1:DATA_WIDTH*201],
                        conv_bottom[DATA_WIDTH*186-1:DATA_WIDTH*185],conv_bottom[DATA_WIDTH*170-1:DATA_WIDTH*169],conv_bottom[DATA_WIDTH*154-1:DATA_WIDTH*153],conv_bottom[DATA_WIDTH*138-1:DATA_WIDTH*137],
                        conv_bottom[DATA_WIDTH*122-1:DATA_WIDTH*121],conv_bottom[DATA_WIDTH*106-1:DATA_WIDTH*105],conv_bottom[DATA_WIDTH*90-1:DATA_WIDTH*89],  conv_bottom[DATA_WIDTH*74-1:DATA_WIDTH*73],
                        conv_bottom[DATA_WIDTH*58-1:DATA_WIDTH*57],  conv_bottom[DATA_WIDTH*42-1:DATA_WIDTH*41],  conv_bottom[DATA_WIDTH*26-1:DATA_WIDTH*25],  conv_bottom[DATA_WIDTH*10-1:DATA_WIDTH*9]};
      end
      4'd10: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*251-1:DATA_WIDTH*250],conv_bottom[DATA_WIDTH*235-1:DATA_WIDTH*234],conv_bottom[DATA_WIDTH*219-1:DATA_WIDTH*218],conv_bottom[DATA_WIDTH*203-1:DATA_WIDTH*202],
                        conv_bottom[DATA_WIDTH*187-1:DATA_WIDTH*186],conv_bottom[DATA_WIDTH*171-1:DATA_WIDTH*170],conv_bottom[DATA_WIDTH*155-1:DATA_WIDTH*154],conv_bottom[DATA_WIDTH*139-1:DATA_WIDTH*138],
                        conv_bottom[DATA_WIDTH*123-1:DATA_WIDTH*122],conv_bottom[DATA_WIDTH*107-1:DATA_WIDTH*106],conv_bottom[DATA_WIDTH*91-1:DATA_WIDTH*90],  conv_bottom[DATA_WIDTH*75-1:DATA_WIDTH*74],
                        conv_bottom[DATA_WIDTH*59-1:DATA_WIDTH*58],  conv_bottom[DATA_WIDTH*43-1:DATA_WIDTH*42],  conv_bottom[DATA_WIDTH*27-1:DATA_WIDTH*26],  conv_bottom[DATA_WIDTH*11-1:DATA_WIDTH*10]};
      end
      4'd11: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*252-1:DATA_WIDTH*251],conv_bottom[DATA_WIDTH*236-1:DATA_WIDTH*235],conv_bottom[DATA_WIDTH*220-1:DATA_WIDTH*219],conv_bottom[DATA_WIDTH*204-1:DATA_WIDTH*203],
                        conv_bottom[DATA_WIDTH*188-1:DATA_WIDTH*187],conv_bottom[DATA_WIDTH*172-1:DATA_WIDTH*171],conv_bottom[DATA_WIDTH*156-1:DATA_WIDTH*155],conv_bottom[DATA_WIDTH*140-1:DATA_WIDTH*139],
                        conv_bottom[DATA_WIDTH*124-1:DATA_WIDTH*123],conv_bottom[DATA_WIDTH*108-1:DATA_WIDTH*107],conv_bottom[DATA_WIDTH*92-1:DATA_WIDTH*91],  conv_bottom[DATA_WIDTH*76-1:DATA_WIDTH*75],
                        conv_bottom[DATA_WIDTH*60-1:DATA_WIDTH*59],  conv_bottom[DATA_WIDTH*44-1:DATA_WIDTH*43],  conv_bottom[DATA_WIDTH*28-1:DATA_WIDTH*27],  conv_bottom[DATA_WIDTH*12-1:DATA_WIDTH*11]};
      end
      4'd12: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*253-1:DATA_WIDTH*252],conv_bottom[DATA_WIDTH*237-1:DATA_WIDTH*236],conv_bottom[DATA_WIDTH*221-1:DATA_WIDTH*220],conv_bottom[DATA_WIDTH*205-1:DATA_WIDTH*204],
                        conv_bottom[DATA_WIDTH*189-1:DATA_WIDTH*188],conv_bottom[DATA_WIDTH*173-1:DATA_WIDTH*172],conv_bottom[DATA_WIDTH*157-1:DATA_WIDTH*156],conv_bottom[DATA_WIDTH*141-1:DATA_WIDTH*140],
                        conv_bottom[DATA_WIDTH*125-1:DATA_WIDTH*124],conv_bottom[DATA_WIDTH*109-1:DATA_WIDTH*108],conv_bottom[DATA_WIDTH*93-1:DATA_WIDTH*92],  conv_bottom[DATA_WIDTH*77-1:DATA_WIDTH*76],
                        conv_bottom[DATA_WIDTH*61-1:DATA_WIDTH*60],  conv_bottom[DATA_WIDTH*45-1:DATA_WIDTH*44],  conv_bottom[DATA_WIDTH*29-1:DATA_WIDTH*28],  conv_bottom[DATA_WIDTH*13-1:DATA_WIDTH*12]};
      end
      4'd13: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*254-1:DATA_WIDTH*253],conv_bottom[DATA_WIDTH*238-1:DATA_WIDTH*237],conv_bottom[DATA_WIDTH*222-1:DATA_WIDTH*221],conv_bottom[DATA_WIDTH*206-1:DATA_WIDTH*205],
                        conv_bottom[DATA_WIDTH*190-1:DATA_WIDTH*189],conv_bottom[DATA_WIDTH*174-1:DATA_WIDTH*173],conv_bottom[DATA_WIDTH*158-1:DATA_WIDTH*157],conv_bottom[DATA_WIDTH*142-1:DATA_WIDTH*141],
                        conv_bottom[DATA_WIDTH*126-1:DATA_WIDTH*125],conv_bottom[DATA_WIDTH*110-1:DATA_WIDTH*109],conv_bottom[DATA_WIDTH*94-1:DATA_WIDTH*93],  conv_bottom[DATA_WIDTH*78-1:DATA_WIDTH*77],
                        conv_bottom[DATA_WIDTH*62-1:DATA_WIDTH*61],  conv_bottom[DATA_WIDTH*46-1:DATA_WIDTH*45],  conv_bottom[DATA_WIDTH*30-1:DATA_WIDTH*29],  conv_bottom[DATA_WIDTH*14-1:DATA_WIDTH*13]};
      end
      4'd14: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*255-1:DATA_WIDTH*254],conv_bottom[DATA_WIDTH*239-1:DATA_WIDTH*238],conv_bottom[DATA_WIDTH*223-1:DATA_WIDTH*222],conv_bottom[DATA_WIDTH*207-1:DATA_WIDTH*206],
                        conv_bottom[DATA_WIDTH*191-1:DATA_WIDTH*190],conv_bottom[DATA_WIDTH*175-1:DATA_WIDTH*174],conv_bottom[DATA_WIDTH*159-1:DATA_WIDTH*158],conv_bottom[DATA_WIDTH*143-1:DATA_WIDTH*142],
                        conv_bottom[DATA_WIDTH*127-1:DATA_WIDTH*126],conv_bottom[DATA_WIDTH*111-1:DATA_WIDTH*110],conv_bottom[DATA_WIDTH*95-1:DATA_WIDTH*94],  conv_bottom[DATA_WIDTH*79-1:DATA_WIDTH*78],
                        conv_bottom[DATA_WIDTH*63-1:DATA_WIDTH*62],  conv_bottom[DATA_WIDTH*47-1:DATA_WIDTH*46],  conv_bottom[DATA_WIDTH*31-1:DATA_WIDTH*30],  conv_bottom[DATA_WIDTH*15-1:DATA_WIDTH*14]};
      end
      4'd15: begin
        _conv_bottom <= {conv_bottom[DATA_WIDTH*256-1:DATA_WIDTH*255],conv_bottom[DATA_WIDTH*240-1:DATA_WIDTH*239],conv_bottom[DATA_WIDTH*224-1:DATA_WIDTH*223],conv_bottom[DATA_WIDTH*208-1:DATA_WIDTH*207],
                        conv_bottom[DATA_WIDTH*192-1:DATA_WIDTH*191],conv_bottom[DATA_WIDTH*176-1:DATA_WIDTH*175],conv_bottom[DATA_WIDTH*160-1:DATA_WIDTH*159],conv_bottom[DATA_WIDTH*144-1:DATA_WIDTH*143],
                        conv_bottom[DATA_WIDTH*128-1:DATA_WIDTH*127],conv_bottom[DATA_WIDTH*112-1:DATA_WIDTH*111],conv_bottom[DATA_WIDTH*96-1:DATA_WIDTH*95],  conv_bottom[DATA_WIDTH*80-1:DATA_WIDTH*79],
                        conv_bottom[DATA_WIDTH*64-1:DATA_WIDTH*63],  conv_bottom[DATA_WIDTH*48-1:DATA_WIDTH*47],  conv_bottom[DATA_WIDTH*32-1:DATA_WIDTH*31],  conv_bottom[DATA_WIDTH*16-1:DATA_WIDTH*15]};
      end
    endcase
    end
  end

//conv_op ctrl
  conv_op#(
    .K_C(K_C),       
    .K_H(K_H),         
    .K_W(K_W),   
    .CW_H(CW_H),   
    .CW_W(CW_W),
    .DATA_WIDTH(DATA_WIDTH),
    .EXP_WIDTH(EXP_WIDTH),
    .MID_WIDTH(MID_WIDTH)
  )conv_op_u(
    //for debug
    .rd_col(_col),
    .rd_row(_row),
  
    .conv_rst_n(rst_n),
    .conv_clk(clk),
    .conv_start(conv_start),
    .conv_ker(conv_ker),
    .conv_bottom(_conv_bottom),
    .conv_partial_sum_valid(conv_partial_sum_valid), 
    .conv_partial_sum(conv_partial_sum),
    .conv_top(conv_top),
    .conv_rd_data_partial_sum(conv_rd_data_partial_sum),
    .conv_first_pos(conv_first_pos),
    .conv_last_pos(conv_last_pos), 
    .conv_output_valid(conv_output_valid),
    .conv_output_last(conv_output_last),
    .conv_x(conv_x),
    .conv_y(conv_y),
    .conv_to_x(conv_to_x),
    .conv_to_y(conv_to_y),
    .conv_busy(conv_busy)
  );
  
  fixed_to_float #(
    .FP_WIDTH(FP_WIDTH),
    .MID_WIDTH(MID_WIDTH)
  )fixed_to_float_u(
    .datain(conv_top),
//    .expin(EXP_BOTTOM+EXP_KER),
    .datain_valid(conv_output_valid),
    .dataout(conv_top_fp)
  );
  
  //compare
  reg  [31:0]           err;
  always@(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      err = 32'd0;
    end else if(conv_output_valid)begin
      cmpCnnCorr(EXP_BOTTOM, EXP_KER, conv_x, conv_y, top_directC, conv_top_fp, err);
    end
  end
  
  // terminate
  assign conv_done = (conv_x == 4'd13) && (conv_y == 4'd13);
  always@(posedge clk) begin
    if(conv_done) begin
      closeFile(fd_data);
      closeFile(fd_ker);
      $finish;
    end
  end

  
endmodule
