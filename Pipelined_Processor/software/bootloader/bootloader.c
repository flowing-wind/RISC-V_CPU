#include "uart.h"

#define APP_ENTRY_ADDR 0x00001000

void main() {
    // ISP  -->  no interrupt
    UART_Init(UART_ISP_BASE, 0);

    // Ready Signal
    UART_SendChar(UART_ISP_BASE, CMD_READY);
    
    uint32_t *app_entry_ptr = (uint32_t*)APP_ENTRY_ADDR;
    int force_isp = 0;
    int isp_step = 0;

    // wait for handshake
    // uint32_t wait_timeout = (*app_entry_ptr == 0x0) ? 0xFFFFFFFF : 20000000;
    uint32_t wait_timeout = 0xFFFFFFFF;

    for (volatile uint32_t i = 0; i < wait_timeout; i++) {
        if (UART_READ_REG(UART_ISP_BASE, UART_REG_STATUS) & UART_STS_RX_READY) {
            uint8_t data = (uint8_t)UART_READ_REG(UART_ISP_BASE, UART_REG_RX_FIFO);
            
            // Sequence: CMD_WAKE_H -> CMD_WAKE_L
            if (isp_step == 0 && data == CMD_WAKE_H) {
                isp_step = 1;
            } else if (isp_step == 1 && data == CMD_WAKE_L) {
                force_isp = 1;
                break; // handshake succeed
            } else {
                isp_step = 0;
            }
        }
    }

    // Jump to APP
    if (!force_isp && *app_entry_ptr != 0x0) {
        ((void (*)(void))APP_ENTRY_ADDR)(); 
    }

    // Enter ISP: Clear RX_FIFO
    while (UART_READ_REG(UART_ISP_BASE, UART_REG_STATUS) & UART_STS_RX_READY) {
        volatile uint32_t dump = UART_READ_REG(UART_ISP_BASE, UART_REG_RX_FIFO);
    }

    // ACK
    UART_SendChar(UART_ISP_BASE, CMD_WAKE_H);
    UART_SendChar(UART_ISP_BASE, CMD_WAKE_L);

    // prog_size
    uint32_t prog_size = 0;
    for(int i = 0; i < 4; i++) {
        ((uint8_t*)&prog_size)[i] = (uint8_t)UART_PollChar(UART_ISP_BASE);
    }

    // write to mem
    uint8_t *write_ptr = (uint8_t *)APP_ENTRY_ADDR;
    for (uint32_t i = 0; i < prog_size; i++) {
        write_ptr[i] = (uint8_t)UART_PollChar(UART_ISP_BASE);
    }

    UART_SendString(UART_ISP_BASE, "\nUpdate Done. Jumping...\n");

    while (!(UART_READ_REG(UART_ISP_BASE, UART_REG_STATUS) & UART_STS_TX_EMPTY));
    
    ((void (*)(void))APP_ENTRY_ADDR)();
}
