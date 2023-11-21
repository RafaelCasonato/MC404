.section .text
.globl _start

_start:
    # Read decoded bits
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, decoded #  buffer to write the data
    li a2, 5  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall

    la a3, output
    la a0, decoded
    jal encode
        
    # Read encoded bits
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, encoded #  buffer to write the data
    li a2, 8  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall
    
    la a0, encoded
    jal decode

    li t0, 10
    sb t0, 14(a3)
    
    # Write
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output       # buffer
    li a2, 15           # size
    li a7, 64           # syscall write (64)
    ecall    

    # Exit
    li a0, 0
    li a7, 93
    ecall

decode:
    # Entrada a0 / Output a3
    lb t0, 2(a0)
    sb t0, 8(a3)
    lb t0, 4(a0)
    sb t0, 9(a3)
    lb t0, 5(a0)
    sb t0, 10(a3)
    lb t0, 6(a0)
    sb t0, 11(a3)
    li t0, 10
    sb t0, 12(a3)
    
    lb t0, (a0)
    addi t0, t0, -48 # P1
    lb t1, 1(a0) 
    addi t1, t1, -48 # P2
    lb t2, 2(a0) 
    addi t2, t2, -48 # D1
    lb t3, 3(a0) 
    addi t3, t3, -48 # P3
    lb t4, 4(a0) 
    addi t4, t4, -48 # D2
    lb t5, 5(a0) 
    addi t5, t5, -48 # D3
    lb t6, 6(a0) 
    addi t6, t6, -48 # D4
    
    # P1
    xor s0, t0, t2
    xor s0, s0, t4
    xor s0, s0, t6

    # P2
    xor s1, t1, t2
    xor s1, s1, t5
    xor s1, s1, t6

    # P3
    xor s2, t3, t4
    xor s2, s2, t5
    xor s2, s2, t6

    add s0, s0, s1
    add s0, s0, s2

    bnez s0, error
    beqz s0, not_error
    ret

not_error:
    li t0, 48
    sb t0, 13(a3)
    ret
error:
    li t0, 49
    sb t0, 13(a3)
    ret

encode:
    # Entrada a0 / Output a3
    lb t0, (a0)
    addi t0, t0, -48 # D1
    lb t1, 1(a0) 
    addi t1, t1, -48 # D2
    lb t2, 2(a0)
    addi t2, t2, -48 # D3
    lb t3, 3(a0)
    addi t3, t3, -48 # D4

    # P1
    xor s0, t0, t1
    xor s0, s0, t3
    addi s0, s0, 48
    sb s0, 0(a3)

    # P2
    xor s0, t0, t2
    xor s0, s0, t3
    addi s0, s0, 48
    sb s0, 1(a3)
    
    # P3
    xor s0, t1, t2
    xor s0, s0, t3
    addi s0, s0, 48
    sb s0, 3(a3)

    addi t0, t0, 48 
    addi t1, t1, 48 
    addi t2, t2, 48 
    addi t3, t3, 48

    sb t0, 2(a3)
    sb t1, 4(a3)
    sb t2, 5(a3)
    sb t3, 6(a3)
    li t0, 10
    sb t0, 7(a3)
    ret

.section .data:
decoded: .skip 0x5
encoded: .skip 0x8
output: .skip 0xf