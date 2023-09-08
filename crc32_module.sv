module crc32_module (
	input   logic               clk,
	input   logic               areset,
	input   logic   [31:0]      data,
	output  logic   [31:0]      crc
);

logic [31:0] crc_next;

always @(posedge clk)
begin
	if(!areset) begin
		crc <= '0;
	end
	else begin
		crc <= crc_next;
	end
end

always_comb begin
    crc_next = crc_next ^ data; // TODO: Реализовать алгоритм crc32
end

endmodule