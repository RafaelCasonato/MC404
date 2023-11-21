.section .text
.align 4

int_handler:
    # ##### Syscall and Interrupts handler ##### #
    # Salvar o contexto
    csrrw sp, mscratch, sp     # Troca sp com mscratch
    addi sp, sp, -24           # Aloca espaço na pilha da ISR
    sw a1, (sp)                # Salva a1
    sw a2, 4(sp)               # Salva a2
    sw a7, 8(sp)               # Salva a7
    sw t0, 12(sp)              # Salva t0
    sw t1, 16(sp)              # Salva t1
    sw t2, 20(sp)              # Salva t2

    # Trata a syscall
    li t0, 10
    bne a7, t0, 1f
    jal t2, set_engine_and_steering
    1:
    addi t0, t0, 1
    bne a7, t0, 2f
    jal t2, set_hand_brake
    2:
    addi t0, t0, 1
    bne a7, t0, 3f
    jal t2, read_sensors
    3:
    addi t0, t0, 3
    bne a7, t0, 4f
    jal t2, get_position
    4:

    # Recupera o contexto
    lw t2, 20(sp)              # Recupera t2
    lw t1, 16(sp)              # Recupera t1
    lw t0, 12(sp)              # Recupera t0
    lw a7, 8(sp)               # Recupera a7
    lw a2, 4(sp)               # Recupera a2
    lw a1, (sp)                # Recupera a1
    addi sp, sp, 24            # Desaloca espaço na pilha da ISR
    csrrw sp, mscratch, sp     # Troca sp com mscratch novamente     

    csrr t0, mepc   # load return address (address of the instruction that invoked the syscall)
    addi t0, t0, 4  # adds 4 to the return address (to return after ecall) 
    csrw mepc, t0   # stores the return address back on mepc
    mret            # Recover remaining context (pc <- mepc)

set_engine_and_steering:
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
    li a0, 0xFFFF0121                   # a0 recebe o endereço da engine
    sb t0, (a0)                         # Saída para a engine direction
    
    # Ajuste da steering wheel
    li a0, 0xFFFF0120                   # a0 recebe o endereço da steering wheel
    sb a1, (a0)                         # Saída para o steering wheel angle
    li a0, 0                            # Retorno da função: a0 = 0 -> sucesso
    j 3f
    2:
    li a0, -1                           # Retorno da função: a0 = -1 -> failure
    3:
    jr t2

set_hand_brake:
# entrada: a0 
# saída: -
    mv t0, a0                           # t0 recebe o valor de a0
    li a0, 0xFFFF0122
    sb t0, (a0)
    jr t2

read_sensors:
# entrada: a0 = endereço do array com 256 elementos que vai guardar a leitura 
# saída: -

get_position:
# entrada: a0 = endereço da variavel x; a1 = endereço da variavel y; a2 = endereço da variavel z
# saída: -
    # ligar o gps e pegar salvar as leituras nos endereços
    # Ativar o GPS
    li t0, 1
    li t1, 0xFFFF0100
    sb t0, (t1)
    0:
        lb t0, (t1)
        bnez t0, 0b 
    li t1, 0xFFFF0110   # Endereço do valor lido de X   
    lw t0, (t1)         # Valor de X
    sw t0, (a0)         # Guarda o valor de X na variável recebida
    lw t0, 4(t1)        # Valor de Y
    sw t0, (a1)         # Guarda o valor de Y na variável recebida
    lw t0, 8(t1)        # Valor de Z
    sw t0, (a2)         # Guarda o valor de Z na variável recebida
    jr t2

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
    la t0, user_main    # Loads the user software
    csrw mepc, t0       # entry point into mepc

    li sp, 0x07FFFFFC   # Inicializa a user stack
    mret                # PC <= MEPC; mode <= MPP;

.globl control_logic
control_logic:
# implement your control logic here, using only the defined syscalls
    # syscall para o carro andar
    li a7, 10
    li a0, 1
    li a1, 0
    ecall
    li t0, 10000
    0:                                  # Busy waiting para fazer o carro andar por 10000 iterações 
        addi t0, t0, -1
        bnez t0, 0b

    # syscall para parar o carro e virar o volante
    li a7, 10
    li a0, 0
    li a1, -100
    ecall

    li t0, 7100
    1:                                  # Busy waiting para fazer o carro virar para a esquerda durante 12500 iterações
        addi t0, t0, -1
        bnez t0, 1b

    # syscall para zerar o volante e colocar o carro pra andar
    li a7, 10
    li a0, 1
    li a1, 0
    ecall

    li t0, 15000       
    w:                                  # Busy waiting para fazer o carro andar por  iterações           
        addi t0, t0, -1
        bnez t0, w

    # syscall para parar o carro
    li a7, 10
    li a0, 0
    li a1, 0
    ecall
    # syscall para ligar o hand brake
    li a7, 11
    li a0, 1
    ecall

.section .bss
usr_stack:                     # Final da pilha do user
.skip 1024                     # Aloca 1024 bytes para a pilha
usr_stack_end:                 # Base da pilha do user 