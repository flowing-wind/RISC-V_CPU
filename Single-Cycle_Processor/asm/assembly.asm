addi x1, x0, 10     // x1 = 0d10
addi x2, x0, 20     // x2 = 0d20
add x3, x1, x2      // x3 = 0d30
sw x3, 4(x0)        // mem[4] = 0d30
lw x4, 4(x0)        // x4 = mem[4] = 0d30
beq x1, x2, -8      // 2 instr forward
