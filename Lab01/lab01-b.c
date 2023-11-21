int read(int __fd, const void *__buf, int __n){
    int ret_val;
	__asm__ __volatile__(
    "mv a0, %1           # file descriptor\n"
    "mv a1, %2           # buffer \n"
    "mv a2, %3           # size \n"
    "li a7, 63           # syscall write code (63) \n"
    "ecall               # invoke syscall \n"
    "mv %0, a0           # move return value to ret_val\n"
    : "=r"(ret_val)  // Output list
    : "r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
	);
	return ret_val;
}

void write(int __fd, const void *__buf, int __n)
{
	__asm__ __volatile__(
    "mv a0, %0           # file descriptor\n"
    "mv a1, %1           # buffer \n"
    "mv a2, %2           # size \n"
    "li a7, 64           # syscall write (64) \n"
    "ecall"
    :   // Output list
    :"r"(__fd), "r"(__buf), "r"(__n)    // Input list
    : "a0", "a1", "a2", "a7"
	);
}

int soma(int a , int b) {
	return (a + b);
}

int sub(int a, int b) {
	return (a - b);
}

int mult(int a, int b) { 
	return (a * b);
}

int char_int(char a) {
	return a - '0'; 
}

char int_char(int a) {
	return a + '0';
}

void exit(int code)
{
	__asm__ __volatile__(
    "mv a0, %0           # return code\n"
    "li a7, 93           # syscall exit (64) \n"
    "ecall"
    :   // Output list
    :"r"(code)    // Input list
    : "a0", "a7"
	);
}

void _start()
{
	int ret_code = main();
	exit(ret_code);
}

#define STDIN_FD  0
#define STDOUT_FD 1

/* Aloca um buffer com 6 bytes.*/
char buffer[6];

int main()
{
  	/* Lê uma string da entrada padrão */
	int n = read(STDIN_FD, (void*) buffer, 6);

	/* Atribuição dos dados */
	int num = char_int(buffer[0]);
	int num2 = char_int(buffer[4]);
	char op = buffer[2];
	char resultado[2];
	/* Realização da operação requisitada */
	switch (op) {
		case '+':
			resultado[0] = int_char(soma(num, num2));
			break;
		case '-':
			resultado[0] = int_char(sub(num, num2));
			break;
		case '*':
			resultado[0] = int_char(mult(num, num2));
			break;
	}	

	resultado[1] = '\n';

	/* Imprime o resultado da operação */
	write(STDOUT_FD, (void*) resultado, 2);

	return 0;
}
