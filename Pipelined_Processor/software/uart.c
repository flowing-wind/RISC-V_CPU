#include "uart.h"

void UART_Init(uint32_t base_addr, int interrupt_en) {
    if (interrupt_en) {
        UART_WRITE_REG(base_addr, UART_REG_CTRL, 0x13);
    } else {
        UART_WRITE_REG(base_addr, UART_REG_CTRL, 0x00);
    }
}

void UART_SendChar(uint32_t base_addr, char ch) {
    while (UART_READ_REG(base_addr, UART_REG_STATUS) & UART_STS_TX_FULL);
    UART_WRITE_REG(base_addr, UART_REG_TX_FIFO, ch);
}

void UART_SendString(uint32_t base_addr, const char *s) {
    while (*s) {
        UART_SendChar(base_addr, *s++);
    }
}

