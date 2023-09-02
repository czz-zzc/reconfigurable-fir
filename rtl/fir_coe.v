`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: caozheng
// 
// Create Date: 2023/08/31 10:49:03
// Design Name: 
// Module Name: fir_coe
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


module fir_coe#(
parameter COE_LOCAL_NUM         = 2,
parameter COE_SEL_WIDTH         = 2,//log2(COE_LOCAL_NUM + 1)
parameter COE_WIDTH             = 16,
parameter COE_TAPS              = 3,
parameter COE_SYMMETRY          = 0,
parameter COE_ODD               = COE_TAPS % 2,
parameter COE_TAPS_TRUE         = COE_SYMMETRY ? (COE_TAPS + COE_ODD)/2 : COE_TAPS,
parameter [COE_WIDTH*COE_TAPS*COE_LOCAL_NUM-1:0] COE_FILE = {16'd11,16'd12,16'd13,//index 0
                                                              16'd21,16'd22,16'd33}//index-1
)(
input                                           clk,
input                                           rst_n,

input                                           coe_sel_vld_i,
input            [COE_SEL_WIDTH-1:0]            coe_sel_index_i,

input                                           coe_reload_vld_i,
input            [COE_WIDTH-1:0]                coe_reload_data_i,

output           [COE_WIDTH*COE_TAPS_TRUE-1:0]  coe_o
    );


reg [COE_WIDTH-1:0] coe_local_r [0:COE_TAPS_TRUE-1];
reg [COE_WIDTH-1:0] coe_config_r [0:COE_TAPS_TRUE-1];
reg                 coe_reload_vld_d [0:COE_TAPS_TRUE-1];

integer j;
genvar i;
generate
    for (i=0;i<COE_TAPS_TRUE;i=i+1)begin:local_coe_coe
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                coe_local_r[i] <= COE_FILE[(((COE_LOCAL_NUM-0)*COE_TAPS-i)*COE_WIDTH-1)-:COE_WIDTH];//index 0
            end else if(coe_sel_vld_i == 1'b1) begin
                for(j=0;j<COE_LOCAL_NUM;j=j+1)begin
                    if(coe_sel_index_i == j)
                        coe_local_r[i] <= COE_FILE[(((COE_LOCAL_NUM-j)*COE_TAPS-i)*COE_WIDTH-1)-:COE_WIDTH];
                end
                if(coe_sel_index_i == COE_LOCAL_NUM)begin
                    coe_local_r[i] <= coe_config_r[i];
                end
            end
        end
    end
endgenerate

//delay reload vld
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        for(j=0;j<COE_TAPS_TRUE;j=j+1)begin
            coe_reload_vld_d[j] <= 1'b0;
        end
    end else begin
        for(j=1;j<COE_TAPS_TRUE;j=j+1)begin
            coe_reload_vld_d[j] <= coe_reload_vld_d[j-1];
        end
        coe_reload_vld_d[0] <= coe_reload_vld_i;
    end
end

//lock cfg data
always@(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0)begin
        for(j=0;j<COE_TAPS_TRUE;j=j+1)begin
            coe_config_r[j] <= COE_FILE[(((COE_LOCAL_NUM-0)*COE_TAPS-j)*COE_WIDTH-1)-:COE_WIDTH];
        end
    end else begin
        for(j=1;j<COE_TAPS_TRUE;j=j+1)begin
            if(coe_reload_vld_d[j]== 1'b0 && coe_reload_vld_d[j-1] == 1'b1)begin
                coe_config_r[j] <= coe_reload_data_i;
            end
        end
        if(coe_reload_vld_d[0] == 1'b0 && coe_reload_vld_i == 1'b1)begin
            coe_config_r[0] <= coe_reload_data_i;
        end
    end
end

generate
    for (i=0; i < COE_TAPS_TRUE; i=i+1)begin: coe_reg
        assign coe_o[i*COE_WIDTH+:COE_WIDTH] = coe_local_r[i];
    end
endgenerate

endmodule
