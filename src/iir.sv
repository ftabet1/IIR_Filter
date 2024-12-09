module iir #(parameter OPSIZE = 16, RANK = 2)
(
	input logic clk,
	input logic start,
	input logic reset,
	input logic[OPSIZE-1:0] xin,
	output logic[OPSIZE-1:0] yout,
	output logic ready = 0
);

    //coefficient block {{xn..xn-RANK}, {yn-1..yn-RANK}}
    logic [OPSIZE-1:0] ROM[0:RANK*2+1] = {16'h251E, 16'hB508, 16'h251E, 0, 16'h15F6, 0}; 
    
    //delay chains
    logic wr_x, wr_y;
    logic[OPSIZE-1:0] x_n[0:RANK];
    logic[OPSIZE-1:0] y_n[0:RANK-1];
    
    logic[OPSIZE-1:0] mux_in[0:RANK*2+1];
    assign mux_in[RANK*2+1] = 0; //when cnt is RANK*2+1 to prevent X state
    logic[OPSIZE-1:0] mux_out;
    logic[RANK:0] mux_sel;
    assign mux_out = mux_in[mux_sel];
    assign mux_sel = cnt;
    //********************mux input assign********************
    genvar i_mux;
    generate
        //place x_n values to mux
        for(i_mux = 0; i_mux < RANK+1; i_mux++) begin
            assign mux_in[i_mux] = x_n[i_mux];
        end
        
        //place y_n values to mux
        for(i_mux = 0; i_mux < RANK; i_mux++) begin
            assign mux_in[i_mux+RANK+1] = y_n[i_mux];
        end
    endgenerate
    //*********************************************************
    
    //mac core instantiation
    logic[OPSIZE-1:0] mac_a, mac_b;
    logic[(OPSIZE*2)-1:0] mac_out; 
    logic mac_ready, mac_reset, mac_start = 0;
    mac #(OPSIZE) mac_i(clk, mac_start, mac_reset, mac_a, mac_b, mac_out, mac_ready);
    
    assign mac_a = mux_out;
    assign mac_b = ROM[cnt];
    assign yout = mac_out[OPSIZE*2-2:OPSIZE-1];
    
    parameter p_state_idle = 0;
    parameter p_state_oper = 1;
    logic[RANK:0] cnt = 0;
    logic mac_ready_delay = 0;
    logic state = p_state_idle;
    
    logic wr_xy = 0;
    //main always block
    always@(posedge clk) begin
    
        if(reset) begin
            wr_xy = 0;
            state = p_state_idle;
            ready = 1;
            mac_ready_delay = 0;
            mac_start = 0;
            mac_reset = 1;
            cnt = 0;
            //delays reset
            for(int i = 0; i < RANK+1; i++) begin
                x_n[i] = 0;
            end
            for(int i = 0; i < RANK; i++) begin
                y_n[i] = 0;
            end
        end
        else begin
            if(state == p_state_oper) begin
                mac_reset = 0;
                wr_xy = 0;
                if(cnt < RANK*2+1) begin
                    if(mac_ready) begin
                        mac_start = 1;
                     end
                     if(!mac_ready && mac_ready_delay) begin
                        cnt++;
                     end
                     mac_ready_delay = mac_ready;
                end else begin
                    mac_start = 0;
                    if(mac_ready) begin
                        ready = 1;
                        state = p_state_idle;
                        mac_ready_delay = 0;
                        cnt = 0;
                    end
                end
            end else begin
                mac_start = 0;
            end
            
            if(state == p_state_idle && start) begin
                state = p_state_oper;
                ready = 0;
                
                //yn shift
                for(int i = RANK-1; i > 0; i--) begin
                    y_n[i] = y_n[i-1];
                end
                y_n[0] = yout;
                
                //xn shift
                for(int i = RANK; i > 0; i--) begin
                    x_n[i] = x_n[i-1];
                end
                x_n[0] = xin;
                mac_reset = 1;
            end
        end
end

endmodule

module iir_test;
    parameter OPSIZE = 16;
    parameter RANK = 2;
    integer cnt = 0;
    logic clk = 0, reset = 0, ready, start = 0;
    logic[OPSIZE-1:0]xin, yout;
    logic[OPSIZE-1:0]y_out=0; 
    iir #(OPSIZE, RANK) uut(clk, start, reset, xin, yout, ready);
    
    always #1 clk = ~clk;
    
    initial begin
		$dumpfile("test.wcd");
		$dumpvars(0, iir_test);
        reset = 1;
        start = 0;
        xin = 0;
        #2
        reset = 0;
        xin = 16'h7FFF;
        start = 1;
        #2
        start = 0;
        xin = 0;
        while(1) begin
            #2
            if(ready) begin
                cnt++;
                start = 1;
                $display("%H\n", yout);
				y_out = yout;
                #2
                start = 0;
                xin = 0;
            end
            if(cnt == 10) begin
                $finish;
            end
        end
        $finish;
    end

endmodule
