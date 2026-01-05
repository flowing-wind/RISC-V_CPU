#include <stdint.h>
#include "uart.h"

#define DELAY_CYCLES  8000000 

void delay() {
    for (volatile int i = 0; i < DELAY_CYCLES; i++) {
        __asm__ volatile ("nop");
    }
}

void print_uint(uint32_t num) {
    char buf[16];
    int i = 0;
    
    if (num == 0) {
        uart_putc('0');
        return;
    }

    while (num > 0) {
        buf[i++] = (num % 10) + '0';
        num /= 10;
    }

    while (i > 0) {
        uart_putc(buf[--i]);
    }
}


void main() {
    uart_init();
    
    for (volatile int i=0; i<1000; i++);

    uart_puts("\r\n=== Fibonacci Generator ===\r\n");

    uint32_t a = 0;
    uint32_t b = 1;
    uint32_t next;

    while (1) {
        print_uint(b);
        uart_puts("\r\n");

        delay();

        next = a + b;

        if (next < a) {
            uart_puts("--- Overflow! Resetting sequence ---\r\n\r\n");
            delay();
            delay();
            
            a = 0;
            b = 1;
        } else {
            a = b;
            b = next;
        }
    }
}

void external_interrupt_handler() {
    // Do Nothing
}
