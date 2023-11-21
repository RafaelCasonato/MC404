.section .text
.globl _start
.set READ, 0xFFFF0102           # Setar como 1 aciona o read
.set WRITE, 0xFFFF0100          # Setar como 1 aciona o write
.set BYTE_READ, 0xFFFF0103
.set BYTE_WRITTEN, 0xFFFF0101

_start:
    jal read
    lb a2, (a0)               # a2 possui a operação
    li t0, 49
    li t1, 50
    li t2, 51
    li t3, 52
    jal read                  # Le o primeiro \n, que vai ser descartado
    li t4, '\n'
    mv s3, sp                 # s0 armazenda o começo da pilha
    mv a1, zero               # Contador para o tamanho da string 
    0:                        # For pra ler a string de entrada até \n
        jal read
        lb s0, (a0)
        beq s0, t4, 1f
        addi sp, sp, -4
        sb s0, (sp)           # Armazena a string na stack
        addi a1, a1, 1        # Tamanho da string, sem \n
        j 0b
    1:
    mv a0, s3                 
    addi a0, a0, -4           # a0 = aponta o começo da string 
    beq a2, t0, op1
    beq a2, t1, op2
    beq a2, t2, op3
    beq a2, t3, op4
    
    mv sp, s3                 # retorna sp para o endereço inicial, desempilhando tudo
    # exit
    li a0, 0
    li a7, 93
    ecall

read:
    li a0, READ
    li t5, 1
    sb t5, (a0)
    0:
        lb t6, (a0)
        bnez t6, 0b
    li a0, BYTE_READ
    ret

write:
    # a0 tem o que vai ser escrito
    li a2, BYTE_WRITTEN
    sb a0, (a2)
    li a1, WRITE
    li t3, 1
    sb t3, (a1)
    0:
        lb t4, (a1)
        bnez t4, 0b
    ret

op1:
    # Le a string e escreve ela de volta
    # Entrada: a0 com o começo da string (endereço do começo da stack), a1 com o tamanho da string
    mv t0, a0                # t0 armazena o começo da string
    addi sp, sp, -4
    sw ra, (sp)              # salva o endereço de retorno na pillha
    mv t2, a1                # t2 armazena o tamanho da string
    # mv sp, a0                # Faz sp apontar para o começo da string
    2:                       # For para percorrer a pilha e imprimir a string
        beqz t2, 3f
        lb a0, (t0)
        jal write
        addi t0, t0, -4
        addi t2, t2, -1
        j 2b
    3:
    li a0, '\n'
    jal write                # Imprime a quebra de linha: \n
    lw ra, (sp)              # recupera o endereço de retorno, que estva na posição seguinte da ultima letra
    addi sp, sp, 4           # desempilha o ra
    ret

op2:
    # Le a string e escreve ela ao contrário
    # Entrada: a0 com o começo da string; a1 com o tamanho da string; sp aponta o fim da string 
    mv t0, sp                # t0 tem o endereço do final da stack, primeira letra
    addi sp, sp, -4
    sw ra, (sp)              # salva o endereço de retorno na pilha
    mv t2, a1                # t2 armazena o tamanho da string
    0:                       # For pra percorrer a string ao contrário
        beqz t2, 1f
        lb a0, (t0)
        jal write
        addi t0, t0, 4       # Vai desempilhando e percorrendo a string de trás pra frente
        addi t2, t2, -1
        j 0b
    1:
    li a0, '\n'
    jal write
    lw ra, (sp)              # Recupera o endereço de retorno da pilha
    addi sp, sp, 4           # desempilha o ra
    ret

op3:
    # Le um número decimal e escreve ele na base hexa 
    # Entrada: a0 com o começo do número; a1 com o número de dígitos do número
    addi sp, sp, -4
    sw ra, (sp)                     # salva o endereço de retorno
    jal atoi                        # retorna o valor em a0
    li a2, 16
    jal itoa
    lw ra, (sp)                     # recupera o end de retorno
    addi sp, sp, 4                  # desempilha
    ret

op4:
    # Le uma operação algébrica e imprime o resultado dela
    # a0 aponta o começo da operação; a1 o tamanho
    mv s0, a0                       # s0 tem o começo da operação
    addi sp, sp, -4
    li t0, '\n'
    sb t0, (sp)
    addi sp, sp, -4
    sw ra, (sp)                     # salva o end de retorno
    mv a2, a1                       # a2 salva o tamanho da operação/string
    mv a1, zero                     # a1 vai salvar o número de dígitos
    li s1, 1
    1:                           # While para pegar o número de dígitos do número
        li t4, ' '
        li t6, '\n'
        lb t5, (s0)
        beq t5, t4, 2f           # Confere se o caractere é espaço
        beq t5, t6, 2f           # Confere se o caractere é \n
        addi a1, a1, 1
        addi s0, s0, -4
        j 1b
    2:
    jal atoi                     # retorna em a0 o número
    addi sp, sp, -4
    sw a0, (sp)                  # salva o número na stack
    beqz s1, 3f                  # s1 = 0: esta fazendo o atoi do segundo número, então não precisa fazer o resto
    addi s0, s0, -4
    lb s2, (s0)                  # s2 guarda o operador
    addi s0, s0, -4              # s0 aponta pro começo do segundo número
    addi s0, s0, -4              # s0 aponta pro começo do segundo número
    mv a0, s0                    # a0 aponta o começo do segundo número
    mv s1, zero
    mv a1, zero
    j 1b
    3:
    lw a0, (sp)                  # a0 = segundo número
    addi sp, sp, 4
    lw a1, (sp)                  # a1 = primeiro número
    addi sp, sp, 4
    li t0, '+'
    li t1, '-'
    li t2, '*'
    li t3, '/'
    bne s2, t0, 4f
    add a0, a1, a0
    j 7f
    4:
    bne s2, t1, 5f
    sub a0, a1, a0
    j 7f
    5:
    bne s2, t2, 6f
    mul a0, a1, a0
    j 7f
    6:
    div a0, a1, a0
    7:
    li a2, 10
    jal itoa
    lw ra, (sp)
    addi sp, sp, 4
    ret

# itoa
# entrada: valor a ser convertido em a0; base em a2
# Obs.: str deve ser um array longo o suficiente para conter qualquer valor possível (33bytes)
itoa:
    addi sp, sp, -4
    sw ra, (sp)                      # salva o endereço de retorno
    li s0, 0                         # pra salvar o número de dígitos do número novo
    la a3, char_inv                  # char_inv salva a string invertida
    li t0, 10                       
    bne t0, a2, 0f                   # confere se a base é 10
    li t0, 0
    bge a0, t0, 0f                   # confere se a0 é negativo
    li t0, -1
    mul a0, a0, t0                   # transforma o inteiro em natural
    mv t0, a0
    li a0, '-'                       
    jal write
    li a2, 10
    mv a0, t0                              
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
    3:                               # For pra imprimir o número corretamente
        beqz s1, 4f
        lb a0, (a3)
        jal write
        addi a3, a3, -1
        addi s1, s1, -1 
        j 3b
    4:
    li a0, '\n'
    jal write
    lw ra, (sp)
    addi sp, sp, 4                   # Desempilha o endereço de retorno
    ret

# atoi
# entrada: Número salvo na stack; a0 = começo do número; a1 tamanho do número
# saída: valor convertido em a0, a0 = 0 caso str seja nulo ou apenas espaços em branco
atoi:
    li t0, 0                        # t0 = valor em ASCII para '\0'
    li t1, 45                       # t1 = valor em ASCII para '-'
    li t6, 32                       # t6 = valor em ASCII para ' '

    0:                              # While para pular espaços em branco, se tiver
        lb t2, (a0)
        bne t2, t6, 1f
        addi a0, a0, -4
    1:
    li t4, 0                        # t4 vai armazenar o valor convertido
    li t5, 10

    li t3, 1
    lb t2, (a0)                     # t2 = primeiro byte de a0 após espaços em branco
    bne t1, t2, 1f                  # confere se é negativo
    addi a0, a0, -4
    li t3, -1
    addi a1, a1, -1
    1:
    li t6, '+'
    bne t6, t2, 2f                  # confere se tem o sinal +
    addi a0, a0, -4
    2:                              # For para percorrer o número
        beqz a1, 3f
        lb t2, (a0)
        addi t2, t2, -48
        mul t4, t4, t5    
        add t4, t4, t2
        addi a0, a0, -4
        addi a1, a1, -1
        j 2b
    3:
    mul t4, t4, t3
    mv a0, t4                       # a0 retorna com o valor convertido
    ret

.section .bss
char_inv: .skip 10