.align 4
.section .text
.globl _start
_start: 
    lw x1, ONE
_halt: 
    beq x1, x1, _halt 
.section .rodata
.balign 256
ONE:    .word 0x00000001