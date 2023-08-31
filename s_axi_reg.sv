`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2023 11:15:56 AM
// Design Name: 
// Module Name: s_axi_reg
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


module s_axi_reg(
    // GLOBAL SIGNALS
    input               clk,        
    input               areset,
    // WRITE SIGNALS
    //   Address
    input   [3:0]       awid_i,
    input   [31:0]      awaddr_i,
    input               awvalid_i,
    output              awready_o
    //   Data
    input   [3:0]       wid_i,
    input   [31:0]      wdata_i,
    input   [3:0]       wstrb_i,
    input               wlast_i,
    input               wvalid_i,
    input               wready_i,
    // READ SIGNALS
    //   Address
    input   [3:0]       arid_i,
    input   [31:0]      araddr_i,
    input               arvalid_i,
    output              arready_o
    //   Data
    input   [3:0]       rid_i,
    input   [31:0]      rdata_i,
    input   [3:0]       rstrb_i,
    input               rlast_i,
    input               rvalid_i,
    input               rready_i,
    // RESPONSE SIGNALS
    output  [3:0]       bid_o,
    output  [1:0]       bresp_o,
    output              bvalid_o,
    input               bready_i,
    );
endmodule
