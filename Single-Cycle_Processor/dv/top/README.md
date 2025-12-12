Process:

1. test_top.py --> generate_random_asm to generate *instr.asm* in **Current DIR**
2. copy *instr.asm* to *asm* folder and use asm.py to generate *instr.txt* (hex file)
3. copy *instr.txt* to *dv/top* folder
4. delete .asm .txt file in *asm* folder, only kept in *dv/top*
5. run simulation in the *dv/top* folder
6. keep all the generated file in the *dv/top* folder and delete them every tiem before **make**