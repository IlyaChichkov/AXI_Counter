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
    output logic   [3:0]     rid_o,
    output logic   [31:0]    rdata_o,
    output logic   [3:0]     rstrb_o,
    output logic             rlast_o,
    output logic             rvalid_o,
    input  logic             rready_i,
    // RESPONSE SIGNALS
    output logic [3:0]       bid_o,
    output logic [1:0]       bresp_o,
    output logic             bvalid_o,
    input  logic             bready_i
    );

logic [31:0]    BRAM [0:7];

/* Module signals */

logic [31:0]        awaddr_ff;
logic [31:0]        wdata_ff;

logic [31:0]        araddr_ff;
logic [31:0]        rdata_ff;

logic               has_addr;
logic               has_data;

logic               awready_en;
logic               wready_en;
logic               bvalid_en;

logic               awrite_handshake;
logic               write_handshake;
logic               aread_handshake;

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
        if(awrite_handshake && !has_addr)
        begin
            awaddr_ff <= awaddr_i;
            has_addr <= 1;
            if(!has_data) begin 
                wdata_ff <= wdata_i;
                has_data <= 1;
            end
        end
    end
end

assign awrite_handshake = awvalid_i && awready_o;
// Write data reset
generate
    for(genvar i = 0; i < 8; i++)
    begin
        always_ff @( posedge clk or negedge areset ) begin
            if(!areset)
            begin
                BRAM[i] <= 32'b0;
            end
        end
    end
endgenerate


// Write data
generate
    for(genvar i = 0; i < 4; i++)
    begin
        always_ff @( posedge clk ) begin
            if(write_handshake && has_addr)
            begin
                if(wstrb_i[i]) BRAM[awaddr_i][(8*i)+7:(8*i)] <= wdata_ff[(8*i)+7:(8*i)];
                has_addr <= 0;
                has_data <= 0;
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
        wdata_ff <= '0;
    end
    else
    begin
        if(write_handshake && !has_data)
        begin
            if(has_addr)
            begin
                awready_en <= 1; // Got data -> ready HIGH 
                wready_en <= 0;
                bvalid_en <= 1;
            end
            else
            begin
                wdata_ff <= wdata_i;
                has_data <= 1;
            end
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
            wready_en <= 1;
        end
    end
end

assign write_handshake = wvalid_i && wready_o;

// Read data
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        // Reset
        arready_o <= '1;
        aread_handshake <= '0;

        rdata_ff <= '0;
        araddr_ff <= '0;

        rid_o <= '0;
        rlast_o <= '0;
        rvalid_o <= '0;
        rstrb_o <= '1;
    end
    else
    begin
        if(aread_handshake)
        begin
            if(rready_i)
            begin
                arready_o <= 1;
                rvalid_o <= 0;
                aread_handshake <= 0;
            end
            else
            begin
                rvalid_o <= 1;
            end
        end
        // Check incoming address if valid
        if(arvalid_i)
        begin
            // TODO: arid_i
            araddr_ff <= araddr_i;
            // TODO: strb
            rdata_ff <= BRAM[araddr_i];
            aread_handshake <= 1;
            arready_o <= 0;
        end
    end
end

assign rdata_o = rdata_ff;

// Handshake
always_ff @( posedge clk or negedge areset ) begin
    if(!areset)
    begin
        // Reset
        has_addr = '0;
        has_data = '0;
    end
    else
    begin
        // Handshake write address and data
        if(awrite_handshake)
        begin
            awready_en <= 0;
        end
    end
end


endmodule
