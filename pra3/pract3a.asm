PRACT3A SEGMENT BYTE PUBLIC 'CODE'
ASSUME CS: PRACT3A
	PUBLIC _comprobarNumeroSecreto, _rellenarIntento
	_comprobarNumeroSecreto PROC FAR
		PUSH BP
		MOV BP, SP ;COLOCAMOS EL PUNTERO EN LA CIMA DE LA PILA
		PUSH DI BX
		LES DI, [BP+6] ;SEGMENT=>ES OFFSET=>DI
		
		;METEMOS LOS 4 NUMEROS EN REGISTROS
		MOV AH, ES:[DI] 
		MOV AL, ES:[DI+1]
		MOV BH, ES:[DI+2]
		MOV BL, ES:[DI+3]
		
		;COMPRUEBA SI HAY NUMEROS REPETIDOS, SI LOS HAY SALTA A FALLO
		CMP AH, AL
		JE FALLO
		CMP AH, BH
		JE FALLO
		CMP AH, BL
		JE FALLO
		CMP AL, BH
		JE FALLO
		CMP AL, BL
		JE FALLO
		CMP BH, BL
		JE FALLO
		
		MOV AX, 0
		POP DI BX BP
		RET ;DEVUELVE CERO SI NO HAY REPETIDOS
		
	FALLO:
		MOV AX, 1
		POP BX DI BP
		RET ;DEVUELVE UNO SI HAY REPETIDOS
	_comprobarNumeroSecreto ENDP

	_rellenarIntento PROC FAR
		PUSH BP
		MOV BP, SP ;COLOCAMOS EL PUNTERO EN LA CIMA DE LA PILA
		
		PUSH DI SI BX
		
		LES DI, [BP+8] ;SEGMENT=>ES OFFSET=>DI
		
		MOV AX, [BP+6] ;GUARDA EL NUMERO EN AX
		MOV CX, 10 ; GUARDA 10 EN CL PARA LUEGO DIVIDIR
		MOV SI, 4 ; INICIALIZA EL INDICE A 4 PARA DECREMENTAR PRIMERO

		DIGITS:
		DEC SI ; DECREMENTA EL INDICE
		MOV DX, 0 ; PONE EL RESTO A CERO
		DIV CX ; DIVIDE EL CONTENIDO DE AX ENTRE 10. COCIENTE EN AX Y RESTO EN DX
		MOV BX, DI
		ADD BX, SI
		MOV ES:[BX], DL ; METE EL RESTO EN ES
		CMP SI, 0 ; SI NO LO HEMOS HECHO 4 VECES
		JNE DIGITS ; SIGUE DIVIDIENDO
		
		POP BX SI DI BP
		
		RET
	
	_rellenarIntento ENDP
	
PRACT3A ENDS
END