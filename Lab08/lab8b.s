.section .text
.globl _start
_start:
    # Open image
    la a0, input_file       # address for the file path
    li a1, 0                # flags (0: rdonly, 1: wronly, 2: rdwr)
    li a2, 0                # mode
    li a7, 1024             # syscall open 
    ecall

    # Read 
    # a0 ja possui o endereco do input_file
    la a1, input_address    #  buffer to write the data
    li a2, 262159           # size (reads only 1 byte)
    li a7, 63               # syscall read (63)
    ecall

    la a3, input_address
    addi a3, a3, 3
    jal get_width_height    
    mv s0, a0               # s0 guarda widht
    addi a2, a2, 1
    add a3, a3, a2
    jal get_width_height
    mv s1, a0               # s1 guarda height
    addi a2, a2, 1          
    add a3, a3, a2
    addi a3, a3, 4          # a3 está no começo dos pixels da imagem

    # setCanvasSize
    mv a0, s0
    mv a1, s1
    li a7, 2201
    ecall

    jal fazBorda
    
    li a7, 2200                 # syscall setPixel (2200)
    li t0, 0                    # valor minimo do pixel
    li t1, 256                  # valor maximo do pixel

    mv t2, a3                   
    add t2, t2, s0 
    addi t2, t2, 1              # t2 tem o endereço do pixel (1,1)
    
    addi s2, s0, -1             # s2 = largura -1; a imagem de saida tem largura -1 e 
    addi s3, s1, -1             # s3 = altura -1; pois existem as bordas

    li a1, 1                    # indice inicial da linha
    f:                          # for para percorrer as linhas
        li a0, 1                # indice inicial da coluna, volta a ser 1 sempre que sair de f2
        bge a1, s3, cont        # para quando a1 chegar na ultima linha
        f2:                     # for para percorrer as colunas
            bge a0, s2, cont2   # para quando a0 chegar na ultima coluna
            li a4, 0            # valor do pixel
            li a2, 0            
            jal applyFilter     # a4 = valor do pixel
            blt a4, t1, max
            li a4, 255
            max:
            bge a4, t0, min
            li a4, 0
            min:
            jal setRGB
            ecall
            addi a0, a0, 1
            addi t2, t2, 1
            j f2
        cont2:
            addi a1, a1, 1
            addi t2, t2, 2
            j f
    cont:
    # Exit
    li a0, 0
    li a7, 93
    ecall

get_width_height:
    mv t4, a3       # endereco da linha em t4
    li t1, 32       # Valor em ASCII para o espaço
    li t5, 10       # valor em ASCII para o \n
    li t3, 0        # armazena o numero de digitos
    
    while:
        lbu t2, (t4)
        beq t2, t1, continua
        beq t2, t5, continua
        addi t3, t3, 1  # Número de dígitos
        addi t4, t4, 1
        j while

    continua:
    li a0, 3
    mv t4, a3
    li t0, 0
    beq a0, t3, 3f
    li a0, 2
    beq a0, t3, 2f
    addi t4, t4, -2
    j 1f
    
    2:
    addi t4, t4, -1
    j 2f
    
    3:
    li t2, 100
    lb t5, 0(t4)
    addi t5, t5, -48
    mul t5, t5, t2
    add t0, t0, t5
    
    2:
    li t2, 10
    lb t1, 1(t4)
    addi t1, t1, -48
    mul t1, t1, t2
    add t0, t0, t1
    
    1:
    lb t1, 2(t4)
    addi t1, t1, -48
    add t0, t0, t1

    mv a0, t0                   # Valor de widht/height
    mv a2, t3                   # Número de digitos do valor
    ret

setRGB:
    slli a4, a4, 8
    add a2, a2, a4
    slli a4, a4, 8
    add a2, a2, a4
    slli a4, a4, 8
    add a2, a2, a4
    addi a2, a2, 255
    ret

applyFilter:
    add t3, t2, s0      # endereço do primeiro pixel da linha posterior à do pixel central
    addi t3, t3, -1
    sub t4, t2, s0      # endereço do primeiro pixel da linha anterior à do pixel central
    addi t4, t4, -1
    li t5, 3
    li t6, 0
    for_filter:
        bge t6, t5, 5f  # para se t6 >= 3, iterou 3x
        lbu s4, (t3)     
        lbu s5, (t4)
        sub a4, a4, s4
        sub a4, a4, s5
        addi t6, t6, 1
        addi t3, t3, 1
        addi t4, t4, 1
        j for_filter
    5:
    mv t3, t2
    lbu s4, 1(t3)       # pixel posterior ao pixel central
    sub a4, a4, s4
    addi t3, t3, -1
    lbu s4, (t3)        # pixel anterior ao pixel central
    sub a4, a4, s4
    lbu s4, (t2)        # pixel central
    li t4, 8
    mul s4, s4, t4      
    add a4, a4, s4
    ret

fazBorda:
    # s0 é a largura
    # s1 é a altura
    li a7, 2200          # syscall setPixel (2200)
    li a2, 0x000000ff
    mv s11, ra           # Salva o endereço de retorno para a _start em s11
    li a0, 0             # a0, indice da coluna
    li a1, 0             # a1, indice da linha
    for:                 # Preenche a linha 0 com pixels pretos
        bge a0, s0, 1f   # Sai do for com a0 = width
        ecall            # se der problema, voltar pra jal setPixel
        addi a0, a0, 1
        j for
    1:                   
    mv a1, s1
    li a0, 0
    addi a1, a1, -1      # a1 tem a coordenada da ultima linha
    for2:                # Preenche a linha height - 1 com pixels pretos
        bge a0, s0, 2f   # Sai do for com a0 = width
        ecall
        addi a0, a0, 1
        j for2
    2:
    li a0, 0             # a0 começa na primeira coluna 
    li a1, 1             # a1 começa na segunda linha
    mv t0, s1 
    addi t0, t0, -1      # t0 é o indice da ultima linha
    for3:                # Preenche a primeira coluna com pixels pretos 
        bge a1, t0, 3f   # Sai do for com a1 = height - 1, fez até height - 2
        ecall
        addi a1, a1, 1
        j for3
    3: 
    li a1, 1             # a1 começa na segunda linha
    mv a0, s0            
    addi a0, a0, -1      # a0 é a útlima coluna
    for4:                # Preenche a última coluna com pixels pretos
        bge a1, t0, sai
        ecall
        addi a1, a1, 1
        j for4
    sai:
    mv ra, s11
    ret

.section .bss
input_address: .skip 262159
.section .data
input_file: .asciz "image.pgm"