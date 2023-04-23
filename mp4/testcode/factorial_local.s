factorial_local.s:
.align 4
.section .text
.globl factorial_local
factorial_local:
# Register a0 holds the input value
# Register t0-t6 are caller-save, so you may use them without saving
# Return value need to be put in register a0

# Register t0 holds accumulated multiplication
# Register t1 holds the counter (i = 1; i <= a0; i++)
# Register t2 holds the stopping condition (a0 + 1) -> i >= t2 then we're done
# Register t4 is hardcoded 1, used to skip iteration i = 1 
# Register t3 and t5 are temps used in multiplication algorithm

# Initialization 
    lw   a0, eleven
    lw   t0, one 
    lw   t1, one
    addi t2, a0, 1 
    lw   t4, one

fact_loop: 
    bge t1, t2, ret
    beq t1, t4, increment_i # skip mult if i = 1 
    beq t1, t1, mult
increment_i: 
    addi t1, t1, 1
    beq t1, t1, fact_loop

mult: 
    addi t3, t1, 0           # t3 = i 
    addi t5, t0, 0           # t5 = temp sum
mult_loop:
    add  t0, t0, t5          # build the sum 
    addi t3, t3, -1          # decrement t3
    bne  t3, t4, mult_loop   # counter != 1 -> then continue mult
    beq  t0, t0, increment_i

ret:
    addi a0, t0, 0 
    # jr ra # Register ra holds the return address
halt:
    beq a0, a0, halt

.section .rodata
one:           .word 0x1
eleven:         .word 0x1