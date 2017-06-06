	.global main      @ ligador precisa desse rótulo

@///////////////////////////////Controle inicial////////////////////////////////////////////////////////////////////////
	@ Endereco do teclado
	.set dados_teclado,   	0x00090000	@ endereço do teclado na memória
	.set status_teclado, 	0x00090001	@ endereço do status do teclado na memória
	.equ flag,		1			@ flag do teclado

	@ Constantes que definem o tamanho da chave e da mensagem
	.equ key_size,		16			@ define o tamanho maximo para chave de 15 caracteres e 1 espaco para o \n
	.equ msg_size,		255			@ define o tamanho maximo para mensagem 254 caracteres e 1 espaco para o \n

main:

@/////////////////////////////////////inicio///////////////////////////////////////////////////////////////////
	@escreve no console pedindo a chave de criptografia
	mov     r0, #1      			@ Comando de saida padrão
	ldr     r1, =mensagem1    			@ carrega o r1 com o endereco da mensagem que será escrita
	ldr     r2, =len    			@ tamanho da mensagem
	mov     r7, #4                  @r7 recebe função padrão de escrita
	svc     0x55                   @chamada do sistema para a função

	@ Leitura inicial do *
leitura_inicial:
	ldr		r3, =status_teclado
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #flag			@ Compara R4 com 0x1
	bne    	leitura_inicial			@ Fica no loop se diferentes
	ldr		r3, =dados_teclado
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado

	@ Comparar se precionou '*' para iniciar a chave
	cmp		r4, #10					@ Comprar se foi digitado o *
	bne		leitura_inicial			@ Se diferente de * volta para leitura_inicial
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	0x55

@/////////////////////////////////////faz leitura da chave/////////////////////////////////////////////////////
	@ depois de ler e escrever um *, inicia a leitura da chave numérica

	mov		r5, #0					@ Controle do deslocamento da chave
leitura_chave:
	ldr		r3, =status_teclado
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #flag			@ Compara R4 com 0x1
	bne    	leitura_chave		@ Fica no loop se diferentes
	ldr		r3, =dados_teclado
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado
	cmp		r4, #10					@ Compara se foi outro *
	bne		escrever				@ Se diferente de * escreve na tela e guarda
	b		leitura_chave

	@ Exibe um asterisco na tela
escrever:
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	0x55

	@ Compara se precionou '#' para encerar a chave
	cmp		r4, #11					@ Compara se foi '#'
	bne	guardar_chave			@ Se for diferente salva e le outro valor

	b 		leitura_mensagem		@ Se nao vai para leitura_mensagem

@////////////////////////////////////guarda a chave//////////////////////////////////////////////////////
	@ Guarda a chave na memoria
guardar_chave:
	ldr 	r10, =chave				@ coloca endereco em R10
	strb	r4, [r10, r5]			@ Armazena o valor
	add 	r5, r5, #1				@ Incrementa Deslocamento
	mov 	r4, #0					@ Limpa registrador
	b		leitura_chave		@ Retorna a leitura da chave

@///////////////////////////////////faz leitura da mensagem//////////////////////////////////////////////////////////
leitura_mensagem:

	@Escreve no console pedindo para digitar a mensagem
	mov     r0, #1      			@ Comando de saida
	ldr     r1, =mensagem2    			@ Endereco da mensagem
	ldr     r2, =len2    			@ Tamanho mensagem a ser escrita
	mov     r7, #4
	svc     0x055

	@Faz a leitura da mensagem digitada pelo usuario
	mov     r0, #0      			@ Comando de entrada
	ldr     r1, =mensagem    		@ Endereco da mensagem
	ldr     r2, =msg_size 			@ Tamanho maxio a ser lido
	mov     r7, #3
	svc     0x55

@///////////////////////////////////criptografa mensagem/////////////////////////////////////////////////////////////
	mov		r0, #0					@ Registrador vai ser usado no desolocamento da mensagem e mensagem criptografada
	mov		r1, #0					@ Registrador vai ser usado no desolocamento da chave
	ldr		r2, =mensagem			@ Define o endereco da mensagem em r2
	ldr		r3, =chave				@ Define o endereco da chave em r3
	ldr		r4, =msg_cripto			@ Define o endereco da mensagem criptografada em r4

criptografia:
	@ Inicio do processo de criptografia
	ldrb	r5, [r2, r0]			@ Em r5 define o inicio da mensagem
	cmp		r5, #0x0A				@ Se for o enter (0A em ascii) encera a criptografia
	beq		escreve_cripto			@ E vai para escreve_cripto que apresenta a mensagem criptografada
	ldrb	r6, [r3, r1]			@ Em r6 define o inicio da chave
	cmp		r6, #0					@ Se for nulo volta ao inico da chave
	moveq	r1, #0					@ Mudando o deslocamento para 0
	add		r5, r5, r6				@ Adiciona na possicao da mensagem o valor da chave na possicao do deslocamento
	strb	r5, [r4, r0]			@ Escreve na memoria o resultado da soma
	add		r0, r0, #1				@ Desloca um no controle das mensagem
	add		r1, r1, #1				@ Desloca um no controle da chave
	b		criptografia			@ retorna ao inico da criptografia

escreve_cripto:
	mov		r5, #0x0A				@ Coloca o enter em ascii no registrador 5
	strb	r5, [r4, r0]			@ para q no final da mensagem fique enter para para na descriptografia

	@Escreve a mensagem criptografada
	mov     r0, #1   				@ Comando de saida
	ldr     r1, =msg_cripto			@ Endereco da mensagem
	ldr     r2, =msg_size			@ Tamanho da mensagem
	mov     r7, #4
	svc     #0x55

@///////////////////////////////////inicio descriptografia da mensagem/////////////////////////////////////////////////

	@Escreve a mensagem pedindo a chave de descriptografia
	mov     r0, #1      			@ Comando de saida
	ldr     r1, =mensagem3    			@ Endereco da mensagem
	ldr     r2, =len3	 			@ Tamanho da mensagem
	mov     r7, #4
	svc     #0x55

	@ Leitura inicial da chave *
leitura_desc:
	ldr		r3, =status_teclado
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #flag			@ Compara R4 com 0x1
	bne    	leitura_desc			@ Fica no loop se diferentes
	ldr		r3, =dados_teclado
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado

	@ Comparar se precionou '*' para iniciar a chave
	cmp		r4, #10					@ Comprar se foi digitado o *
	bne		leitura_desc			@ Se diferente de * volta para leitura
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	#0x55

@///////////////////////////////////faz leitura da chave//////////////////////////////////////
	@ Apos digitado * leitura da chave

	mov		r5, #0					@ Controle do deslocamento da chave de descriptografia
leitura_kdb_desc:
	ldr		r3, =status_teclado
	ldr		r4, [r3]				@ Carrega no R4 o valor de R3
	cmp     r4, #flag			@ Compara R4 com 0x1
	bne    	leitura_kdb_desc		@ Fica no loop se diferentes
	ldr		r3, =dados_teclado
	ldr		r4, [r3]				@ Se nao, carrega em R4 o valor digitado
	cmp		r4, #10					@ Compara se foi outro *
	bne		escrever2				@ Se diferente de * escreve na tela e guarda
	b		leitura_kdb_desc

	@ Exibe um asterisco na tela
escrever2:
	mov    	r0, #1  				@ Comando de saida
	mov    	r1,	#10			 		@ Define a mensagem como *
	mov    	r2, #1					@ Define tamanho mensagem a ser escrita como 1
	mov    	r7, #4
	svc    	#0x55

	@ Compara se precionou '#' para encerar a chave
	cmp		r4, #11					@ Compara se foi '#'
	bne		guardar_desc			@ Se for diferente salva e le outro valor
	b 		descriptografar			@ Se nao vai para descriptografia

@///////////////////////////////////guarda chave////////////////////////////////////////////////////
@ Guarda a chave na memoria
guardar_desc:

	ldr 	r10, =chave_desc				@ coloca endereco em R10
	strb	r4, [r10, r5]			@ Armazena o valor
	add 	r5, r5, #1				@ Deslocamento
	mov 	r4, #0					@ Limpa registrador
	b		leitura_kdb_desc		@ Retorna a leitura da chave

@///////////////////////////////////faz descriptografia/////////////////////////////////////////////
descriptografar:
	mov		r0, #0					@ Registrador controla desolocamento das mensagens
	mov		r1, #0					@ Registrador controla desolocamento da chave
	ldr		r2, =msg_cripto			@ Define o endereco da mensagem criptografadaem r2
	ldr		r3, =chave_desc			@ Define o endereco da chave de descriptografia em r3
	ldr		r4, =msg_desc			@ Define o endereco da mensagem descriptografada em r4

descriptografia:
	@ Inicio do processo de descriptografia
	ldrb	r5, [r2, r0]			@ Em r5 define o inicio da mensagem criptografada
	cmp		r5, #0x0A				@ Se for o enter (0A em ascii) encera a descriptografia
	beq		escreve_desc			@ E vai para escreve_desc que apresenta a mensagem descriptografada
	ldrb	r6, [r3, r1]			@ Em r6 define o inicio da chave descriptografia
	cmp		r6, #0					@ Se for nulo volta ao inico da chave
	moveq	r1, #0					@ Mudando o deslocamento para 0
	sub		r5, r5, r6				@ Subtrai na possicao da mensagem o valor da chave na possicao do deslocamento
	strb	r5, [r4, r0]			@ Escreve na memoria o resultado da subtracao
	add		r0, r0, #1				@ Desloca um no controle das mensagem
	add		r1, r1, #1				@ Desloca um no controle da chave
	b		descriptografia			@ retorna ao inico da descriptografia

escreve_desc:

	@Escreve a mensagem criptografada
	mov     r0, #1   				@ Comando de saida
	ldr     r1, =msg_desc			@ Endereco da mensagem
	ldr     r2, =msg_size			@ Tamanho da mensagem
	mov     r7, #4
	svc     #0x55

final:
	mov     r0, #0
	mov     r7, #1
	svc     #0x55

@///////////////////////////////////mensagens///////////////////////////////////////////////////////

@mensagens exibidas para o usuario no console
           
mensagem1:		.ascii   "|---------------------------------|\n|Insira uma chave de criptografia |\n|---------------------------------|\n|inicie com '*' e termine com '#' |\n|---------------------------------|\n"
len = . - mensagem1
mensagem2:		.ascii   "\n|---------------------------------|\n|Insira a mensagem a criptografar |\n|---------------------------------|\n\n"
len2 = . - mensagem2
mensagem3:		.ascii   "\n|---------------------------------|\n|A mensagem esta criptografada!   |\n|---------------------------------|\n|Insira a chave de descriptografia|\n|---------------------------------|\n|inicie com '*' e termine com '#' |\n|---------------------------------|\n"
len3 = . - mensagem3


@onde serao armazenados os caracteres lidos

chave:
	.skip key_size			@ guarda a chave de criptografia
chave_desc:
	.skip key_size			@ guarda a chave de descriptografia
mensagem:
	.skip msg_size			@ guarda a mensagem digitada
msg_cripto:
	.skip msg_size			@ guarda a mensagem criptografada
msg_desc:
	.skip msg_size			@ guarda a mensagem descriptografada

