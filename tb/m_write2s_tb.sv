module m_write2s_tb #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 6
)(

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

    // Write Length
    write(32'hA3DD000C, 32'h00000004);
    // Write Length
    write(32'hA3DD0010, 32'h00000004);
    // Write A2
    write(32'hA3DD0008, 32'hA3DD0014);
    // Write Length
    write(32'hA3DD0000, 32'h00000001);
end


logic   [3:0]      awid_i;
logic   [31:0]     awaddr_i;
logic              awvalid_i;
logic              awready_o;

logic [31:0]        wdata_i;
logic [3:0]         wstrb_i;
logic               wvalid_i;
logic               wready_o;

logic [3:0]         bid_o;
logic [1:0]         bresp_o;
logic               bvalid_o;
logic               bready_i;

logic [31:0]        rdata_o;
logic [3:0]         arid_i;
logic [31:0]        araddr_i;
logic               arvalid_i;
logic               rvalid_o;
logic               arready_o;

logic               rready_i;

logic [             1:0] m_awburst_o;
logic [            63:0] m_awaddr_o;
logic                    m_awvalid_o;
logic                    m_awready_i;
logic [             3:0] m_wid_o;
logic [DATA_WIDTH - 1:0] m_wdata_o;
logic [             3:0] m_wstrb_o;
logic                    m_wlast_o;
logic                    m_wvalid_o;
logic                    m_wready_i;
logic [             3:0] m_bid_i;
logic [             1:0] m_bresp_i;
logic                    m_bvalid_i;
logic                    m_bready_o;

wire [DATA_WIDTH - 1:0] m_bram [0 : BRAM_QUANTITY - 1];
wire [             2:0] master_status;

m_axi_reg #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .BRAM_QUANTITY (BRAM_QUANTITY)
) master
(
    .clk            (clk),
    .areset         (areset),
    .BRAM           (m_bram),
    .awburst_o    (m_awburst_o),
    .awaddr_o     (m_awaddr_o),
    .awvalid_o    (m_awvalid_o),
    .awready_i    (m_awready_i),
    .wid_o        (m_wid_o),
    .wdata_o      (m_wdata_o),
    .wstrb_o      (m_wstrb_o),
    .wlast_o      (m_wlast_o),
    .wvalid_o     (m_wvalid_o),
    .wready_i     (m_wready_i),
    .bid_i        (m_bid_i),
    .bresp_i      (m_bresp_i),
    .bvalid_i     (m_bvalid_i),
    .bready_o     (m_bready_o),
    .master_status_o(master_status)
);

s_axi_reg #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .BRAM_QUANTITY (BRAM_QUANTITY)
) slave
(
    .clk            (clk),
    .areset         (areset),
    .m_bram_o       (m_bram),
    .awaddr_i       (awaddr_i),
    .awvalid_i      (awvalid_i),
    .awready_o      (awready_o),
    .wdata_i        (wdata_i),
    .wstrb_i        (wstrb_i),
    .wvalid_i       (wvalid_i),
    .wready_o       (wready_o),
    .bresp_o        (bresp_o),
    .bvalid_o       (bvalid_o),
    .araddr_i       (araddr_i),
    .arvalid_i      (arvalid_i),
    .rready_i       (rready_i),
    .bready_i       (bready_i),
    .arready_o      (arready_o),
    .rvalid_o       (rvalid_o),
    .rdata_o        (rdata_o),
    .master_status_i(master_status)
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
    arid_i = 0;
    araddr_i = 0;
    arvalid_i = 0;
    rready_i = 0;

    m_bid_i = 0;
  
    m_wready_i = 0;
    m_awready_i = 0;
    m_bresp_i = 0;
    m_bvalid_i = 0;
    #40;
    areset = 1;
    #20;

endtask

task write(
    input logic [31:0] addr,
    input logic [31:0]  data
);
    $display("Write addr");
    awaddr_i = addr;
    #7;
    awvalid_i = '1;
    $display("Waiting write addr ready");
    do begin
        @(posedge clk);
    end while(!awready_o); 
    awvalid_i = '0;

    $display("Write data");
    wstrb_i = 4'b1111;
    wdata_i = data;
    #7;
    wvalid_i = '1;
    do begin
        @(posedge clk);
    end while(!wready_o); 
    wvalid_i = '0;

    $display("Waiting response ready");
    do begin
        @(posedge clk);
    end while(!bvalid_o); 
    bready_i = '1;
    #10;
    bready_i = '0;
endtask

task write_data(
    input logic [31:0]  data
    );
    $display("Write data");
    wstrb_i = 4'b1111;
    wdata_i = data;
    #7;
    wvalid_i = '1;
endtask

task write_addr(
    input logic [31:0] addr
    );
    $display("Write addr");
    awaddr_i = addr;
    #7;
    awvalid_i = '1;
endtask

task uncheck_vaddr();
    #10;
    awvalid_i = '0;
endtask

task uncheck_vdata();
    do begin
        @(posedge clk);
    end while(!wready_o); 
    wvalid_i = '0;
endtask

task wait_waddr_ready();
    $display("Waiting write addr ready");
    do begin
        @(posedge clk);
    end while(!awready_o); 
    awvalid_i = '0;
endtask

task wait_wdata_ready();
    $display("Waiting write data ready");
    do begin
        @(posedge clk);
    end while(!wready_o); 
    wvalid_i = '0;
endtask

task wait_response_ready();
    $display("Waiting response ready");
    do begin
        @(posedge clk);
    end while(!bvalid_o); 
    bready_i = '1;
    #10;
    bready_i = '0;
endtask

endmodule