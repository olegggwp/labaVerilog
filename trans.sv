enum{ADDR_SIZE = 5} as;
enum{DATA1_BUS_SIZE = 16} bds;
enum{CTR1_BUS_SIZE = 4} cbs;
enum{CACHE_SIZE = 1024} cs;
enum{CACHE_LINE_SIZE = 32} cls;
enum{C1_NOP, C1_READ8, C1_READ16, C1_READ32, C1_INVALIDATE_LINE, C1_WRITE8, C1_WRITE16, C1_WRITE32} cmd;
enum{C1_RESPONSE = 1} cache2cpu; 


module trans;
    wire[ADDR_SIZE-1:0] a1;
    wire[DATA1_BUS_SIZE-1:0] d1;
    wire[CTR1_BUS_SIZE-1:0] c1;
    reg clk;
    a cpu(a1, d1, c1, clk);
    b mem(a1, d1, c1, clk);
    initial begin 
        $dumpfile("dump_trans.vcd");
        $dumpvars(1, cpu);
        $dumpvars(1, mem);
        clk = 0;
        #20;
        $finish;
    end
    always #1 clk = ~clk;
endmodule

module a(a1, d1, c1, clk);
    output[ADDR_SIZE-1:0] a1;
    inout[DATA1_BUS_SIZE-1:0] d1;
    inout[CTR1_BUS_SIZE-1:0] c1;
    input clk;
    reg[ADDR_SIZE-1:0] a1out;
    reg[DATA1_BUS_SIZE-1:0] d1out;
    reg[CTR1_BUS_SIZE-1:0] c1out;
    reg write;
    assign d1 = write ? d1out : 8'bZ;
    assign c1 = write ? c1out : 8'bZ;
    assign a1 = a1out;
    
    initial begin
        write = 1;
        @(posedge clk);
        $display("A: send request");
        a1out = 0;
        c1out = C1_READ8;
        @(posedge clk);
        write = 0;
        @(negedge clk);
        $display("A: got answer: w %b", d1);
    end
endmodule
//lala

module b(a1, d1, c1, clk);
    input[ADDR_SIZE-1:0] a1;
    inout[DATA1_BUS_SIZE-1:0] d1;
    inout[CTR1_BUS_SIZE-1:0] c1;
    input clk;
    int adr;
    reg[DATA1_BUS_SIZE-1:0] d1out;
    reg[CTR1_BUS_SIZE-1:0] c1out;
    reg[CACHE_SIZE*8-1:0] mem;
    reg write;
    assign d1 = write ? d1out : 8'bZ;
    assign c1 = write ? c1out : 8'bZ;
    integer i = 0;
    
    initial begin
        write = 0;
        mem = 0;
        for (i = 0; i < CACHE_SIZE*8; i++) begin
            mem[i] = 1;
        end
        while (1) begin
            @(posedge clk);
            @(negedge clk);
            write = 0;
            $display("B(cache): listening request");
            case (c1)
                C1_NOP : $display("B(cache): doing nothing");
                C1_READ8 : begin
                    adr = a1;
                    @(posedge clk);
                    write = 1;
                    
                    d1out = mem[adr*8 +: 8];
                    c1out = C1_RESPONSE;
                    $display("B(cache): i want return %b", mem[adr*8 +: 8]);
                end
                default : $display("B(cache): doing default nothing");
            endcase
        end
        @(posedge clk);
    end
endmodule