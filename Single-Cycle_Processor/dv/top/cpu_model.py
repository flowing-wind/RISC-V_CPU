import random
import json
import os

class CPU_Model:
    def __init__(self):
        self.regs = [0] * 32
        self.pc = 0
        self.memory = {}
        self.imem = {}

    def to_signed(self, val):
        val = val & 0xFFFFFFFF
        if val >= 0x80000000:   # val is negative
            return val - 0x100000000
        return val
    
    def to_unsigned(self, val):
        return val & 0xFFFFFFFF
    
    # data memory read/write
    def mem_read(self, addr, size, signed=False):
        val = 0
        for i in range(size):
            byte_val = self.memory.get(addr + i, 0)
            val |= (byte_val << (8 * i))
        if signed:
            if val & (1 << (size*8 - 1)):
                val -= (1 << (size*8))
        return val
    
    def mem_write(self, addr, size, val):
        for i in range(size):
            byte_val = (val >> (8*i)) & 0xFF
            self.memory[addr + i] = byte_val

    # instr memory load
    def load_program(self, asm_list):
        current_pc = 0
        self.imem = {}
        for line in asm_list:   # (op, rd, rs1, rs2, imm)
            self.imem[current_pc] = line
            current_pc += 4
    
    def step(self, op, rd, rs1, rs2, imm):
        rd  = int(rd) if rd is not None else 0
        rs1 = int(rs1) if rs1 is not None else 0
        rs2 = int(rs2) if rs2 is not None else 0
        imm = int(imm) if imm is not None else 0

        val1 = self.regs[rs1]
        val2 = self.regs[rs2]

        next_pc = self.pc + 4

        res = None

        # R-Type
        if op == 'add':
            res = val1 + val2
        elif op == 'sub':
            res = val1 - val2
        elif op == 'sll':
            res = val1 << (val2 & 0x1F)
        elif op == 'slt':
            res = 1 if self.to_signed(val1) < self.to_signed(val2) else 0
        elif op == 'sltu':
            res = 1 if self.to_unsigned(val1) < self.to_unsigned(val2) else 0
        elif op == 'xor':
            res = val1 ^ val2
        elif op == 'srl':
            res = self.to_unsigned(val1) >> (val2 & 0x1F)
        elif op == 'sra':
            res = self.to_signed(val1) >> (val2 & 0x1F)
        elif op == 'or':
            res = val1 | val2
        elif op == 'and':
            res = val1 & val2

        # I-Type(1)  -->  R-Type + i
        elif op == 'addi':
            res = val1 + imm
        elif op == 'slli':
            res = val1 << (imm & 0x1F)
        elif op == 'slti':
            res = 1 if self.to_signed(val1) < self.to_signed(imm) else 0
        elif op == 'sltiu':
            res = 1 if self.to_unsigned(val1) < self.to_unsigned(imm) else 0
        elif op == 'xori':
            res = val1 ^ imm
        elif op == 'srli':
            res = self.to_unsigned(val1) >> (imm & 0x1F)
        elif op == 'srai':
            res = self.to_signed(val1) >> (imm & 0x1F)
        elif op == 'ori':
            res = val1 | imm
        elif op == 'andi':
            res = val1 & imm

        # I-Type(2)
        elif op == 'lb':
            res = self.mem_read(val1 + imm, 1, signed=True)
        elif op == 'lh':
            res = self.mem_read(val1 + imm, 2, signed=True)
        elif op == 'lw':
            res = self.mem_read(val1 + imm, 4, signed=True)
        elif op == 'lbu':
            res = self.mem_read(val1 + imm, 1, signed=False)
        elif op == 'lhu':
            res = self.mem_read(val1 + imm, 2, signed=False)
        
        # I-Type(3)
        elif op == 'jalr':
            res = self.pc + 4
            next_pc = (val1 + imm) & ~1

        # S-Type
        elif op == 'sb':
            self.mem_write(val1 + imm, 1, val2)
        elif op == 'sh':
            self.mem_write(val1 + imm, 2, val2)
        elif op == 'sw':
            self.mem_write(val1 + imm, 4, val2)

        # B-Type
        elif op == 'beq':
            if val1 == val2:
                next_pc = self.pc + imm
        elif op == 'bne':
            if val1 != val2:
                next_pc = self.pc + imm
        elif op == 'blt':
            if self.to_signed(val1) < self.to_signed(val2):
                next_pc = self.pc + imm
        elif op == 'bge':
            if self.to_signed(val1) >= self.to_signed(val2):
                next_pc = self.pc + imm
        elif op == 'bltu':
            if self.to_unsigned(val1) < self.to_unsigned(val2):
                next_pc = self.pc + imm
        elif op == 'bgeu':
            if self.to_unsigned(val1) >= self.to_unsigned(val2):
                next_pc = self.pc + imm

        # U-Type
        elif op == 'auipc':
            res = self.pc + (imm << 12)
        elif op == 'lui':
            res = (imm << 12)

        # J-Type
        elif op == 'jal':
            res = self.pc + 4
            next_pc = self.pc + imm


        self.regs[rd] = res & 0xFFFFFFFF

def generate_files(asm_file, json_file, num_instr=1023):
    cpu = CPU_Model()
    asm_code = []
    ops_r = ['add', 'sub', 'and', 'or', 'slt']
    ops_i = ['addi']

    for _ in range(num_instr):
        is_i_type = random.choice([True, False])
        rd = random.randint(0, 31)
        rs1 = random.randint(0, 31)

        if is_i_type:
            imm = random.randint(-2**11, 2**11-1)
            op = 'addi'
            cpu.step(op, rd, rs1, 0, imm)
            asm_code.append(f"{op} x{rd}, x{rs1}, {imm}")
        else:
            rs2 = random.randint(0, 31)
            op = random.choice(ops_r)
            cpu.step(op, rd, rs1, rs2, 0)
            asm_code.append(f"{op} x{rd}, x{rs1}, x{rs2}")
    
    asm_code.append("beq x0, x0, 0")
    
    with open(asm_file, 'w') as f:
        f.write('\n'.join(asm_code))
    with open(json_file, 'w') as f:
        json.dump(cpu.regs, f)
    print(f"[Gen] Generated {asm_file} and {json_file}")

if __name__ == "__main__":
    generate_files("instr.asm", "expected_regs.json")
    