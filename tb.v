`timescale 1ns / 1ps

module tb_cpu();

    reg         reset;
    reg         clk;
    reg [15:0]  instr;
    reg         ie;
    wire        ix;
    wire        wex;
    wire        rex;
    wire        r2x;
    wire [23:0] addr;
    reg [15:0]  rvx;
    wire [15:0] wvx;
    wire        jfx;
    wire [7:0]  jad;
    wire        jfl;
    wire        rfx;
    reg         jmf;
    reg [23:0]  pc;

    reg [7:0]   ram [0:32'hFFFF];
    reg [7:0]   rom [0:32'hFFFF];
    wire        ram_sel;
    wire [22:0] mem_addr;
    reg [7:0]   high_code;  // 0x080020
    reg         high_code_x;
    wire        rom_high;
    wire [21:0] rom_mad;
    reg  [15:0] sp; // 0x8C2000

    reg         mem_dbg = 1;
    reg         instr_dbg = 1;

    // 0xC20000 : sector to read/write
    // 0xC20002 : byte of sector to read/write
    // 0xC20004 : out/in byte
    // 0xC20005 : action
    reg [7:0]   fda [0:(512*16)-1];
    reg [15:0]  fda_sect;
    reg [15:0]  fda_bytn;
    reg [7:0]   fda_bio;

    assign      ram_sel =   addr[23];
    assign      mem_addr =  addr[22:0];
    assign      rom_high =  ram_sel == 0 & addr[22] == 1;
    assign      rom_mad =   ram_sel == 0 ? mem_addr[21:0] : 0;

    cpu uut (
        .reset  (reset),
        .clk    (clk),
        .instr  (instr),
        .ie     (ie),
        .ix     (ix),
        .wex    (wex),
        .rex    (rex),
        .addr   (addr),
        .rvx    (rvx),
        .wvx    (wvx),
        .r2x    (r2x),
        .jfx    (jfx),
        .jad    (jad),
        .jfl    (jfl),
        .rfx    (rfx)
    );

    always      #5 clk = ~clk;

    always @(posedge clk) begin
        if (reset) begin
            sp = 16'hBFD1;
            pc = 24'h00FFF0;
        end
    end

    function getInstrIn;
    input [23:0] pc;
    begin
        if (pc[23]) getInstrIn = {ram[pc[22:0]], ram[pc[22:0]+1]};
        else getInstrIn = {rom[pc], rom[pc+1]};
    end
    endfunction

    task pushInStack;
    input [15:0] data;
    begin
        ram[sp] = data[15:8];
        ram[sp+1] = data[7:0];
        sp = sp - 2;
    end
    endtask

    task popOfStack;
    output [15:0] data;
    begin
        sp = sp + 2;
        data = {ram[sp], ram[sp+1]};
    end
    endtask

    always @(negedge clk) begin
        if (!jmf & ix) begin
            if (instr_dbg) $display("%h INS_TRS %h", pc, instr);
        end

        if (pc[23]) instr = {ram[pc[22:0]], ram[pc[22:0]+1]};
        else instr = {rom[pc], rom[pc+1]};
        ie = 1;

        if (jmf) begin
            jmf = 0;
        end

        if (!ix) begin
            if (wex) begin                
                if (mem_dbg) $display("%h WEX_SIG%0d addr=%h val=%h", pc, ram_sel, mem_addr, wvx);
                if (rom_high & ram_sel == 0) begin
                    if (rom_mad == 22'h20) begin
                        high_code = wvx[7:0];
                        high_code_x = 1;
                    end // high code pos
                end

                if (ram_sel) begin
                    if (mem_addr == 23'h420000)
                        fda_sect = wvx;
                    else if (mem_addr == 23'h420002)
                        fda_bytn = wvx;
                    else if (mem_addr == 23'h420004) begin
                        fda[(fda_sect * 512) + fda_bytn] = wvx[7:0];
                    end
                    else begin
                        if (r2x) begin
                            ram[mem_addr+0] = wvx[15:8];
                            ram[mem_addr+1] = wvx[7:0];
                        end
                        else begin
                            ram[mem_addr] = wvx[7:0];
                        end
                    end
                end
                else if (!rom_high) begin
                    if (mem_dbg) $display("WEX0_SIG you cannot write in ROM");
                end
            end
            else if (rex) begin
                if (jfl) begin
                end

                if (mem_dbg) $display("%h REX_SIG%0d addr=%h",pc ,ram_sel, mem_addr);
                if (ram_sel) begin
                    if (mem_addr == 23'h420004) begin
                        rvx = {8'h00, fda[(fda_sect * 512) + fda_bytn]};
                    end
                    else begin
                        if (r2x) rvx = {ram[mem_addr], ram[mem_addr + 1]};
                        else rvx = {8'h0, ram[mem_addr]};
                    end
                end
                else begin
                    if (r2x) rvx = {rom[mem_addr], rom[mem_addr + 1]};
                    else rvx = {8'h0, rom[mem_addr]};
                end
            end
        end

        if (ix) begin
            if (rfx) begin
                if (instr_dbg) $display("%h RET sp=%h", pc, sp);

                popOfStack(pc[15:0]);
            end
            else if (jfx) begin
                if (jfl) begin
                    if (instr_dbg) $display("%h CALL %h", pc, sp);
                    pushInStack(pc[15:0]);
                end
                if (high_code_x) begin
                    if (instr_dbg) $display("%h JMP_FAR %0x", pc, high_code);
                    high_code_x = 0;
                    pc = {high_code , 8'h0, jad};
                    if (pc[23]) instr = {ram[pc[22:0]], ram[pc[22:0]+1]};
                    else instr = {rom[pc], rom[pc+1]};
                end
                else begin
                    jmf = 1;
                    if (jad[7]) begin
                        if (instr_dbg) $display("%h JMP_SIG step -%0d steps", pc, jad[6:0]);
                        pc = pc - (jad[6:0] + 2);
                    end
                    else begin
                        if (instr_dbg) $display("%h JMP_SIG step +%0d steps", pc, jad[7:0]);
                        pc = (pc + jad) - 2;
                    end
                end
            end
            else begin
                pc = pc + 2;
            end
        end
    end

    initial begin
        clk = 0;
        reset = 1;
        ie = 0;
        pc = 0;
        rvx = 16'h0000;
        jmf = 0;
        $readmemh("test.hex", rom);
        $readmemh("test.hex", ram);

        instr = {rom[pc], rom[pc+1]};
        ie = 1;

        #20 reset = 0;
    
        #700 $finish;
    end

endmodule