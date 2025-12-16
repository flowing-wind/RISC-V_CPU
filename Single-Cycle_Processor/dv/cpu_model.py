import json
import os
import re

class CPU_Model:
    def __init__(self):
        self.regs = [0] * 32
        self.pc = 0
        self.memory = {}
        self.imem = {}
        self.max_cycles = 5000

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
            next_pc = (val1 + imm) & ~1     # ignore LSB and set to 0
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

        # update reg and pc
        if rd != 0 and res is not None:
            self.regs[rd] = self.to_unsigned(res)

        self.pc = self.to_unsigned(next_pc)

    def parse_reg(self, s):
        s = s.strip().replace(',', '')

        abi_map = {
            'zero': 0,
            'ra': 1,
            'sp': 2,
            'gp': 3,
            'tp': 4,
            't0': 5, 't1': 6, 't2': 7,
            's0': 8, 'fp': 8,
            's1': 9,
            'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
            's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
            't3': 28, 't4': 29, 't5': 30, 't6': 31
        }

        if s in abi_map:
            return abi_map[s]
        
        if s.startswith('x'):
            try:
                val = int(s[1:])
                if 0 <= val <= 31:
                    return val
                else:
                    print(f"[Parser] Error: Register {s} out of range (0-31)")
            except ValueError:
                pass    # not a register

        print(f"[Parser] Warning: Unknown register '{s}', defaulting to x0")
        return 0
    
    def parse_offset_base(self, s):
        # eg: 4(x2)  -->  imm=4, rs1=2
        match = re.match(r'(-?\d+)\((.*?)\)', s)
        if match:
            return int(match.group(1), 0), self.parse_reg(match.group(2))
        return 0, 0
    
    def load_asm_file(self, filename):
        self.imem = {}
        self.pc = 0
        current_pc = 0

        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for line in lines:
            line = line.split('#')[0].strip()   # remove note
            if not line: continue
            if ':' in line: continue

            parts = line.replace(',', ' ').split()
            op = parts[0]

            rd, rs1, rs2, imm = 0, 0, 0, 0

            # R-Type
            if op in ['add', 'sub', 'and', 'or', 'xor', 'slt', 'sltu', 'sll', 'srl', 'sra']:
                rd = self.parse_reg(parts[1])
                rs1 = self.parse_reg(parts[2])
                rs2 = self.parse_reg(parts[3])
            
            # I-Type(1)
            elif op in ['addi', 'andi', 'ori', 'xori', 'slti', 'sltiu', 'slli', 'srli', 'srai']:
                rd = self.parse_reg(parts[1])
                rs1 = self.parse_reg(parts[2])
                imm = int(parts[3], 0)

            # I-Type(2) + jalr
            elif op in ['lb', 'lh', 'lw', 'lbu', 'lhu', 'jalr']:
                rd = self.parse_reg(parts[1])
                imm, rs1 = self.parse_offset_base(parts[2])
            
            # S-Type
            elif op in ['sb', 'sh', 'sw']:
                rs2 = self.parse_reg(parts[1])
                imm, rs1 = self.parse_offset_base(parts[2])

            # B-Type
            elif op in ['beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu']:
                rs1 = self.parse_reg(parts[1])
                rs2 = self.parse_reg(parts[2])
                imm = int(parts[3], 0)
            
            # U/J-Type
            elif op in ['lui', 'auipc', 'jal']:
                rd = self.parse_reg(parts[1])
                imm = int(parts[2], 0)
            
            self.imem[current_pc] = (op, rd, rs1, rs2, imm)
            current_pc += 4

    def run(self):
        cycles = 0
        print(f"[Sim] Starting simulation from PC=0...")
        while self.pc in self.imem and cycles < self.max_cycles:
            op, rd, rs1, rs2, imm = self.imem[self.pc]
            self.step(op, rd, rs1, rs2, imm)
            cycles += 1
        
        print(f"[Sim] Finished in {cycles} cycles. Final PC={hex(self.pc)}")
        if cycles >= self.max_cycles:
            print("[Sim] Warning: Max cycles reached!")
    
    def dump_results(self):
        # RegFile
        with open("expected_regs.json", 'w') as f:
            json.dump(self.regs, f)

        # dmem
        dmem_dump = {str(k): v for k, v in self.memory.items()}
        with open("expected_dmem.json", 'w') as f:
            json.dump(dmem_dump, f, indent=2)

        print("[Sim] Results saved to 'expected_regs.json' and 'expected_dmem.json'")


if __name__ == "__main__":
    cpu = CPU_Model()

    asm_file = "main.asm"
    if not os.path.exists(asm_file):
        print(f"Error: {asm_file} not found.")

    cpu.load_asm_file(asm_file)
    cpu.run()
    cpu.dump_results()

    