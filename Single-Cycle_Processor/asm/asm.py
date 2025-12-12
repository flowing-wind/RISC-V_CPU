import sys

OP = {
    'R-Type':   '0110011',
    'I-Type1':  '0000011',
    'I-Type2':  '0010011',
    'S-Type':   '0100011',
    'B-Type':   '1100011'
}

FUNCT = {
    # R-Type
    'add':  {'funct3': '000', 'funct7': '0000000'},
    'sub':  {'funct3': '000', 'funct7': '0100000'},
    'slt':  {'funct3': '010', 'funct7': '0000000'},
    'or':   {'funct3': '110', 'funct7': '0000000'},
    'and':  {'funct3': '111', 'funct7': '0000000'},
    # I-Type
    'lw':   {'funct3': '010'},
    'addi': {'funct3': '000'},
    # S-Type
    'sw':   {'funct3': '010'},
    # B-Type
    'beq':  {'funct3': '000'}
}

REGISTERS = {f'x{i}': i for i in range(32)}


# convert an int to bin
# val can be string
def to_bin(val, bits):
    val = int(val)
    if val < 0:
        val = (1 << bits) + val
    return f"{val:0{bits}b}"

# convert funct
def assemble(asm_file, hex_file):
    with open(asm_file, 'r') as f:
        lines = f.readlines()
    output_hex = []

    # ---------------------------------- #

    for line in lines:
        line = line.split('//')[0].strip()
        if not line: continue   # blank, skip

        parts = line.replace(',', ' ').split()
        instr = parts[0]
        args = parts[1:]

        machine_code = ""

        # R-Type
        # add   rd,  rs1, rs2
        if instr in ['add', 'sub', 'slt', 'or', 'and']:
            rd = to_bin(REGISTERS[args[0]], 5)
            rs1 = to_bin(REGISTERS[args[1]], 5)
            rs2 = to_bin(REGISTERS[args[2]], 5)
            funct3 = FUNCT[instr]['funct3']
            funct7 = FUNCT[instr]['funct7']
            op = OP['R-Type']
            # funct7 | rs2 | rs1 | funct3 | rd | op
            machine_code = f"{funct7}{rs2}{rs1}{funct3}{rd}{op}"

        # I-Type    op = 0d3
        # lw    rd,  imm(rs1)
        # imm: 0x 0h 0d 0b ?
        # imm(offfset) 0d by default
        elif instr in ['lw']:
            rd = to_bin(REGISTERS[args[0]], 5)
            offset, rs1 = args[1].split('(')
            rs1 = rs1.strip(')')

            rs1 = to_bin(REGISTERS[rs1], 5)
            imm = to_bin(offset, 12)
            funct3 = FUNCT[instr]['funct3']
            op = OP['I-Type1']
            # imm[11:0] | rs1 | funct3 | rd | op
            machine_code = f"{imm}{rs1}{funct3}{rd}{op}"

        # I-Type    op = 0d19
        # addi  rd,  rs1, imm
        # imm 0d by default
        elif instr in ['addi']:
            rd = to_bin(REGISTERS[args[0]], 5)
            rs1 = to_bin(REGISTERS[args[1]], 5)
            imm = to_bin(args[2], 12)
            funct3 = FUNCT[instr]['funct3']
            op = OP['I-Type2']
            # imm[11:0] | rs1 | funct3 | rd | op
            machine_code = f"{imm}{rs1}{funct3}{rd}{op}"

        # S-Type
        # sw    rs2, imm(rs1)
        # imm(offfset) 0d by default
        elif instr in ['sw']:
            rs2 = to_bin(REGISTERS[args[0]], 5)
            offset, rs1 = args[1].split('(')
            rs1 = rs1.strip(')')

            rs1 = to_bin(REGISTERS[rs1], 5)
            imm = to_bin(offset, 12)
            imm_11_5 = imm[0:7]
            imm_4_0 = imm[7:12]
            funct3 = FUNCT[instr]['funct3']
            op = OP['S-Type']
            # imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | op
            machine_code = f"{imm_11_5}{rs2}{rs1}{funct3}{imm_4_0}{op}"

        # B-Type
        # beq   rs1, rs2, label
        # label(imm) 0d by default
        elif instr in ['beq']:
            rs1 = to_bin(REGISTERS[args[0]], 5)
            rs2 = to_bin(REGISTERS[args[1]], 5)
            imm = to_bin(args[2], 12)
            imm_12 = imm[0]
            imm_10_5 = imm[2:8]
            imm_4_1 = imm[8:12]
            imm_11 = imm[1]
            funct3 = FUNCT[instr]['funct3']
            op = OP['B-Type']
            # imm_12 | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm_11 | op
            machine_code = f"{imm_12}{imm_10_5}{rs2}{rs1}{funct3}{imm_4_1}{imm_11}{op}"

        # convert to hex
        if machine_code:
            hex_val = f"{int(machine_code, 2):08X}"
            output_hex.append(hex_val)
            # print(f"{line:<20} -> 0x{hex_val}")
    
    with open(hex_file, 'w') as f:
        f.write('\n'.join(output_hex))

if __name__ == "__main__":
    assemble("instr.asm", "instr.txt")
