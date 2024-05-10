module chache(clk, A1, D1, C1, A2, D2, C2, C_DUMP, RESET);
input clk;
input [ADDR1_BUS_SIZE-1:0] A1;
inout [DATA1_BUS_SIZE-1:0] D1;
inout [CTR1_BUS_SIZE-1:0] C1;
output [ADDR2_BUS_SIZE-1:0] A2;
inout [DATA2_BUS_SIZE-1:0] D2;
inout [CTR2_BUS_SIZE-1:0] C2;
input C_DUMP, RESET;
reg write1, write2;
reg[CACHE_LINE_SIZE*8-1 : 0] mem [0:CACHE_LINE_COUNT-1];
reg[CACHE_TAG_SIZE-1 : 0] tags [0:CACHE_LINE_COUNT-1];
reg[1 : 0] lastUsedInBlock [0:CACHE_LINE_COUNT-1];
reg[1 : 0] v [0:CACHE_LINE_COUNT-1];
reg[1 : 0] d [0:CACHE_LINE_COUNT-1];
int i, flag, adr;
// int tagNset, offset, tag, adr;

reg[CACHE_TAG_SIZE-1:0] tag;
reg[CACHE_SET_SIZE-1:0] set;
reg[CACHE_OFFSET_SIZE-1:0] offset;
reg[CACHE_TAG_SIZE+CACHE_SET_SIZE-1:0] tagNset;

reg[CACHE_LINE_SIZE*8-1:0] cache_line, cache_line2;
reg[DATA1_BUS_SIZE-1:0] data, data2;


reg [DATA1_BUS_SIZE-1:0] d1out;
reg [CTR1_BUS_SIZE-1:0] c1out;
reg [ADDR2_BUS_SIZE-1:0] a2out;
reg [DATA2_BUS_SIZE-1:0] d2out;
reg [CTR2_BUS_SIZE-1:0] c2out;
assign A2 = a2out;
assign D1 = write1 ? d1out : 16'bZ;
assign C1 = write1 ? c1out : 16'bZ;
assign D2 = write2 ? d2out : 16'bZ;
assign C2 = write2 ? c2out : 16'bZ;

int cellCashAdr;

int cacheloosecnt;

initial begin
    cacheloosecnt = 0;
    for(i = 0; i < CACHE_LINE_COUNT; i+=1) begin
        lastUsedInBlock[i] = 0;
        v[i] = 0;
    end
    write1 = 0;
    write2 = 1;
    while (1) begin
        d2out = 0;
        @(posedge clk);
        write1 = 0;
        write2 = 1;
        @(negedge clk);
        case (C1)
            C1_NOP : $display("CACHE: doing nothing");
            C1_READ8 : begin
                addrDecode();
                updCacheLine();
                // возвращаем данные
                setupResponse();
                d1out = cache_line[offset*8 +: 8];
                // $display("CACHE: send %h %b", cache_line[offset*8 +: 8], offset);
            
            end
            C1_READ16 : begin
                addrDecode();
                updCacheLine();
                // возвращаем данные
                setupResponse();
                d1out = cache_line[offset*8 +: 16];
                // $display("CACHE: send %h %b", cache_line[offset*8 +: 16], offset);
            end
            C1_READ32 : begin
                addrDecode();
                updCacheLine();
                // возвращаем данные
                setupResponse();
                d1out = cache_line[offset*8 +: 16];
                // $display("CACHE: send %h %b", cache_line[offset*8 +: 16], offset);
                
                setupResponse();
                d1out = cache_line[offset*8+16 +: 16];
                // $display("CACHE: send %h %b", cache_line[offset*8+16 +: 16], offset);
            end

            // C1_INVALIDATE_LINE : begin
            //     addrDecode();
            //     // updCacheLine();
            //     if ( (v[(set<<1)] && tags[(set<<1)] == tag) || (v[(set<<1)+1] && tags[(set<<1)+1] == tag) ) begin // если данные есть в кэше
            //         findCacheAddr();
            //         v[cellCashAdr] = 0;
            //         if (d[cellCashAdr]) begin
            //             // $display("CACHE : I'll upadate mem data");
            //             @(posedge clk);
            //             write1 = 1;
            //             c1out = C1_NOP;
            //             write2 = 1;
            //             c2out = C2_WRITE_LINE;
            //             a2out <= tagNset;

            //             // нужно подождать, пока ram ищет и собирает данные
            //             @(negedge clk);
            //             while(C2 != C2_RESPONSE) begin
            //                 @(posedge clk);
            //                 write2 = 0;
            //                 write1 = 1;
            //                 c1out = C1_NOP;
            //                 @(negedge clk);
            //             end
                    
            //         end    
            //     end
            //     setupResponse();
            // end

            C1_WRITE8 : begin
                data = D1;
                addrDecode();
                updCacheLine();
                mem[cellCashAdr][offset*8 +: 8] = data[0 +: 8];
                d[cellCashAdr] = 1;
                // $display("CACHE: пытаюсь записать %h", data[0 +: 8]);
                setupResponse();
            end

            C1_WRITE16 : begin
                data = D1;
                addrDecode();
                updCacheLine();
                mem[cellCashAdr][offset*8 +: 16] = data[0 +: 16];
                d[cellCashAdr] = 1;
                // $display("CACHE: пытаюсь записать %h", data[0 +: 16]);
                setupResponse();
            end
            
            C1_WRITE32 : begin
                data = D1;
                addrDecode();
                data2 = D1;
                updCacheLine();
                $display("ABABAB %t", $time);
                mem[cellCashAdr][offset*8 +: 16] = data[0 +: 16];
                mem[cellCashAdr][offset*8+16 +: 16] = data2[0 +: 16];
                d[cellCashAdr] = 1;
                // $display("CACHE: пытаюсь записать %h %h", data, data2);
                setupResponse();
            end
            // default : $display("CACHE: doing default nothing");
        endcase
    end
end

task line_invalidation(int tagNsetfun);
    @(posedge clk);
    $display("invalidation START %t", $time);
    write1 = 1;
    c1out = C1_NOP;
    write2 = 1;
    c2out = C2_WRITE_LINE;
    a2out = tagNsetfun;
    cache_line2 = mem[cellCashAdr];
    @(posedge clk);
    for (i = (CACHE_LINE_SIZE/2)-1; i >= 0; i -= 1) begin
        @(posedge clk);
        write2 = 1;
        d2out = (cache_line2[i*2*8 +: 8] ) + (cache_line2[i*2*8+8 +: 8] << 8);
        $display("%t RAM: DEBUG send %h", $time, d2out);
    end 
    $display("AAAA %t", $time);
    
    @(posedge clk);
    write2 = 0;
    write1 = 1;
    c1out = C1_NOP;
    @(negedge clk);
    while(C2 != C2_RESPONSE) begin
        @(posedge clk);
        @(negedge clk);
    end
    
    $display("invalidation end %t", $time);
endtask

task getData();
    // $display("CACHE : I'll read data!");
    //чтение из памяти
    @(posedge clk);
    write1 = 1;
    c1out = C1_NOP;
    write2 = 1;
    c2out = C2_READ_LINE;
    a2out <= tagNset;
    $display("DEBUG: RED %t", $time);
    // нужно подождать, пока ram ищет и собирает данные
    @(posedge clk);
    write2 = 0;
    @(negedge clk);
    while(C2 != C2_RESPONSE) begin
        @(posedge clk);
        write2 = 0;
        write1 = 1;
        c1out = C1_NOP;
        @(negedge clk);
    end
    // ПОЛУЧЕНИЕ ДАННЫХ
    for (i = 0; i < CACHE_LINE_SIZE/2; i+=1) begin   
        if(i > 0) begin
            @(posedge clk);
            write2 = 0;
            write1 = 1;
            c1out = C1_NOP; 
            @(negedge clk);
        end
        // $display("CAUGHT %h %d %t", i,CACHE_LINE_SIZE/2, $time);     
        cache_line[i*16 +: 16] = D2;
    end
    // write2 = 1;
    // c2out = 0;
    $display("CCCCCIII %t", $time);
    // записать в кэш полученную линию
    if(!v[(set<<1)]) begin
        cellCashAdr = (set<<1);
    end else if(!v[(set<<1)+1]) begin
        cellCashAdr = (set<<1)+1;
    end else begin
        // не нашли инвалид линию => lru
        if(lastUsedInBlock[(set<<1)]) begin
            cellCashAdr = (set<<1)+1;
        end else begin
            cellCashAdr = (set<<1);
        end 
    end
    if(d[cellCashAdr]) begin 
        // $display("DEBUG: BLUE %t", $time);

        // $display("RAM: DEBUG tagset %h", ?tag[cellCashAdr]);
        line_invalidation( (tags[cellCashAdr] << CACHE_SET_SIZE) + (cellCashAdr>>1) );  //TODO add set number);
        cacheloosecnt+=1; 
        // $display("CACHE LOOSES CNT: %d", cacheloosecnt);
    end
    
    v[cellCashAdr] = 1;
    d[cellCashAdr] = 0;
    tags[cellCashAdr] = tag;
    mem[cellCashAdr] = cache_line;

endtask

task findCacheAddr();
    if (v[(set<<1)] && tags[(set<<1)] == tag) begin
        cellCashAdr = (set<<1);
    end else begin 
        cellCashAdr = (set<<1) + 1; 
    end
    lastUsedInBlock[(set<<1)] = 0;
    lastUsedInBlock[(set<<1)+1] = 0;
    lastUsedInBlock[cellCashAdr] = 1;
    cache_line = mem[cellCashAdr];
endtask


task addrDecode();
    tagNset = A1;
    @(posedge clk);
    @(negedge clk);
    offset = A1[0 +: CACHE_OFFSET_SIZE];
    tag = tagNset >> CACHE_SET_SIZE;
    $display("DEBUG:  __tag: %h", tag);
    set = tagNset;
    adr <= (tagNset << CACHE_OFFSET_SIZE) + offset;
    // $display("CACHE : tag : %b, set: %b, offset: %b", tag, set, offset);
endtask

task updCacheLine();
    // addrDecode();
    if ( !(v[(set<<1)] && tags[(set<<1)] == tag) && !(v[(set<<1)+1] && tags[(set<<1)+1] == tag) ) begin // если данных нет в кэше
        cacheloosecnt+=1;
        getData();
        // $display("CACHE LOOSES CNT: %d", cacheloosecnt);
    end
    findCacheAddr();
endtask

task setupResponse();
    @(posedge clk);
    write2 = 1;
    write1 = 1;
    c1out = C1_RESPONSE;
    c2out = C2_NOP;
endtask

endmodule