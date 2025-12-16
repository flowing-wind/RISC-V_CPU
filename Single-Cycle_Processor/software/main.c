/* main.c */

#define LED_ADDR 0x80000000
#define LED_REG  (*((volatile int*)LED_ADDR))

void delay(int count) {
    volatile int i = 0;
    while (i < count) {
        i ++;
    }
}

int main() {
    int counter = 0;
    while (1) {
        LED_REG = 1;
        delay(500000);

        LED_REG = 0;
        delay(500000);
    }
    
    return 0;
}
