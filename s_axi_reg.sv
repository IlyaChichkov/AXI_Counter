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
    input  logic [3:0]       awid_i,
    input  logic [31:0]      awaddr_i,
    input  logic             awvalid_i,
    output logic             awready_o,
    //   Data
    input  logic [3:0]       wid_i,
    input  logic [31:0]      wdata_i,
    input  logic [3:0]       wstrb_i,
    input  logic             wlast_i,
    input  logic             wvalid_i,
    output logic             wready_o,
    // READ SIGNALS
    //   Address
    input  logic [3:0]       arid_i,
    input  logic [31:0]      araddr_i,
    input  logic             arvalid_i,
    output logic             arready_o,
    //   Data
    output logic   [3:0]      rid_i,
    output logic   [31:0]     rdata_i,
    output logic   [3:0]      rstrb_i,
    output logic              rlast_i,
    output logic             rvalid_i,
    input  logic             rready_i,
    // RESPONSE SIGNALS
    output logic [3:0]       bid_o,
    output logic [1:0]       bresp_o,
    output logic             bvalid_o,
    input  logic             bready_i
    );

logic           reg_data_en;
logic [31:0]    reg_data_ff [0:7];

/* Module signals */

logic               awaddr_en;
logic [31:0]        awaddr_ff;

logic               awready_en;
logic               wready_en;

/* Functional methods */
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        reg_data_ff[0] <= 32'b0;
        reg_data_ff[1] <= 32'b0;
        reg_data_ff[2] <= 32'b0;
        reg_data_ff[3] <= 32'b0;
    end
    else
    begin
        if(reg_data_en)
        begin
            reg_data_ff[awaddr_ff] <= wdata_i;
        end
    end
end

always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        awaddr_ff <= 0;
    end
    else
    begin
        if(awaddr_en)
        begin
            awaddr_ff <= awaddr_i;
            awaddr_en <= 0;
        end
    end
end

always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        awready_o <= 0;
    end
    else
    begin
        if(awready_en)
        begin
            awready_o <= 1;
            awready_en <= 0;
        end
        else
        begin
            awready_o <= 0;
        end
    end
end

always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        wready_o <= 0;
    end
    else
    begin
        if(wready_en)
        begin
            wready_o <= 1;
            wready_en <= 0;
        end
        else
        begin
            wready_o <= 0;
        end
    end
end

always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        // Reset
    end
    else
    begin
        // Handshake write address
        if(awvalid_i)
        begin
            awaddr_en <= 1;
            awready_en <= 1;
        end

        // Handshake write data
        if(wvalid_i)
        begin
            reg_data_en <= 1;
            wready_en <= 1;
        end
    end
end


endmodule
