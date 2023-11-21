.section .text
.globl _start
_start:
    # Read coordinates
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, input_coord #  buffer to write the data
    li a2, 12  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall

    la a0, input_coord

    # Coordenada Yb
    jal get_int
    mv s4, a1         # Registrador s4 guarda Yb

    # Coordenada Xc
    addi a0, a0, 5
    jal get_int
    mv s5, a1         # Registrador s5 guarda Xc

    # Read times
    li a0, 0  # file descriptor = 0 (stdin)
    la a1, input_times #  buffer to write the data
    li a2, 20  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    ecall

    la a2, output_address
    la a0, input_times

    # Tempo R
    addi a0, a0, 15
    jal char_to_int 
    mv s3, a1         # Registrador s3 guarda Tr

    addi a0, a0, -15

    # Tempo A
    jal char_to_int
    jal calc_dist
    mv s0, a1         # Registrador s0 guarda Da

    # Tempo B
    addi a0, a0, 5
    jal char_to_int
    jal calc_dist
    mv s1, a1         # Registrador s1 guarda Db

    # Tempo C
    addi a0, a0, 5
    jal char_to_int
    jal calc_dist
    mv s2, a1         # Registrador s2 guarda Dc

    addi a2, a2, 6
    jal calc_y
    mv a1, s6         # Registrador s6 guarda y
    addi a2, a2, 1
    jal int_to_char

    addi a2, a2, -7
    jal calc_x
    addi a2, a2, 1
    jal int_to_char

    li t0, 10
    addi a2, a2, 10
    sb t0, 0(a2)

    # Write
    li a0, 1            # file descriptor = 1 (stdout)
    la a1, output_address       # buffer
    li a2, 12           # size
    li a7, 64           # syscall write (64)
    ecall    

    # Exit
    li a0, 0
    li a7, 93
    ecall

do_babylonian:
    li t3, 21
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

get_int:
    mv a5, ra
    lb t3, 0(a0)
    li t4, 45
    addi a0, a0, 1
    jal char_to_int
    beq t3, t4, 1f
    mv ra, a5
    ret
1:
    li t5, -1
    mul a1, a1, t5
    mv ra, a5
    ret

y_neg_sign:
    li t0, 45
    sb t0, 0(a2)
    li t1, -1
    mul s6, s6, t1
    ret
neg_sign:
    li t0, 45
    sb t0, 0(a2)
    ret
pos_sign:
    li t0, 43
    sb t0, 0(a2)
    ret

calc_dist:
    # Entrada a1
    # Distancia = velocidade * temp * 10
    # Velocidade 3.10^8 m/s, tempo em nanosegundos
    # Tempo = Tr - Ta ou Tb ou Tc
    mv t0, s3
    sub t0, t0, a1 # Tr - T , guardado em t0
    li t1, 3
    mul t0, t1, t0 # velocidade * tempo , guardado em t0
    li t1, 10
    div t0, t0, t1
    mv a1, t0
    ret

calc_y:
    # y = (Da^2 + Yb^2 - Db^2) / 2*Yb
    mv t0, s1
    mv t1, s0
    mv t2, s4

    add t4, t2, t2   # 2*Yb
    mul t0, t0, t0   # Db^2
    mul t1, t1, t1   # Da^2
    mul t2, t2, t2   # Yb^2
    add t1, t1, t2   # Da^2 + Yb^2
    sub t0, t1, t0   # Da^2 + Yb^2 - Db^2
    div t0, t0, t4   # Da^2 + Yb^2 - Db^2 / 2Yb
    
    mv s6, t0         # Registrador s6 guarda y
    li t1, 0
    blt s6, t1, y_neg_sign
    bge s6, t1, pos_sign
    ret

calc_x:
    # x = +/- sqrt(Da^2 - y^2)
    mv a5, ra
    mv t0, s6
    mv t1, s0 

    mul t1, t1, t1 # Da^2
    mul t0, t0, t0 # y^2
    sub t0, t1, t0 # Da^2 - y^2
    
    mv a1, t0
    jal do_babylonian
check_x:
    mv t0, s2
    mv t1, s5
    mv t2, s6
    mv t3, a1
    li t5, -1
    mul t4, t3, t5 # -x

    mul t0, t0, t0 # t0 = Dc^2
    mul t2, t2, t2 # t2 = y^2
    sub t3, t3, t1 # t3 = +x - Xc
    sub t4, t4, t1 # t4 = -x - Xc
    mul t3, t3, t3 # t3 = (+x - Xc)^2
    add t3, t3, t2 # t3 = (+x - Xc)^2 + y^2
    mul t4, t4, t4 # t4 = (-x - Xc)^2
    add t4, t4, t2 # t4 = (-x - Xc)^2 + y^2

    # Erro de x < 0
    sub t1, t0, t4 
    mul t1, t1, t1

    # Erro de x > 0 
    sub t2, t0, t3 
    mul t2, t2, t2

    mv ra, a5
big:
    bltu t2, t1, pos_sign # x > 0
    bltu t1, t2, neg_sign # x < 0
    ret

.section .data
output_address: .skip 0xC
input_coord: .skip 0xC 
input_times: .skip 0x14  