// [main.c]
#include "uart.h"

void main() {
    // USER UART  -->  need interrupt
    UART_Init(UART_BASE, 1);

    UART_SendString(UART_BASE, "System Started.\n");

    while(1) {
        int c = UART_GetChar(UART_BASE);
        
        UART_SendString(UART_BASE, "Received: ");
        UART_SendChar(UART_BASE, (char)c);
        UART_SendChar(UART_BASE, '\n');
    }
}

// ISR entry
void UART_ISR_Handler() {
    UART_User_ISR();
}