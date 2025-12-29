#include <stdint.h>

// UART base address
#define UART_BASE 0x10000000

// AXI-Lite reg
#define UART_RX_FIFO    (*(volatile uint32_t *)(UART_BASE + 0X00))
#define UART_TX_FIFO    (*(volatile uint32_t *)(UART_BASE + 0X04))
#define UART_STATUS     (*(volatile uint32_t *)(UART_BASE + 0X08))
#define UART_CTRL       (*(volatile uint32_t *)(UART_BASE + 0X0C))

// Status reg
#define STS_TX_FULL     (1 << 3)
#define STS_TX_EMPTY    (1 << 2)
#define STS_RX_VALID    (1 << 0)

void uart_putc(char c) {
    while (UART_STATUS & STS_TX_FULL);
    UART_TX_FIFO = c;
}

void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

int main() {
    // delay for a while
    for (volatile int i=0; i<1000; i++);

    uart_puts("Hello World!");

    int cnt = 0;
    while (1) {
        if (UART_STATUS & STS_RX_VALID) {
            char c = UART_RX_FIFO;
            uart_putc(c);
        }
    }

    return 0;
}