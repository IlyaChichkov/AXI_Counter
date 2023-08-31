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
    output              awready_o,
    //   Data
    input   [3:0]       wid_i,
    input   [31:0]      wdata_i,
    input   [3:0]       wstrb_i,
    input               wlast_i,
    input               wvalid_i,
    output              wready_o,
    // READ SIGNALS
    //   Address
    input   [3:0]       arid_i,
    input   [31:0]      araddr_i,
    input               arvalid_i,
    output              arready_o,
    //   Data
    output   [3:0]      rid_o,
    output   [31:0]     rdata_o,
    output   [3:0]      rstrb_o,
    output              rlast_o,
    output              rvalid_o,
    input               rready_i,
    // RESPONSE SIGNALS
    output  [3:0]       bid_o,
    output  [1:0]       bresp_o,
    output              bvalid_o,
    input               bready_i
    );

logic           reg_data_en;
logic [31:0]    reg_data_ff [0:7];

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
            bvalid_en <= 1;
        end
    end
end

/* Module signals */

logic               awaddr_en;
logic [31:0]        awaddr_ff;

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

logic               awready_en;
logic               awready_ff;

assign awready_o = awready;

always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        awready_ff <= 0;
    end
    else
    begin
        if(awready_en)
        begin
            awready_ff <= 1;
            awready_en <= 0;
        end
    end
end

// Response valid
logic               bvalid_en;
logic               bvalid_ff;

always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        awready_ff <= 0;
    end
    else
    begin
        if(bvalid_en)
        begin
            bvalid_ff <= 1;
            bvalid_en <= 0;
        end
        
        if(bready_i)
        begin
            bvalid_ff <= 0;
        end
    end
end

/* Functional methods */
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
            wready_o <= 0;
        end
    end
end


endmodule
