import random
import json
import os

class CPU_Model:
    def __init__(self):
        self.regs = [0] * 32
    
    def to_signed(self, val):
        if val >= 0x80000000:   # val is negative
            return val - 0x100000000
        return val
    
    def step(self, op, rd, rs1, rs2, imm):
        if rd == 0: return  # x0 is not writable

        val1 = self.regs[rs1]
        val2 = self.regs[rs2]
        res = 0

        if op == 'add':
            res = val1 + val2
        elif op == 'sub':
            res = val1 - val2
        elif op == 'and':
            res = val1 & val2
        elif op == 'or':
            res = val1 | val2
        elif op == 'slt':
            v1_signed = self.to_signed(val1)
            v2_signed = self.to_signed(val2)
            res = 1 if v1_signed < v2_signed else 0
        elif op == 'addi':
            res = val1 + imm

        self.regs[rd] = res & 0xFFFFFFFF

def generate_files(asm_file, json_file, num_instr=60):
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
    