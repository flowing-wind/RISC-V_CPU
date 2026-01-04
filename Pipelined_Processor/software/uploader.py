import serial
import struct
import time
import os
import sys

PORT = 'COM4'
BAUD = 9600
BIN_FILE = 'main.bin'

def upload():
    if not os.path.exists(BIN_FILE):
        print(f"Error: {BIN_FILE} not found.")
        return

    try:
        ser = serial.Serial(PORT, BAUD, timeout=None)
    except Exception as e:
        print(f"无法打开串口 {PORT}: {e}")
        return

    print(f"--- 正在监听 {PORT}... ---")

    # === 步骤 1: 等待 Bootloader 发送 'Ready' 信号 (0x5A) ===
    while True:
        try:
            # 读取 1 字节
            byte = ser.read(1) 
            if byte == b'\x5A': # 收到 CMD_READY
                print("\n[检测到复位信号] 处理器已就绪！")
                break
            else:
                # 可能是之前的垃圾数据，打印出来看看
                print(f"Ignored: {byte.hex()}") 
                pass
        except KeyboardInterrupt:
            print("\n用户取消")
            return

    # === 步骤 2: 立即发送握手指令 ===
    print("--- 发送握手请求... ---")
    ser.write(b'\x8A\xBF') # CMD_WAKE_H + CMD_WAKE_L
    
    # === 步骤 3: 确认握手回显 (ACK) ===
    # Bootloader 现在的逻辑是握手成功后会回发 0x8A 0xBF
    ser.timeout = 2 # 设置超时防止卡死
    ack = ser.read(2)
    print (f"received: {ack.hex()}")
    if ack != b'\x8A\xBF':
        print(f"Error: 握手失败，未收到ACK。收到: {ack.hex()}")
        return

    print("--- 握手成功！开始发送固件... ---")
    
    # === 步骤 4: 发送大小和数据 (保持原有逻辑) ===
    size = os.path.getsize(BIN_FILE)
    print(f"固件大小: {size} bytes")
    ser.write(struct.pack('<I', size))
    
    with open(BIN_FILE, 'rb') as f:
        data = f.read()
        
    # 批量发送比逐字节发送快
    # 如果你的 FIFO 只有 16 字节，且没有流控，建议还是分块发送并加一点延时
    CHUNK_SIZE = 64 
    for i in range(0, len(data), CHUNK_SIZE):
        chunk = data[i:i+CHUNK_SIZE]
        ser.write(chunk)
        # 简单延时防止爆 FIFO (根据波特率调整)
        time.sleep(0.01) 
    
    ser.flush()
    print("\n--- 发送完成，等待跳转 ---")
    
    # 读取 Bootloader 最后的打印信息
    result = ser.read(100).decode(errors='ignore')
    print(f"MCU Message: {result}")
    
    ser.close()

if __name__ == "__main__":
    upload()
    