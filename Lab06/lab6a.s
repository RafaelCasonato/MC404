.section .text
.globl _start
_start:
    # Read
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, input_address #  buffer to write the data
    li a2, 20  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall

    la a2, output_address
    la a0, input_address
    # Primeiro valor 
    jal char_to_int 
    jal do_babylonian
    jal int_to_char

    # Segundo valor
    addi a2, a2, 5
    addi a0, a0, 5
    jal char_to_int
    jal do_babylonian 
    jal int_to_char

    # Terceito valor
    addi a2, a2, 5
    addi a0, a0, 5
    jal char_to_int
    jal do_babylonian
    jal int_to_char

    # Quarto valor
    addi a2, a2, 5
    addi a0, a0, 5
    jal char_to_int
    jal do_babylonian 
    jal int_to_char

    li t0, 10
    addi a2, a2, 4
    sb t0, 0(a2)

    # Write
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output_address       # buffer
    li a2, 20           # size
    li a7, 64           # syscall write (64)
    ecall    

    # Exit
    li a0, 0
    li a7, 93
    ecall

do_babylonian:
    li t3, 10
    srli t0, a1, 1 # cálculo do valor de k
aux:
    div t4, a1, t0 # divisão de y (a1) por k (t0)
    add t4, t4, t0 # adição de k(t0) com y/k (t4)
    srli t4, t4, 1 # divisão de k + y/k por 2, ou seja, k' (t4)

    mv t0, t4      # valor de k' vai ser o novo k para a iteração
    addi t3, t3, -1
    bnez t3, aux
    mv a1, t0
    ret 

char_to_int:
    # Entrada a0
    li t2, 1000
    lb t0, 0(a0)
    addi t0, t0, -48
    mul t0, t0, t2

    li t2, 100
    lb t1, 1(a0)
    addi t1, t1, -48
    mul t1, t1, t2
    add t0, t0, t1

    li t2, 10
    lb t1, 2(a0)
    addi t1, t1, -48
    mul t1, t1, t2
    add t0, t0, t1

    li t2, 1
    lb t1, 3(a0)
    addi t1, t1, -48
    mul t1, t1, t2
    add t0, t0, t1

    mv a1, t0
    ret

int_to_char:
    # Entrada a2 e a1
    li t1, 1000
    div t2, a1, t1
    addi t2, t2, 48 
    sb t2, 0(a2)

    rem a1, a1, t1
    li t1, 100
    div t2, a1, t1
    addi t2, t2, 48 
    sb t2, 1(a2)

    rem a1, a1, t1
    li t1, 10
    div t2, a1, t1
    addi t2, t2, 48
    sb t2, 2(a2)

    rem a1, a1, t1
    li t1, 1
    div t2, a1, t1
    addi t2, t2, 48 
    sb t2, 3(a2)
    li t1, 32
    sb t1, 4(a2)
    ret

.section .data
output_address: .skip 0x34 
input_address: .skip 0x14  # buffer