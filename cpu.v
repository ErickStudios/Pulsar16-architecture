module cpu(
    input              reset,     // reset
    input              clk,       // clock
    input       [15:0] instr,     // instruction
    input              ie,        // instruction enable
    output reg         ix,        // instruction executed
    output reg         wex,       // cuando requiere escribir
    output reg         rex,       // cuando requiere leer
    output reg  [23:0] addr,      // dirección solicitada
    input       [15:0] rvx,       // valor leído de memoria
    output reg  [15:0] wvx,       // valor a escribir en memoria
    output reg         r2x,       // si van a ser 16 bits
    output reg         jfx,       // cuando hace jmp
    output reg  [7:0]  jad,       // jump address
    output reg         jfl,       // cuando un jmp activo la bandera de enlace
    output reg         rfx        // cuando retorna
);

reg [7:0]   ar;
reg [7:0]   br;
reg [7:0]   cr;
reg [7:0]   dr;
reg [7:0]   er;
reg [7:0]   fr;
reg [7:0]   gr;
reg [7:0]   hr;
reg [7:0]   ir;
reg [7:0]   jr;
reg [7:0]   kr;
reg [7:0]   cmpr;
reg [15:0]  cmpr16;
reg [7:0]   flags;
reg [15:0]  tmp16;
reg [15:0]  tmp216;

wire [15:0] bc;
wire [15:0] fg;
wire [15:0] hi;
wire [15:0] jk;

assign bc = {br, cr};
assign fg = {fr, gr};
assign hi = {hr, ir};
assign jk = {jr, kr};

// Estados de la CPU (para manejar operaciones de memoria con handshake)
parameter IDLE        = 4'd0;
parameter MEM_READ    = 4'd1;
parameter MEM_WRITE   = 4'd2;
parameter CMP_CALC    = 4'd3;

reg condition_met;
reg [3:0] state;

// Helper para obtener registros pares
function [15:0] get_reg16(input [3:0] idx);
    case (idx)
        4'd0: get_reg16 = {8'h00, ar};
        4'd1: get_reg16 = hi;
        4'd2: get_reg16 = jk;
        4'd3: get_reg16 = fg;
        default: get_reg16 = 8'h00;
    endcase
endfunction

// Helper para obtener registros
function [7:0] get_reg(input [3:0] idx);
    case (idx)
        4'd0: get_reg = ar;
        4'd1: get_reg = br;
        4'd2: get_reg = cr;
        4'd3: get_reg = dr;
        4'd4: get_reg = er;
        4'd5: get_reg = fr;
        4'd6: get_reg = gr;
        4'd7: get_reg = hr;
        4'd8: get_reg = ir;
        4'd9: get_reg = jr;
        4'd10: get_reg = kr;
        default: get_reg = 8'h00;
    endcase
endfunction

always @(posedge clk or posedge reset) begin
    if (reset) begin
        ar <= 8'h00;
        br <= 8'h00;
        cr <= 8'h00;
        dr <= 8'h00;
        er <= 8'h00;
        fr <= 8'h00;
        gr <= 8'h00;
        hr <= 8'h00;
        ir <= 8'h00;
        ix <= 1'b0;
        addr <= 24'h0;
        wvx <= 16'h0;
        rex <= 1'b0;
        wex <= 1'b0;
        state <= IDLE;
        cmpr <= 8'h00;
        flags <= 8'h00;
    end else begin
        ix <= 1'b0;
        rfx <= 1'b0;
        if (rex) rex <= 1'b0;
        if (wex) wex <= 1'b0;
        if (jfl) jfl <= 1'b0;

        if (jfx) begin
            jfx <= 1'b0;
        end

        case (state)
            IDLE: begin
                if (ie) begin
                    // Formato 0: 0I XX = mov r8, XXh
                    if (instr[15:12] == 4'h0) begin
                        casex (instr[11:8])
                            4'h0: ar <= instr[7:0];
                            4'h1: br <= instr[7:0];
                            4'h2: cr <= instr[7:0];
                            4'h3: dr <= instr[7:0];
                            4'h4: er <= instr[7:0];
                            4'h5: fr <= instr[7:0];
                            4'h6: gr <= instr[7:0];
                            4'h7: hr <= instr[7:0];
                            4'h8: ir <= instr[7:0];
                            4'h9: jr <= instr[7:0];
                            4'd10:kr <= instr[7:0];
                            default: ;
                        endcase
                        ix <= 1'b1;
                    end
                    
                    // Formato 1: 1O II = {o} r8, r8
                    else if (instr[15:12] == 4'h1) begin
                        case (instr[11:8])
                            4'h0: begin // add
                                case (instr[7:4])
                                    4'h0: ar <= ar + get_reg(instr[3:0]);
                                    4'h1: br <= br + get_reg(instr[3:0]);
                                    4'h2: cr <= cr + get_reg(instr[3:0]);
                                    4'h3: dr <= dr + get_reg(instr[3:0]);
                                    4'h4: er <= er + get_reg(instr[3:0]);
                                    4'h5: fr <= fr + get_reg(instr[3:0]);
                                    4'h6: gr <= gr + get_reg(instr[3:0]);
                                    4'h7: hr <= hr + get_reg(instr[3:0]);
                                    4'h8: ir <= ir + get_reg(instr[3:0]);
                                    4'h9: jr <= jr + get_reg(instr[3:0]);
                                    4'd10: kr <= kr + get_reg(instr[3:0]);
                                    default: ;
                                endcase
                            end
                            4'h1: begin // sub
                                case (instr[7:4])
                                    4'h0: ar <= ar - get_reg(instr[3:0]);
                                    4'h1: br <= br - get_reg(instr[3:0]);
                                    4'h2: cr <= cr - get_reg(instr[3:0]);
                                    4'h3: dr <= dr - get_reg(instr[3:0]);
                                    4'h4: er <= er - get_reg(instr[3:0]);
                                    4'h5: fr <= fr - get_reg(instr[3:0]);
                                    4'h6: gr <= gr - get_reg(instr[3:0]);
                                    4'h7: hr <= hr - get_reg(instr[3:0]);
                                    4'h8: ir <= ir - get_reg(instr[3:0]);
                                    4'h9: jr <= jr - get_reg(instr[3:0]);
                                    4'd10: kr <= kr - get_reg(instr[3:0]);
                                    default: ;
                                endcase
                            end
                            4'h2: begin // mov opr
                                case (instr[7:4])
                                    4'h0: ar <= get_reg(instr[3:0]);
                                    4'h1: br <= get_reg(instr[3:0]);
                                    4'h2: cr <= get_reg(instr[3:0]);
                                    4'h3: dr <= get_reg(instr[3:0]);
                                    4'h4: er <= get_reg(instr[3:0]);
                                    4'h5: fr <= get_reg(instr[3:0]);
                                    4'h6: gr <= get_reg(instr[3:0]);
                                    4'h7: hr <= get_reg(instr[3:0]);
                                    4'h8: ir <= get_reg(instr[3:0]);
                                    4'h9: jr <= get_reg(instr[3:0]);
                                    4'd10: kr <= get_reg(instr[3:0]);
                                    default: ;
                                endcase
                            end
                            4'h3: begin // cmp
                                case (instr[7:4])
                                    4'h0: cmpr <= ar - get_reg(instr[3:0]);
                                    4'h1: cmpr <= br - get_reg(instr[3:0]);
                                    4'h2: cmpr <= cr - get_reg(instr[3:0]);
                                    4'h3: cmpr <= dr - get_reg(instr[3:0]);
                                    4'h4: cmpr <= er - get_reg(instr[3:0]);
                                    4'h5: cmpr <= fr - get_reg(instr[3:0]);
                                    4'h6: cmpr <= gr - get_reg(instr[3:0]);
                                    4'h7: cmpr <= hr - get_reg(instr[3:0]);
                                    4'h8: cmpr <= ir - get_reg(instr[3:0]);
                                    4'h9: cmpr <= jr - get_reg(instr[3:0]);
                                    4'd10: cmpr <= kr - get_reg(instr[3:0]);
                                    default: ;
                                endcase

                                state <= CMP_CALC;
                            end
                            default: ;
                        endcase
                        if (instr[11:8] != 4'h3) begin
                            ix <= 1'b1;
                        end
                    end
                    
                    // Formato 2: 2X SV = l/s adr, vr
                    else if (instr[15:12] == 4'h2) begin
                        // 1. Calcular Dirección
                        case (instr[11:8])
                            4'h0: addr <= {dr, 16'h0000} + bc;
                            4'h1: addr <= {er, 16'h0000} + bc;
                            4'h2: addr <= {dr, 16'h0000} + fg;
                            4'h3: addr <= {er, 16'h0000} + fg;
                            default: addr <= 24'h0;
                        endcase

                        // 2. Determinar si es Load (S=0) o Store (S=1)
                        if (instr[7:4] == 4'h1) begin // Store
                            wvx <= get_reg16(instr[3:0]);
                            wex <= 1'b1;
                            state <= MEM_WRITE; // Ir a estado de escritura
                        end else if (instr[7:4] == 4'h0) begin // Load
                            rex <= 1'b1;
                            state <= MEM_READ;  // Ir a estado de lectura
                        end

                        if (instr[3:0] == 4'h1) begin
                            r2x <= 1;
                        end
                        else begin
                            r2x <= 0;
                        end
                    end

                    // Formato 3: 3? XX = jv XXh (Saltos condicionales e incondicionales)
                    else if (instr[15:12] == 4'h3) begin                        
                        // Evaluar condición de salto de forma segura sin desbordar índices
                        case (instr[11:8])
                            4'h0: condition_met = 1'b1;                  // Salto incondicional puro (jmp)
                            4'h1: condition_met = 1'b1;                  // Salto con enlace (ej: call/link)
                            4'h2: condition_met = flags[0];              // Zero flag (jz)
                            4'h3: condition_met = flags[1];              // Negative/Sign flag (jn)
                            default: condition_met = 1'b0;
                        endcase

                        if (condition_met) begin
                            jfx <= 1;
                            jad <= instr[7:0];
                            if (instr[11:8] == 4'h1) begin
                                jfl <= 1'b1;
                            end
                        end
                        ix <= 1'b1;
                    end

                    // Formato 4: 4? DS r16 = r16 * r8/16 / acciones varias / cmpw r16, r16
                    else if (instr[15:12] == 4'h4) begin
                        if (instr[11:8] == 4'h0) begin
                            tmp216 = get_reg16(instr[3:0]);

                            case (instr[7:4])
                                4'h1: begin 
                                    tmp16 = hi * tmp216; 
                                    hr = tmp16[15:8];
                                    ir = tmp16[7:0];
                                end
                                4'h2: begin
                                    tmp16 = jk * tmp216;
                                    jr = tmp16[15:8];
                                    kr = tmp16[7:0];
                                end
                                4'h3: begin
                                    tmp16 = fg * tmp216;
                                    fr = tmp16[15:8];
                                    gr = tmp16[7:0];
                                end
                            endcase
                        end
                        else if (instr[11:8] == 4'h1) begin
                            if (instr[7:0] == 0) begin
                                rfx <= 1'b1;
                            end
                        end
                        else if (instr[11:8] == 4'h2) begin
                            cmpr16 = get_reg16(instr[7:4]) - get_reg16(instr[3:0]);
                            flags <= 0;
                            if (cmpr16 == 0) begin
                                flags[0] <= 1'b1;
                            end
                            if (cmpr16[15] == 1) begin
                                flags[1] <= 1'b1;
                            end
                        end
                        else if (instr[11:8] == 4'h3) begin
                            tmp216 = get_reg16(instr[3:0]);

                            case (instr[7:4])
                                4'h1: begin 
                                    tmp16 = hi + tmp216; 
                                    hr = tmp16[15:8];
                                    ir = tmp16[7:0];
                                end
                                4'h2: begin
                                    tmp16 = jk + tmp216;
                                    jr = tmp16[15:8];
                                    kr = tmp16[7:0];
                                end
                                4'h3: begin
                                    tmp16 = fg + tmp216;
                                    fr = tmp16[15:8];
                                    gr = tmp16[7:0];
                                end
                            endcase
                        end

                        ix <= 1'b1;
                    end
                end
            end

            MEM_READ: begin
                // Mantener activa la señal de lectura (si tu memoria requiere ciclos de espera)
                // O capturar el valor de 'rvx' inmediatamente en este ciclo:
                if (instr[3:0] == 4'h1) begin
                    hr <= rvx[15:8];
                    ir <= rvx[7:0];
                end
                else if (instr[3:0] == 4'h2) begin
                    jr <= rvx[15:8];
                    kr <= rvx[7:0];
                end else begin
                    ar <= rvx[7:0];
                end
                rex <= 1'b0;
                ix <= 1'b1;       // Indicar instrucción ejecutada
                state <= IDLE;    // Regresar al estado libre
            end

            MEM_WRITE: begin
                wex <= 1'b0;
                // Ciclo de confirmación de escritura en memoria
                ix <= 1'b1;       // Indicar instrucción ejecutada
                state <= IDLE;    // Regresar al estado libre
            end

            CMP_CALC: begin
                flags <= 0;
                if (cmpr == 0) begin
                    flags[0] <= 1'b1;
                end
                if (cmpr[7] == 1) begin
                    flags[1] <= 1'b1;
                end
                // Ciclo de finalizacion de calculo
                ix <= 1'b1;       // Indicar instrucción ejecutada
                state <= IDLE;    // Regresar al estado libre
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule