#include "uart.h"

void main() {
    UART_Init(0); 
    uint32_t *app_entry_ptr = (uint32_t*)APP_ENTRY_ADDR;
    int force_isp = 0;
    int isp_step = 0;

    uint32_t wait_timeout = (*app_entry_ptr == 0x0) ? 0xFFFFFFFF : 2000000;

    for (volatile uint32_t i = 0; i < wait_timeout; i++) {
        if (UART_STATUS & UART_STS_RX_READY) {
            uint8_t data = (uint8_t)UART_RX_FIFO;
            
            if (isp_step == 0 && data == CMD_WAKE_H) {
                isp_step = 1;
            } else if (isp_step == 1 && data == CMD_WAKE_L) {
                force_isp = 1;
                break;
            } else {
                isp_step = 0;
            }
        }
    }

    if (!force_isp && *app_entry_ptr != 0x0) {
        ((void (*)(void))APP_ENTRY_ADDR)(); 
    }

    while (UART_STATUS & UART_STS_RX_READY) {
        volatile uint8_t dump = UART_RX_FIFO;
    }

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
    }

    UART_SendString("\nUpdate Done. Jumping...");
    UART_Flush();
    ((void (*)(void))APP_ENTRY_ADDR)();
}
