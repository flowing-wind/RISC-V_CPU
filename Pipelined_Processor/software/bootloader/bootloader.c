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

// APP ENTRY ADDR
#define APP_ENTRY_ADDR 0x00001000

void uart_putc(char c) {
    while (UART_STATUS & STS_TX_FULL);
    UART_TX_FIFO = c;
}

void uart_puts(const char *str) {
    while (*str) {
        uart_putc(*str++);
    }
}

char uart_getc() {
    while (!(UART_STATUS & STS_RX_VALID));
    return (char)(UART_RX_FIFO & 0XFF);
}

void main() {
    int jump2app = 1;
    for (uint32_t i = 0; i < 5000000; i ++) {    // short window for loading prog
        if (UART_STATUS & STS_RX_VALID) {
            if (UART_RX_FIFO == 0x7F) {
                jump2app = 0;
                break;
            }
        }
    }

    void (*app_entry)(void) = (void (*)(void))APP_ENTRY_ADDR;

    if (jump2app) {
        if (*(uint32_t*)APP_ENTRY_ADDR != 0x0) {
            app_entry ();
        }
    }


    uint8_t *app_ptr = (uint8_t *)APP_ENTRY_ADDR;
    uint32_t prog_size = 0;

    uart_putc('R');     // Ready to receive prog

    for(int i = 0; i < 4; i++) {
        ((uint8_t*)&prog_size)[i] = uart_getc();
    }

    for(uint32_t i = 0; i < prog_size; i++) {
        app_ptr[i] = uart_getc();
        if (i % 128 == 0) uart_putc('.');
    }

    uart_putc('\n');
    uart_puts("Jumping...");
    app_entry();
}
