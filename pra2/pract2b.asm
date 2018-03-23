;**************************************************************************
; SBM 2015. ESTRUCTURA BÁSICA DE UN PROGRAMA EN ENSAMBLADOR
;**************************************************************************
; DEFINICION DEL SEGMENTO DE DATOS
DATOS SEGMENT
	MATRIX DB 1,0,0,0,1,1,0,  0,1,0,0,1,0,1,  0,0,1,0,0,1,1,  0,0,0,1,1,1,1 ; Matriz de Generacion
	DV DB 1,0,1,1
	VECTOR DB 4 DUP (?)

DATOS ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO DE PILA
PILA SEGMENT STACK "STACK"
	DB 40H DUP (0) ;ejemplo de inicialización, 64 bytes inicializados a 0
PILA ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO EXTRA
EXTRA SEGMENT
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
	; Inicializa los registros con el vector
	MOV DH, DV[0]
	MOV DL, DV[1]
	MOV BH, DV[2]
	MOV BL, DV[3]
	; Llama a la subrutina
	CALL MATMULT
	; Guarda el resultado en memoria

	; FIN DEL PROGRAMA
	MOV AX, 4C00H
	INT 21H
INICIO ENDP
; COMIENZO DE LA SUBRUTINA
MATMULT PROC NEAR
	; guardo en memoria el vector
	MOV VECTOR[0], DH
	MOV VECTOR[1], DL
	MOV VECTOR[2], BH
	MOV VECTOR[3], BL

	MOV DI, 7 ; inicializo el primer indice a 7. Este recorre las columnas
	BUCLE1:
		DEC DI
		MOV SI, 4 ; inicializo segundo indice a 4. Recorre filas
		MOV BX, 28 ; realmente BX siempre es SI * 7, pero seria mas incomodo estarlo multiplicando
		MOV DX, 0 ; inicializo el acumulador a 0
		BUCLE2:
			DEC SI ; decremento el indice
			SUB BX, 7
			MOV AL, VECTOR[SI] ; guardo en AL el elemento del vector que toca
			MUL MATRIX[BX][DI] ; lo multiplico por el elemento de la matriz que toca
			ADD DX, AX ; sumo el resultado en el acumulador
			CMP SI, 0 ; si no ha recorrido todas las filas de la columna
			JNZ BUCLE2 ; siguiente iteracion del bucle
		AND DL, 1 ; modulo 2
		MOV RESULT[DI], DL ; guarda el aumulador de esta fila en el resultado
		CMP DI, 0 ; si no ha recorrido todas las columnas
		JNZ BUCLE1 ; siguiente iteracion del bucle 
	RET
MATMULT ENDP
; FIN DEL SEGMENTO DE CODIGO
CODE ENDS
; FIN DEL PROGRAMA INDICANDO DONDE COMIENZA LA EJECUCION
END INICIO 