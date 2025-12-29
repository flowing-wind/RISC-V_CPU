import serial
import struct
import os
import time

# --- Configuration ---
SERIAL_PORT = 'COM4'
BAUD_RATE   = 9600
BIN_FILE    = 'main.bin'
TRIGGER_CMD = b'\x7F'  # Wake up command

def upload():
    if not os.path.exists(BIN_FILE):
        print(f"Error: {BIN_FILE} not found.")
        return

    file_size = os.path.getsize(BIN_FILE)
    
    try:
        # 1. Initialize Serial Port
        with serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=2) as ser:
            print(f"--- Port {SERIAL_PORT} opened. Sending trigger {TRIGGER_CMD.hex()}... ---")
            
            # 2. Send Trigger Character to interrupt App or catch Bootloader window
            for _ in range(5):
                ser.write(b'\x7F')
                time.sleep(0.01)
            
            # 3. Wait for 'R' (Ready) signal from Bootloader
            start_time = time.time()
            ready = False
            while time.time() - start_time < 5:
                if ser.read(1) == b'R':
                    ready = True
                    print("--- Handshake 'R' received! Starting upload ---")
                    break
            
            if not ready:
                print("--- Error: No response from MCU. Check hardware or baud rate. ---")
                return

            # 4. Send 4-byte Program Size (Little Endian)
            # <I means Little-Endian unsigned int (4 bytes)
            size_bytes = struct.pack('<I', file_size)
            ser.write(size_bytes)
            print(f"--- Size sent: {file_size} bytes ---")

            # 5. Send Binary Content
            with open(BIN_FILE, 'rb') as f:
                content = f.read()

            print("--- Transferring data... ---")
            for i, byte in enumerate(content):
                # Write one byte
                ser.write(bytes([byte]))
                
                # Check for progress dot '.' sent every 128 bytes
                if (i + 1) % 128 == 0:
                    dot = ser.read(1)
                    if dot == b'.':
                        print(".", end='', flush=True)

            # 6. Wait for final jump confirmation
            print("\n--- Upload finished! Waiting for 'Jumping...' ---")
            msg = ser.read(20).decode(errors='ignore')
            if "Jumping" in msg:
                print(f"--- MCU Response: {msg.strip()} ---")
                print("--- Application should be running now. ---")

    except Exception as e:
        print(f"\nAn error occurred: {e}")

if __name__ == "__main__":
    upload()