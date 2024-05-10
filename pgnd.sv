module pgnd;
reg clk, write;
wire[7:0] w;
reg[7:0] bufa, bufb, a, b, c;
// assign w = bufa;
// assign w = bufb;
// assign bufa = write ? a : 8'bZ;
// assign bufb = write ? 8'bZ : b;
assign w = write ? a : 8'bZ;
assign w = write ? 8'bZ : b;
initial begin
    $dumpfile("dump_pgnd.vcd");
    $dumpvars(1, pgnd);
    write = 1;
    clk = 0;
    a = 0;
    b = 0;
    c = 0;
    @(posedge clk);
    write = 0;
    // b controls
    b = 3;
    $display("request for : %d, wire : %d", b, w);
    @(posedge clk);
    write = 1;
    // a controls
    a <= w*2;
    @(posedge clk);
    c = w;
    $display("listening answer : %d, wire: %d", c, w);
    @(posedge clk);
    write = 0;
    // b controls
    b = 5;
    #20 $finish;
end
always #2 clk = ~clk;
// always @(posedge clk) write = ~write;
// always @(posedge clk) write2 = ~write2;
endmodule
