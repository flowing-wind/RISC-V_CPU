/* main.c */

#define RESULT_ADDR ((volatile int*)0x2000)

int main() {
    int a = 10;
    int b = 20;
    int c = 0;

    c = a + b;
    c = c + 5;

    *RESULT_ADDR = c;

    while (1){
        // pass
    }

    return 0;
}
