import cocotb
from cocotb.triggers import Timer
import json
import os

# cocotb
@cocotb.test()
async def verify(dut):
    if not os.path.exists("expected_regs.json"):
        raise FileNotFoundError("expected_regs.json not found!")
    if not os.path.exists("expected_dmem.json"):
        raise FileNotFoundError("expected_dmem.json not found!")
    with open("expected_regs.json", 'r') as f:
        expected_regs = json.load(f)
    with open("expected_dmem.json", 'r') as f:
        expected_dmem = json.load(f)
    
    cocotb.log.info("[Test] Start Simulation...")

    # Start Simulation
    await Timer(500000, unit='ns')

    cocotb.log.info("[Test] Checking Registers...")

    # Check regs
    rf_handle = dut.dut.d_unit.rf.regs

    mismatch =  False
    for i in range(0, 32):
        rtl_val = int(rf_handle[i].value)
        exp_val = expected_regs[i]

        if rtl_val != exp_val:
            cocotb.log.error(f"Mismatch at x{i}! Expected: {hex(exp_val)}, Got: {hex(rtl_val)}")
            mismatch = True

    if not mismatch:
        cocotb.log.info("PASS: All registers match model!")
    else:
        raise Exception("FAIL: Register mismatch detected!")
    
    # Check dmem
    cocotb.log.info("[Test] Checking Data memory...")

    dmem_handle = dut.dmem_unit.RAM

    mismatch =  False
    for addr_str, val in expected_dmem.items():
        addr = int(addr_str)
        word_addr = addr >> 2 & 0x3FF  # divided by 4
        byte_offset = addr & 0x3    # the least 2 bits

        rtl_word = int(dmem_handle[word_addr].value)
        rtl_byte = (rtl_word >> (byte_offset * 8)) & 0xFF

        if rtl_byte != val:
            cocotb.log.error(f"DMem Mismatch at addr {addr}! Exp: {hex(val)}, Got: {hex(rtl_byte)}")
            mismatch = True
    
    if not mismatch:
        cocotb.log.info("PASS: Data memory match model!")
    else:
        raise Exception("FAIL: Data memory mismatch detected!")
