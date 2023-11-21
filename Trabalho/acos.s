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
        li t1, 0xFFFF0500
        li t4, 1
        sb t4, (t1)
        0:
            lb t4, (t1)
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

.section .bss
usr_stack:                     # Final da pilha do user
.skip 1024                     # Aloca 1024 bytes para a pilha
usr_stack_end:                 # Base da pilha do user 

systm_stack:                   # Final da pilha do sistema
.skip 1024                     # Aloca 1024 bytes para a pilha
systm_stack_end:               # Base da pilha do sistema