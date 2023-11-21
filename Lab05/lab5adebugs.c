void inverte(int *numero, int inicio, int fim) {
/* Função que inverte o ponteiro in place. */
    if (inicio > fim) 
        return;
    int aux = numero[fim];
    numero[fim] = numero[inicio];
    numero[inicio] = aux;
    inverte(numero, inicio + 1, fim - 1);
}

int potencia(int x, int y) {
/* Função que retorna o valor da potência com base x e expoente y. */
	int resultado = 1;
    for (int i = 0; i < y; i++) {
		resultado *= x;
	}
	return resultado;
}

int char_to_int(char *entrada, int start) {
/* Função que transforma um inteiro representado em char para int. */
    unsigned int soma = 0;
	int expoente = 0;
	int valor = 0;
    int j = 0;
    int negativo = 0;
    int n = start + 4;
    if (entrada[start] == '-') {
        negativo = 1;
    }
	for (int i = n; i > start; i--) {
		valor = entrada[i] - '0';
		soma += valor * (potencia(10, expoente));
		expoente++;
	}
    if (negativo == 1) {
        soma *= -1;
    }
	return soma;
}

void completa_bits(int *numero, int i) {
    for (int j = i + 1; j < 32; j++) {
        numero[j] = 0;
    }
}

void pack(int numero, int start_bit, int end_bit, int *val) {
/* Função que realiza a mudança de base decimal para binária. Agrupa os bits a partir do
start_bit ate o end_bit no binario val. */
    int base = 2;
    unsigned int aux = numero;
    int i = 0;
    int binario[32];
    int num = 0;

    while (aux / base != 0) {
        num = (aux % base); 
        binario[i] = num;
        aux = aux / base;
        i++;
    }
    num = (aux % base);
    binario[i] = (aux % base);
    if (numero >= 0)
        completa_bits(binario, i);
    int j = 0;
    
    for (int i = start_bit; i < end_bit + 1; i++) {
        val[i] = binario[j];
        j++;
    }
}

void get_values(char *entrada, int *val_ini) {
    val_ini[0] = char_to_int(entrada, 0);
    val_ini[1] = char_to_int(entrada, 6);
    val_ini[2] = char_to_int(entrada, 12);
    val_ini[3] = char_to_int(entrada, 18);
    val_ini[4] = char_to_int(entrada, 24);
}

void hex_code(int val) {
    char hex[11];
    unsigned int uval = (unsigned int) val, aux;

    hex[0] = '0';
    hex[1] = 'x';
    hex[10] = '\n';

    for (int i = 9; i > 1; i--){
        aux = uval % 16;
        if (aux >= 10)
            hex[i] = aux - 10 + 'A';
        else
            hex[i] = aux + '0';
        uval = uval / 16;
    }
    write(1, hex, 11);
}

void complemento2(int *val) {
    for (int i = 0; i < 32; i++) {
        if (val[i] == 0)
            val[i] = 1;
        else if (val[i] == 1)
            val[i] = 0;
    }
    int carry = 0;
    if (val[0] == 0) {
        val[0] += 1;
    }
    else {
        carry = 1;
        val[0] = 0;
        for (int i = 1; i < 32; i++) {
            int num = val[i] + carry;
            if (num == 1) {
                val[i] = num;
                break;
            }
            else if  (val[i] + 1 > 1) {
                val[i] = 0;
            } 
        }
    }
}

int bi_int(int *val) {
    int soma = 0;
    int negativo = 0;
    if (val[31] == 1) {
        complemento2(val);
        negativo = 1;
    }
    for (int i = 0; i < 32;i++) {
        soma += val[i] * potencia(2, i);
    }
    if (negativo == 1)
        soma *= -1;
    return soma;
}

int main() {
    int val[32];
    char entrada[30];
    int n = read(STDIN_FD, entrada, 30);
    int val_ini[5];
    get_values(entrada, val_ini);
    pack(val_ini[0], 0, 2, val);
    pack(val_ini[1], 3, 10, val);
    pack(val_ini[2], 11, 15, val);
    pack(val_ini[3], 16, 20, val);
    pack(val_ini[4], 21, 31, val);
    int valor = bi_int(val);
    hex_code(valor);
}