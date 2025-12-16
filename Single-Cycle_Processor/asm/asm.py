import sys

# =================================================================================================================
ABI_MAP = {
    'zero': 0,  'ra': 1,   'sp': 2,   'gp': 3,   'tp': 4,
    't0': 5,    't1': 6,   't2': 7,   's0': 8,   'fp': 8,   's1': 9,
    'a0': 10,   'a1': 11,  'a2': 12,  'a3': 13,  'a4': 14,  'a5': 15, 'a6': 16, 'a7': 17,
    's2': 18,   's3': 19,  's4': 20,  's5': 21,  's6': 22,  's7': 23, 's8': 24, 's9': 25, 's10': 26, 's11': 27,
    't3': 28,   't4': 29,  't5': 30,  't6': 31
}
# =================================================================================================================
def parse_reg(s):
    s = s.strip().replace(',', '')
    if s in ABI_MAP: return ABI_MAP[s]
    if s.startswith('x'):
        try: return int(s[1:])
        except: pass
    return 0

# convert an int to bin
# val can be string
def to_bin(val, bits):
    val = int(str(val), 0)
    if val < 0: val = (1 << bits) + val
    return f"{val & ((1 << bits) - 1):0{bits}b}"

# =================================================================================================================
INSTR_DB = {
    # --- R-Type: op=0110011 ---
    'add':  {'type': 'R', 'op': '0110011', 'f3': '000', 'f7': '0000000'},
    'sub':  {'type': 'R', 'op': '0110011', 'f3': '000', 'f7': '0100000'},
    'sll':  {'type': 'R', 'op': '0110011', 'f3': '001', 'f7': '0000000'},
    'slt':  {'type': 'R', 'op': '0110011', 'f3': '010', 'f7': '0000000'},
    'sltu': {'type': 'R', 'op': '0110011', 'f3': '011', 'f7': '0000000'},
    'xor':  {'type': 'R', 'op': '0110011', 'f3': '100', 'f7': '0000000'},
    'srl':  {'type': 'R', 'op': '0110011', 'f3': '101', 'f7': '0000000'},
    'sra':  {'type': 'R', 'op': '0110011', 'f3': '101', 'f7': '0100000'},
    'or':   {'type': 'R', 'op': '0110011', 'f3': '110', 'f7': '0000000'},
    'and':  {'type': 'R', 'op': '0110011', 'f3': '111', 'f7': '0000000'},

    # --- I-Type Arithmetic: op=0010011 ---
    'addi': {'type': 'I', 'op': '0010011', 'f3': '000'},
    'slli': {'type': 'I_sh', 'op': '0010011', 'f3': '001', 'f7': '0000000'}, # 特殊处理移位立即数
    'slti': {'type': 'I', 'op': '0010011', 'f3': '010'},
    'sltiu':{'type': 'I', 'op': '0010011', 'f3': '011'},
    'xori': {'type': 'I', 'op': '0010011', 'f3': '100'},
    'srli': {'type': 'I_sh', 'op': '0010011', 'f3': '101', 'f7': '0000000'},
    'srai': {'type': 'I_sh', 'op': '0010011', 'f3': '101', 'f7': '0100000'},
    'ori':  {'type': 'I', 'op': '0010011', 'f3': '110'},
    'andi': {'type': 'I', 'op': '0010011', 'f3': '111'},

    # --- I-Type Load: op=0000011 ---
    'lb':   {'type': 'I_mem', 'op': '0000011', 'f3': '000'},
    'lh':   {'type': 'I_mem', 'op': '0000011', 'f3': '001'},
    'lw':   {'type': 'I_mem', 'op': '0000011', 'f3': '010'},
    'lbu':  {'type': 'I_mem', 'op': '0000011', 'f3': '100'},
    'lhu':  {'type': 'I_mem', 'op': '0000011', 'f3': '101'},

    # --- I-Type Jump: op=1100111 ---
    'jalr': {'type': 'I_mem', 'op': '1100111', 'f3': '000'}, # 语法类似于 lw: jalr rd, offset(rs1)

    # --- S-Type: op=0100011 ---
    'sb':   {'type': 'S', 'op': '0100011', 'f3': '000'},
    'sh':   {'type': 'S', 'op': '0100011', 'f3': '001'},
    'sw':   {'type': 'S', 'op': '0100011', 'f3': '010'},

    # --- B-Type: op=1100011 ---
    'beq':  {'type': 'B', 'op': '1100011', 'f3': '000'},
    'bne':  {'type': 'B', 'op': '1100011', 'f3': '001'},
    'blt':  {'type': 'B', 'op': '1100011', 'f3': '100'},
    'bge':  {'type': 'B', 'op': '1100011', 'f3': '101'},
    'bltu': {'type': 'B', 'op': '1100011', 'f3': '110'},
    'bgeu': {'type': 'B', 'op': '1100011', 'f3': '111'},

    # --- U-Type ---
    'lui':  {'type': 'U', 'op': '0110111'},
    'auipc':{'type': 'U', 'op': '0010111'},

    # --- J-Type ---
    'jal':  {'type': 'J', 'op': '1101111'},
}
# =================================================================================================================

def assemble(asm_file, bin_file):
    try:
        with open(asm_file, 'r', encoding='utf-8') as f: lines = f.readlines()
    except FileNotFoundError:
        print(f"Error: {asm_file} not found.")
        return
    
    output_bytes = bytearray()
    instruction_count = 0

    for i, line in enumerate(lines):
        line = line.split('#')[0].split('//')[0].strip() # 支持两种注释
        if not line or line.endswith(':'): continue # 跳过空行和标签行

        # add x1, x2, x3  -->  ['add', 'x1', 'x2', 'x3']
        # lw x1, 4(x2)    -->  ['lw', 'x1', '4', 'x2']
        tokens = line.replace(',', ' ').replace('(', ' ').replace(')', ' ').split()
        instr_name = tokens[0]

        if instr_name not in INSTR_DB:
            print(f"Error: Unknown instruction '{instr_name}' at line {i+1}")
            continue
        
        info = INSTR_DB[instr_name]
        itype = info['type']
        op = info['op']
        f3 = info.get('f3', '')
        f7 = info.get('f7', '')
        
        bin_code = ""

        try:
            # R-Type: add rd, rs1, rs2 
            if itype == 'R':
                rd  = to_bin(parse_reg(tokens[1]), 5)
                rs1 = to_bin(parse_reg(tokens[2]), 5)
                rs2 = to_bin(parse_reg(tokens[3]), 5)
                bin_code = f"{f7}{rs2}{rs1}{f3}{rd}{op}"

            # I-Type (Arithmetic): addi rd, rs1, imm ---
            elif itype == 'I':
                rd  = to_bin(parse_reg(tokens[1]), 5)
                rs1 = to_bin(parse_reg(tokens[2]), 5)
                imm = to_bin(tokens[3], 12)
                bin_code = f"{imm}{rs1}{f3}{rd}{op}"

            # I-Type (Shift)
            elif itype == 'I_sh':
                rd  = to_bin(parse_reg(tokens[1]), 5)
                rs1 = to_bin(parse_reg(tokens[2]), 5)
                shamt = to_bin(tokens[3], 5) # shift amount
                bin_code = f"{f7}{shamt}{rs1}{f3}{rd}{op}"

            # I-Type (Memory): lw rd, imm(rs1)
            elif itype == 'I_mem':
                rd  = to_bin(parse_reg(tokens[1]), 5)
                imm = to_bin(tokens[2], 12) # offset
                rs1 = to_bin(parse_reg(tokens[3]), 5) # base
                bin_code = f"{imm}{rs1}{f3}{rd}{op}"

            # S-Type: sw rs2, imm(rs1)
            elif itype == 'S':
                rs2 = to_bin(parse_reg(tokens[1]), 5)
                imm = to_bin(tokens[2], 12)
                rs1 = to_bin(parse_reg(tokens[3]), 5)

                imm_11_5 = imm[0:7]
                imm_4_0  = imm[7:12]
                bin_code = f"{imm_11_5}{rs2}{rs1}{f3}{imm_4_0}{op}"

            # B-Type: beq rs1, rs2, imm
            elif itype == 'B':
                rs1 = to_bin(parse_reg(tokens[1]), 5)
                rs2 = to_bin(parse_reg(tokens[2]), 5)
                imm = to_bin(tokens[3], 13) # B-Type immediate is 13 bits (bit 0 is 0)

                # imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
                imm_12   = imm[0]
                imm_11   = imm[1]
                imm_10_5 = imm[2:8]
                imm_4_1  = imm[8:12]
                
                bin_code = f"{imm_12}{imm_10_5}{rs2}{rs1}{f3}{imm_4_1}{imm_11}{op}"

            # U-Type: lui rd, imm
            elif itype == 'U':
                rd  = to_bin(parse_reg(tokens[1]), 5)
                imm = to_bin(tokens[2], 20) # 20 bits
                bin_code = f"{imm}{rd}{op}"

            # J-Type: jal rd, imm
            elif itype == 'J':
                rd  = to_bin(parse_reg(tokens[1]), 5)
                imm = to_bin(tokens[2], 21) # 21 bits (bit 0 is 0)

                # imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd | opcode
                imm_20    = imm[0]
                imm_19_12 = imm[1:9]
                imm_11    = imm[9]
                imm_10_1  = imm[10:20]
                
                bin_code = f"{imm_20}{imm_10_1}{imm_11}{imm_19_12}{rd}{op}"

        except Exception as e:
            print(f"Error assembling line {i+1}: '{line}' -> {e}")
            continue

        if bin_code:
            val = int(bin_code, 2)
            output_bytes.extend(val.to_bytes(4, byteorder='little'))
            instruction_count += 1

    with open(bin_file, 'wb') as f:
        f.write(output_bytes)
    print(f"[Asm] Assembled {instruction_count} instructions ({len(output_bytes)} bytes) to {bin_file}")

if __name__ == "__main__":
    if len(sys.argv) >= 3:
        input_file = sys.argv[1]  # dv/instr.asm)
        output_file = sys.argv[2] # dv/instr.txt)
        assemble(input_file, output_file)
    else:
        print("[Asm] No args provided, using default 'instr.asm' -> 'main.bin'")
        assemble("instr.asm", "main.bin")
