node asmbin.js test.asm test.hex
node asmbin.js fda.asm fda.hex
node asmbin.js test.asm test.bin -rbin

iverilog -o cpu_sim tb.v cpu.v
vvp cpu_sim