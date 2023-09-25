module m_axi_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 6
) (
    // GLOBAL SIGNALS 
    input                           clk,
    input                           areset,
    input  wire                     BRAM,
    ////////////////// SLAVE_BUS /////////////////////
    // WRITE SIGNALS
    //   Burst
    input  logic [             3:0] awid_i,
    // Number of data transfers per burst
    input  logic [             3:0] awlen_i,
    // Burst transaction data size (2 - 32-bit)
    input  logic [             2:0] awsize_i,
    // Burst type
    // 0'b00    fixed
    // 0'b01    incrementing
    // 0'b10    wrap
    // 0'b11    -
    input  logic [             1:0] awburst_i,
    //   Address
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
    input  logic                    bready_i,
    ////////////////// SLAVE_BUS END /////////////////////

    ////////////////// MASTER_BUS /////////////////////

    // WRITE SIGNALS
    //   Burst
    input  logic [             3:0] m_awid_o,
    // Number of data transfers per burst
    input  logic [             3:0] m_awlen_o,
    // Burst transaction data size (2 - 32-bit)
    input  logic [             2:0] m_awsize_o,
    // Burst type
    // 0'b00    fixed
    // 0'b01    incrementing
    // 0'b10    wrap
    // 0'b11    -
    input  reg [             1:0] m_awburst_o,
    //   Address
    input  reg [            63:0] m_awaddr_o,
    input  reg                    m_awvalid_o,
    output reg                    m_awready_i,
    //   Data
    input  reg [             3:0] m_wid_o,
    input  reg [DATA_WIDTH - 1:0] m_wdata_o,
    input  reg [             3:0] m_wstrb_o,
    input  reg                    m_wlast_o,
    input  reg                    m_wvalid_o,
    output reg                    m_wready_i,
    // RESPONSE SIGNALS
    output reg [             3:0] m_bid_i,
    output reg [             1:0] m_bresp_i,
    output reg                    m_bvalid_i,
    input  reg                    m_bready_o
    ////////////////// MASTER_BUS END /////////////////////
);

  typedef enum bit[32:0] { ENABLED, ADDR_W_0, ADDR_W_1, LENGTH, INCR_STEP, STATUS } REG_TYPE;

  logic [DATA_WIDTH - 1:0] BRAM     [0 : BRAM_QUANTITY - 1];

  /* Module signals */

  wire correct_addr;
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

  logic [             3:0] awid_ff;
  logic [             3:0] awlen_ff;
  logic [             2:0] awsize_ff;
  logic [             1:0] awburst_ff;

  logic [             3:0] burst_counter;

  typedef enum bit[2:0] { IDLE, WRITING_ADDR, WRITING_DATA, DATA_RESPONSE, INCR_VAL } counter_states;
  logic [ 2:0]             counter_status;
  logic [ 2:0]             cnt_state_next; 
  logic [ 2:0]             cnt_state;

  logic [31:0]             counter_ff;

  /* Functional methods */

  assign awaddr_ff = awaddr_i[7:0] >> 2;
  assign araddr_ff = araddr_i[7:0] >> 2;

  logic can_write_data;
  assign can_write_data = has_data && has_addr;
  // Burst counter
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      burst_counter <= '0;
    end else begin
      if (awrite_handshake && !has_addr) begin
        burst_counter <= '0;
      end
    
      if (can_write_data) begin
        burst_counter <= burst_counter + 1;
      end
    end
  end

  // Burst
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
        awburst_ff <= '0;
        awsize_ff <= '0;
        awlen_ff <= '0;
        awid_ff <= '0;
    end else begin
      if (awrite_handshake && !has_addr) begin
        awburst_ff <= awburst_i;
        awsize_ff <= awsize_i;
        awlen_ff <= awlen_i;
        awid_ff <= awid_i;
      end

      if(wready_en && !wlast_i) begin
        burst_counter <= burst_counter + 1;

      /*
        case (awburst_ff)
          2'b00: begin
            // Addr not changed
          end
          2'b01: begin
            // Incr
            awaddr_ff <= awaddr_ff + 1;
          end
          2'b10: begin
            // Wrap
            if(awaddr_ff + 1 > 7) begin
              awaddr_ff <= 0;
            end
            else
            begin
              awaddr_ff <= awaddr_ff + 1;
            end
          end
          default: begin
            
          end
        endcase
        */
      end
    end
  end

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

      if (wlast_i) begin
        has_addr  <= 0;
      end

      if (bvalid_en && bready_i) begin
        awready_en <= 1;
      end

      // TODO: Признак готовности принять новый адрес
      // В данный момент когда есть адрес но нет данных
       
      /* ???
      if (write_handshake && !has_data && has_addr) begin
        awready_en <= 1;  // Got data -> ready HIGH 
      end
      */
    end
  end

  assign correct_addr = awaddr_ff < BRAM_QUANTITY && awaddr_ff >= 0 ? 1 : 0;
  assign bresp_o = correct_addr == 1 ? 2'b00 : 2'b10;
  assign awrite_handshake = awvalid_i && awready_o;

  // Write data to registers
  generate
    for (genvar i = 0; i < 8; i++) begin
      always_ff @(posedge clk or negedge areset) begin
        if (~areset) begin
          BRAM[i] <= 32'b0;
        end else begin
          if (can_write_data && awaddr_ff == i && correct_addr) begin
            if (wstrb_i[0] == 1) BRAM[i][7:0] <= wdata_ff[7:0];
            if (wstrb_i[1] == 1) BRAM[i][(8*1)+7:(8*1)] <= wdata_ff[(8*1)+7:(8*1)];
            if (wstrb_i[2] == 1) BRAM[i][(8*2)+7:(8*2)] <= wdata_ff[(8*2)+7:(8*2)];
            if (wstrb_i[3] == 1) BRAM[i][(8*3)+7:(8*3)] <= wdata_ff[(8*3)+7:(8*3)];
          end
          // READ ONLY REGISTER (COUNTER STATUS)
          BRAM[BRAM_QUANTITY] = { 30'b0 , counter_status };
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

      if (can_write_data) begin
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
    end else begin
      if (bvalid_en && bready_i) begin
        bvalid_en  <= 0;
      end

      if (can_write_data && !bvalid_en /* TODO: WLAST && wlast_i */ ) begin
        bvalid_en <= 1;
      end
    end
  end

  assign write_handshake = wvalid_i && wready_o;

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
        rdata_ff <= BRAM[araddr_ff];
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

  // Counter State Machine
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      cnt_state_next <= IDLE;
    end else begin
      case (cnt_state)
          IDLE: begin
            if(BRAM[ENABLED]) begin
              cnt_state_next <= WRITING_ADDR;
            end
          end
          WRITING_ADDR: begin
            if(m_awready_i) begin
              cnt_state_next <= WRITING_DATA;
            end
          end
          WRITING_DATA: begin
            if(m_wready_i) begin
              cnt_state_next <= DATA_RESPONSE;
            end
          end
          DATA_RESPONSE: begin
            if(m_bvalid_i) begin
              cnt_state_next <= INCR_VAL;
            end
          end
          INCR_VAL: begin
            if(BRAM[ENABLED]) begin
              cnt_state_next <= WRITING_ADDR;
            end
            else begin
              cnt_state_next <= IDLE;
            end
          end
          default: begin
            cnt_state_next <= IDLE;
          end
        endcase
    end
  end

  // Current Counter State
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      cnt_state <= IDLE;
    end else begin
      cnt_state <= cnt_state_next;
    end
  end

  // Counter 
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      counter_ff <= '0;
    end else begin
      if(cnt_state == INCR_VAL) begin
          counter_ff += BRAM[INCR_STEP];
      end
    end
  end

  // Address valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      m_awvalid_o <= '0;
    end else begin
      if(cnt_state == WRITING_ADDR) begin
        m_awvalid_o <= 1;
        if(m_awready_i) begin
          m_awvalid_o <= 0;
        end
      end
    end
  end

  // Data valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      m_wvalid_o <= '0;
    end else begin
      if(cnt_state == WRITING_DATA) begin
        m_wvalid_o <= 1;
        if(m_awready_i) begin
          m_wvalid_o <= 0;
        end
      end
    end
  end

  // Data 
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      m_wdata_o <= '0;
      m_wstrb_o <= '1;
    end else begin
      if(cnt_state == WRITING_DATA) begin
        m_wdata_o <= counter_ff;
      end
    end
  end

  // Response valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      m_bready_o <= '0;
    end else begin
      if(cnt_state == DATA_RESPONSE) begin
        m_bready_o <= 1;
        if(m_bvalid_i) begin
          m_bready_o <= 0;
        end
      end
    end
  end

  assign counter_status = cnt_state;
  assign m_awaddr_o = { BRAM[ADDR_W_0], BRAM[ADDR_W_1] };

endmodule
