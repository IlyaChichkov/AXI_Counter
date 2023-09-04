`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/31/2023 01:18:45 PM
// Design Name: 
// Module Name: testbench
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


module testbench(

    );

logic clk;
logic areset;

initial begin
clk = 0;
areset = 0;

forever 
    #5 clk = ~clk;
end

initial begin
    reset();
    s_write_data();
    reset();
    s_write_data_before_addr();
end

logic   [3:0]      awid_i;
logic   [31:0]     awaddr_i;
logic              awvalid_i;
logic              awready_o;

logic   [31:0]     wdata_i;
logic [3:0]        wstrb_i;
logic              wvalid_i;
logic              wready_o;

logic  [3:0]       bid_o;
logic  [1:0]       bresp_o;
logic              bvalid_o;
logic              bready_i;

s_axi_reg slave(
    .clk            (clk),
    .areset         (areset),
    .awid_i         (awid_i),
    .awaddr_i       (awaddr_i),
    .awvalid_i      (awvalid_i),
    .awready_o      (awready_o),
    .wdata_i        (wdata_i),
    .wstrb_i        (wstrb_i),
    .wvalid_i       (wvalid_i),
    .wready_o       (wready_o),
    .bresp_o        (bresp_o),
    .bvalid_o       (bvalid_o),
    .bready_i       (bready_i)
);

task reset();
    #20;
    awid_i = 0;
    awaddr_i = 0;
    wdata_i = 0;
    bready_i = 0;
    awvalid_i = 0;
    wstrb_i = 0;
    wvalid_i = 0;
    #20;
endtask

task s_write_data_before_addr();
    #20;
    areset = 1;
    #20;

    wstrb_i = 4'b1010;
    wdata_i = 32'hEFDBCA54;
    #20;
    wvalid_i = '1;

    awaddr_i = 32'b1;

    #7
    awvalid_i = '1;
    
    do begin
        @(posedge clk);
    end while(!awready_o); 
    awvalid_i = '0;


    do begin
        @(posedge clk);
    end while(!wready_o); 
    wvalid_i = '0;


    do begin
        @(posedge clk);
    end while(!bvalid_o); 
    #5;
    bready_i = '1;
    #20;
    bready_i = '0;
endtask

task s_write_data();
    #20;
    areset = 1;
    #20;
    awaddr_i = 32'b1;

    #7
    awvalid_i = '1;
    
    do begin
        @(posedge clk);
    end while(!awready_o); 
    awvalid_i = '0;

    wstrb_i = 4'b1010;
    wdata_i = 32'hABCDEFAC;
    #10;
    wvalid_i = '1;

    do begin
        @(posedge clk);
    end while(!wready_o); 
    wvalid_i = '0;


    do begin
        @(posedge clk);
    end while(!bvalid_o); 
    #5;
    bready_i = '1;
    #20;
    bready_i = '0;
endtask

endmodule
