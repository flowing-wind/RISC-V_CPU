import cocotb
from cocotb.triggers import Timer
import json
import os

# cocotb
@cocotb.test()
async def verify(dut):
    if not os.path.exists("expected_regs.json"):
        raise FileNotFoundError("expected_regs.json not found!")
    with open("expected_regs.json", 'r') as f:
        expected_regs = json.load(f)
    
    cocotb.log.info("[Test] Start Simulation...")

    # Start Simulation
    await Timer(500000, unit='ns')

    cocotb.log.info("[Test] Checking Registers...")

    rf_handle = dut.dut.d_unit.rf.regs

    mismatch =  False
    for i in range(0, 32):
        rtl_val = int(rf_handle[i].value)
        exp_val = expected_regs[i]

        if rtl_val != exp_val:
            cocotb.log.error(f"Mismatch at x{i}! Expected: {hex(exp_val)}, Got: {hex(rtl_val)}")
            mismatch = True

    if not mismatch:
        cocotb.log.info("PASS: All registers match golden model!")
    else:
        raise Exception("FAIL: Register mismatch detected!")
