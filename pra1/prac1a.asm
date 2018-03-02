;**************************************************************************
; SBM 2015. ESTRUCTURA BÁSICA DE UN PROGRAMA EN ENSAMBLADOR
;**************************************************************************
; DEFINICION DEL SEGMENTO DE DATOS
DATOS SEGMENT
;-- rellenar con los datos solicitados
DATOS ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO DE PILA
PILA SEGMENT STACK "STACK"
DB 40H DUP (0) ;ejemplo de inicialización, 64 bytes inicializados a 0
PILA ENDS
;**************************************************************************
; DEFINICION DEL SEGMENTO EXTRA
EXTRA SEGMENT
RESULT DW 0,0 ;ejemplo de inicialización. 2 PALABRAS (4 BYTES)
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
MOV AX, 15H		; carga 00 en AH y 15 en AL
MOV BX, 0BBH	; carga 00 en BH y BB en BL
MOV CX, 3412H	; carga 34 en CH y 12 en CL
MOV DX, CX		; carga el contenido de CX en DX

MOV BX, 6560H	; carga 6560 en BX
MOV ES, BX		; carga 6560 en ES
MOV BX, ES:[36H]; carga el contenido de la posicion 65600+36 en BX

MOV AX, 5000H	; carga 5000 en AX
MOV ES, AX		; carga 5000 en AX
MOV ES:[5H], CH	; carga el contenido de CH en la posicion 50000+5

MOV AX, [DI]	; carga en AX el contenido de la direccion apuntada por DI

MOV BX, BP[0AH]	; carga en BX el contenido de la direccion 10 bytes por encima de la apuntada por BP

; FIN DEL PROGRAMA
MOV AX, 4C00H
INT 21H
INICIO ENDP
; FIN DEL SEGMENTO DE CODIGO
CODE ENDS
; FIN DEL PROGRAMA INDICANDO DONDE COMIENZA LA EJECUCION
END INICIO 