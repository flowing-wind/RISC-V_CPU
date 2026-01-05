#include <stdint.h>
#include "uart.h"

void main() {
    uart_init();
    
    for (volatile int i=0; i<1000; i++);

    uart_puts("Hello World!\r\n");

    char line_buf[64];
    int line_idx = 0;

    while (1) {
        int c = uart_getc();

        if (c != -1) {
            char ch = (char)c;

            uart_putc(ch);
        }

    }
}

void external_interrupt_handler() {
    uart_isr();
}
