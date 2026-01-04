// [main.c]
#include "uart.h"

void main() {
    // disable interrupt here
    UART_Init(UART_BASE, 0);

    UART_SendString(UART_BASE, "System Started.\n");

    while(1) {
        uint32_t status = UART_READ_REG(UART_BASE, UART_REG_STATUS);

        if (status & UART_STS_RX_READY) {
            int c = UART_GetChar(UART_BASE);
            
            UART_SendString(UART_BASE, "Received: ");
            UART_SendChar(UART_BASE, (char)c);
            UART_SendChar(UART_BASE, '\n');
        }
    }
}

// ISR entry
void UART_ISR_Handler() {
    UART_User_ISR();
}