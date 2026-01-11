#include "uart.h"

#define UART_BASE 0x10000000
#define UART_RX_FIFO    (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_TX_FIFO    (*(volatile uint32_t *)(UART_BASE + 0x04))
#define UART_STATUS     (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_CTRL       (*(volatile uint32_t *)(UART_BASE + 0x0C))

#define STS_RX_VALID    (1 << 0) // Rx FIFO Valid Data
#define STS_RX_FULL     (1 << 1) // Rx FIFO Full
#define STS_TX_EMPTY    (1 << 2) // Tx FIFO Empty
#define STS_TX_FULL     (1 << 3) // Tx FIFO Full
#define STS_INTR_EN     (1 << 4) // Intr Enabled

#define CTRL_RST_TX     (1 << 0) // Reset Tx FIFO
#define CTRL_RST_RX     (1 << 1) // Reset Rx FIFO
#define CTRL_INTR_EN    (1 << 4) // Enable Intr

// buffer
#define RX_BUFFER_SIZE  256
static volatile char rx_buffer[RX_BUFFER_SIZE];
static volatile int rx_head = 0;
static volatile int rx_tail = 0;

void uart_init(void) {
    // reset, disable interrupt
    UART_CTRL = CTRL_RST_RX | CTRL_RST_TX;
    // UART_CTRL = CTRL_INTR_EN; 

    rx_head = 0;
    rx_tail = 0;
}

void uart_putc(char c) {
    while (UART_STATUS & STS_TX_FULL);
    UART_TX_FIFO = c;
}

void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

int uart_getc(void) {
    if (UART_STATUS & STS_RX_VALID) {
        return (int)(UART_RX_FIFO & 0xFF);
    }
    
    return -1;
}

// ISR
void uart_isr(void) {
    uint32_t status = UART_STATUS;

    if (status & STS_RX_VALID) {
        while (UART_STATUS & STS_RX_VALID) {
            char c = (char)(UART_RX_FIFO & 0xFF);
            int next_head = (rx_head + 1) % RX_BUFFER_SIZE;
            if (next_head != rx_tail) {
                rx_buffer[rx_head] = c;
                rx_head = next_head;
            }
        }
    }

    if (status & STS_TX_EMPTY) {
        // Do Nothing
    }
}