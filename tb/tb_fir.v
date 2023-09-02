`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/29 16:38:47
// Design Name: 
// Module Name: tb_fir
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_fir(

    );
    
parameter period=2;
reg clk=1'b1;
reg rst_n=1'b1;


always #(period/2)
clk=~clk;
initial
begin
   rst_n = 1'b0;
   #(100*period)
   rst_n = 1'b1;
end

reg [31:0]test_cnt;

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        test_cnt <= 0;
    end else begin
        test_cnt <= test_cnt + 1;
    end
end


parameter SPEED_FAST     = 1;
parameter DATA_IN_WIDTH  = 16;
parameter DATA_OUT_WIDTH = 16+16+5; //COE_WIDTH + DATA_IN_WIDTH + log2(COE_TAPS)
parameter COE_WIDTH      = 16;
parameter COE_TAPS       = 22;
parameter COE_SYMMETRY   = 1;
parameter COE_LOCAL_NUM  = 3;
parameter COE_SEL_WIDTH  = 2;//log2(COE_LOCAL_NUM + 1)
parameter [COE_WIDTH*COE_TAPS*COE_LOCAL_NUM-1:0] COE_FILE = {-16'd5,16'd0,16'd4,16'd2,-16'd4,-16'd5,16'd5,16'd11,-16'd5,-16'd36,16'd64,16'd64,-16'd36,-16'd5,16'd11,16'd5,-16'd5,-16'd4,16'd2,16'd4,16'd0,-16'd5,
-16'd5,16'd0,16'd4,16'd2,-16'd4,-16'd5,16'd5,16'd11,-16'd5,-16'd36,16'd64,16'd64,-16'd36,-16'd5,16'd11,16'd5,-16'd5,-16'd4,16'd2,16'd4,16'd0,-16'd5,
 16'd5,16'd0,16'd4,16'd2,-16'd4,-16'd5,16'd5,16'd11,-16'd5,-16'd36,16'd16384,16'd16384,-16'd36,-16'd5,16'd11,16'd5,-16'd5,-16'd4,16'd2,16'd4,16'd0,16'd5};//index-1
                                                              
reg [DATA_IN_WIDTH-1:0]data_in_real_4096[0:4096-1];
//read data
initial
begin
   $readmemh ("F:/workfile2023/soc/verif/fir/model/data_in_real.txt",data_in_real_4096);
end                                                              

reg                                           coe_sel_vld_i;
reg            [COE_SEL_WIDTH-1:0]            coe_sel_index_i;
reg                                           coe_reload_vld_i;
reg            [COE_WIDTH-1:0]                coe_reload_data_i;
reg                                           data_vld_i;
reg            [DATA_IN_WIDTH-1:0]            data_i;
wire                                          data_vld_o;
wire           [DATA_OUT_WIDTH-1:0]           data_o;

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        data_vld_i <= 0;
        data_i <= 0;
    end else begin
        if(test_cnt>=1 && test_cnt <= 4096)begin
            data_vld_i <= 1;
            data_i     <= data_in_real_4096[test_cnt-1];
        end else if(test_cnt>=10001 && test_cnt <= 14096)begin
            data_vld_i <= 1;
            data_i     <= data_in_real_4096[test_cnt-10001];
        end else if(test_cnt>=20001 && test_cnt <= 24096)begin
            data_vld_i <= 1;
            data_i     <= data_in_real_4096[test_cnt-20001];
        end else begin
            data_vld_i <= 0;
        end
    end
end

always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        coe_sel_vld_i <= 0;
        coe_sel_index_i <= 0;
    end else begin
        if(test_cnt==10000)begin
            coe_sel_vld_i       <= 1;
            coe_sel_index_i     <= 2;
        end else if(test_cnt==20000)begin
            coe_sel_vld_i       <= 1;
            coe_sel_index_i     <= 3;
        end else begin
            coe_sel_vld_i       <= 0;
            coe_sel_index_i     <= 0;
        end
    end
end


parameter [COE_WIDTH*COE_TAPS-1:0] COE_FILE_RELOAD = {
 16'd5,16'd0,16'd4,16'd2,-16'd4,-16'd5,16'd5,16'd11,-16'd5,-16'd36,-16'd16384,-16'd16384,-16'd36,-16'd5,16'd11,16'd5,-16'd5,-16'd4,16'd2,16'd4,16'd0,16'd5};
 
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        coe_reload_vld_i <= 0;
        coe_reload_data_i <= 0;
    end else begin
        if(test_cnt>=15001 && test_cnt<=15022)begin
            coe_reload_vld_i    <= 1;
            coe_reload_data_i   <= COE_FILE_RELOAD[((COE_TAPS-(test_cnt-15001))*COE_WIDTH-1)-:COE_WIDTH];
        end else begin
            coe_reload_vld_i       <= 0;
            coe_reload_data_i     <= 0;
        end
    end
end

fir_top #(
.SPEED_FAST         ( SPEED_FAST        ),
.DATA_IN_WIDTH      ( DATA_IN_WIDTH     ),
.DATA_OUT_WIDTH     ( DATA_OUT_WIDTH    ),
.COE_WIDTH          ( COE_WIDTH         ),
.COE_TAPS           ( COE_TAPS          ),
.COE_SYMMETRY       ( COE_SYMMETRY      ),
.COE_LOCAL_NUM      ( COE_LOCAL_NUM     ),
.COE_SEL_WIDTH      ( COE_SEL_WIDTH     ),
.COE_FILE           ( COE_FILE          )
               
)fir_top_inst(
.clk                ( clk               ),
.rst_n              ( rst_n             ),
.coe_sel_vld_i      ( coe_sel_vld_i     ),
.coe_sel_index_i    ( coe_sel_index_i   ),
.coe_reload_vld_i   ( coe_reload_vld_i  ),
.coe_reload_data_i  ( coe_reload_data_i ),
.data_vld_i         ( data_vld_i        ),
.data_i             ( data_i            ),
.data_vld_o         ( data_vld_o        ),
.data_o             ( data_o            )
    );
integer fp_datao_1_w;
integer fp_datao_2_w;
integer fp_datao_3_w;
//write data
initial
begin
   fp_datao_1_w = $fopen("F:/workfile2023/soc/verif/fir/model/data_out1.txt","w"); 
   fp_datao_2_w = $fopen("F:/workfile2023/soc/verif/fir/model/data_out2.txt","w"); 
   fp_datao_3_w = $fopen("F:/workfile2023/soc/verif/fir/model/data_out3.txt","w"); 
end
reg [31:0]  record1_cnt = 0;


 always@(posedge clk)  
 begin
     if(data_vld_o == 1'b1 && record1_cnt >=0 && record1_cnt<4096)begin
        record1_cnt <= record1_cnt +1;
        $fwrite(fp_datao_1_w,"%d\n",data_o);
     end else if(data_vld_o == 1'b1 && record1_cnt >=4096 && record1_cnt<4096*2)begin
        record1_cnt <= record1_cnt +1;
        $fwrite(fp_datao_2_w,"%d\n",data_o);
     end else if(data_vld_o == 1'b1 && record1_cnt >=4096*2 && record1_cnt<4096*3)begin
        record1_cnt <= record1_cnt +1;
        $fwrite(fp_datao_3_w,"%d\n",data_o);
     end
     if(record1_cnt == 4096*3)begin
        $fclose(fp_datao_1_w);
        $fclose(fp_datao_2_w);
        $fclose(fp_datao_3_w);
     end
 end
 
endmodule
