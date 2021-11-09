// this is the top module of my graduate verilog code
// i need to modify the width of message, 5 bits not ok
// vivado systhesis needs right logic,or some module may be earsed
module TOP_FPGA (
    input    clk,
    input    rst,
    //input    [4:0]              LLR_in,  //-15--+15  initial by coe file
    //input                       new_fram, // start decode a new fram
                                // active to initial the memeory
    //output   [26111:0]   codeword,
    //output               DV_codeword,
    output   reg    [4:0]       iteration,
    output   reg                Decode_over

);

//***********input buffer***************//
//wire    [2303:0]    LLR;
//inputbuffer  U_buffer(
//    .clk    (clk),
//    .LLR_in    (LLR_in),
//    .LLR       (LLR)
//);

//******instance app memory*************//
wire    [2303:0]    to_app;   //mux to app
wire    [2303:0]    app_out;
reg                 app_rd_en;
reg     [6:0]       app_rd_addr;
reg     [6:0]       app_wr_addr;
reg                 app_wr_en;      

// a for write , b for read
APP_RAM  u_app_ram(   
    .doutb    (app_out),
    .dina     (to_app),
    .clka     (clk),
    .clkb     (clk),
    .ena      (1'b1),
    .enb      (app_rd_en),
    .addrb    (app_rd_addr),
    .addra    (app_wr_addr),
    .wea      (app_wr_en)
);
//******************************************//

//*******appshifter****************************//

reg     [8:0]      app_shift_sel;
wire    [2303:0]   app_shift_to_subtracter;
right_shifter384 u_right_shift(
    .app          (app_out),
    .sel          (app_shift_sel),
    .shift_app    (app_shift_to_subtracter)
);

//*****************************************//

//**********submatrix subtraction***********//
// plus : shifer  to VN2CN memory
wire    [1535:0]    CN2VN_RAM_out_not;     //384*4=1536
wire    [2303:0]    submatrix_VN2CN;
wire    [1535:0]    CN2VN_RAM_out;  //32*48 = 1536
wire    [1535:0]    CN2VN_ram_out_shift;
assign CN2VN_RAM_out_not = ~CN2VN_ram_out_shift;

// subtraction
submatrix_384 subtractor(
    .app        (app_shift_to_subtracter),
    .CN2VN      (CN2VN_RAM_out_not),
    .VN2CN      (submatrix_VN2CN)
);

reg     [4:0]       to_vn2cn_ram_sel;
wire    [2303:0]    to_VN2CN_ram;
barrel_shift2    u_barrel_right_VN2CN(
    .CN2VN_4bit    (submatrix_VN2CN),
    .sel           (to_vn2cn_ram_sel),
    .CN2VN_ram     (to_VN2CN_ram)
);
//*************************************
  
//*********instance  VN2CN_RAM************//
wire    [2303:0]    VN2CN_RAM_out;   //32*72 = 2304

reg     [31:0]      rd_en_VN2CN_RAM;
reg     [31:0]      wr_en_VN2CN_RAM;
reg     [159:0]     rd_addr_VN2CN_RAM;  //32*5=160
reg     [159:0]     wr_addr_VN2CN_RAM;
genvar i;
generate for ( i = 0; i < 32; i = i+ 1 )
begin : U_vn2cn_ram
VN2CN_RAM U_VN2CN_ram(
        .doutb     (VN2CN_RAM_out[i*72+71:i*72]),
        .dina     (to_VN2CN_ram[i*72+71:i*72]),
        .clka      (clk),
        .clkb      (clk),
        .enb       (rd_en_VN2CN_RAM[i]),
        .addrb     (rd_addr_VN2CN_RAM[i*5+4:i*5]),
        .addra     (wr_addr_VN2CN_RAM[i*5+4:i*5]),
        .wea       (wr_en_VN2CN_RAM[i])
    );

end
endgenerate
//***********instance  over******************//

// lack of a barrel shift   
wire    [2303:0]    VN2CN_RAM_out_temp;
reg     [4:0]       VN2CN_RAM_out_sel;
barrel_shift2  u_barrel_right(           //shift right
    .CN2VN_4bit    (VN2CN_RAM_out),
    .sel           (VN2CN_RAM_out_sel),
    .CN2VN_ram     (VN2CN_RAM_out_temp)
);



//***********to cn***************************//
wire    [1367:0]    to_CNU;
assign    to_CNU = VN2CN_RAM_out_temp[1367:0];  // 19*60 = 1140 
reg     reset_counter;                          //19*72  = 1368
reg     en_lock_message;
reg     [18:0]    max_valid;
reg     [2:0]     RandomNum;
wire    [911:0]   cn_submatrix;                 //19*48=912
                                           
matrix2matrix U_matrix2matrix(
    .clk    (clk),
    .reset_n     (reset_counter),
    .en_lock_message  (en_lock_message),
    .submatrix0out    (to_CNU[71:0]),    
    .submatrix1out    (to_CNU[143:72]),
    .submatrix2out    (to_CNU[215:144]),
    .submatrix3out    (to_CNU[287:216]),
    .submatrix4out    (to_CNU[359:288]),
    .submatrix5out    (to_CNU[431:360]),
    .submatrix6out    (to_CNU[503:432]),
    .submatrix7out    (to_CNU[575:504]),
    .submatrix8out    (to_CNU[647:576]),
    .submatrix9out    (to_CNU[719:648]),
    .submatrix10out    (to_CNU[791:720]),
    .submatrix11out    (to_CNU[863:792]),
    .submatrix12out    (to_CNU[935:864]),
    .submatrix13out    (to_CNU[1007:936]),
    .submatrix14out    (to_CNU[1079:1008]),    
    .submatrix15out    (to_CNU[1151:1080]),    
    .submatrix16out    (to_CNU[1223:1152]),    
    .submatrix17out    (to_CNU[1295:1224]),    
    .submatrix18out    (to_CNU[1367:1296]), 
    .max_valid         (max_valid),
    .RandomNum         (RandomNum),
    .cn_submatrix0     (cn_submatrix[47:0]),   
    .cn_submatrix1     (cn_submatrix[95:48]),   
    .cn_submatrix2     (cn_submatrix[143:96]),   
    .cn_submatrix3     (cn_submatrix[191:144]),   
    .cn_submatrix4     (cn_submatrix[239:192]),   
    .cn_submatrix5     (cn_submatrix[287:240]),   
    .cn_submatrix6     (cn_submatrix[335:288]),   
    .cn_submatrix7     (cn_submatrix[383:336]),   
    .cn_submatrix8     (cn_submatrix[431:384]),   
    .cn_submatrix9     (cn_submatrix[479:432]),   
    .cn_submatrix10     (cn_submatrix[527:480]),   
    .cn_submatrix11     (cn_submatrix[575:528]),   
    .cn_submatrix12     (cn_submatrix[623:576]),   
    .cn_submatrix13     (cn_submatrix[671:624]),   
    .cn_submatrix14     (cn_submatrix[719:672]),   
    .cn_submatrix15     (cn_submatrix[767:720]),   
    .cn_submatrix16     (cn_submatrix[815:768]),   
    .cn_submatrix17     (cn_submatrix[863:816]),   
    .cn_submatrix18     (cn_submatrix[911:864]) 
);

reg    [159:0]    CN2VN_mux_sel;  //32*5 = 160
wire   [1535:0]   CN2VN_mux_out;   //32*48=1536
genvar j;
generate for(j = 0;j < 32;j = j+ 1)
begin : mux19_1
mux_19_1 u_mux_19_1(
    .in0            (cn_submatrix[47:0]),   
    .in1            (cn_submatrix[95:48]),   
    .in2            (cn_submatrix[143:96]),  
    .in3            (cn_submatrix[191:144]), 
    .in4            (cn_submatrix[239:192]), 
    .in5            (cn_submatrix[287:240]), 
    .in6            (cn_submatrix[335:288]), 
    .in7            (cn_submatrix[383:336]), 
    .in8            (cn_submatrix[431:384]), 
    .in9            (cn_submatrix[479:432]), 
    .in10            (cn_submatrix[527:480]),
    .in11            (cn_submatrix[575:528]),
    .in12            (cn_submatrix[623:576]),
    .in13            (cn_submatrix[671:624]),
    .in14            (cn_submatrix[719:672]),
    .in15            (cn_submatrix[767:720]),
    .in16            (cn_submatrix[815:768]),
    .in17            (cn_submatrix[863:816]),
    .in18            (cn_submatrix[911:864]),
    .sel             (CN2VN_mux_sel[j*5+4:j*5]),
    .mux_out         (CN2VN_mux_out[j*48+47:j*48])
     
);

end
endgenerate


reg    [351:0]    CN2VN_RAM_rd_addr;  // 32*11 = 352
reg    [351:0]    CN2VN_RAM_wr_addr;
reg    [31:0]     CN2VN_RAM_rd_en;
reg    [31:0]     CN2VN_RAM_wr_en;
//wire   [1535:0]    CN2VN_RAM_out;  //32*48 = 1536
genvar k;
generate for (k = 0; k<32 ; k = k + 1)
begin : cn2vn_memory
CN2VN_RAM   U_CN2VN_RAM(
    .doutb     (CN2VN_RAM_out[k*48+47:k*48]),
    .dina      (CN2VN_mux_out[k*48+47:k*48]),
    .clka      (clk),
    .clkb      (clk),
    .enb       (CN2VN_RAM_rd_en[k]),
    .addrb     (CN2VN_RAM_rd_addr[k*11+10:k*11]),
    .addra     (CN2VN_RAM_wr_addr[k*11+10:k*11]),
    .wea       (CN2VN_RAM_wr_en[k]) 
);
end
endgenerate

reg    [4:0]    sel_cn2vn_ram;
//wire    [1535:0]    CN2VN_ram_out_shift;
barrel_1535_rightshift U_1535_right_shift(
    .CN2VN_ram_out          (CN2VN_RAM_out),
    .sel                    (sel_cn2vn_ram),
    .CN2VN_ram_shift    (CN2VN_ram_out_shift)
);
//*************cn over*****************************//

//********** adder to get new app*******************//
wire    [2303:0]    app_adder_out;
submatrix_384   U_app_adder(
    .app     (VN2CN_RAM_out_temp),
    .CN2VN   (CN2VN_ram_out_shift),
    .VN2CN   (app_adder_out)
);

//*****************************************************//

//*******  app shift  *************************************//
//wire    [2303:0]    to_app_temp;
reg    [8:0]       app_rightshift_sel;
right_shifter384   U_rightshift384(
    .app       (app_adder_out),
    .sel       (app_rightshift_sel),
    .shift_app (to_app)
);

//assign to_app = (new_fram == 1'b1 ) ? LLR : to_app_temp;

//******************** fixed iterations , excluding earlystop*******************//
//wire    [383:0]    partialcodeword;
//genvar i2;
//generate for(i2 = 0; i2 < 384; i2 = i2 + 1 )
//begin : codewordshift
//    assign partialcodeword[i2] = app_out[i2*6+5]; //-31--+31  6 bits Q
//    end
//endgenerate

//reg    [26111:0]    codeword;
//always @(posedge clk ) begin
//    codeword <= {partialcodeword,codeword[26111:383]};
//    
//end

//reg    start_early_stop;       // generate by FSM

//partialearlystop U_stop(
//    .clk    (clk),
//    .rst    (rst),
//    .start_early_stop    (start_early_stop),
//    .app_rd_addr         (app_rd_addr),
//    .partialcodeword     (partialcodeword),
//    .iteration           (iteration),
//    .decode_over         (Decode_over)
//);

//earlystop2 U_stop(
//    .codeword    (codeword),
//    .check_sum    (Decode_over)
//);

//********************************************************************************

//**** initial driver  control unit FSM*****************
always @(posedge clk , posedge rst) begin
    if(rst) begin
        app_rd_en <= 1'b1;
        app_wr_en <= 1'b1;
        app_rd_addr <= 7'd0;
        app_wr_addr <= 7'd0;
        app_shift_sel <= 9'd0;
        to_vn2cn_ram_sel <= 5'd0;
        rd_en_VN2CN_RAM <= 32'd0;
        wr_en_VN2CN_RAM <= 32'd0;
        rd_addr_VN2CN_RAM <= 160'd0;
        wr_addr_VN2CN_RAM <= 160'd0;
        VN2CN_RAM_out_sel <= 5'd0;
        reset_counter <= 1'b0;
        en_lock_message <= 1'b0;
        max_valid <= 19'd0;
        RandomNum <= 3'b111;
        CN2VN_mux_sel <= 160'd0;
        CN2VN_RAM_rd_addr <= 352'd0;
        CN2VN_RAM_wr_addr <= 352'd0;
        CN2VN_RAM_rd_en <= 352'd0;
        CN2VN_RAM_wr_en <= 352'd0;
        sel_cn2vn_ram <= 5'd0;
        app_rightshift_sel <= 9'd0;
        iteration <= 5'd0;
    end
    else begin    //20211109 start write FSM for galobal controling
       
    end
    
end
endmodule