#include "uart.h"

static int isp_state = 0;

void main() {
    UART_Init(1);
    UART_SendString("App Running...\n");

    uint8_t user_data;
    while (1) {
        if (UART_ReceiveChar(&user_data)) {
            UART_SendChar('[');
            UART_SendChar(user_data);
            UART_SendChar(']');
        }
    }
}

void external_interrupt_handler() {
    uint32_t status = UART_STATUS;

    // RX FIFO interrupt
    if (status & UART_STS_RX_READY) {
        while (UART_STATUS & UART_STS_RX_READY) {
            uint8_t data = (uint8_t)(UART_RX_FIFO & 0xFF);

            if (isp_state == 0 && data == CMD_WAKE_H) {
                isp_state = 1;
            } else if (isp_state == 1 && data == CMD_WAKE_L) {
                UART_SendString("\nISP Triggered!");
                UART_Flush();
                __asm__ volatile ("csrci mstatus, 8"); // disable interrupt
                ((void (*)(void))0x00000000)(); 
            } else {
                isp_state = 0;
                void UART_Internal_Push(uint8_t data);
                UART_Internal_Push(data);
            }
        }
    }
}