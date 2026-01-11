#include <stdint.h>
#include "uart.h"


int is_digit(char c) {
    return (c >= '0' && c <= '9');
}

void print_int(int num) {
    char buf[16];
    int i = 0;
    
    if (num == 0) {
        uart_putc('0');
        return;
    }

    if (num < 0) {
        uart_putc('-');
        num = -num;
    }

    while (num > 0) {
        buf[i++] = (num % 10) + '0';
        num /= 10;
    }

    while (i > 0) {
        uart_putc(buf[--i]);
    }
}

void uart_readline(char *buffer, int max_len) {
    int idx = 0;
    char c;
    
    while (1) {
        int received = uart_getc();
        if (received != -1) {
            c = (char)received;
            uart_putc(c);

            if (idx == 0 && c == '\n') {
                continue;
            }

            if (c == '\r' || c == '\n') {
                buffer[idx] = '\0';
                uart_putc('\n');
                break;
            }

            if (idx < max_len - 1) {
                buffer[idx++] = c;
            }
        }
    }
}

int parse_numbers(const char *str, int *out_array, int max_count) {
    int count = 0;
    int current_num = 0;
    int has_digits = 0;

    while (*str) {
        if (is_digit(*str)) {
            current_num = current_num * 10 + (*str - '0');
            has_digits = 1;
        } else {
            if (has_digits) {
                if (count < max_count) {
                    out_array[count++] = current_num;
                }
                current_num = 0;
                has_digits = 0;
            }
        }
        str++;
    }
    if (has_digits && count < max_count) {
        out_array[count++] = current_num;
    }
    return count;
}

void bubble_sort(int *arr, int n) {
    for (int i = 0; i < n - 1; i++) {
        for (int j = 0; j < n - i - 1; j++) {
            if (arr[j] > arr[j + 1]) {
                int temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}


void main() {
    char input_buf[64];
    int numbers[16];
    int count;

    uart_init();
    
    for (volatile int i=0; i<1000; i++);

    uart_puts("\r\n=== Bubble Sort ===\r\n");
    
    while (1) {
        uart_puts("Enter numbers: ");
        
        uart_readline(input_buf, 64);
        
        count = parse_numbers(input_buf, numbers, 16);
        
        if (count > 0) {
            uart_puts("Sorting ");
            print_int(count);
            uart_puts(" numbers...\r\n");

            bubble_sort(numbers, count);

            uart_puts("Result: ");
            for (int i = 0; i < count; i++) {
                print_int(numbers[i]);
                uart_putc(' ');
            }
            uart_puts("\r\n\r\n");
        } else {
            uart_puts("No numbers found.\r\n");
        }
    }
}

void external_interrupt_handler() {
    uart_isr();
}
