module testbench #(
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

    // Write addr0
    $display("Write addr0");
    write_data(32'hC2AAEE2A);
    uncheck_vdata();

    write_addr(32'hA3DD0004);
    wait_waddr_ready();
    wait_response_ready();

    // Write addr1
    $display("Write addr1");
    write_data(32'h43C10000);
    uncheck_vdata();

    write_addr(32'hA3DD0008);
    wait_waddr_ready();
    wait_response_ready();
    
    // Write incr
    $display("Write incr");
    write_data(32'h00000004);
    uncheck_vdata();

    write_addr(32'hA3DD0010);
    wait_waddr_ready();
    wait_response_ready();

    // Write Length
    $display("Write Length");
    write_data(32'h00000001);
    uncheck_vdata();

    write_addr(32'hA3DD000C);
    wait_waddr_ready();
    wait_response_ready();

    // Write enable
    $display("Write enable");
    write_data(32'h00000001);
    uncheck_vdata();

    write_addr(32'hA3DD0000);
    wait_waddr_ready();
    wait_response_ready();

    test_master_counter();
    
    m_read_all();

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


master_top #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .BRAM_QUANTITY (BRAM_QUANTITY)
) master
(
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
    .arid_i         (arid_i),
    .araddr_i       (araddr_i),
    .arvalid_i      (arvalid_i),
    .rready_i       (rready_i),
    .bready_i       (bready_i),
    .arready_o      (arready_o),
    .rvalid_o       (rvalid_o),
    .rdata_o        (rdata_o),
    .m_awburst_o    (m_awburst_o),
    .m_awaddr_o     (m_awaddr_o),
    .m_awvalid_o    (m_awvalid_o),
    .m_awready_i    (m_awready_i),
    .m_wid_o        (m_wid_o),
    .m_wdata_o      (m_wdata_o),
    .m_wstrb_o      (m_wstrb_o),
    .m_wlast_o      (m_wlast_o),
    .m_wvalid_o     (m_wvalid_o),
    .m_wready_i     (m_wready_i),
    .m_bid_i        (m_bid_i),
    .m_bresp_i      (m_bresp_i),
    .m_bvalid_i     (m_bvalid_i),
    .m_bready_o     (m_bready_o)
);
/*
axi_master_top #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .BRAM_QUANTITY (BRAM_QUANTITY)
) master
(
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
    .arid_i         (arid_i),
    .araddr_i       (araddr_i),
    .arvalid_i      (arvalid_i),
    .rready_i       (rready_i),
    .bready_i       (bready_i),
    .arready_o      (arready_o),
    .rvalid_o       (rvalid_o),
    .rdata_o        (rdata_o)
);*/

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

task test_master_counter();
    $display("test master counter...");
    #60;
    m_awready_i = 1;
    #60;
    m_wready_i = 1;
    #60;
    m_bresp_i = 0;
    m_bvalid_i = 1;
    $display("done.");
endtask

task uncheck_vaddr();
    #10;
    awvalid_i = '0;
endtask

task uncheck_vdata();
    #10;
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

task m_read_data(input int addr);
    areset = 1;
    #20;
    araddr_i = addr;
    rready_i = '0;
    #7
    arvalid_i = '1;
    
    do begin
        @(posedge clk);
    end while(arready_o); 
    arvalid_i = '0;
    
    #10;

    do begin
        @(posedge clk);
    end while(!rvalid_o); 

    $display("val: %h", rdata_o);

    #20;
    rready_i = '1;
    #20;
    rready_i = '0;
endtask


task m_read_all();

    for (int i = 0; i<9; i=i+1) begin
        
        #20;
        araddr_i = {'h34c0, i << 2};
        rready_i = '0;
        #7
        arvalid_i = '1;
        
        do begin
            @(posedge clk);
        end while(arready_o); 
        arvalid_i = '0;
        
        #10;

        do begin
            @(posedge clk);
        end while(!rvalid_o); 

        $display("Read Value: %h", rdata_o);

        #20;
        rready_i = '1;
        #20;
        rready_i = '0;
    end
endtask

endmodule