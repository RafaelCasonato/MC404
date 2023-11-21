.section .text

.globl set_engine
set_engine:
# parâmetros: a0 = veritcal movement; a1 = horizontal movement
# retorno: a0 = 0 -> sucesso; a0 = -1 -> erro
    ; addi sp, sp, -4
    ; sw ra, (sp)

    li a7, 10
    ecall
    
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl set_handbrake
set_handbrake:
# parâmetros: a0 = byte que define se vai ser ligado ou não. 1 -> aciona, 0 -> para de usar
# retorno: -1 se parâmetro é inválido; 0 se sucesso
    ; addi sp, sp, -4
    ; sw ra, (sp)
    
    li a7, 11
    beq a0, zero, parar
    li t0, 1
    beq a0, t0, acionar
    li a0, -1
    j 2f
    parar:
        li a0, 0
        ecall
        j 1f
    acionar:
        li a0, 1
        ecall
    1:
    li a0, 0
    2:
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl read_sensor_distance
read_sensor_distance:
# parâmetros: nenhum
# retorno: distância lida pelo sensor, em centímetros
    ; addi sp, sp, -4
    ; sw ra, (sp)

    li a7, 13
    ecall
    
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl get_position 
get_position:
# parâmetros: igual da syscall
# retorno: nenhum
    ; addi sp, sp, -4
    ; sw ra, (sp)
    
    li a7, 15
    ecall
    
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl get_rotation 
get_rotation:
# parâmetros: mesmos da syscall
# retorno: nenhhum
    ; addi sp, sp, -4
    ; sw ra, (sp)
    
    li a7, 16
    ecall
    
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl get_time 
get_time:
# parâmetros: nenhum
# retorno: tempoo do sistema em milisegundos
    ; addi sp, sp, -4
    ; sw ra, (sp)
    
    li a7, 20
    ecall
    
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl puts
puts:
# parâmetros: endereço da string terminada em \0
# retorno: nenhum
    ; addi sp, sp, -4
    ; sw ra, (sp)

    li a7, 18
    mv t0, a0
    mv t4, a0
    li t3, 0
    # Loop para pegar o tamanho da string, sem o \0
    0:
        lb t1, (t0)
        beqz t1, 1f
        addi t0, t0, 1
        addi t3, t3, 1
        j 0b
    1:
    mv a1, t3       # Salva o tamanho da string em a1
    ecall           # Printa a string ate o \0
    addi a0, a0, 1
    li t1, 10       
    sb t1, (a0)     # Troca o \0 por \n
    li a1, 1
    ecall           # Printa o \n
    teste:
    addi a0, a0, -1 # Volta a0 para o fim da string
    li t1, 0
    sb t1, (a0)     # String volta a terminar com \0
    mv a0, t4       # a0 aponta pro endereço do inicio da string
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl gets
gets:
# parâmetros: a0 = endereço do buffer a ser preenchido
# retorno: buffer preenchido com a string terminada em \0
    ; addi sp, sp, -4
    ; sw ra, (sp)

    li a7, 17
    li a1, 1
    mv t1, a0
    mv t4, a0
    0:
        mv a0, t1
        ecall
        lb t3, (t1)
        beqz t3, 1f
        addi t1, t1, 1
        j 0b
    1:
    mv a0, t4
    ; lw ra, (sp)
    ; addi sp, sp, 4
    ret

.globl atoi
atoi:
# parâmetros: a0 = end da string terminada em \0 com o decimal
# retorno: a0 = valor convertido
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

.globl itoa
# parâmetros: a0 = valor; a1 = end do buffer a ser preenchido; a2 = base
# retorno: buffer preenchido com a string terminada em \0
itoa:
    mv t4, a1        
    li t5, 0                         # tamanho da string
    li t0, 10                       
    bne t0, a2, 0f                   # confere se a base é 10
    li t0, 0
    bge a0, t0, 0f                   # confere se a0 é negativo
    li t0, -1
    mul a0, a0, t0                   # transforma o inteiro em natural
    li t0, 45                        # t0 = '-'
    sw t0, (a1)                      # adiciona o sinal - no começo de str
    addi a1, a1, 1     
    mv t1, sp                        # t1 aponta para o topo da pilha, nesse momento
    0:
        li t0, 10
        rem t3, a0, a2
        div a0, a0, a2
        blt t3, t0, 1f
        addi t3, t3, 7
        1:
        addi t3, t3, 48
        addi sp, sp, -4
        sb t3, (sp)
        addi t5, t5, 1
        beqz a0, 2f
        j 0b
    2:
        beqz t5, 4f
        lb t0, (sp)
        sb t0, (a1)
        addi a1, a1, 1
        addi sp, sp, 4
        addi t5, t5, -1 
        j 2b
    4:
    li t0, 0
    sb t0, (a1)                        # adiciona o \0 no final da str
    mv a0, t4                          # a0 tem o endereço da str
    ret

.globl strlen_custom
strlen_custom:
# parâmetros: string terminada em \0
# retorno: tamanho da string sem o \0
    mv a1, zero           # Contador para o tamanho da string
    0:                    # While: até achar o \0
        lb t1, (a0)   
        beqz t1, 1f       # Se achou o \0, sai do while
        addi a1, a1, 1
        addi a0, a0, 1
        j 0b
    1:
    mv a0, a1             # Retorna o tamanho da string em a0
    ret

.globl approx_sqrt
approx_sqrt:
# parâmetros: a0 = valor, a1 = numero de iteracoes pra fazer o metodo Babylonian
# retorno: raiz quadrada aproximada
    srli t0, a0, 1        # cálculo do valor de k
    aux:
    div t1, a0, t0        # divisão de y (a0) por k (t0)
    add t1, t1, t0        # adição de k(t0) com y/k (t1)
    srli t1, t1, 1        # divisão de k + y/k por 2, ou seja, k' (t1)

    mv t0, t1             # valor de k' vai ser o novo k para a iteração
    addi a1, a1, -1
    bnez a1, aux
    mv a0, t0
    ret 

.globl get_distance
get_distance:
# parâmetros: a0 = Xa, a1 = Ya, a2 = Za; a3 = Xb, a4 = Yb, a5 = Zb
# retorno: distância euclidiana entre A e B
    addi sp, sp, -4
    sw ra, (sp)
    
    sub t0, a3, a0        # Xb - Xa
    sub t1, a4, a1        # Yb - Ya
    sub t2, a5, a2        # Zb - Za

    mul t0, t0, t0        # (Xb - Xa)^2
    mul t1, t1, t1        # (Yb - Ya)^2
    mul t2, t2, t2        # (Zb - Za)^2

    add t0, t0, t1
    add t0, t0, t2

    mv a0, t0             # a0 = (Xb - Xa)^2 + (Yb - Ya)^2 + (Zb - Za)^2
    li a1, 10             
    jal approx_sqrt            

    lw ra, (sp)
    addi sp, sp, 4
    ret

.globl fill_and_pop
fill_and_pop:
# parâmetros: a0 = atual head_node; a1 = node struct que vai ser preenchida com os valores do head node
# retorno: próximo nó da lista ligada
    # Copia o campo X
    lw t0, (a0)
    sw t0, (a1)
    # Copia o campo Y
    lw t0, 4(a0)
    sw t0, 4(a1)
    # Copia o campo Z
    lw t0, 8(a0)
    sw t0, 8(a1)
    # Copia o campo a_x
    lw t0, 12(a0)
    sw t0, 12(a1)
    # Copia o campo a_y
    lw t0, 16(a0)
    sw t0, 16(a1)
    # Copia o campo a_z
    lw t0, 20(a0)
    sw t0, 20(a1)
    # Copia o campo action
    lw t0, 24(a0)
    sw t0, 24(a1)
    # Copia o campo *next
    lw t0, 28(a0)
    sw t0, 28(a1)
    # Retorna, em a0, o próximo nó (head->next)
    mv a0, t0
    ret