import serial
import struct
import time

PORT = 'COM4'
BAUD = 9600
BIN_FILE = 'main.bin'

def upload():
    with serial.Serial(PORT, BAUD, timeout=2) as ser:
        print("--- Sending 16-bit Wakeup (0x8ABF) ---")
        ser.write(b'\x8A\xBF')
        
        # Wait for 16-bit ACK from CPU
        ack = ser.read(2)
        if ack != b'\x8A\xBF':
            print(f"Error: No ACK from MCU. Got: {ack.hex()}")
            return

        print("--- ACK Received. Preparing data... ---")
        size = os.path.getsize(BIN_FILE)
        ser.write(struct.pack('<I', size))
        
        with open(BIN_FILE, 'rb') as f:
            data = f.read()
            
        print("--- Transferring... ---")

        print("\n--- Sending End Signal (0xFEFE) ---")
        ser.write(b'\xFE\xFE')
        
        result = ser.read(30).decode(errors='ignore')
        print(f"--- MCU: {result} ---")

if __name__ == "__main__":
    import os
    upload()