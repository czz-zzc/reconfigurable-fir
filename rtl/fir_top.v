`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: caozheng
// 
// Create Date: 2023/08/31 16:12:55
// Design Name: 
// Module Name: fir_top
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


module fir_top #(
parameter SPEED_FAST     = 1,
parameter DATA_IN_WIDTH  = 16,
parameter DATA_OUT_WIDTH = 16+16+2,
parameter COE_WIDTH      = 16,
parameter COE_TAPS       = 3,
parameter COE_SYMMETRY   = 0,
parameter COE_LOCAL_NUM  = 2,
parameter COE_SEL_WIDTH  = 2,//log2(COE_LOCAL_NUM + 1)
parameter [COE_WIDTH*COE_TAPS*COE_LOCAL_NUM-1:0] COE_FILE = {16'd11,16'd12,16'd13,//index 0
                                                              16'd21,16'd22,16'd33}//index-1
)(
input                                           clk,
input                                           rst_n,

input                                           coe_sel_vld_i,
input            [COE_SEL_WIDTH-1:0]            coe_sel_index_i,

input                                           coe_reload_vld_i,
input            [COE_WIDTH-1:0]                coe_reload_data_i,

input                                           data_vld_i,
input            [DATA_IN_WIDTH-1:0]            data_i,

output                                          data_vld_o,
output           [DATA_OUT_WIDTH-1:0]           data_o
    );
    
localparam COE_ODD        = COE_TAPS % 2;
localparam COE_TAPS_TRUE  = COE_SYMMETRY ? (COE_TAPS + COE_ODD)/2 : COE_TAPS;

wire  [COE_WIDTH*COE_TAPS_TRUE-1:0]  coe;

//COE config module
fir_coe#(
.COE_LOCAL_NUM      ( COE_LOCAL_NUM     ),
.COE_SEL_WIDTH      ( COE_SEL_WIDTH     ),
.COE_WIDTH          ( COE_WIDTH         ),
.COE_TAPS           ( COE_TAPS          ),
.COE_SYMMETRY       ( COE_SYMMETRY      ),
.COE_ODD            ( COE_ODD           ),
.COE_TAPS_TRUE      ( COE_TAPS_TRUE     ),
.COE_FILE           ( COE_FILE          )
)fir_coe_inst(
.clk                ( clk               ),
.rst_n              ( rst_n             ),
.coe_sel_vld_i      ( coe_sel_vld_i     ),
.coe_sel_index_i    ( coe_sel_index_i   ),
.coe_reload_vld_i   ( coe_reload_vld_i  ),
.coe_reload_data_i  ( coe_reload_data_i ),
.coe_o              ( coe               )
);

//calculate module
fir_cal#(
.DATA_IN_WIDTH      ( DATA_IN_WIDTH     ),
.DATA_OUT_WIDTH     ( DATA_OUT_WIDTH    ),
.COE_WIDTH          ( COE_WIDTH         ),
.COE_TAPS           ( COE_TAPS          ),
.COE_SYMMETRY       ( COE_SYMMETRY      ),
.SPEED_FAST         ( SPEED_FAST        ),
.COE_ODD            ( COE_ODD           ),
.COE_TAPS_TRUE      ( COE_TAPS_TRUE     )
)fir_cal_inst(
.clk                ( clk               ),
.rst_n              ( rst_n             ),
.coe_i              ( coe               ),
.data_vld_i         ( data_vld_i        ),
.data_i             ( data_i            ),
.data_vld_o         ( data_vld_o        ),
.data_o             ( data_o            )
);

endmodule
