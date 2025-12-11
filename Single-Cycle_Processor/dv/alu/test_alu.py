import cocotb
from cocotb.triggers import Timer
import random

def alu_model(a, b, control):
    res = 0
    a = a & 0xFFFFFFFF
    b = b & 0xFFFFFFFF

    if control == 0b000:
        res = a + b
    elif control == 0b001:
        res = a - b
    elif control == 0b010:
        res = a & b
    elif control == 0b011:
        res = a | b
    elif control == 0b101:  # slt is signed
        a_signed = a if (a < 0x80000000) else a - 0x100000000
        b_signed = b if (b < 0x80000000) else b - 0x100000000
        res = 1 if (a_signed < b_signed) else 0

    res = res & 0xFFFFFFFF
    return res

@cocotb.test()
async def alu_random_test(dut):
    # operations
    ops = [0b000, 0b001, 0b010, 0b011, 0b101]

    for i in range(1000):
        a = random.randint(0, 0xFFFFFFFF)
        b = random.randint(0, 0xFFFFFFFF)
        op = random.choice(ops)

        dut.src_a.value = a
        dut.src_b.value = b
        dut.alu_control.value = op

        await Timer(1, unit='ns')

        try:
            actual_res = int(dut.alu_result.value)
            actual_zero = int(dut.zero.value)
        except ValueError:
            raise ValueError(f"Output is X (unknown), src_a={hex(a)}, src_b={hex(b)}, op={bin(op)}")
        
        expected_res = alu_model(a, b, op)
        expected_zero = 1 if (expected_res == 0) else 0

        assert actual_res == expected_res, \
            f"Unexpected alu_result, src_a={hex(a)}, src_b={hex(b)}, op={bin(op)} | Exp={hex(expected_res)} Got={hex(actual_res)}"
        assert actual_zero == expected_zero, \
            f"Unexpected zero flag, src_a={hex(a)}, src_b={hex(b)}, op={bin(op)} | Exp={hex(expected_zero)} Got={hex(actual_zero)}"
        