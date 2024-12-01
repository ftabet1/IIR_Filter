module mac #(parameter opsize = 8)
(
	input wire clk, start, reset,
	input wire[opsize-1:0] A, B,
	output reg[(opsize*2)-1:0] OUT = 0,
	output wire ready
);
	wire[(opsize*2)-1:0] OUT_mul;
	
	mul #(opsize) uut(clk, start, reset, A, B, OUT_mul, ready_mul);
	wire ready_mul;
	logic delay = 1;
	assign ready = delay; 
	always@(posedge clk) begin
		if(reset) begin
			OUT = 0;
			delay = 1;
		end else begin
			OUT = ready_mul && !delay ? OUT_mul + OUT : OUT;
			delay = ready_mul;		
		end
	end

endmodule

module testmac;
	parameter opsize = 8;
	reg start = 0;
	reg reset = 0;
	reg clk = 0;
	wire ready;
	wire[(opsize*2)-1:0] OUT;
	reg[opsize-1:0] A = 0;
	reg[opsize-1:0] B = 0;
	always #1 clk = ~clk;
	
	mac #(opsize) uut(clk, start, reset, A, B, OUT, ready);
	
	initial begin
		$dumpfile("testmac.wcd");
		$dumpvars(0, testmac);
		#3
		A = 48;
		B = 110;//
		start = 1;
		#2
		start = 0;
		#30
		A = 48;
		B = -110;
		start = 1;
		#2
		start = 0;
		#30
		A = -48;
		B = 110;
		start = 1;
		#2
		start = 0;
		#30
		A = -48;
		B = -110;
		start = 1;
		#2
		start = 0;
		#30
		A = -1;
		B = -1;
		start = 1;
		#2
		start = 0;
		#30
		A = 127;
		B = 127;
		start = 1;
		#2
		start = 0;
		#30
		$finish;
	end
endmodule