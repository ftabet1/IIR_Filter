module mul #(parameter opsize = 8)
(
	input wire clk, start, reset,
	input wire[opsize-1:0] A, B,
	output reg[(opsize*2)-1:0] OUT = 0,
	output reg ready = 1
);

	parameter p_state_idle = 0;
	parameter p_state_oper = 1;

	wire[opsize:0] sum;
	
	reg[5:0] cnt = 0;
	reg[2:0] state = 0;
	reg[opsize-1:0] MN = 0;
	reg MTsign = 0;
	wire[opsize-1:0] twos_compl;
	reg dopsign = 0;
	
	assign twos_compl = (~MN)+1;
	
	//sum assign
	assign sum = OUT[(opsize*2)-1:opsize] + mult;
	//multiplexor for sum
	wire[1:0] sel;
	reg[opsize-1:0] mult;
	assign sel[0] = OUT[0];
	assign sel[1] = cnt==(opsize-1) && MTsign ? 1 : 0;
	always@(sel or MN) begin
		case(sel)
			0: mult = 0;
			1: mult = MN;//OUT[(opsize*2)-1:opsize];
			default: mult = twos_compl;
		endcase
	end
	
	//main mul process
	always@(posedge clk) begin
		if(reset) begin
			state = p_state_idle;
			ready = 1;
			OUT = 0;
		end else if(state == p_state_idle && start != 0) begin
			ready = 0;
			state = p_state_oper;
			cnt = 0;
			MN = B;
			OUT[(opsize*2)-1:opsize-1] = 0;
			OUT[opsize-2:0] = A[opsize-2:0];
			MTsign = A[opsize-1];
			dopsign = 0;
		end else if(state == p_state_oper) begin
			if(cnt != opsize) begin
				cnt++;
				OUT[opsize-2:0] = {OUT[opsize-1], OUT[opsize-2:1]};
				OUT[(opsize*2)-2:opsize-1] = sum[opsize-1:0];
				dopsign = dopsign | sum[opsize-1];
				OUT[(opsize*2)-1] = MN[opsize-1] ? dopsign : 0;
			end else begin
				ready = 1;
				state = p_state_idle;
				OUT[(opsize*2)-1] = MTsign ^ MN[opsize-1];
			end
		end
	end
	
endmodule


module testmul;
	parameter opsize = 4;
	reg reset = 0;
	reg start = 0;
	reg clk = 0;
	wire ready;
	wire[(opsize*2)-1:0] OUT;
	reg[opsize-1:0] A = 0;
	reg[opsize-1:0] B = 0;
	always #1 clk = ~clk;
	
	mul #(opsize) uut(clk, start, reset, A, B, OUT, ready);
	
	initial begin
		$dumpfile("testmul.wcd");
		$dumpvars(0, testmul);
		#3
		A = 4;
		B = 6;//
		start = 1;
		#2
		start = 0;
		#30
		A = -4;
		B = 6;
		start = 1;
		#2
		start = 0;
		#30
		A = 4;
		B = -6;
		start = 1;
		#2
		start = 0;
		#30
		A = -4;
		B = -6;
		start = 1;
		#2
		start = 0;
		#30
		A = -1;
		B = -1;
		start = 1;
		#2
		start = 0;
		#500
		$finish;
	end
endmodule