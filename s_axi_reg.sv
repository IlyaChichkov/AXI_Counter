module s_axi_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 8
) (
    // GLOBAL SIGNALS 
    input                           clk,
    input                           areset,
    // WRITE SIGNALS
    //   Address
    input  logic [             3:0] awid_i,
    input  logic [ADDR_WIDTH - 1:0] awaddr_i,
    input  logic                    awvalid_i,
    output logic                    awready_o,
    //   Data
    input  logic [             3:0] wid_i,
    input  logic [DATA_WIDTH - 1:0] wdata_i,
    input  logic [             3:0] wstrb_i,
    input  logic                    wlast_i,
    input  logic                    wvalid_i,
    output logic                    wready_o,
    // READ SIGNALS
    //   Address
    input  logic [             3:0] arid_i,
    input  logic [ADDR_WIDTH - 1:0] araddr_i,
    input  logic                    arvalid_i,
    output logic                    arready_o,
    //   Data
    output logic [             3:0] rid_o,
    output logic [DATA_WIDTH - 1:0] rdata_o,
    output logic                    rlast_o,
    output logic                    rvalid_o,
    input  logic                    rready_i,
    // RESPONSE SIGNALS
    output logic [             3:0] bid_o,
    output logic [             1:0] bresp_o,
    output logic                    bvalid_o,
    input  logic                    bready_i
);

  logic [DATA_WIDTH - 1:0] BRAM     [0 : BRAM_QUANTITY - 1];

  /* Module signals */

  logic [ADDR_WIDTH - 1:0] awaddr_ff;
  logic [DATA_WIDTH - 1:0] wdata_ff;

  logic [ADDR_WIDTH - 1:0] araddr_ff;
  logic [DATA_WIDTH - 1:0] rdata_ff;

  logic                    has_addr;
  logic                    has_data;

  logic                    awready_en;
  logic                    wready_en;
  logic                    bvalid_en;

  logic                    awrite_handshake;
  logic                    write_handshake;
  logic                    aread_handshake;

  logic [DATA_WIDTH - 1:0] crc_result;

  /* Functional methods */

  assign awaddr_ff = awaddr_i[7:0] >> 2;
  assign araddr_ff = araddr_i[7:0] >> 2;
  // Write address

  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      has_addr = '0;
      awready_en <= 1;
    end else begin
      if (awrite_handshake && !has_addr) begin
        has_addr  <= 1;
        awready_en <= 0;
      end

      if (has_data && has_addr) begin
        has_addr  <= 0;
      end

      if (bvalid_en && bready_i) begin
        awready_en <= 1;
      end

      if (write_handshake && !has_data && has_addr) begin
        awready_en <= 1;  // Got data -> ready HIGH 
      end
    end
  end

  assign correct_addr = awaddr_ff < BRAM_QUANTITY && awaddr_ff >= 0 ? 1 : 0;
  assign awrite_handshake = awvalid_i && awready_o;

  // Write data to registers
  generate
    for (genvar i = 0; i < 8; i++) begin
      always_ff @(posedge clk or negedge areset) begin
        if (~areset) begin
          BRAM[i] <= 32'b0;
        end else begin
          if (has_data && has_addr && awaddr_ff == i && correct_addr) begin
            if (wstrb_i[0] == 1) BRAM[i][7:0] <= wdata_ff[7:0];
            if (wstrb_i[1] == 1) BRAM[i][(8*1)+7:(8*1)] <= wdata_ff[(8*1)+7:(8*1)];
            if (wstrb_i[2] == 1) BRAM[i][(8*2)+7:(8*2)] <= wdata_ff[(8*2)+7:(8*2)];
            if (wstrb_i[3] == 1) BRAM[i][(8*3)+7:(8*3)] <= wdata_ff[(8*3)+7:(8*3)];
          end
        end
      end
    end
  endgenerate

  // Write data signals
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      // Reset
      has_data = '0;
      wready_en <= 1;
      wdata_ff  <= '0;
    end else begin
      if (awrite_handshake && !has_addr) begin
        if (!has_data) begin
          wdata_ff <= wdata_i;
          has_data <= 1;
        end
      end

      if (write_handshake && !has_data) begin
        if (!has_addr) begin
          wdata_ff  <= wdata_i;
          wready_en <= 0;
          has_data  <= 1;
        end
      end

      if (has_data && has_addr) begin
        has_data  <= 0;
        wready_en <= 1;
      end

      if (bvalid_en && bready_i) begin
        wready_en  <= 1;
      end
    end
  end

  assign awready_o = awready_en;
  assign wready_o  = wready_en;
  assign bvalid_o  = bvalid_en;

  // Response valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      bvalid_en <= '0;
      bid_o <= '0;
      bresp_o <= '0;
    end else begin
      if (bvalid_en && bready_i) begin
        bvalid_en  <= 0;
      end

      if (has_data && has_addr) begin
        bvalid_en <= 1;
      end
    end
  end

  assign write_handshake = wvalid_i && wready_o;

  assign crc_result = BRAM[0] ^ BRAM[1] ^ BRAM[2] ^ BRAM[3] ^ BRAM[4] ^ BRAM[5] ^ BRAM[6] ^ BRAM[7];

  // Read data
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      // Reset
      arready_o <= '1;
      aread_handshake <= '0;

      rdata_ff <= '0;

      rid_o <= '0;
      rlast_o <= '0;
      rvalid_o <= '0;
    end else begin
      // Check incoming address if valid
      if (arvalid_i && arready_o) begin
        rdata_ff <= araddr_ff < BRAM_QUANTITY ? BRAM[araddr_ff] : crc_result;
        aread_handshake <= 1;
        rvalid_o   <= 1;
        arready_o <= 0;
      end
      
      // Read ready
      if (rready_i && rvalid_o) begin
        arready_o <= 1;
        rvalid_o <= 0;
        aread_handshake <= 0;
      end
      
    end
  end

  assign rdata_o = rdata_ff;

endmodule
