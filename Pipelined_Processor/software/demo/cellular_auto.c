#include <stdint.h>
#include "uart.h"

#define GRID_SIZE     10      
#define DELAY_CYCLES  5000000 

#define CHAR_LIVE     'O'     
#define CHAR_DEAD     '.'     

#define STATUS_DEAD   0
#define STATUS_ALIVE  1

uint8_t grid[GRID_SIZE][GRID_SIZE];
uint8_t next_grid[GRID_SIZE][GRID_SIZE];
uint32_t frame_count = 0;


void delay() {
    for (volatile int i = 0; i < DELAY_CYCLES; i++) {
        __asm__ volatile ("nop");
    }
}

void init_grid() {
    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            grid[i][j] = STATUS_DEAD;
        }
    }

    // Glider
    grid[1][2] = STATUS_ALIVE;
    grid[2][3] = STATUS_ALIVE;
    grid[3][1] = STATUS_ALIVE;
    grid[3][2] = STATUS_ALIVE;
    grid[3][3] = STATUS_ALIVE;
}

void draw_grid() {

    uart_puts("------\r\n");

    for (int i = 0; i < GRID_SIZE; i++) {
        uart_puts("  "); 
        for (int j = 0; j < GRID_SIZE; j++) {
            if (grid[i][j]) {
                uart_putc(CHAR_LIVE);
            } else {
                uart_putc(CHAR_DEAD);
            }
            uart_putc(' '); 
        }
        uart_puts("\r\n");
    }
}

int count_neighbors(int r, int c) {
    int count = 0;
    
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            if (i == 0 && j == 0) continue;

            int nr = r + i;
            int nc = c + j;

            if (nr < 0) nr = GRID_SIZE - 1;
            else if (nr >= GRID_SIZE) nr = 0;

            if (nc < 0) nc = GRID_SIZE - 1;
            else if (nc >= GRID_SIZE) nc = 0;

            if (grid[nr][nc] != STATUS_DEAD) {
                count++;
            }
        }
    }
    return count;
}

void update_grid() {
    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            int neighbors = count_neighbors(i, j);
            int is_alive = grid[i][j];

            if (is_alive) {
                if (neighbors < 2 || neighbors > 3) {
                    next_grid[i][j] = STATUS_DEAD;
                } else {
                    next_grid[i][j] = STATUS_ALIVE;
                }
            } else {
                if (neighbors == 3) {
                    next_grid[i][j] = STATUS_ALIVE;
                } else {
                    next_grid[i][j] = STATUS_DEAD;
                }
            }
        }
    }

    for (int i = 0; i < GRID_SIZE; i++) {
        for (int j = 0; j < GRID_SIZE; j++) {
            grid[i][j] = next_grid[i][j];
        }
    }
}

void main() {
    uart_init();
    
    for (volatile int i=0; i<1000; i++);

    uart_puts("Game of Life\r\n");

    init_grid();

    while (1) {
        draw_grid();
        delay();
        update_grid();
    }
}

void external_interrupt_handler() {
    // None
}
