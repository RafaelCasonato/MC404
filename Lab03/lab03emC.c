#include <stdio.h>

int potencia(int x, int y) {
/* Função que retorna o valor da potência com base x e expoente y. */
	int resultado = 1;
    for (int i = 0; i < y; i++) {
		resultado *= x;
	}
	return resultado;
}

int digitos_dec(int x) {
/* Função que calcula o número de digitos de um decimal. */
    int aux = x;
    int i = 0;
    for (i;; i++) {
        if (aux == 0) {
            return i + 1;
        }
        aux = aux / 10;
    }
    return i + 1;
}

void unsignedint_to_char(unsigned int numero) {
    int expoente;
    unsigned int aux = numero;
    int i, j, corretor;
    int m = 0;
    for (m;; m++) {
        if (aux == 0) {
            break;
        }
        aux = aux / 10;
    }
    char decimal[m + 1];
    expoente = m - 1;
    i = 0;
    j = m;
    decimal[m] = '\n';
    aux = numero;
    for (i;; i++) {
        if ((((aux / potencia(10, expoente))) == 0) && (expoente < 0))
            break;
        decimal[i] = ((aux / potencia(10, expoente))) + '0'; 
        aux = aux % potencia(10, expoente);
        expoente--;
    }
    //write(STDOUT_FD, decimal, m + 1);
}

void int_to_char(int numero) {
/* Função que representa um decimal int como char. */
    int expoente;
    int aux = numero;
    int i, j, corretor;
    int n = digitos_dec(numero);
    char decimal[n + 1];
    expoente = n - 2;
    if (numero < 0) {
        i = 1;
        j = n + 1;
        decimal[0] = '-';
        corretor = -1;
        decimal[n] = '\n';
    }
    else {
        i = 0;
        j = n;
        corretor = 1;
        decimal[n - 1] = '\n';
    }
    for (i;; i++) {
        if (((aux / potencia(10, expoente))) == 0)
            break;
        decimal[i] = ((aux / potencia(10, expoente)) * corretor) + '0'; 
        aux = aux % potencia(10, expoente);
        expoente--;
    }
    //write(STDOUT_FD, decimal, i + 1);
}

void inverte(char *numero, int inicio, int fim) {
/* Função que inverte o char in place. */
    if (inicio > fim) 
        return;
    char aux = numero[fim];
    numero[fim] = numero[inicio];
    numero[inicio] = aux;
    inverte(numero, inicio + 1, fim - 1);
}

int char_to_int(char *entrada, int n, int base) {
/* Função que transforma um inteiro representado em char para int. Além disso, realiza a troca de base
hexadecimal para decimal, se requisitado. */
    unsigned int soma = 0;
	int expoente = 0;
	int valor = 0;
    int j;
    int negativo = 0;
    if (base == 16)
        j = 2;
    else if (entrada[0] == '-') {
        j = 1;
        negativo = 1;
    }
    else 
        j = 0;
	for (int i = n - 2; i > j - 1; i--) {
		if ((entrada[i] <= 102) && (entrada[i] >= 97))
			valor = entrada[i] - 87;
		else 
			valor = entrada[i] - '0';
		soma += valor * (potencia(base, expoente));
		expoente++;
	}
    if (negativo == 1) {
        soma *= -1;
    }
	return soma;
}

void dec_bi(int numero) {
/* Função que realiza a mudança de base decimal para binária. */
    int base = 2;
    unsigned int aux = numero;
    int i = 2;
    char binario[35];
    binario[0] = '0';
	binario[1] = 'b';
    while (aux / base != 0) {
        char num = (aux % base) + '0'; 
        binario[i] = num;
        aux = aux / base;
        i++;
    }
    binario[i] = (aux % base) + '0';
    binario[i + 1] = '\n';
    inverte(binario, 2, i);
    //write(STDOUT_FD, binario, i + 2); 
}

void inverte_endianness(char *numero, int i) {
/* Função que inverte o endianness de um número hexadecimal e imprime o resultante na base decimal. */
    char aux;
    if (i != 9) {
        char novo[11];
        novo[0] = '0';
        novo[1] = 'x';
        novo[10] = '\n';
        int j = 2;
        int l = 0;
        int limite = 10 - (i + 1);
        for (j; l < limite; j++) {
            novo[j] = '0';
            l++;
        }
        for (int k = 2; k < i + 1; k++) {
            novo[j] = numero[k];
            j++;
        }
        numero = novo;
    }

    aux = numero[2];
    numero[2] = numero[8];
    numero[8] = aux;

    aux = numero[3];
    numero[3] = numero[9];
    numero[9] = aux;

    aux = numero[4];
    numero[4] = numero[6];
    numero[6] = aux;

    aux = numero[5];
    numero[5] = numero[7];
    numero[7] = aux;
    
    unsigned int num = char_to_int(numero, 11, 16);
    unsignedint_to_char(num);
}

void dec_hex(int numero) {
/* Função que realiza a mudança de base decimal para hexadecimal. */
    int base = 16;
    unsigned int aux = numero;
	int i = 2;
    char hex[11];
	hex[0] = '0';
	hex[1] = 'x';
    for (i; ; i++) {
        int resto = (aux % base); 
		if (resto <= 15 && resto >= 10)
			hex[i] = resto + 87;
		else 
			hex[i] = resto + '0';
        if (aux / base == 0)
            break;
        aux = aux / base;
    }
	hex[i + 1] = '\n';
    inverte(hex, 2, i);
    //write(STDOUT_FD, hex, i + 2);
    inverte_endianness(hex, i);
}

int main() {
    //int numero = char_to_int("0x80000000\n", 11, 16);
    int numero = char_to_int("-42\n", 4, 10);
    dec_bi(numero);
    int_to_char(numero);
    dec_hex(numero);
    // char entrada[20];
    // int n = read(STDIN_FD, entrada, 20);
    // if (entrada[1] == 'x') {
    //     int numero = char_to_int(entrada, n, 16);
    //     dec_bi(numero);
    //     int_to_char(numero);
    //     dec_hex(numero);
    // }
    // else {
    //     int numero = char_to_int(entrada, n, 10);
    //     dec_bi(numero);
    //     int_to_char(numero);
    //     dec_hex(numero);
    // }
    // return 0;
}