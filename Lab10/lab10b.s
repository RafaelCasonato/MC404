.section .text
.globl recursive_tree_search
.globl itoa
.globl atoi
.globl gets
.globl puts
.globl exit

# Linked list search
# entrada: a0 é o root_node, a1 é o valor
# saída: 
recursive_tree_search:
# dois proximos nos nulos, retorna 0
# achou o valor, retorna 1
    addi sp, sp, -4
    sw ra, (sp)
    addi sp, sp, -4
    sw a0, (sp)

    # Caso base 1
    beq a0, zero, 1f

    lw t0, (a0)
    # Caso base 2
    beq a1, t0, 2f
    lw a0, 4(a0)                   # Procura nos filhos esquerdos
    jal recursive_tree_search

    bne a0, zero, 3f
    lw a0, (sp)
    lw a0, 8(a0)                   # Procura nos filhos direitos
    jal recursive_tree_search
    bne a0, zero, 3f               
    mv a0, zero                    # Não achou
    j sai

    3:  # Achou o número, soma a profundidade
        addi a0, a0, 1
        j sai
    2:  # Caso base 2: achou o número
        li t1, 1
        mv a0, t1
        j sai
    1:  # Caso base 1: filho esquerdo e direito são nulos
        mv a0, zero
        j sai
    sai:
        lw ra, 4(sp)
        addi sp, sp, 8
        ret

# gets
# entrada: str em a0 (str é um char (ponteiro))
# saída: a0 como ponteiro de str
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

# puts
# entrada: str em a0
# saída: valor não negativo em a0
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

# atoi
# entrada: str em a0
# saída: valor convertido em a0, a0 = 0 caso str seja nulo ou apenas espaços em branco
atoi:
    li t0, 0                        # t0 = valor em ASCII para '\0'
    li t1, 45                       # t1 = valor em ASCII para '-'
    li t6, 32                       # t6 = valor em ASCII para ' '

    0:                              # While para pular espaços em branco, se tiver
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
    bne t6, t2, 2f                  # confere se tem o sinal +
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


# itoa
# entrada: valor a ser convertido em a0, vetor na memoria para escrever o valor em a1, base em a2
# saída: ponteiro a0 com string terminando com \0
# Obs.: str deve ser um array longo o suficiente para conter qualquer valor possível (33bytes)
itoa:
    mv t6, a1        
    li s0, 0                
    la a3, char_inv
    li t0, 10                       
    bne t0, a2, 0f                   # confere se a base é 10
    li t0, 0
    bge a0, t0, 0f                   # confere se a0 é negativo
    li t0, -1
    mul a0, a0, t0                   # transforma o inteiro em natural
    li t0, 45                        # t0 = '-'
    sw t0, (a1)                      # adiciona o sinal - no começo de str
    addi a1, a1, 1       
    0:
        li t0, 10
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
    mv a0, t6                          # a0 tem o endereço da str
    ret


# exit
exit:
    li a0, 0
    li a7, 93
    ecall


.section .bss
char_inv: .skip 32
buffer: .skip 10
.section .data
