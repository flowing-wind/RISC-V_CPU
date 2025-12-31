#include "uart.h"

void main() {
    UART_Init(0); // disable interrupt
    uint32_t *app_entry_ptr = (uint32_t*)APP_ENTRY_ADDR;
    int force_isp = 0;

    // ISP
    if (*app_entry_ptr == 0x0) {
        while (1) {
            if (UART_STATUS & UART_STS_RX_READY) {
                if ((uint8_t)UART_RX_FIFO == CMD_WAKE_H) {
                    if ((uint8_t)UART_RX_FIFO == CMD_WAKE_L) { force_isp = 1; break; }
                }
            }
        }
    } else {
        // load window
        for (volatile uint32_t i = 0; i < 500000; i++) {
            if (UART_STATUS & UART_STS_RX_READY) {
                if ((uint8_t)UART_RX_FIFO == CMD_WAKE_H) {
                    if ((uint8_t)UART_RX_FIFO == CMD_WAKE_L) { force_isp = 1; break; }
                }
            }
        }
    }

    if (!force_isp) {
        ((void (*)(void))APP_ENTRY_ADDR)(); 
    }

    // ACK
    UART_SendChar(CMD_WAKE_H);
    UART_SendChar(CMD_WAKE_L);

    uint32_t prog_size = 0;
    for(int i = 0; i < 4; i++) {
        while (!(UART_STATUS & UART_STS_RX_READY));
        ((uint8_t*)&prog_size)[i] = (uint8_t)UART_RX_FIFO;
    }

    uint8_t *write_ptr = (uint8_t *)APP_ENTRY_ADDR;
    for (uint32_t i = 0; i < prog_size; i++) {
        while (!(UART_STATUS & UART_STS_RX_READY));
        write_ptr[i] = (uint8_t)UART_RX_FIFO;
        if (i % 128 == 0) UART_SendChar('.');
    }

    UART_SendString("\nJump...");
    UART_Flush();
    ((void (*)(void))APP_ENTRY_ADDR)();
}
