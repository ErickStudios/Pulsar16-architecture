node asmbin.js test.asm test.hex
iverilog -o cpu_sim tb.v cpu.v
vvp cpu_sim