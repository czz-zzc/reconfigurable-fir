`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: caozheng
// 
// Create Date: 2023/08/29 14:02:16
// Design Name: 
// Module Name: fir_cal
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


module fir_cal#(
parameter DATA_IN_WIDTH  = 16,
parameter DATA_OUT_WIDTH = 16+16+5,
parameter COE_WIDTH      = 16,
parameter COE_TAPS       = 20,
parameter COE_SYMMETRY   = 0,
parameter SPEED_FAST     = 1,
parameter COE_ODD        = COE_TAPS % 2,
parameter COE_TAPS_TRUE  = COE_SYMMETRY ? (COE_TAPS + COE_ODD)/2 : COE_TAPS
)(
input                                           clk,
input                                           rst_n,

input            [COE_WIDTH*COE_TAPS_TRUE-1:0]  coe_i,
input                                           data_vld_i,
input            [DATA_IN_WIDTH-1:0]            data_i,

output                                          data_vld_o,
output           [DATA_OUT_WIDTH-1:0]           data_o
    );

localparam PIPE_STEP = 2;  
wire signed [COE_WIDTH-1:0] coe[0:COE_TAPS-1];

integer j;
genvar i;

generate
    for (i=0; i < COE_TAPS_TRUE; i=i+1)
    begin: coe_reg
        assign coe[i] = coe_i[i*COE_WIDTH+:COE_WIDTH];
    end
endgenerate


generate
if (COE_SYMMETRY == 0) begin: unsymmetry_gen
    ///////////////////////////////////////////////////////////////////////////
    //----------------------  Un Symmetry Architecture  --------- -----------//
    ///////////////////////////////////////////////////////////////////////////

    localparam MULT_WIDTH_US = DATA_IN_WIDTH + COE_WIDTH;
    localparam DELAY = 2 + SPEED_FAST + COE_TAPS;
    
    reg  signed [DATA_IN_WIDTH-1:0] data_r[0:COE_TAPS*PIPE_STEP-1];
    reg                             data_vld_delay[0:DELAY-1];
    reg  signed [MULT_WIDTH_US-1:0] mult_r[0:COE_TAPS-1];
    reg  signed [DATA_OUT_WIDTH-1:0] mult_add_r[0:COE_TAPS-1];
    
    //vld_delay
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<DELAY;j=j+1)begin
                data_vld_delay[j] <= 'h0;
            end
        end else begin
            for(j=1;j<DELAY;j=j+1)begin
                data_vld_delay[j] <= data_vld_delay[j-1];
            end
            data_vld_delay[0] <= data_vld_i;
        end
    end
    
    //data delay
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<COE_TAPS*PIPE_STEP;j=j+1)begin
                data_r[j]  <= 'h0;
            end
        end else begin
            for(j=1;j<COE_TAPS*PIPE_STEP;j=j+1)begin
                data_r[j]  <= data_r[j-1];
            end
            if(data_vld_i == 1'b1)begin
                data_r[0]  <= data_i;
            end else begin
                data_r[0]  <= 'h0;
            end
        end
    end
    
    if(SPEED_FAST == 0)begin :speed_low
    
        always@(*) begin
            for(j=0;j<COE_TAPS;j=j+1)begin
                mult_r[j]  = data_r[PIPE_STEP*(j+1)-1] * coe[j];
            end
        end
        
    end else begin:speed_high
    
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                for(j=0;j<COE_TAPS;j=j+1)begin
                    mult_r[j]  <= 'h0;
                end
            end else begin
                for(j=0;j<COE_TAPS;j=j+1)begin
                    mult_r[j]  <= data_r[PIPE_STEP*(j+1)-1] * coe[j];
                end
            end
        end
        
    end

    //mult sum
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<COE_TAPS;j=j+1)begin
                mult_add_r[j]  <= 'h0;
            end
        end else begin
            mult_add_r[0]  <= mult_r[0];
            for(j=1;j<COE_TAPS-1;j=j+1)begin
                mult_add_r[j]  <= mult_r[j] + mult_add_r[j-1];
            end
            if(data_vld_delay[DELAY-2]==1'b1)begin
                mult_add_r[COE_TAPS-1] <= mult_r[j] + mult_add_r[j-1];
            end else begin
                mult_add_r[COE_TAPS-1] <= 'h0;
            end
        end
    end
    
    assign data_o = mult_add_r[COE_TAPS-1];
    assign data_vld_o = data_vld_delay[DELAY-1];

end else begin
    ///////////////////////////////////////////////////////////////////////////
    //-----------------------  Symmetry Architecture  -----------------------//
    ///////////////////////////////////////////////////////////////////////////
    localparam MULT_WIDTH_S  = DATA_IN_WIDTH + COE_WIDTH + 1;
    localparam ADD1_NUM      = COE_TAPS_TRUE;
    localparam MULT_NUM      = ADD1_NUM; 
    localparam ADD2_NUM      = MULT_NUM;  
    localparam DELAY = 3 + SPEED_FAST + MULT_NUM;
    
    reg  signed [DATA_IN_WIDTH-1:0] data_r[0:COE_TAPS];
    reg                             data_vld_delay[0:DELAY-1];
    reg  signed [DATA_IN_WIDTH:0]   add_step1[0:ADD1_NUM-1];
    wire signed [DATA_IN_WIDTH:0]   add_step1_mid;
    reg  signed [MULT_WIDTH_S-1:0]   mult_r[0:MULT_NUM-1];
    reg  signed [DATA_OUT_WIDTH-1:0] add_step2[0:ADD2_NUM-1];  
    
     //vld_delay
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<DELAY;j=j+1)begin
                data_vld_delay[j] <= 'h0;
            end
        end else begin
            for(j=1;j<DELAY;j=j+1)begin
                data_vld_delay[j] <= data_vld_delay[j-1];
            end
            data_vld_delay[0] <= data_vld_i;
        end
    end
    //data delay
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<=COE_TAPS;j=j+1)begin
                data_r[j]  <= 'h0;
            end
        end else begin
            for(j=1;j<=COE_TAPS;j=j+1)begin
                data_r[j]  <= data_r[j-1];
            end
            if(data_vld_i == 1'b1)begin
                data_r[0]  <= data_i;
            end else begin
                data_r[0]  <= 'h0;
            end
        end
    end
    
    if(COE_ODD == 1)begin
        assign add_step1_mid = data_r[PIPE_STEP*ADD1_NUM-1];
    end else begin
        assign add_step1_mid = data_r[PIPE_STEP*ADD1_NUM-1] +  data_r[COE_TAPS];
    end
    
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<ADD1_NUM;j=j+1)begin
                add_step1[j]  <= 'h0;
            end
        end else begin
            for(j=0;j<ADD1_NUM-1;j=j+1)begin
                add_step1[j]  <= data_r[PIPE_STEP*(j+1)-1] +  data_r[COE_TAPS];
            end
            add_step1[ADD1_NUM-1] <= add_step1_mid;
        end
    end

    if(SPEED_FAST == 0)begin :speed_low
    
        always@(*) begin
            for(j=0;j<MULT_NUM;j=j+1)begin
                mult_r[j]  = add_step1[j] * coe[j];
            end
        end
        
    end else begin:speed_high
    
        always@(posedge clk or negedge rst_n) begin
            if(rst_n == 1'b0)begin
                for(j=0;j<MULT_NUM;j=j+1)begin
                    mult_r[j]  <= 'h0;
                end
            end else begin
                for(j=0;j<MULT_NUM;j=j+1)begin
                    mult_r[j]  <= add_step1[j] * coe[j];
                end
            end
        end
        
    end
    
    //mult sum
    always@(posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0)begin
            for(j=0;j<ADD2_NUM;j=j+1)begin
                add_step2[j]  <= 'h0;
            end
        end else begin
            add_step2[0]  <= mult_r[0];
            for(j=1;j<ADD2_NUM-1;j=j+1)begin
                add_step2[j]  <= mult_r[j] + add_step2[j-1];
            end
            if(data_vld_delay[DELAY-2]==1'b1)begin
                add_step2[ADD2_NUM-1] <= mult_r[j] + add_step2[j-1];
            end else begin
                add_step2[ADD2_NUM-1] <= 'h0;
            end
        end
    end
    
    assign data_o = add_step2[ADD2_NUM-1];
    assign data_vld_o = data_vld_delay[DELAY-1];

end
endgenerate


endmodule
