#ifndef UART_H
#define UART_H

#include <stdint.h>

#define UART_BASE      0x10000000
#define UART_RX_FIFO   (*(volatile uint32_t *)(UART_BASE + 0x00))
#define UART_TX_FIFO   (*(volatile uint32_t *)(UART_BASE + 0x04))
#define UART_STATUS    (*(volatile uint32_t *)(UART_BASE + 0x08))
#define UART_CTRL      (*(volatile uint32_t *)(UART_BASE + 0x0C))

#define UART_STS_RX_READY (1 << 0)
#define UART_STS_TX_EMPTY (1 << 2)
#define UART_STS_TX_FULL  (1 << 3)

#define CMD_WAKE_H 0x8A
#define CMD_WAKE_L 0xBF
#define CMD_END_H  0xFE
#define CMD_END_L  0xFE
#define APP_ENTRY_ADDR 0x00001000

void UART_Init(uint32_t interrupt_en);
void UART_SendChar(uint8_t ch);
void UART_SendString(const char *s);
int  UART_ReceiveChar(uint8_t *pData);
void UART_Flush(void);

#endif
