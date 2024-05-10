module ram #(parameter _SEED = 225526)(clk, A2, D2, C2, M_DUMP, RESET);
input clk;
input [ADDR2_BUS_SIZE-1:0] A2;
inout [DATA2_BUS_SIZE-1:0] D2;
inout [CTR2_BUS_SIZE-1:0] C2;
input M_DUMP, RESET;
integer SEED = _SEED;
reg[7:0] mem[0:MEM_SIZE-1];
integer i = 0;
int adr;
reg[DATA2_BUS_SIZE-1:0] cache_line = 0;
reg write2;

reg [DATA2_BUS_SIZE-1:0] d2out;
reg [CTR2_BUS_SIZE-1:0] c2out;
assign D2 = write2 ? d2out : 16'bZ;
assign C2 = write2 ? c2out : 16'bZ;

integer fd;
initial begin
    write2 = 0;
    for (i = 0; i < MEM_SIZE; i += 1) begin
        mem[i] = $random(SEED)>>16;
    end
    fd = $fopen("meminit", "w");
    for (i = 0; i < (MEM_SIZE/CACHE_LINE_SIZE); i += 1) begin
        $fdisplay(fd, "%h", mem[i]);
    end
    $fclose(fd);

    // for (i = 0; i < (MEM_SIZE/CACHE_LINE_SIZE); i += 1) begin
    //     $display("%d", mem[i]);
    // end
    // $display("[%d] %h", 173, mem[173]);
    // $display("[%d] %h", 172, mem[172]);
    $display("memory init done");


    while (1) begin

        if(M_DUMP) begin 
            // fd = $fopen("memend", "w");
            // for (i = 0; i < (MEM_SIZE/CACHE_LINE_SIZE); i += 1) begin
            //     $fdisplay(fd, "%d", mem[i]);
            // end
            // $fclose(fd);
            for (i = 0; i < 32; i += 1) begin
                $display("RAM [%d]: %h",i, mem[i]);
                if(mem[i] == 8'd?)
                    $display("CRINGE");
            end     
            // $finish;
        end
        // write2 = 0;
        @(posedge clk);
        write2 = 0;
        d2out = 0;
        @(negedge clk);

        // c2out = C2_NOP;
        case (C2)
            C2_NOP : begin
                // @(posedge clk);
                // $display("RAM: doing nothing %t", $time);
            end//$display("RAM: doing nothing");
            C2_READ_LINE : begin
                // $display("RAM: GOT IT !!!! %t", $time);
                adr = A2 << CACHE_OFFSET_SIZE;
                for(i = 0; i < 10; i+=1) begin 
                    @(posedge clk);
                    write2 = 1;
                    c2out = C2_NOP;
                
                end
                for (i = 0; i < CACHE_LINE_SIZE/2; i += 1) begin
                    @(posedge clk);
                    write2 = 1;
                    d2out = (mem[adr+i*2] ) + (mem[adr+i*2+1] << 8);
                    c2out = C2_RESPONSE;
                end 
                $display("AAAA %t", $time);
                @(negedge clk);
            end
            C2_WRITE_LINE : begin
                $display("RAM: GOT IT !!!! %t", $time);
                adr = A2 << CACHE_OFFSET_SIZE;
                // if(adr == 0)
                    $display("RAM: DEBUG: invalidation? adr : %d %t", adr, $time);

                for (i = CACHE_LINE_SIZE/2; i >= 0; i -= 1) begin
                    @(posedge clk);
                    write2 = 0;
                    @(negedge clk);
                    mem[adr+i*2] = D2;
                    mem[adr+i*2+1] = D2>>8;
                end
                for(i = 0; i < 10; i+=1) begin 
                    @(posedge clk);
                    write2 = 1;
                    c2out = C2_NOP;
                end
                @(posedge clk);
                write2 = 1;
                c2out = C2_RESPONSE;
                @(negedge clk);
                     
            end
            // default : $display("RAM: AAAA %t", $time);
            default : begin
                // @(posedge clk);
            end /*c2out = C2_NOP;*/ //$display("RAM: doing default nothing");
        endcase
    end
end

endmodule


