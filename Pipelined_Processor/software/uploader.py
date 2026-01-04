import serial
import struct
import time
import os

PORT = 'COM4'
BAUD = 9600
BIN_FILE = 'main.bin'

def upload():
    if not os.path.exists(BIN_FILE):
        print(f"Error: {BIN_FILE} not found.")
        return

    with serial.Serial(PORT, BAUD, timeout=2) as ser:
        print("--- Step 1: Triggering MCU Jump ---")
        ser.write(b'\x8A\xBF')
        ser.reset_input_buffer()

        print("--- Step 2: Sending Wakeup to Bootloader ---")
        ser.write(b'\x8A\xBF')
        
        ack = ser.read(2)
        if ack != b'\x8A\xBF':
            print(f"Error: No ACK. Got: {ack.hex()}")
            return

        print("--- ACK Received. Sending Data ---")
        time.sleep(0.05)
        size = os.path.getsize(BIN_FILE)
        ser.write(struct.pack('<I', size))
        
        with open(BIN_FILE, 'rb') as f:
            data = f.read()
            
        for i, byte in enumerate(data):
            ser.write(bytes([byte]))
        ser.flush()
        
        print("\n--- Transfer Complete. Waiting for MCU response ---")
        ser.timeout = 5
        result = ser.read(50).decode(errors='ignore')
        print(f"--- MCU: {result} ---")

if __name__ == "__main__":
    upload()