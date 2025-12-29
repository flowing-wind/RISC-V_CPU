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

#define BUFFER_SIZE 64

uint8_t rx_buffer[BUFFER_SIZE];
volatile uint16_t head = 0;
volatile uint16_t tail = 0;

/* Check if App has received normal data */
int app_uart_available() {
    return head != tail;
}

/* Read data from software buffer */
uint8_t app_uart_read() {
    if (head == tail) return 0;
    uint8_t data = rx_buffer[tail];
    tail = (tail + 1) % BUFFER_SIZE;
    return data;
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

void main() {
    UART_CTRL = 0X13;

    uart_puts("Hello World!");

    while (1) {
        // None
    }
}

void external_interrupt_handler() {
    while (UART_STATUS & STS_RX_VALID) {
        uint8_t cmd = (uint8_t)(UART_RX_FIFO & 0xFF);

        if (cmd == 0x7F) {
            uart_puts("Restarting to Bootloader...");
            // no interrupt enabled
            __asm__ volatile ("csrci mstatus, 8");
            void (*bootloader)(void) = (void (*)(void))0x00000000;
            bootloader();
        }
        else {
            uint16_t next_head = (head + 1) % BUFFER_SIZE;
            if (next_head != tail) {
                rx_buffer[head] = cmd;
                head = next_head;
            }
        }
    }
}
