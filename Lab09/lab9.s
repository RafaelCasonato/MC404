.section .text
.globl _start
_start:
    # Read
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, input_address #  buffer to write the data
    li a2, 20  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall

    mv a0, a1
    jal char_to_int

    la a2, output_address
    la a0, head_node
    
    li t0, 0
    for:
        beqz a0, saida1
        lw t1, (a0)
        lw t2, 4(a0)
        add t3, t2, t1
        beq t3, a1, saida2
        addi t0, t0, 1
        lw a0, 8(a0)
        j for
    saida1:
    li t0, 45
    sb t0, (a2)
    li t0, 49
    sb t0, 1(a2)
    li t0, 10
    sb t0, 2(a2)
    li t0, 3
    j write 
    saida2:   
    mv a1, t0

    jal int_to_char
    sub a2, a2, t0

    write:
    # Write
    li a0, 1                    # file descriptor = 1 (stdout)
    la a1, output_address       # buffer
    mv a2, t0                   # size
    li a7, 64                   # syscall write (64)
    ecall    

    # Exit
    li a0, 0
    li a7, 93
    ecall

char_to_int:
    li t0, 10                       # t0 = valor em ASCII para '\n'
    li t1, 45                       # t1 = valor em ASCII para '-'
    
    li t4, 0                        # t4 = inteiro
    li t5, 10

    li t3, 1
    lb t2, (a0)                     # t2 = primeiro byte de a0
    bne t1, t2, while               # confere se é negativo
    addi a0, a0, 1
    li t3, -1
    while:
        lb t2, (a0)
        beq t0, t2, continua
        addi t2, t2, -48
        mul t4, t4, t5    
        add t4, t4, t2
        addi a0, a0, 1
        j while
    continua:
    mul t4, t4, t3
    mv a1, t4
    ret

int_to_char:
    li s0, 0               # Tamanho
    la a3, char_inv
    li t0, 10
    while2:
        rem t3, a1, t0
        div a1, a1, t0
        addi t3, t3, 48
        sb t3, (a3)
        addi s0, s0, 1
        beqz a1, f
        addi a3, a3, 1
        j while2
    f:
    mv s1, s0
    f2:
        beqz s1, 2f
        lb t0, (a3)
        sb t0, (a2)
        addi a2, a2, 1
        addi a3, a3, -1
        addi s1, s1, -1 
        j f2
    2:
    li t0, 10
    sb t0, (a2)
    mv t0, s0
    addi t0, t0, 1
    ret

.section .bss
input_address: .skip 8 
output_address: .skip 8
char_inv: .skip 8