.section .text
.globl _start
.globl main
.globl interrupts
.globl play_note
.globl _system_time
.set GPT, 0xFFFF0100
.set MIDI_CHANNEL, 0xFFFF0300
.set ID, 0xFFFF0302
.set NOTE, 0xFFFF0304
.set VELOCITY, 0xFFFF0305
.set DURATION, 0xFFFF0306
.set TIME, 0xFFFF0104
.set INTERRUPTION, 0xFFFF0108

_start:

    # Seta o endereço da função que trata interrupção no registrador mtvec
    la a0, interrupts
    csrw mtvec, a0

    # Seta o endereço da base da stack em mscratch
    la a0, isr_stack_end
    csrw mscratch, a0

    # Habilita Interrupções Externas
    csrr t1, mie               # Seta o bit 11 (MEIE)
    li t2, 0x800               # do registrador mie
    or t1, t1, t2
    csrw mie, t1

    # Habilita Interrupções Global
    csrr t1, mstatus           # Seta o bit 3 (MIE)
    ori t1, t1, 0x8            # do registrador mstatus
    csrw mstatus, t1

    # Seta o GPT pela primeira vez
    la t0, _system_time
    li t1, 0
    sb t1, (t0)

    # Seta o intervalo das interrupções (100ms)
    li t0, INTERRUPTION
    li t1, 100
    sw t1, (t0)
    
    # Chamada da função main
    jal main
    mret

interrupts:
    # Salvar o contexto
    csrrw sp, mscratch, sp     # Troca sp com mscratch
    addi sp, sp, -16           # Aloca espaço na pilha da ISR
    sw a0, 0(sp)               # Salva a0
    sw a1, 4(sp)               # Salva a1
    sw t0, 8(sp)               # Salva t0
    sw t1, 12(sp)               # Salva t1
    
    # Trata a interrupção
    # Seta GPT pra ler o horário
    li t0, GPT
    li t1, 1
    sb t1, (t0)
    0:
        lb t1, (t0)
        bnez t1, 0b
    li a0, TIME
    lw t0, (a0)
    la a1, _system_time
    sw t0, (a1)
    
    # Seta o intervalo das interrupções (100ms)
    li t0, INTERRUPTION
    li t1, 100
    sw t1, (t0)
    
    # Recupera o contexto
    lw t1, 12(sp)              # Recupera t1
    lw t0, 8(sp)               # Recupera t0
    lw a1, 4(sp)               # Recupera a1
    lw a0, 0(sp)               # Recupera a0
    addi sp, sp, 16            # Desaloca espaço na pilha da ISR
    csrrw sp, mscratch, sp     # Troca sp com mscratch novamente     
    mret                       # Retorna da interrupção

play_note:
# Entrada: a0 = ch, a1 = inst, a2 = note, a3 = vel, a4 = dur
# Saída: void
    li t0, MIDI_CHANNEL        # byte
    li t1, ID                  # short
    li t2, NOTE                # byte
    li t3, VELOCITY            # byte
    li t4, DURATION            # short

    # Seta a saída dos peiféricos com os parâmetros da função
    sb a0, (t0)                   
    sh a1, (t1)
    sb a2, (t2)
    sb a3, (t3)
    sh a4, (t4)
    
    ret

.section .data
.section .bss
isr_stack:                     # Final da pilha das ISRs
.skip 1024                     # Aloca 1024 bytes para a pilha
isr_stack_end:                 # Base da pilha das ISRs   
_system_time: .skip 4