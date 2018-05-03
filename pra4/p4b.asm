;**************************************************************************
; SBM 2015. ESTRUCTURA BÁSICA DE UN PROGRAMA EN ENSAMBLADOR
;**************************************************************************
; DEFINICION DEL SEGMENTO DE DATOS
DATOS SEGMENT
	str1 db "Probando a cifrar...", 13, 10, "$"
	str2 db 13,10,"Probando a descifrar...", 13, 10, "$"
	str3 db "Deberia salir: ", 13, 10, "$"
	str4 db 13,10,"Sale: ", 13, 10, "$"
	cifrar db "cesar es un loser$"
	descifrar db "suiqh ui kd beiuh$"
DATOS ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO DE PILA
PILA SEGMENT STACK "STACK"
	DB 40H DUP (0) ;ejemplo de inicialización, 64 bytes inicializados a 0
PILA ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO EXTRA
EXTRA SEGMENT
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
	MOV SP, 64 
	; Cifrar
	mov dx, offset str1
	mov ah, 9h
	int 21h
	
	mov dx, offset str3
	mov ah, 9h
	int 21h
	
	mov dx, offset descifrar
	mov ah, 9h
	int 21h
	
	mov dx, offset str4
	mov ah, 9h
	int 21h
	
	mov dx, offset cifrar
	mov ah, 11h
	int 60h
	
	; Descifrar
	mov dx, offset str2
	mov ah, 9
	int 21h
	
	mov dx, offset str3
	mov ah, 9
	int 21h
	
	mov dx, offset cifrar
	mov ah, 9
	int 21h
	
	mov dx, offset str4
	mov ah, 9
	int 21h
	
	mov dx, offset descifrar
	mov ah, 12h
	int 60h
	
	mov AX, 4C00h
	int 21h
INICIO ENDP
CODE ENDS
; FIN DEL PROGRAMA INDICANDO DONDE COMIENZA LA EJECUCION
END INICIO 