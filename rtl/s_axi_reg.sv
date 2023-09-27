module s_axi_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 6
) (
    // GLOBAL SIGNALS 
    output logic  [DATA_WIDTH - 1:0] m_bram_o [0 : BRAM_QUANTITY - 1],

    input                           clk,
    input                           areset,
    // WRITE SIGNALS
    //   Address
    input  logic [ADDR_WIDTH - 1:0] awaddr_i,
    input  logic                    awvalid_i,
    output logic                    awready_o,
    //   Data
    input  logic [DATA_WIDTH - 1:0] wdata_i,
    input  logic [             3:0] wstrb_i,
    input  logic                    wvalid_i,
    output logic                    wready_o,
    // READ SIGNALS
    //   Address
    input  logic [ADDR_WIDTH - 1:0] araddr_i,
    input  logic                    arvalid_i,
    output logic                    arready_o,
    //   Data
    output logic [DATA_WIDTH - 1:0] rdata_o,
    output logic                    rvalid_o,
    input  logic                    rready_i,
    // RESPONSE SIGNALS
    output logic [             1:0] bresp_o,
    output logic                    bvalid_o,
    input  logic                    bready_i,

    input  logic [             2:0] master_status_i
);

  logic [DATA_WIDTH - 1:0] BRAM     [0 : BRAM_QUANTITY - 1];
  assign m_bram_o = BRAM;

  /* Module signals */

  // Address buffer
  logic [ADDR_WIDTH - 1:0] write_addr;
  logic [ADDR_WIDTH - 1:0] read_addr;

  // Data buffer
  logic [DATA_WIDTH - 1:0] wdata_ff;
  logic [DATA_WIDTH - 1:0] rdata_ff;

  logic                    has_addr;
  logic                    has_data;

  logic                    awrite_handshake;
  logic                    write_handshake;
  logic                    resp_handshake;

  logic                    aread_handshake;
  logic                    read_handshake;

  logic                    can_write;

  assign awrite_handshake = awvalid_i && awready_o;
  assign aread_handshake = arvalid_i && arready_o;

  assign write_handshake = wvalid_i && wready_o;
  assign read_handshake = rvalid_o && rready_i;

  assign can_write = has_addr && has_data;

  assign rdata_o = rdata_ff;

  /* Address */
  
  // Address W Ready
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awready_o <= 1;
    end else begin
      if(awrite_handshake) begin
        awready_o <= 0;
      end
      if(resp_handshake) begin
        awready_o <= 1;
      end
    end
  end

  // Address R Ready
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      arready_o <= 1;
    end else begin
      if(aread_handshake) begin
        arready_o <= 0;
      end
      if(read_handshake) begin
        arready_o <= 1;
      end
    end
  end

  // Address W Bufferization
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      write_addr <= 0;
    end else begin
      if(awrite_handshake) begin
        write_addr <= (awaddr_i[7:0] >> 2);
      end
    end
  end

  // Address R Bufferization
  assign read_addr = (araddr_i[7:0] >> 2);

  /* Data */

  // Data W Ready
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wready_o <= 1;
    end else begin
      if(write_handshake) begin
        wready_o <= 0;
      end
      if(resp_handshake) begin
        wready_o <= 1;
      end
    end
  end

  // Data R Ready
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      rvalid_o <= 0;
    end else begin
      if(aread_handshake) begin
        rvalid_o <= 1;
      end
      if(read_handshake) begin
        rvalid_o <= 0;
      end
    end
  end

  // Data W
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wdata_ff <= 0;
    end else begin
      if(write_handshake) begin
        wdata_ff <= wdata_i;
      end
    end
  end

  generate;
    for (genvar i = 0; i<BRAM_QUANTITY; i++) begin
      always_ff @(posedge clk or negedge areset) begin
        if (~areset) begin
          BRAM[i] <= 0;
        end else begin
          if(can_write && write_addr == i) begin
            if (wstrb_i[0] == 1) BRAM[i][7:0] <= wdata_ff[7:0];
            if (wstrb_i[1] == 1) BRAM[i][(8*1)+7:(8*1)] <= wdata_ff[(8*1)+7:(8*1)];
            if (wstrb_i[2] == 1) BRAM[i][(8*2)+7:(8*2)] <= wdata_ff[(8*2)+7:(8*2)];
            if (wstrb_i[3] == 1) BRAM[i][(8*3)+7:(8*3)] <= wdata_ff[(8*3)+7:(8*3)];
          end
        end
      end
    end
  endgenerate

  // Data R
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      rdata_ff <= 0;
    end else begin
      if(aread_handshake) begin
        rdata_ff <= read_addr < BRAM_QUANTITY ? BRAM[read_addr] : master_status_i;
      end
    end
  end

  /* Response */

  assign resp_handshake = bvalid_o && bready_i;
  /*
  // Response handshake
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      resp_handshake <= 0;
    end else begin
      if(bvalid_o && bready_i) begin
        resp_handshake <= 1;
      end
      if(resp_handshake) begin
        resp_handshake <= 0;
      end
    end
  end*/

  // Response valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      bvalid_o <= 0;
    end else begin
      if(!resp_handshake) begin
      if(has_addr && has_data) begin
        bvalid_o <= 1;
      end
      end
      else
      begin
        bvalid_o <= 0;
      end
    end
  end

  // Response
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      bresp_o <= 0;
    end else begin
      if(has_addr && has_data) begin
        bresp_o <= 0;
      end
      if(resp_handshake) begin
        bresp_o <= 0;
      end
    end
  end

  // Addr buf signal
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      has_addr <= 0;
    end else begin
      if(awrite_handshake) begin
        has_addr <= 1;
      end
      if(resp_handshake) begin
        has_addr <= 0;
      end
    end
  end
  
  // Data buf signal
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      has_data <= 0;
    end else begin
      if(write_handshake) begin
        has_data <= 1;
      end
      if(resp_handshake) begin
        has_data <= 0;
      end
    end
  end
endmodule
