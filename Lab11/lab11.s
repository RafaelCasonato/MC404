# Mover o carro do estacionamento até a entrada do Test Track
# Deve ser feito em até 180s
# Coordenadas da entrada do Test Track: (X, Y, Z) = (73, 1, -19)
# Chegou no destino: carro está em um ponto dentro de um raio de 15m da entrada
# Endereço base: 0xFFFF0100 
# Valores da direção variam de -127 a 127, negativo é pra esquerda e positivo pra direita
# Coordenadas da posição inicial do carrinho: {"x":180.5295867919922,"y":2.597162961959839,"z":-108.00169372558594}

.section .text
.globl _start
.set STEERING_WHEEL, 0xFFFF0120         # Variam de -127 a 127, negativo é pra esquerda e positivo pra direita
.set ENGINE_DIRECTION, 0xFFFF0121       # 1: para frente / 0: parar / -1: para trás
.set HAND_BRAKE, 0xFFFF0122             # 1: ativado

_start:
    li a1, 10000
    li a0, ENGINE_DIRECTION
    li t0, 1                    
    sb t0, (a0)                         # Saída para a engine direction: 1 para andar para frente
    0:                                  # Busy waiting para fazer o carro andar por 10000 iterações 
        addi a1, a1, -1
        bnez a1, 0b

    sb zero, (a0)
    li a1, -100
    li a0, STEERING_WHEEL   
    sb a1, (a0)                         # Saída para a steering wheel: virar o carro -100 para a esquerda
    li a1, 6500
    1:                                  # Busy waiting para fazer o carro virar para a esquerda durante 12500 iterações
        addi a1, a1, -1
        bnez a1, 1b

    sb zero, (a0)
    li a0, ENGINE_DIRECTION
    sb t0, (a0)                         # Saída para a engine direction: 1 para andar pra frente
    li a1, 1600            
    w:                                  # Busy waiting para fazer o carro andar por 1500 iterações           
        addi a1, a1, -1
        bnez a1, w

    li a0, ENGINE_DIRECTION             # Saída para a engine direction: 0 para parar o carro
    sb zero, (a0)


