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
int i;
int tagNset, offset, tag, adr;
reg[CACHE_LINE_SIZE*8-1:0] cache_line;
// int cache_line;
reg[CACHE_SET_SIZE] set;

// reg [ADDR1_BUS_SIZE-1:0] a1out;
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


initial begin
    for(i = 0; i < CACHE_LINE_COUNT; i+=1) begin
        lastUsedInBlock[i] = 0;
        v[i] = 0;
    end
    write1 = 0;
    write2 = 1;
    while (1) begin
        @(posedge clk);
        write1 = 0;
        write2 = 1;
        
        case (C1)
            C1_NOP : $display("RAM: doing nothing");
            C1_READ8 : begin
                tagNset = A1;
                @(posedge clk);
                @(negedge clk);
                offset = A1;
                tag = tagNset >> CACHE_SET_SIZE;
                set = tagNset;
                adr <= (tagNset << CACHE_OFFSET_SIZE) + offset; 

                if ( !(v[(set<<1)] && tags[(set<<1)] == tag) && !(v[(set<<1)+1] && tags[(set<<1)+1] == tag) ) begin // если данных нет в кэше
                    //чтение из памяти
                    @(posedge clk);
                    write1 = 1;
                    write2 = 1;
                    c1out = C1_NOP;
                    c2out = C2_READ_LINE;
                    a2out <= adr>>CACHE_OFFSET_SIZE;
                    cache_line = 0;
                    // @(posedge clk);
                    for (i = 0; i < 8; i+=1) begin   //TODO : проверить что я правильно читаю кэш линию и правлильно потом беру из нее байт
                        @(posedge clk);
                        write2 = 0;
                        write1 = 1;
                        c1out = C1_NOP;
                        $display("%t CACHE : my line: %h", $time,  cache_line); 
                        @(negedge clk);     //TODO: зачем здесь negedge?
                        // cache_line = (cache_line<<16) + D2;
                        cache_line[i*16 +: 16] = D2;
                        $display("%t CACHE got: d: %h, my line: %h", $time, D2, cache_line);    
                    end
                    $display("here what i got: %h", cache_line);
                    // запись в кэш
                    // поискать invalid линию
                    if(!v[(set<<1)]) begin
                        v[(set<<1)] = 1;
                        // TODO обновить время
                        d[(set<<1)] = 0;
                        tags[(set<<1)] = tag;
                        mem[(set<<1)] <= cache_line;
                    end else if(!v[(set<<1)+1]) begin
                        v[(set<<1)+1] = 1;
                        // TODO обновить время
                        d[(set<<1)+1] = 0;
                        tags[(set<<1)+1] = tag;
                        mem[(set<<1)+1] <= cache_line;
                    end else begin
                        // не нашли инвалид линию => lru
                        if(lastUsedInBlock[(set<<1)]) begin
                            v[(set<<1)] = 1;
                            // TODO обновить время
                            d[(set<<1)] = 0;
                            tags[(set<<1)] = tag;
                            mem[(set<<1)] <= cache_line;
                        end else begin
                            v[(set<<1)+1] = 1;
                            // TODO обновить время
                            d[(set<<1)+1] = 0;
                            tags[(set<<1)+1] = tag;
                            mem[(set<<1)+1] <= cache_line;
                        end 
                    end
                end
                
                // возвращаем данные
                @(posedge clk);
                write1 = 1;
                write2 = 0;
                $display("pLEASE LISTEN ITS RESONSE %h %t", C1_RESPONSE, $time);
                c1out = C1_RESPONSE;
                c2out = C2_NOP;
                if(v[(set<<1)] && tags[(set<<1)] == tag)begin
                    //вывести линию, TODO:обновить бит последнего использования
                    d1out <= mem[(set<<1)];
                    // $display("try to send back part of %h", (mem[(set<<1)]));
                end else if (v[(set<<1)+1] && tags[(set<<1)+1] == tag) begin
                    //вывести линию, TODO:обновить бит последнего использования
                    d1out <= mem[(set<<1)+1];
                    // $display("try to send back part of %h", (mem[(set<<1)+1]));
                end else
                    $display("ERROR IN CHACHE");
                
            end
            // default : $display("CACHE: doing default nothing");
        endcase
    end
end

endmodule