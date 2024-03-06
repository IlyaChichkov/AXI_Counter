module m_axi_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 6,
    parameter AWSIZE = (DATA_WIDTH >> 3)
) (
    // GLOBAL SIGNALS 
    input                           clk,
    input                           areset,
    input logic                     [DATA_WIDTH - 1:0] BRAM     [0 : BRAM_QUANTITY - 1],

    // WRITE SIGNALS
    //   Burst
    output logic [             3:0] awid_o,
    // Number of data transfers per burst
    output logic [             7:0] awlen_o,
    // Burst transaction data size (2 - 32-bit)
    output logic [             2:0] awsize_o,
    // Burst type
    // 0'b00    fixed
    // 0'b01    incrementing
    // 0'b10    wrap
    // 0'b11    -
    output logic [             1:0] awburst_o,
    //   Address
    output logic [ADDR_WIDTH - 1:0] awaddr_o,
    output logic                    awvalid_o,
    input  logic                    awready_i,
    //   Data
    output logic [             3:0] wid_o,
    output logic [DATA_WIDTH - 1:0] wdata_o,
    output logic [             3:0] wstrb_o,
    output logic                    wlast_o,
    output logic                    wvalid_o,
    input  logic                    wready_i,
    // RESPONSE SIGNALS
    input  logic [             3:0] bid_i,
    input  logic [             1:0] bresp_i,
    input  logic                    bvalid_i,
    output logic                    bready_o,

    // Master module signals
    output logic [             2:0] master_status_o,
    input  logic                    status_read_i,
    input  logic                    master_start_i
);

  /* Module signals */

  logic [DATA_WIDTH - 1:0]             current_burst_cnt;
  logic [DATA_WIDTH - 1:0]             burst_len;

  logic [             3:0] awid_ff;

  typedef enum bit[32:0] { ENABLED, ADDR_W_0, ADDR_W_1, LENGTH, INCR_STEP, BTYPE, STATUS }       REG_TYPE;

  logic                     awrite_handshake;
  logic                     write_handshake;
  logic                     response_handshake;

  logic                     is_last_burst;

  logic [DATA_WIDTH - 1:0]  counter_ff;

  logic                     start_transaction;
  logic                     making_transaction;
  logic                     burst_processing;
  logic                     finished_transaction;

  logic                     enabled_last;

  assign awrite_handshake = awvalid_o && awready_i;
  assign write_handshake = wvalid_o && wready_i;
  assign response_handshake = bvalid_i && bready_o;
  assign is_last_burst = current_burst_cnt + 1 >= burst_len;

  assign awid_o = awid_ff;
  assign wid_o = awid_ff;

  // Master status
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      master_status_o <= '0;
    end else begin
      if(status_read_i) begin
        master_status_o <= '0;
      end
      
      if(response_handshake) begin
        master_status_o <= { 1'b1, bresp_i };
      end
    end
  end

  // AWID
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awid_ff <= '0;
    end else begin
      if(finished_transaction) begin
        awid_ff <= awid_ff + 1;
      end
    end
  end

  // Start transaction signal

  assign start_transaction = master_start_i;

/*
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      start_transaction <= '0;
    end else begin
      enabled_last <= BRAM[ENABLED];
      if(BRAM[ENABLED] != enabled_last && enabled_last == 0 && !making_transaction) begin
        start_transaction <= 1;
      end
      if(start_transaction) begin
        start_transaction <= 0;
      end
    end
  end
*/

  // Making transaction signal
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      making_transaction <= '0;
    end else begin
      if(start_transaction) begin
        making_transaction <= 1;
      end
      
      if(response_handshake) begin
        making_transaction <= 0;
      end
    end
  end

  // Finished transaction signal
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      finished_transaction <= '0;
    end else begin
      if(finished_transaction) begin
        finished_transaction <= 0;
      end
      
      if(response_handshake) begin
        finished_transaction <= 1;
      end
    end
  end

  // burst processing
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      burst_processing <= 0;
    end else begin
      if(awrite_handshake) begin
        burst_processing <= 1;
      end
      if(wlast_o && write_handshake) begin
        burst_processing <= 0;
      end
    end
  end

  // Address valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awvalid_o <= '0;
    end else begin
      if(start_transaction && !making_transaction) begin
        awvalid_o <= 1;
      end
      
      if(awrite_handshake) begin
        awvalid_o <= 0;
      end
    end
  end

  // Address
  assign awaddr_o = { BRAM[ADDR_W_1], BRAM[ADDR_W_0] };

  // Data valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wvalid_o <= '0;
    end else begin
      if(burst_processing && !wvalid_o) 
        wvalid_o <= 1;
      if(write_handshake) 
        wvalid_o <= 0;
    end
  end

  // Data 
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wdata_o <= '0;
      wstrb_o <= '1;
    end else begin
      if(awrite_handshake) begin
        wdata_o <= counter_ff;
      end

      if(burst_processing && write_handshake) begin
        wdata_o <= counter_ff + BRAM[INCR_STEP];
        /*
        if(!is_last_burst) begin
          wdata_o <= counter_ff;
        end*/
      end
    end
  end

  // Response valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      bready_o <= '0;
    end else begin
      if(awrite_handshake) begin
        bready_o <= 1;
      end
      if(response_handshake) begin
        bready_o <= 0;
      end
    end
  end

  // Burst type
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awburst_o <= 0;
      awsize_o <= 'b010;
    end else begin
      if(start_transaction)
      begin
        awburst_o <= 2'b01;
        awsize_o <= 3'b010;
      end
    end
  end

  // Burst length
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awlen_o <= 0;
    end else begin
      if(start_transaction) begin
        awlen_o <= (BRAM[LENGTH] / AWSIZE) - 1;
      end
    end
  end

  assign wlast_o = is_last_burst;

  // Current burst max length
  assign burst_len = awlen_o + 1;
  /*
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      burst_len <= 0;
    end else begin
      if(start_transaction) begin
        burst_len <= awlen_o;
      end
    end
  end*/

  // Current burst count
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      current_burst_cnt <= 0;
    end else begin
      if(start_transaction && !making_transaction) begin
        current_burst_cnt <= 0;
      end
      if(burst_processing && write_handshake) begin
        if(is_last_burst) 
          current_burst_cnt <= 0;
        else 
          current_burst_cnt <= current_burst_cnt + 1;
      end
    end
  end

  // Counter 
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      counter_ff <= '0;
    end else begin
      if(burst_processing && write_handshake) begin
        counter_ff <= counter_ff + BRAM[INCR_STEP];
      end
      if(finished_transaction) begin
        counter_ff <= '0;
      end
    end
  end
endmodule
