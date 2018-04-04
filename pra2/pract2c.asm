;**************************************************************************
; SBM 2015. ESTRUCTURA BÁSICA DE UN PROGRAMA EN ENSAMBLADOR
;**************************************************************************
; DEFINICION DEL SEGMENTO DE DATOS
DATOS SEGMENT
	MATRIX DB 1,0,0,0,1,1,0,  0,1,0,0,1,0,1,  0,0,1,0,0,1,1,  0,0,0,1,1,1,1 ; Matriz de Generacion
	DV DB 4 DUP (?)

	STR1 DB "Input: ",34,"X X X X",34,13,10
	STR2 DB "Output: ",34,"X X X X X X X",34,13,10
	STR3 DB "Computation:",13,10
	STR4 DB "     | P1 | P2 | D1 | P4 | D2 | D3 | D4",13,10
	STR5 DB "WORD | ?  | ?  |  X | ?  |  X |  X |  X",13,10
	STR6 DB "P1   | X  |    |  X |    |  X |    |  X",13,10
	STR7 DB "P2   |    | X  |  X |    |    |  X |  X",13,10
	STR8 DB "P4   |    |    |    | X  |  X |  X |  X",13,10,"$"

	ASK DB "Teclea un numero entre 0 y 15",13,10,"$"
	ERRO DB "Error: El numero tiene que estar entre 0 y 15$"
	READ DB 4 DUP (?)
DATOS ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO DE PILA
PILA SEGMENT STACK "STACK"
	DB 40H DUP (0) ;ejemplo de inicialización, 64 bytes inicializados a 0
PILA ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO EXTRA
EXTRA SEGMENT
	VECTOR DB 4 DUP (?)
	RESULT DB 7 DUP (?)
EXTRA ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO DE CODIGO
CODE SEGMENT
	ASSUME CS: CODE, DS: DATOS, ES: EXTRA, SS: PILA
; COMIENZO DEL PROCEDIMIENTO PRINCIPAL
INICIO PROC
	; INICIALIZA LOS REGISTROS DE SEGMENTO CON SU VALOR
	MOV AX, DATOS
	MOV DS, AX
	MOV AX, PILA
	MOV SS, AX
	MOV AX, EXTRA
	MOV ES, AX
	MOV SP, 64 ; CARGA EL PUNTERO DE PILA CON EL VALOR MAS ALTO
	; FIN DE LAS INICIALIZACIONES
	; COMIENZO DEL PROGRAMA
	CALL TECLADO


	; Inicializa los registros con el vector
	MOV DH, DV[0]
	MOV DL, DV[1]
	MOV BH, DV[2]
	MOV BL, DV[3]
	; Llama a las subrutinas
	CALL MATMULT
	CALL PRINT

	; FIN DEL PROGRAMA
	MOV AX, 4C00H
	INT 21H
INICIO ENDP
; COMIENZO DE LA SUBRUTINA
TECLADO PROC NEAR
	; IMPRIME EL MENSAJE QUE PIDE UN NUMERO
	MOV AH, 9
	MOV DX, OFFSET ASK
	INT 21H
	; LEE POR TELADO EL NUMERO
	MOV AH, 0Ah
	MOV DX, OFFSET READ
	MOV READ[0], 3 ; QUEREMOS LEER 2 DIGITOS COMO MUCHO
	INT 21h
	; OPERAMOS
	MOV AH, 0
	MOV AL, READ[2] ; LEE EL PRIMER DIGITO
	SUB AX, 30h ; LO TRANSFORMA EN ENTERO
	MOV CL, 10
	CMP READ[1], 2
	JNZ ONEDIGIT ; SI SOLO TIENE UN DIGITO, YA ESTA

	MUL CL ; SI HAY DOS, LO MULTIPLICA POR 10
	MOV DH, 0
	MOV DL, READ[3] ; LEE EL SEGUNDO DIGITO
	SUB DX, 30h ; LO TRANSFORMA EN ENTERO
	ADD AX, DX ; SUMA LOS DOS PARA OBTENER EL NUMERO INTRODUCIDO

	ONEDIGIT:
	CMP AX, 0
	JL ERROR ; SI ES NEGATIVO ERROR

	CMP AX, 15
	JG ERROR ; SI ES MAYOR QUE 15 ERROR

	MOV DX, AX
	AND DL, 1 ; NOS QUEDAMOS CON EL BIT MENOS SIGNIFICATIVO
	MOV DV[3], DL
	SHR AX, 1

	MOV DX, AX
	AND DL, 1 ; NOS QUEDAMOS CON EL SEGUNDO BIT MENOS SIGNIFICATIVO
	MOV DV[2], DL
	SHR AX, 1

	MOV DX, AX
	AND DL, 1 ; NOS QUEDAMOS CON EL TERCER BIT MENOS SIGNIFICATIVO
	MOV DV[1], DL
	SHR AX, 1

	MOV DX, AX
	AND DL, 1 ; NOS QUEDAMOS CON EL CUARTO BIT MENOS SIGNIFICATIVO
	MOV DV[0], DL

	RET

	ERROR:
		; IMPRIME EL MENSAJE DE ERROR
		MOV AH, 9
		MOV DX, OFFSET ERRO
		INT 21H
		; TERMINA EL PROGRAMA
		MOV AX, 4C00H
		INT 21H

TECLADO ENDP

MATMULT PROC NEAR
	; guardo en memoria el vector
	MOV VECTOR[0], DH
	MOV VECTOR[1], DL
	MOV VECTOR[2], BH
	MOV VECTOR[3], BL

	MOV DI, 7 ; inicializo el primer indice a 7. Este recorre las columnas
	COLUMNS:
		DEC DI
		MOV SI, 4 ; inicializo segundo indice a 4. Recorre filas
		MOV BX, 28 ; realmente BX siempre es SI * 7, pero seria mas incomodo estarlo multiplicando
		MOV DX, 0 ; inicializo el acumulador a 0
		ROWS:
			DEC SI ; decremento el indice
			SUB BX, 7
			MOV AL, VECTOR[SI] ; guardo en AL el elemento del vector que toca
			MUL MATRIX[BX][DI] ; lo multiplico por el elemento de la matriz que toca
			ADD DX, AX ; sumo el resultado en el acumulador
			CMP SI, 0 ; si no ha recorrido todas las filas de la columna
			JNZ ROWS ; siguiente iteracion del bucle
		AND DL, 1 ; modulo 2
		MOV RESULT[DI], DL ; guarda el aumulador de esta fila en el resultado
		CMP DI, 0 ; si no ha recorrido todas las columnas
		JNZ COLUMNS ; siguiente iteracion del bucle

	; guardo la salida en los registros
	MOV DX, SEG RESULT
	MOV AX, OFFSET RESULT

	RET
MATMULT ENDP

PRINT PROC NEAR
	; CAMBIA LAS X DE STR1
	MOV BL, VECTOR[0]
	ADD BL, 30h
	MOV STR1[8], BL
	MOV BL, VECTOR[1]
	ADD BL, 30h
	MOV STR1[10], BL
	MOV BL, VECTOR[2]
	ADD BL, 30h
	MOV STR1[12], BL
	MOV BL, VECTOR[3]
	ADD BL, 30h
	MOV STR1[14], BL
	; CAMBIA LAS X DE STR2 HASTA STR8
	MOV BL, RESULT[4] ; P1
	ADD BL, 30h
	MOV STR2[9], BL
	MOV STR6[7], BL
	MOV BL, RESULT[5] ; P2
	ADD BL, 30h
	MOV STR2[11], BL
	MOV STR7[12], BL
	MOV BL, RESULT[0] ; D1
	ADD BL, 30h
	MOV STR2[13], BL
	MOV STR5[18], BL
	MOV STR6[18], BL
	MOV STR7[18], BL
	MOV BL, RESULT[6] ; P4
	ADD BL, 30h
	MOV STR2[15], BL
	MOV STR8[22], BL
	MOV BL, RESULT[1] ; D2
	ADD BL, 30h
	MOV STR2[17], BL
	MOV STR5[28], BL
	MOV STR6[28], BL
	MOV STR8[28], BL
	MOV BL, RESULT[2] ; D3
	ADD BL, 30h
	MOV STR2[19], BL
	MOV STR5[33], BL
	MOV STR7[33], BL
	MOV STR8[33], BL
	MOV BL, RESULT[3] ; D4
	ADD BL, 30h
	MOV STR2[21], BL
	MOV STR5[38], BL
	MOV STR6[38], BL
	MOV STR7[38], BL
	MOV STR8[38], BL
	; IMPRIME (COMO SOLO HAY $ EN STR8, LAS IMPRIME TODAS JUNTAS)
	MOV AH, 9
	MOV DX, OFFSET STR1
	INT 21h

	RET
PRINT ENDP
; FIN DEL SEGMENTO DE CODIGO
CODE ENDS
; FIN DEL PROGRAMA INDICANDO DONDE COMIENZA LA EJECUCION
END INICIO 