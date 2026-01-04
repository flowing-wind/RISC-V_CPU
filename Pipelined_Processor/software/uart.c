#include "uart.h"

// Used in USER UART only
#define RX_BUF_SIZE 128
static uint8_t user_rx_buffer[RX_BUF_SIZE];
static volatile uint16_t user_rx_head = 0;
static volatile uint16_t user_rx_tail = 0;

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

int UART_GetChar(uint32_t base_addr) {
    if (base_addr == UART_BASE) {
        // wait for buffer
        while (user_rx_head == user_rx_tail);
        
        uint8_t data = user_rx_buffer[user_rx_tail];
        user_rx_tail = (user_rx_tail + 1) % RX_BUF_SIZE;
        return (int)data;
    } else {
        return 0;
    }
}

// ISR
void UART_User_ISR(void) {
    uint32_t status = UART_READ_REG(UART_BASE, UART_REG_STATUS);
    
    // USER UART received data
    if (status & UART_STS_RX_READY) {
        uint8_t ch = (uint8_t)UART_READ_REG(UART_BASE, UART_REG_RX_FIFO);
        
        // save to buffer
        uint16_t next_head = (user_rx_head + 1) % RX_BUF_SIZE;
        if (next_head != user_rx_tail) {
            user_rx_buffer[user_rx_head] = ch;
            user_rx_head = next_head;
        } else {
            // Overflow --> throw data
        }
    }
}
