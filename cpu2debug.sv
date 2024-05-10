module debugcpu(clk, A1, D1, C1, DUMP);
input clk;
output [ADDR2_BUS_SIZE-1:0] A1;
inout [DATA2_BUS_SIZE-1:0] D1;
inout [CTR2_BUS_SIZE-1:0] C1;
output DUMP;
reg [ADDR2_BUS_SIZE-1:0] a1;
reg [DATA2_BUS_SIZE-1:0] d1out;
reg [CTR2_BUS_SIZE-1:0] c1out;
reg write1, dump;
assign A1 = a1;
assign D1 = write1 ? d1out : 16'bZ;
assign C1 = write1 ? c1out : 16'bZ;
assign DUMP = dump;
int i = 0;

initial begin
    write1 = 1;
    @(posedge clk);
    write1 = 1;
    // @(posedge clk);
    a1 = 0;
    c1out = C2_WRITE_LINE;    
    for(i = 0; i < 8; i+=1) begin
        @(posedge clk);
        write1 = 1;
        d1out = ((i*2)<<8) + (i*2+1);    
        $display("time : %t", $time);
        $display("CPU debug: send : %h", d1out);
        // @(negedge clk);
    end
    $display("end of request");
    @(posedge clk);
    write1 = 1;
    dump = 1;
    @(posedge clk);
    dump = 0;
end
// DEBUG for READ_LINE:
// initial begin
//     write1 = 1;
//     @(posedge clk);
//     write1 = 1;
//     // @(posedge clk);
//     a1 = 0;
//     c1out = C2_READ_LINE;    
//     for(i = 0; i < 8; i+=1) begin
//         @(posedge clk);
//         write1 = 0;
//         // $display("time : %t", $time);
//         @(negedge clk);
//         // $display("got : %h", D1);
//     end
//     $display("end of response");
// end

// debug for WRITE_LINE
endmodule