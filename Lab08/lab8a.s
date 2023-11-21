.section .text
.globl _start
_start:
    # Open image
    la a0, input_file    # address for the file path
    li a1, 0             # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0             # mode
    li a7, 1024          # syscall open 
    ecall

    # Read 
    # a0 ja possui o endereco do input_file
    la a1, input_address #  buffer to write the data
    li a2, 262159   # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall

    la a3, input_address
    addi a3, a3, 3
    jal get_width_height    
    mv s0, a0               # s0 guarda widht
    addi a2, a2, 1
    add a3, a3, a2
    jal get_width_height
    mv s1, a0               # s1 guarda height
    addi a2, a2, 1          
    add a3, a3, a2
    addi a3, a3, 4          # a3 está no começo dos pixels da imagem

    # setCanvasSize
    mv a0, s0
    mv a1, s1
    li a7, 2201
    ecall

    li t1, 0
    for:                    # for para percorrer as linhas
        li t0, 0
        bge t1, s1, cont
        for2:                   # for para percorrer as colunas
            bge t0, s0, cont2
            lbu t2, 0(a3)
            li s2, 0
            slli t2, t2, 8    
            add s2, s2, t2
            slli t2, t2, 8
            add s2, s2, t2
            slli t2, t2, 8
            add s2, s2, t2
            addi s2, s2, 255
            jal setPixel 
            addi t0, t0, 1
            addi a3, a3, 1
            j for2
        cont2:
            addi t1, t1, 1
            j for
    cont:
    # Exit
    li a0, 0
    li a7, 93
    ecall

get_width_height:
    mv t4, a3       # endereco da linha em t4
    li t1, 32       # Valor em ASCII para o espaço
    li t5, 10       # valor em ASCII para o \n
    li t3, 0        # armazena o numero de digitos
    
    while:
        lbu t2, (t4)
        beq t2, t1, continua
        beq t2, t5, continua
        addi t3, t3, 1  # Número de dígitos
        addi t4, t4, 1
        j while

    continua:
    li a0, 3
    mv t4, a3
    li t0, 0
    beq a0, t3, 3f
    li a0, 2
    beq a0, t3, 2f
    addi t4, t4, -2
    j 1f
    
    2:
    addi t4, t4, -1
    j 2f
    
    3:
    li t2, 100
    lb t5, 0(t4)
    addi t5, t5, -48
    mul t5, t5, t2
    add t0, t0, t5
    
    2:
    li t2, 10
    lb t1, 1(t4)
    addi t1, t1, -48
    mul t1, t1, t2
    add t0, t0, t1
    
    1:
    lb t1, 2(t4)
    addi t1, t1, -48
    add t0, t0, t1

    mv a0, t0        # Valor de widht/height
    mv a2, t3        # Número de digitos do valor
    ret

setPixel:
    # setPixel 
    mv a0, t0 # x coordinate 
    mv a1, t1 # y coordinate 
    mv a2, s2 # white pixel
    li a7, 2200 # syscall setPixel (2200)
    ecall
    ret

.section .bss
input_address: .skip 262159
.section .data
input_file: .asciz "image.pgm"