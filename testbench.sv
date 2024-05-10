`include "cpu2debug.sv"
`include "cache.sv"
`include "ram.sv"
enum{ADDR1_BUS_SIZE = 15} a1s;
enum{ADDR2_BUS_SIZE = 15} a2s;
enum{DATA1_BUS_SIZE = 16} b1ds;
enum{DATA2_BUS_SIZE = 16} b2ds;
enum{CTR1_BUS_SIZE = 4} cbs1;
enum{CTR2_BUS_SIZE = 4} cbs2;
enum{CACHE_LINE_SIZE = 32} cls;
enum{CACHE_SIZE = 1024} cs;
enum{CACHE_SETS_COUNT = 16} csc;
enum{CACHE_LINE_COUNT = 32} clc;
enum{CACHE_TAG_SIZE = 11} cts;
enum{CACHE_SET_SIZE = 4} css;
enum{CACHE_OFFSET_SIZE = 5} cofs;
enum{MEM_SIZE = 1048576} cs2;
enum{C1_NOP, C1_READ8, C1_READ16, C1_READ32, C1_INVALIDATE_LINE, C1_WRITE8, C1_WRITE16, C1_WRITE32} cmd;
enum{C2_NOP, C2_RESPONSE, C2_READ_LINE, C2_WRITE_LINE} cacheMemCmd; 
enum{C1_RESPONSE = 7} cache2cpu; 

module testbench;
    wire[ADDR1_BUS_SIZE-1:0] a1;
    wire[DATA1_BUS_SIZE-1:0] d1;
    wire[CTR1_BUS_SIZE-1:0] c1;
    wire[ADDR2_BUS_SIZE-1:0] a2;
    wire[DATA2_BUS_SIZE-1:0] d2;
    wire[CTR2_BUS_SIZE-1:0] c2;
    reg clk, c_dump, reset;
    wire m_dump;
    cpu cpu1(clk, a1, d1, c1, m_dump);
    chache chache1(clk, a1, d1, c1, a2, d2, c2, c_dump, reset);
    ram mem(clk, a2, d2, c2, m_dump, reset);
    
    initial begin 
        $dumpfile("dump_tb.vcd");
        $dumpvars(1, cpu1, testbench);
        $dumpvars(1, chache1);
        $dumpvars(1, mem);
        clk = 0;
        reset = 0;
        // m_dump = 0;
        c_dump = 0;
        
        // #2372193;
        // read8(0, t1);
        // m_dump = 1;
        // #1;
        // m_dump = 0;
        // #200;
        // $finish;
    end
    always #1 clk = ~clk;
endmodule

module cpu(clk, A1, D1, C1, M_dump);
input clk;
output [ADDR1_BUS_SIZE-1:0] A1;
inout [DATA1_BUS_SIZE-1:0] D1;
inout [CTR1_BUS_SIZE-1:0] C1;
output M_dump;
reg [ADDR1_BUS_SIZE-1:0] a1;
reg [DATA1_BUS_SIZE-1:0] d1out;
reg [CTR1_BUS_SIZE-1:0] c1out;
reg write1;
assign A1 = a1;
assign D1 = write1 ? d1out : 16'bZ;
assign C1 = write1 ? c1out : 16'bZ;
integer addr;
int i = 0;
int pa, pb, pc, N, M, K, x, y, k;
int cnt;
reg m_dump;
assign M_dump = m_dump;
reg[31:0] s;
int t1, t2;
reg[CACHE_TAG_SIZE-1:0] tag;
reg[CACHE_SET_SIZE-1:0] set;
reg[CACHE_OFFSET_SIZE-1:0] offset;
initial begin
    // addr_decodeing(0, tag, set, offset);
    // readany(C1_READ8, 0, t1);
    // $display("t1 :%h", t1);  
    // write8(0, 8);
    
    // addr_decodeing((1<<9), tag, set, offset);
    // readany(C1_READ8, (1<<9), t1);
    // $display("t1 :%h", t1);
    
    // addr_decodeing((1<<10), tag, set, offset);
    // readany(C1_READ8, (1<<10), t1);
    // $display("t1 :%h", t1);

    // write8(0, 4);
    

    // m_dump = 0;
    // @(posedge clk);
    // m_dump = 1;
    // @(posedge clk);
    // m_dump = 0;

    // readany(C1_READ32, 1, t1);
    // write32(1, 1);
    // $display("t1 :%h", t1);
    // mull();
    write32(0, 1);
    write32((1<<9), 2);
    write32((1<<10), 3);
    read32(0, t1);
    $display("t1 ; %h", t1);
    // write32((1<<10), 7);
    @(posedge clk);
    @(posedge clk);
    m_dump = 1;
    @(posedge clk);
    m_dump = 0;



    #20;
    $finish;
end

task mull();
    cnt = 0;
    M = 64;
    N = 60;
    K = 32; 
    pa = 0;
    pc = M*N+K*N*2;
//     reg[CACHE_TAG_SIZE-1:0] tag;
// reg[CACHE_SET_SIZE-1:0] set;
// reg[CACHE_OFFSET_SIZE-1:0] offset;
    for(y = 0; y < M; y+=1) begin 
        for(x = 0; x < N; x+=1) begin 
            pb = M*N;
            s = 0;
            for(k = 0; k < K; k+=1) begin 
                read8(pa+k, t1);
                read16(pb+x*2, t2);
                s += t1*t2;
                cnt+=2;
            end
            addr_decodeing(pc+x*4, tag, set, offset);
            // if(set == 0)
            //     $display("DEBUG: y %h, x %h", y, x);
            // $display("deocd: %h %h %h", tag, set, offset);
            write32(pc+x*4, s);
            cnt+=1;
        end
        pa +=K;
        pc +=N*4;
    end    
    $display("cnt of all : %d", cnt);
    $display("time: %t", $time);
endtask

task addr_decodeing(input int addr, output reg[CACHE_TAG_SIZE-1:0] tag, output reg[CACHE_SET_SIZE-1:0] set, output reg[CACHE_OFFSET_SIZE-1:0] offset);
    offset = addr;
    set = (addr>>CACHE_OFFSET_SIZE);
    tag = (addr>>(CACHE_OFFSET_SIZE + CACHE_SET_SIZE));
    // $display("CPU : adr : %b", addr);
    // $display("CPU : tag : %b, set: %b, offset: %b", tag, set, offset);
endtask

task invalidate_line(input int addr);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : INVALIDATE %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_INVALIDATE_LINE;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
    @(posedge clk);
    @(negedge clk);
    end
    // $display("CPU : invalidating done\n");
endtask

task readany(input int cmd,input int addr, output int ans);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : READ32 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = cmd;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
        @(posedge clk);
        @(negedge clk);
    end
    // $display("CPU : RESIEVED : %h", D1);
    ans = D1;
    if(cmd == C1_READ32) begin 
        @(posedge clk);
        @(negedge clk);
        ans = ans + (D1<<16);
    end
endtask




task read8(input int addr, output int ans);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : READ8 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_READ8;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
    @(posedge clk);
    @(negedge clk);
    end
    ans = D1;
    // $display("CPU : RESIEVED : %h", D1);
    // $display("end of request\n");
endtask

task read16(input int addr, output int ans);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : READ16 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_READ16;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
    @(posedge clk);
    @(negedge clk);
    end
    ans = D1;
    // $display("CPU : RESIEVED : %h", D1);
    // $display("end of request\n");
endtask

task read32(input int addr, output int ans);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : READ32 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_READ32;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
        @(posedge clk);
        @(negedge clk);
    end
    // $display("CPU : RESIEVED : %h", D1);
    ans = D1;
    @(posedge clk);
    @(negedge clk);
    ans = ans + (D1<<16);
    // $display("CPU : RESIEVED : %h", D1);
    // $display("end of request\n");
endtask

task write8(int addr, int data);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : write8 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_WRITE8;
    d1out = data;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
        @(posedge clk);
        @(negedge clk);
    end
    // $display("end of request\n");
endtask


task write16(int addr, int data);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : write16 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_WRITE16;
    d1out = data;
    @(posedge clk);
    a1 = addr;    // offset
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
        @(posedge clk);
        @(negedge clk);
    end
    // $display("end of request\n");
endtask

task write32(int addr, reg[31:0] data);
    write1 = 1;
    @(posedge clk);
    // $display("CPU : write16 %d", addr);
    a1 = (addr>>CACHE_OFFSET_SIZE);     // tag and set
    c1out = C1_WRITE32;
    d1out = data[0 +: 16];
    @(posedge clk);
    a1 = addr;    // offset
    d1out = data[16 +: 16];
    @(posedge clk);
    write1 = 0;
    @(negedge clk);
    while(C1 == C1_NOP) begin 
        @(posedge clk);
        @(negedge clk);
    end
    // $display("end of request\n");
endtask


endmodule