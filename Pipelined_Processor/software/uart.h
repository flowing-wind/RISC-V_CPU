#ifndef UART_H
#define UART_H

#include <stdint.h>


void uart_init(void);

// send char
void uart_putc(char c);

// send string
void uart_puts(const char *str);


//  >= 0 : received char
//  -1   : buffer empty
int uart_getc(void);

// UART ISR
void uart_isr(void);

#endif
