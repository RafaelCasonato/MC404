.section .text
.align 4

int_handler:
    # ##### Syscall and Interrupts handler ##### #
    # Salvar o contexto
    csrrw sp, mscratch, sp     # Troca sp com mscratch
    addi sp, sp, -28           # Aloca espaço na pilha da ISR
    sw a1, (sp)                # Salva a1
    sw a2, 4(sp)               # Salva a2
    sw t0, 8(sp)               # Salva t0
    sw t1, 12(sp)              # Salva t1
    sw t2, 16(sp)              # Salva t2
    sw t3, 20(sp)              # Salva t3
    sw t4, 24(sp)              # Salva t4
    # salvar o a7?

    # Trata a syscall
    li t0, 10
    bne a7, t0, 1f
    jal t2, Syscall_set_engine_and_steering
    1:
    li t0, 11
    bne a7, t0, 2f
    jal t2, Syscall_set_handbrake
    2:
    li t0, 12
    bne a7, t0, 3f
    jal t2, Syscall_read_sensors
    3:
    li t0, 13
    bne a7, t0, 4f
    jal t2, Syscall_read_sensors_distance
    4:
    li t0, 15
    bne a7, t0, 5f
    jal t2, Syscall_get_position
    5:
    li t0, 16
    bne a7, t0, 6f
    jal t2, Syscall_get_rotation
    6:
    li t0, 17
    bne a7, t0, 7f
    jal t2, Syscall_read_serial
    7:
    li t0, 18
    bne a7, t0, 8f
    jal t2, Syscall_write_serial
    8:
    li t0, 20
    bne a7, t0, 9f
    jal t2, Syscall_get_systime
    9:

    # Recupera o contexto
    # recuperar a7?
    lw t4, 24(sp)              # Recupera t4
    lw t3, 20(sp)              # Recupera t3
    lw t2, 16(sp)              # Recupera t2
    lw t1, 12(sp)              # Recupera t1
    lw t0, 8(sp)               # Recupera t0
    lw a2, 4(sp)               # Recupera a2
    lw a1, (sp)                # Recupera a1
    addi sp, sp, 28            # Desaloca espaço na pilha da ISR
    csrrw sp, mscratch, sp     # Troca sp com mscratch novamente     

    csrr t0, mepc   # load return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4  # adds 4 to the return address (to return after ecall) 
    csrw mepc, t0   # stores the return address back on mepc
    mret            # Recover remaining context (pc <- mepc)

.globl _start
_start:

    la t0, int_handler  # Load the address of the routine that will handle interrupts
    csrw mtvec, t0      # (and syscalls) on the register MTVEC to set the interrupt array.

    # Seta o endereço da base da user stack em mscratch
    la a0, usr_stack_end
    csrw mscratch, a0

    # Habilita Interrupções Global
    csrr t1, mstatus           # Seta o bit 3 (MIE)
    ori t1, t1, 0x8            # do registrador mstatus
    csrw mstatus, t1

    # Troca para o user privilage 
    csrr t1, mstatus    # Update the mstatus.MPP
    li t2, ~0x1800      # field (bits 11 and 12)
    and t1, t1, t2      # with value 00 (U-mode)
    csrw mstatus, t1
    la t0, main         # Loads the user software
    csrw mepc, t0       # entry point into mepc

    li sp, 0x07FFFFFC   # Inicializa a user stack
    mret                # PC <= MEPC; mode <= MPP;

Syscall_set_engine_and_steering:
# entrada: a0 = movement direction; a1 = steering wheel angle
# saida: a0 = 0: successful; a0 = -1: failed
# steering wheel -127 < x < 127 e engine 0, 1, -1
    
    # Confere se o valor em a0 é uma entrada válida para a engine
    beqz a0, 1f
    li t0, 1
    beq a0, t0, 1f
    li t0, -1
    beq a0, t0, 1f
    j 2f
    
    # Confere se o valor em a1 é uma entrada válida para a steering wheel
    1:
    li t0, -127
    blt a1, t0, 2f
    li t0, 128
    bge a1, t0, 2f

    # Ajuste da engine
    mv t0, a0                           # t0 recebe a engine direction
    li a0, 0xFFFF0321                   # a0 recebe o endereço da engine
    sb t0, (a0)                         # Saída para a engine direction
    
    # Ajuste da steering wheel
    li a0, 0xFFFF0320                   # a0 recebe o endereço da steering wheel
    sb a1, (a0)                         # Saída para o steering wheel angle
    li a0, 0                            # Retorno da função: a0 = 0 -> sucesso
    j 3f
    2:
    li a0, -1                           # Retorno da função: a0 = -1 -> failure
    3:
    # Retorna
    jr t2

Syscall_set_handbrake:
# entrada: a0 
# saída: -
    mv t0, a0                           # t0 recebe o valor de a0
    li a0, 0xFFFF0322
    sb t0, (a0)
    # Retorna
    jr t2

Syscall_read_sensors:
# entrada: a0 = endereço do array com 256 elementos que vai guardar a leitura 
# saída: 
    # Ativar a Line Camera
    li t0, 0xFFFF0301
    li t1, 1
    sb t1, (t0)
    0:
        lb t1, (t0)
        bnez t1, 0b
    # Salvar os pixels no array a0
    li t3, 256
    li t0, 0xFFFF0324
    1:
        beqz t3, 2f
        lb t1, (t0)
        sb t1, (a0)
        addi t0, t0, 1
        addi a0, a0, 1
        addi t3, t3, -1
        j 1b
    2:
    # Retorna
    jr t2

Syscall_read_sensors_distance:
# entrada: -
# saída: a0 = -1, não viu objeto em uma distancia < 20m; a0 = valor lido
    # Ativar o Ultrasonic sensor
    li t0, 0xFFFF0302  # Endereço para o Ultrasonic sensor
    li t1, 1           
    sb t1, (t0)        # Aciona o sensor setando o valor como 1
    0:                 # Busy waiting para esperar a leitura ser concluida
        lb t1, (t0)
        bnez t1, 0b
    # Salvar a distancia em a0
    li t0, 0xFFFF031c  # Endereço onde foi guardada a distancia lida
    lw t1, (t0)
    mv a0, t1          # Salva a distancia em a0
    # Retorna
    jr t2

Syscall_get_position:
# entrada: a0 = endereço da variavel x; a1 = endereço da variavel y; a2 = endereço da variavel z
# saída: -
    # Ativar o GPS
    li t0, 1
    li t1, 0xFFFF0300
    sb t0, (t1)
    0:
        lb t0, (t1)
        bnez t0, 0b 
    # Recuperar os valores da leitura
    li t1, 0xFFFF0310   # Endereço do valor lido de X   
    lw t0, (t1)         # Valor de X
    sw t0, (a0)         # Guarda o valor de X na variável recebida
    lw t0, 4(t1)        # Valor de Y
    sw t0, (a1)         # Guarda o valor de Y na variável recebida
    lw t0, 8(t1)        # Valor de Z
    sw t0, (a2)         # Guarda o valor de Z na variável recebida
    # Retorna
    jr t2

Syscall_get_rotation:
# entrada: a0 = endereço da variavel do angulo x; a1 = endereço da variavel do angulo y; a2 = endereço da variavel do angulo z
# saída: -
    # Ativar o GPS
    li t0, 0xFFFF0300
    li t1, 1
    sb t1, (t0)
    0:
        lb t1, (t0)
        bnez t1, 0b
    # Recuperar os valores da leitura
    lw t1, 4(t0)
    sw t1, (a0)         # Guarda a leitura do Euler angle X no end a0
    lw t1, 8(t0)
    sw t1, (a1)         # Guarda a leitura do Euler angle Y no end a1
    lw t1, 12(t0)
    sw t1, (a2)         # Guarda a leitura do Euler angle Z no end a2
    # Retorna
    jr t2

Syscall_read_serial:
# entrada: a0 = buffer; a1 = tamanho
# saída: a0 = número de caracteres lidos
    li t3, 0
    li t4, '\n'
    1:                   
        beqz a1, 3f     # Confere se a1 = 0
        # Começa a leitura
        li t0, 0xFFFF0502
        li t1, 1
        sb t1, (t0)
        0: 
            lb t1, (t0)
            bnez t1, 0b
        # Recupera o byte lido e salva ao longo do buffer
        li t0, 0xFFFF0503
        lb t1, (t0)
        beqz t1, 2f     # Confere se o stdin é null
        beq t1, t4, 2f  # Confere se leu \n
        sb t1, (a0)
        # Passa para o próximo índice do buffer e adiciona 1 ao contador
        addi t3, t3, 1
        addi a0, a0, 1
        addi a1, a1, -1
        j 1b
    2:
        sb zero, (a0)
    3:
    mv a0, t3
    jr t2

Syscall_write_serial:
# entrada: a0 = buffer; a1 = tamanho
# saída: -
    li t3, 0
    1:
        beqz a1, 2f     # Confere se a1 = 0
        lb t0, (a0)
        beqz t0, 2f     # Confere se chegou no \0 da string
        # Seta o bite do buffer a ser escrito no endereço do serial port
        li t1, 0xFFFF0501
        sb t0, (t1)
        # Triggers serial port to write
        li t2, 0xFFFF0500
        li t4, 1
        sb t4, (t2)
        0:
            lb t4, (t2)
            bnez t4, 0b
        # Passa para o próximo índice do buffer e adiciona 1 no contador
        addi t3, t3, 1
        addi a0, a0, 1
        addi a1, a1, -1
        j 1b
    2:
    jr t2

Syscall_get_systime:
# entrada: -
# saída: a0 = tempo desde que o sistema foi iniciado
    # Ativar o GPT
    li t0, 0xFFFF0100      # Enereço base do GPT
    li t1, 1
    sb t1, (t0)
    0:
        lb t1, (t0)
        bnez t1, 0b
    # Recupera a leitura e salva em a0
    lw t1, 4(t0)         # t0 tem o endereço onde foi salvo o tempo
    mv a0, t1
    # Retorna
    jr t2

.globl set_engine
set_engine:
# parâmetros: a0 = veritcal movement; a1 = horizontal movement
# retorno: a0 = 0 -> sucesso; a0 = -1 -> erro
    li a7, 10
    ecall
    ret

.globl set_handbrake
set_handbrake:
# parâmetros: a0 = byte que define se vai ser ligado ou não. 1 -> aciona, 0 -> para de usar
# retorno: -1 se parâmetro é inválido; 0 se sucesso
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
    ret

.globl read_sensor_distance
read_sensor_distance:
# parâmetros: nenhum
# retorno: distância lida pelo sensor, em centímetros
    li a7, 13
    ecall
    ret

.globl get_position 
get_position:
# parâmetros: igual da syscall
# retorno: nenhum
    li a7, 15
    ecall
    ret

.globl get_rotation 
get_rotation:
# parâmetros: mesmos da syscall
# retorno: nenhhum
    li a7, 16
    ecall
    ret

.globl get_time 
get_time:
# parâmetros: nenhum
# retorno: tempoo do sistema em milisegundos
    li a7, 20
    ecall
    ret

.globl puts
puts:
# parâmetros: endereço da string terminada em \0
# retorno: nenhum
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
    addi a0, a0, -1 # Volta a0 para o fim da string
    li t1, 0
    sb t1, (a0)     # String volta a terminar com \0
    mv a0, t4       # a0 aponta pro endereço do inicio da string
    ret

.globl gets
gets:
# parâmetros: a0 = endereço do buffer a ser preenchido
# retorno: buffer preenchido com a string terminada em \0
    li a7, 17
    li a1, 1
    mv t1, a0
    li t2, '\n'
    mv t3, a0
    0:
        mv a0, t1
        ecall
        lb t3, (t1)
        beq t3, t2, 1f
        addi t1, t1, 1
        j 0b
    1:
    teste:
    sb zero, (t0)
    mv a0, t1
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
    li s0, 0                         # tamanho da string
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
        addi s0, s0, 1
        beqz a0, 2f
        j 0b
    2:
        beqz s0, 4f
        lb t0, (sp)
        sb t0, (a1)
        addi a1, a1, 1
        addi sp, sp, 4
        addi s0, s0, -1 
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
    sb ra, (sp)
    
    sub t0, a3, a0        # Xb - Xa
    sub t1, a4, a1        # Yb - Ya
    sub t2, a5, a2        # Zb - Za

    mul t0, t0, t0        # (Xb - Xa)^2
    mul t1, t1, t1        # (Yb - Ya)^2
    mul t2, t2, t2        # (Zb - Za)^2

    add t0, t0, t1
    add t0, t0, t2

    mv a0, t0             # a0 = (Xb - Xa)^2 + (Yb - Ya)^2 + (Zb - Za)^2
    li a1, 15             
    jal approx_sqrt            

    lb ra, (sp)
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

.globl main
main:
    # la a0, buffer
    # jal puts
    la a0, buffer2
    jal gets

.section .data
buffer: .asciz "Hello\0"

.section .bss
usr_stack:                     # Final da pilha do user
.skip 1024                     # Aloca 1024 bytes para a pilha
usr_stack_end:                 # Base da pilha do user 

systm_stack:                   # Final da pilha do sistema
.skip 1024                     # Aloca 1024 bytes para a pilha
systm_stack_end:               # Base da pilha do sistema

buffer2: .skip 10