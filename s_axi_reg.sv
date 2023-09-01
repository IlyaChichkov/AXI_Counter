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

logic [31:0]    reg_data_ff [0:7];

/* Module signals */

logic [31:0]        awaddr_ff;

logic               awready_en;
logic               wready_en;
logic               bvalid_en;

/* Functional methods */

// Write address
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        awready_en <= 1;
        awaddr_ff <= '0;
    end
    else
    begin
        if(awrite_handshake)
        begin
            awaddr_ff <= awaddr_i;
        end
    end
end

// Write data reset

generate
    for(genvar i = 0; i < 8; i++)
    begin
        always_ff @( posedge clk or negedge areset ) begin
            if(!areset)
            begin
                reg_data_ff[i] <= 32'b0;
            end
        end
    end
endgenerate

// Write data
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        // Reset
        wready_en <= 1;
    end
    else
    begin
        if(write_handshake)
        begin
            awready_en <= 1; // Got data -> ready HIGH  
            wready_en <= 1; // Got data -> ready HIGH  
            bvalid_en <= 1;
        end
    end
end

assign awready_o = awready_en ? 1 : 0;
assign wready_o  = wready_en ? 1 : 0;
assign bvalid_o  = bvalid_en ? 1 : 0;

// Response valid
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        bvalid_en <= 1;
        bid_o <= '0;
        bresp_o <= '0;
    end
    else
    begin
        if(bvalid_en && bready_i)
        begin
            bvalid_en <= 0;
        end
    end
end

logic awrite_handshake;
logic write_handshake;

assign awrite_handshake =  awvalid_i && awready_o;
assign write_handshake = wvalid_i && wready_o;

// Handshake
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        // Reset
    end
    else
    begin
        // Handshake write address and data


        if(awrite_handshake)
        begin
            awready_en <= 0; // TODO: Нужно ли сохранять адрес?
        end

        if(write_handshake)
        begin
            wready_en <= 0;
        end
    end
end


endmodule
