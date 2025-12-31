#include "uart.h"

#define RX_BUF_SIZE 128
static uint8_t rx_buffer[RX_BUF_SIZE];
static volatile uint16_t rx_head = 0;
static volatile uint16_t rx_tail = 0;

void UART_Init(uint32_t interrupt_en) {
    if (interrupt_en) {
        UART_CTRL = 0x13;
    } else {
        UART_CTRL = 0x00;
    }
}

void UART_SendChar(uint8_t ch) {
    while (UART_STATUS & UART_STS_TX_FULL);
    UART_TX_FIFO = ch;
}

void UART_SendString(const char *s) {
    while (*s) UART_SendChar(*s++);
}

int UART_ReceiveChar(uint8_t *pData) {
    if (rx_head == rx_tail) return 0;
    *pData = rx_buffer[rx_tail];
    rx_tail = (rx_tail + 1) % RX_BUF_SIZE;
    return 1;
}

// wait to sned all the character
void UART_Flush(void) {
    while (!(UART_STATUS & UART_STS_TX_EMPTY));
}

void UART_Internal_Push(uint8_t data) {
    uint16_t next = (rx_head + 1) % RX_BUF_SIZE;
    if (next != rx_tail) {
        rx_buffer[rx_head] = data;
        rx_head = next;
    }
}