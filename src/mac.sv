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
	assign ready = ready_mul; 
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
	
	reg int cnt = 0;
	reg [opsize-1:0] Ain [0:6]; //= {48, 48, -48, -1, 127};
	reg [opsize-1:0] Bin [0:6];
	
	
	mac #(opsize) uut(clk, start, reset, A, B, OUT, ready);
	
	initial begin
	Ain[0] = 48;
	Bin[0] = 110;
	Ain[1] = 48;
	Bin[1] = -110;
	Ain[2] = -48;
	Bin[2] = 110;
	Ain[3] = -1;
	Bin[3] = -1;
	Ain[4] = 127;
	Bin[4] = 127;
		$dumpfile("testmac.wcd");
		$dumpvars(0, testmac);
		#3
		while(cnt <= 5) begin
			#2
			if(ready) begin
				start = 1;
				A = Ain[cnt];
				B = Bin[cnt];
				#2
				//start = 0;
				cnt++;
			end
		end
		
		$finish;
	end
endmodule