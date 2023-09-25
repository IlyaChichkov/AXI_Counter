module master_top#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 8
)(
    input                           clk,
    input                           areset,
    
    input  logic [             3:0] awid_i,
    input  logic [ADDR_WIDTH - 1:0] awaddr_i,
    input  logic                    awvalid_i,
    output logic                    awready_o,

    input  logic [             3:0] wid_i,
    input  logic [DATA_WIDTH - 1:0] wdata_i,
    input  logic [             3:0] wstrb_i,
    input  logic                    wlast_i,
    input  logic                    wvalid_i,
    output logic                    wready_o,
    
    input  logic [             3:0] arid_i,
    input  logic [ADDR_WIDTH - 1:0] araddr_i,
    input  logic                    arvalid_i,
    output logic                    arready_o,
    
    output logic [             3:0] rid_o,
    output logic [DATA_WIDTH - 1:0] rdata_o,
    output logic                    rlast_o,
    output logic                    rvalid_o,
    input  logic                    rready_i,
    
    output logic [             3:0] bid_o,
    output logic [             1:0] bresp_o,
    output logic                    bvalid_o,
    input  logic                    bready_i,

    output logic [             3:0] m_awid_o,
    output logic [             3:0] m_awlen_o,
    output logic [             2:0] m_awsize_o,
    output logic [             1:0] m_awburst_o,
    
    output logic [            63:0] m_awaddr_o,
    output logic                    m_awvalid_o,
    input  logic                    m_awready_i,
    
    output logic [             3:0] m_wid_o,
    output logic [DATA_WIDTH - 1:0] m_wdata_o,
    output logic [             3:0] m_wstrb_o,
    output logic                    m_wlast_o,
    output logic                    m_wvalid_o,
    input  logic                    m_wready_i,
    
    input  logic [             3:0] m_bid_i,
    input  logic [             1:0] m_bresp_i,
    input  logic                    m_bvalid_i,
    output logic                    m_bready_o
);

wire  [DATA_WIDTH - 1:0] m_bram [0 : BRAM_QUANTITY - 1];

s_axi_reg #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .BRAM_QUANTITY (BRAM_QUANTITY)
) axi_slave_0
(
    .clk            (clk),
    .areset         (areset),
    .m_bram_o       (m_bram),
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
);


m_axi_reg #(
    .DATA_WIDTH (DATA_WIDTH),
    .ADDR_WIDTH (ADDR_WIDTH),
    .BRAM_QUANTITY (BRAM_QUANTITY)
) axi_master_0
(
    .clk            (clk),
    .areset         (areset),
    .BRAM           (m_bram),
    .awid_o         (m_awid_o),
    .awlen_o        (m_awlen_o),
    .awsize_o       (m_awsize_o),
    .awburst_o      (m_awburst_o),
    .awaddr_o       (m_awaddr_o),
    .awvalid_o      (m_awvalid_o),
    .awready_i      (m_awready_i),
    .wid_o          (m_wid_o),
    .wdata_o        (m_wdata_o),
    .wstrb_o        (m_wstrb_o),
    .wlast_o        (m_wlast_o),
    .wvalid_o       (m_wvalid_o),
    .wready_i       (m_wready_i),
    .bid_i          (m_bid_i),
    .bresp_i        (m_bresp_i),
    .bvalid_i       (m_bvalid_i),
    .bready_o       (m_bready_o)
);
endmodule