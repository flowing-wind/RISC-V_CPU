lui     x1, 0x12345         # x1 = 0x12345000
auipc   x2, 0               # x2 = Current PC

addi    x3, zero, 10        # x3 = 10
addi    x4, zero, -5        # x4 = -5
xori    x5, x4, 0xFF        # x5 = -5 ^ 0xFF
andi    x6, x5, 0xF0        # x6 = x5 & 0xF0
ori     x7, x6, 0x0F        # x7 = x6 | 0x0F
slti    x8, x4, 10          # x8 = 1 (-5 < 10)
sltiu   x9, x4, 10          # x9 = 0 (Unsigned large > 10)
slli    x10, x3, 2          # x10 = 40
srli    x11, x4, 2          # x11 = Logical shift right
srai    x12, x4, 2          # x12 = Arithmetic shift right

add     x13, x3, x4         # x13 = 5
sub     x14, x3, x4         # x14 = 15
sll     x15, x3, x8         # x15 = 20
srl     x16, x4, x8         # x16 = Logical
sra     x17, x4, x8         # x17 = Arithmetic
or      x18, x3, x4         # OR
and     x19, x3, x4         # AND
xor     x20, x3, x4         # XOR
slt     x21, x4, x3         # 1
sltu    x22, x4, x3         # 0


addi    x23, zero, 0x100    
lui     x24, 0x12345
addi    x24, x24, 0x678     

sw      x24, 0(x23)         # Mem[0x100] = 0x12345678

lw      x25, 0(x23)         # x25 = 0x12345678

lh      x26, 0(x23)         # Load Half Signed
lhu     x27, 0(x23)         # Load Half Unsigned

lb      x28, 0(x23)         # Load Byte Signed
lbu     x29, 0(x23)         # Load Byte Unsigned

sb      x3, 4(x23)          # Store byte at 0x104
sh      x3, 6(x23)          # Store half at 0x106


beq     x3, x3, 8           # 10==10? Jump to PC+8
addi    x31, zero, 0x111    # [Error Trap 1] x31 = 0x111

bne     x3, x4, 8           # 10!=-5? Jump to PC+8
addi    x31, zero, 0x222    # [Error Trap 2] x31 = 0x222

blt     x4, x3, 8           # -5 < 10? Jump to PC+8
addi    x31, zero, 0x333    # [Error Trap 3] x31 = 0x333

bge     x3, x4, 8           # 10 >= -5? Jump to PC+8
addi    x31, zero, 0x444    # [Error Trap 4] x31 = 0x444

bltu    x3, x4, 8           # 10 < Unsigned(-5)? Jump to PC+8
addi    x31, zero, 0x555    # [Error Trap 5] x31 = 0x555

bgeu    x4, x3, 8           # Unsigned(-5) >= 10? Jump to PC+8
addi    x31, zero, 0x666    # [Error Trap 6] x31 = 0x666

jal     x1, 8               
addi    x31, zero, 0x777    # [Error Trap 7] x31 = 0x777
