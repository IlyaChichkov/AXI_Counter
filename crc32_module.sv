module crc32_module (
	input   logic               clk,
	input   logic               areset,
	input   logic               valid_i,
	input   logic   [31:0]      data_i,
	output  logic   [31:0]      crc_o
);

logic [31:0] crc;
assign crc_o = crc ^ data_i;

always @(posedge clk or negedge areset) begin
	if (!areset) begin
		crc <= 32'hFFFFFFFF;
	end else begin
		if(valid_i) begin
			crc <= crc_o;
		end
		else begin
			crc <= 32'hFFFFFFFF;
		end
	end
end

endmodule