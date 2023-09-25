module m_axi_reg #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter BRAM_QUANTITY = 6
) (
    // GLOBAL SIGNALS 
    input                           clk,
    input                           areset,
    input logic                     [DATA_WIDTH - 1:0] BRAM     [0 : BRAM_QUANTITY - 1],

    // WRITE SIGNALS
    //   Burst
    output logic [             3:0] awid_o,
    // Number of data transfers per burst
    output logic [             3:0] awlen_o,
    // Burst transaction data size (2 - 32-bit)
    output logic [             2:0] awsize_o,
    // Burst type
    // 0'b00    fixed
    // 0'b01    incrementing
    // 0'b10    wrap
    // 0'b11    -
    output logic [             1:0] awburst_o,
    //   Address
    output logic [            63:0] awaddr_o,
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
    output logic                    bready_o
);

  /* Module signals */

  typedef enum bit[32:0] { ENABLED, ADDR_W_0, ADDR_W_1, LENGTH, INCR_STEP, STATUS }       REG_TYPE;
  typedef enum bit[2:0]  { IDLE, WRITING_ADDR, WRITING_DATA, DATA_RESPONSE, INCR_VAL }    counter_states;

  logic [ 2:0]             counter_status;
  logic [ 2:0]             cnt_state_next; 
  logic [ 2:0]             cnt_state;

  logic                    burst_cnt_en;
  logic [31:0]             current_burst_cnt;
  logic [31:0]             burst_len;
  assign burst_len = BRAM[LENGTH];

  logic                    counter_en;
  logic [31:0]             counter_ff;

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
            if(awready_i) begin
              cnt_state_next <= WRITING_DATA;
            end
          end
          WRITING_DATA: begin
            if(wready_i) begin
              cnt_state_next <= DATA_RESPONSE;
            end
          end
          DATA_RESPONSE: begin
            if(bvalid_i) begin
              cnt_state_next <= INCR_VAL;
            end
          end
          INCR_VAL: begin
            if(BRAM[ENABLED]) begin
              if(current_burst_cnt < burst_len) begin
                cnt_state_next <= WRITING_DATA;
              end
              else
              begin
                cnt_state_next <= WRITING_ADDR;
              end
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
      if(cnt_state == INCR_VAL && counter_en) begin
        counter_ff <= counter_ff + BRAM[INCR_STEP];
      end
    end
  end

  // Counter Add
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      counter_en <= 1;
    end else begin
      if(cnt_state == WRITING_ADDR) begin
        counter_en <= 1;
      end
      if(cnt_state == INCR_VAL) begin
        counter_en <= 0;
      end
    end
  end

  // Address valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awvalid_o <= '0;
    end else begin
      if(cnt_state == WRITING_ADDR) begin
        awvalid_o <= 1;
        if(awready_i) begin
          awvalid_o <= 0;
        end
      end
    end
  end

  // Data valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wvalid_o <= '0;
    end else begin
      if(cnt_state == WRITING_DATA) begin
        wvalid_o <= 1;
        if(wready_i) begin
          wvalid_o <= 0;
        end
      end
    end
  end

  // Data 
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wdata_o <= '0;
      wstrb_o <= '1;
    end else begin
      if(cnt_state == WRITING_DATA) begin
        wdata_o <= counter_ff;
      end
    end
  end

  // Response valid
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      bready_o <= '0;
    end else begin
      if(cnt_state == DATA_RESPONSE) begin
        bready_o <= 1;
        if(bvalid_i) begin
          bready_o <= 0;
        end
      end
    end
  end

  assign counter_status = cnt_state;
  assign awaddr_o = { BRAM[ADDR_W_0], BRAM[ADDR_W_1] };

  // Burst
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awburst_o <= 1;
      awsize_o <= 'b101;
    end else begin
      
    end
  end

  // Burst length
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      awlen_o <= 0;
    end else begin
      awlen_o <= burst_len;
    end
  end

  // Burst last
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      wlast_o <= 0;
    end else begin
      if(current_burst_cnt >= burst_len) begin
        wlast_o <= 1;
      end
    end
  end

  // Can add burst count
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      burst_cnt_en <= 0;
    end else begin
      if(cnt_state == WRITING_DATA) begin
        burst_cnt_en <= 1;
      end
      if(cnt_state == INCR_STEP) begin
        burst_cnt_en <= 0;
      end
    end
  end

  // Current burst count
  always_ff @(posedge clk or negedge areset) begin
    if (~areset) begin
      current_burst_cnt <= 0;
    end else begin
      if(cnt_state == WRITING_ADDR) begin
        current_burst_cnt <= 0;
      end
      if(cnt_state == INCR_STEP && burst_cnt_en) begin
        current_burst_cnt <= current_burst_cnt + 1;
      end
    end
  end
endmodule
