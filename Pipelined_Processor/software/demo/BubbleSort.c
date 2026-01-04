#include "uart.h"

// ==========================================
// 1. 基础轮询驱动函数 (覆盖原有的中断依赖函数)
// ==========================================

// 检查是否有数据可读
int UART_RxReady(uint32_t base_addr) {
    uint32_t status = UART_READ_REG(base_addr, UART_REG_STATUS);
    return (status & UART_STS_RX_READY);
}

// 阻塞式读取一个字符 (轮询模式)
char UART_PollChar(uint32_t base_addr) {
    // 等待直到 Rx Ready
    while (!UART_RxReady(base_addr));
    return (char)UART_READ_REG(base_addr, UART_REG_RX_FIFO);
}

// 发送整数 (把 int 转成 ASCII 发送)
void UART_SendInt(uint32_t base_addr, int num) {
    char buf[16];
    int i = 0;
    
    if (num == 0) {
        UART_SendChar(base_addr, '0');
        return;
    }

    // 提取每一位
    while (num > 0) {
        buf[i++] = (num % 10) + '0';
        num /= 10;
    }

    // 反向发送
    while (i > 0) {
        UART_SendChar(base_addr, buf[--i]);
    }
}

// ==========================================
// 2. 字符串处理与解析
// ==========================================

#define MAX_CMD_LEN 64
#define MAX_NUMS    20

// 从串口读取一行数据，遇到回车结束
int UART_ReadLine(uint32_t base_addr, char* buffer, int max_len) {
    int idx = 0;
    char c;
    
    while (1) {
        c = UART_PollChar(base_addr);
        
        // 如果收到回车(\r) 或 换行(\n)，结束输入
        if (c == '\r' || c == '\n') {
            UART_SendString(base_addr, "\r\n"); // 换行回显
            break;
        }
        
        // 正常字符：存入缓冲区并回显
        if (idx < max_len - 1) {
            buffer[idx++] = c;
            UART_SendChar(base_addr, c); // 实时回显字符，让你看到自己输了什么
        }
    }
    buffer[idx] = '\0'; // 添加字符串结束符
    return idx;
}

// 解析字符串：把 "6 5 2" 解析成 int 数组
int ParseString(char* str, int* arr, int max_nums) {
    int count = 0;
    int current_num = 0;
    int is_parsing_num = 0; // 状态标记
    char* p = str;

    while (*p != '\0' && count < max_nums) {
        if (*p >= '0' && *p <= '9') {
            // 是数字字符
            current_num = current_num * 10 + (*p - '0');
            is_parsing_num = 1;
        } else {
            // 是分隔符（空格或其他）
            if (is_parsing_num) {
                arr[count++] = current_num;
                current_num = 0;
                is_parsing_num = 0;
            }
        }
        p++;
    }
    // 处理最后一个数字（如果字符串不以空格结尾）
    if (is_parsing_num && count < max_nums) {
        arr[count++] = current_num;
    }
    
    return count; // 返回找到的数字个数
}

// ==========================================
// 3. 冒泡排序算法
// ==========================================
void BubbleSort(int* arr, int n) {
    int i, j, temp;
    for (i = 0; i < n - 1; i++) {
        for (j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                // 交换
                temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

// ==========================================
// 4. 主函数
// ==========================================
void main() {
    char rx_buffer[MAX_CMD_LEN];
    int  num_array[MAX_NUMS];
    int  num_count;

    // 初始化：传入0禁用中断，使用纯轮询
    UART_Init(UART_BASE, 0);

    UART_SendString(UART_BASE, "\n=== Sorter App Ready ===\n");
    UART_SendString(UART_BASE, "Enter numbers (e.g. 6 5 2 7): \n");

    while (1) {
        UART_SendString(UART_BASE, ">> "); // 提示符
        
        // 1. 读取一行输入
        UART_ReadLine(UART_BASE, rx_buffer, MAX_CMD_LEN);
        
        // 2. 解析数字
        num_count = ParseString(rx_buffer, num_array, MAX_NUMS);
        
        if (num_count > 0) {
            UART_SendString(UART_BASE, "Sorting...\n");
            
            // 3. 排序
            BubbleSort(num_array, num_count);
            
            // 4. 输出结果
            UART_SendString(UART_BASE, "Result: ");
            for (int i = 0; i < num_count; i++) {
                UART_SendInt(UART_BASE, num_array[i]);
                UART_SendChar(UART_BASE, ' ');
            }
            UART_SendString(UART_BASE, "\n\n");
        } else {
            UART_SendString(UART_BASE, "No numbers found.\n");
        }
    }
}

// 中断处理函数留空，因为我们使用了轮询
void UART_ISR_Handler() {
    // Empty
}