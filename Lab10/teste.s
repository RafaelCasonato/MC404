.section .text
.globl puts
.globl gets
.globl itoa
.globl atoi
.globl linked_list_search
.globl exit
.globl _start
_start:
    la a0, buffer
    jal gets
    jal atoi
    teste:
    li a0, 0
    li a7, 93
    ecall

exit:
    li a0, 0
    li a7, 93
    ecall

linked_list_search:
    li t0, 0
    0:                        # for
        beqz a0, 1f
        lw t1, (a0)
        lw t2, 4(a0)
        add t3, t2, t1
        beq t3, a1, 2f
        addi t0, t0, 1
        lw a0, 8(a0)
        j 0b
    1:
    li a0, -1
    2:   
    mv a0, t0
    ret


iota:
    li s0, 0                
    la a3, char_inv
    li t0, 10                       
    bne t0, a2, 0f                   # confere se a base é 10
    li t0, 0
    bge a0, t1, 0f                   # confere se a0 é negativo
    li t0, -1
    mul a0, a0, t0                   # transforma o inteiro em natural
    li t0, 45                        # t0 = '-'
    sw t0, (a1)                      # adiciona o sinal - no começo de str
    addi a1, a1, 1    
    li t0, 10                        # ve se o numero é maior que 10   
    0:
        rem t3, a0, a2
        div a0, a0, a2
        blt t3, t0, 1f
        addi t3, t3, 7
        1:
        addi t3, t3, 48
        sb t3, (a3)
        addi s0, s0, 1
        beqz a0, 2f
        addi a3, a3, 1
        j 0b
    2:
    mv s1, s0
    3:
        beqz s1, 4f
        lb t0, (a3)
        sb t0, (a1)
        addi a1, a1, 1
        addi a3, a3, -1
        addi s1, s1, -1 
        j 3b
    4:
    li t0, 0
    sb t0, (a1)                        # adiciona o \0 no final da str
    mv t0, s0                          # t0 tem o tamanho da str, contando o \0
    addi t0, t0, 1
    mv a0, a1                          # a0 tem o endereço da str
    ret

atoi:
    li t0, 0                        # t0 = valor em ASCII para '\0'
    li t1, 45                       # t1 = valor em ASCII para '-'
    li t6, 32                       # t6 = valor em ASCII para ' '

    0:                         # While para pular espaços em branco, se tiver
        lb t2, (a0)
        bne t2, t6, 1f
        addi a0, a0, 1
    1:
    li t4, 0                        # t4 vai armazenar o valor convertido
    li t5, 10

    li t3, 1
    lb t2, (a0)                     # t2 = primeiro byte de a0 após espaços em branco
    bne t1, t2, 1f                  # confere se é negativo
    addi a0, a0, 1
    li t3, -1
    1:
    li t6, '+'
    bne t6, t2, 2f               # confere se tem o sinal +
    addi a0, a0, 1
    2:
        lb t2, (a0)
        beq t0, t2, 3f
        addi t2, t2, -48
        mul t4, t4, t5    
        add t4, t4, t2
        addi a0, a0, 1
        j 2b
    3:
    mul t4, t4, t3
    mv a0, t4                       # a0 retorna com o valor convertido
    ret

gets:
    mv t4, a0
    mv t5, a0
    # Read
    li a0, 0  # file descriptor = 0 (stdin)
    li a2, 1  # size (reads only 1 byte)
    li a7, 63 # syscall read (63)
    
    li t0, 10                 # \n
    1:                        # while
        li a0, 0              # file descriptor = 0 (stdin)
        mv a1, t4             # buffer to write the data (1 byte)
        ecall                 # read
        lbu t1, (t4)        
        beq t0, t1, 2f  
        addi t4, t4, 1
        j 1b
    2:
    li t0, 0
    sb t0, (t4)
    mv a0, t5
    ret

puts:
    # a0 tem a str e o retorno deve ser um inteiro != 0
    # Write
    mv t0, a0

    li a0, 1                    # file descriptor = 1 (stdout)
    li a2, 1                    # size
    li a7, 64                   # syscall write (64)

    li t2, 0
    1:                          # while
        li a0, 1
        mv a1, t0
        lbu t3, (a1)
        beq t3, t2, 2f
        ecall
        addi t0, t0, 1
        j 1b
    2:
    li t1, 10
    sb t1, (t0)
    mv a1, t0
    ecall
    li t1, 0
    sb t1, (t0)
    mv a0, t0
    ret

.section .bss
buffer: .skip 10