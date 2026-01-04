#ifndef UART_H
#define UART_H

#include <stdint.h>

#define UART_BASE       0x10000000

#define UART_REG_RX_FIFO    0x00
#define UART_REG_TX_FIFO    0x04
#define UART_REG_STATUS     0x08
#define UART_REG_CTRL       0x0C

#define UART_STS_RX_READY   (1 << 0)
#define UART_STS_TX_EMPTY   (1 << 2)
#define UART_STS_TX_FULL    (1 << 3)

#define UART_READ_REG(base, offset)  (*(volatile uint32_t *)((base) + (offset)))
#define UART_WRITE_REG(base, offset, val)  (*(volatile uint32_t *)((base) + (offset)) = (val))

#define CMD_WAKE_H 0x8A
#define CMD_WAKE_L 0xBF
#define CMD_READY  0x5A

void UART_Init(uint32_t base_addr, int interrupt_en);
void UART_SendChar(uint32_t base_addr, char ch);
void UART_SendString(uint32_t base_addr, const char *s);

int  UART_GetChar(uint32_t base_addr);  // User
void UART_User_ISR(void);               // ISR

#endif
