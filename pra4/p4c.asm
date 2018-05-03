;**************************************************************************
; SBM 2015. ESTRUCTURA BÁSICA DE UN PROGRAMA EN ENSAMBLADOR
;**************************************************************************
; DEFINICION DEL SEGMENTO DE DATOS
DATOS SEGMENT
	flag db 0
	flagint db 0
	cesarflag db 0
	old_70h dw 0,0
	cadena db 64 dup (?)
	saltolinea db 13,10,"$"
	str1 db "Modo cifrado",13,10,"$"
	str2 db "Modo descifrar",13,10,"$"
	str3 db "Cerrando...$"
	str4 db "Resultado: $"
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
	
	;Configuramos el rtc
	call confRTC
	
	;Instalamos nuestra rutina RTC guardando la que habia anteriormente
	push ax es
	xor ax,ax
	mov es,ax
	cli
	;Guardar vectores de interrupción inciales
	mov ax,es:[60h*4]
	mov old_70h,ax
	mov ax,es:[60h*4+2]
	mov old_70h+2,ax
	;Instalar los nuevos vectores de interrupción
	mov es:[70h*4],offset rutina_rtc
	mov es:[70h*4+2],cs
	sti
	pop es ax
	
	mainbucle:
	;Leemos por teclado
	MOV AH,0AH ;Función captura de teclado
	MOV DX,OFFSET cadena ;Área de memoria reservada
	MOV cadena[0],63 ;Lectura de caracteres máxima=63
	INT 21H
	
	;Comprobamos si nos pide codificar
	cmp cadena[1], 4
	jne comprobar_dec
	cmp cadena[2], "c"
	jne comprobar_dec
	cmp cadena[3], "o"
	jne comprobar_dec
	cmp cadena[4], "d"
	jne comprobar_dec
	cmp cadena[5], "e"
	jne comprobar_dec
	mov cesarflag, 0
	mov dx, offset saltolinea
	mov ah, 9h
	int 21h
	mov dx, offset str1
	mov ah, 9h
	int 21h
	jmp mainbucle
	
	;Comprobamos si nos pide decodificar
	comprobar_dec:
	cmp cadena[1], 6
	jne comprobar_fin
	cmp cadena[2], "d"
	jne comprobar_fin
	cmp cadena[3], "e"
	jne comprobar_fin
	cmp cadena[4], "c"
	jne comprobar_fin
	cmp cadena[5], "o"
	jne comprobar_fin
	cmp cadena[6], "d"
	jne comprobar_fin
	cmp cadena[7], "e"
	jne comprobar_fin
	mov dx, offset saltolinea
	mov ah, 9h
	int 21h
	mov cesarflag, 1
	mov dx, offset str2
	mov ah, 9h
	int 21h
	jmp mainbucle
	
	;Comprobamos si nos pide cerrar
	comprobar_fin:
	cmp cadena[1], 3
	jne string
	cmp cadena[2], "f"
	jne string
	cmp cadena[3], "i"
	jne string
	cmp cadena[4], "n"
	jne string
	jmp finalmain
	
	;Si no es ninguna funcion es string a codificar/decodificar
	string:
	mov dx, offset saltolinea
	mov ah, 9h
	int 21h
	mov dx, offset str4
	mov ah, 9h
	int 21h
	;Ponemos un fin de cadena donde acabe
	mov bx, 0
	mov bl, cadena[1]
	add bl, 2 ;Saltamos los dos primeros bytes
	mov cadena[bx], "$"
	;Guardamos la cadena en ds:dx para cifrar/descifrar
	mov dx, offset cadena
	add dx, 2 ;Primer byte es bytes a leer, segundo byte es bytes leidos
	;Miramos si nos han pedido cifrar o descifrar
	cmp cesarflag, 0
	jne fundecode
	;Ciframos
	call rutina_cifrar
	mov dx, offset saltolinea
	mov ah, 9h
	int 21h
	jmp mainbucle
	;Desciframos
	fundecode:
	call rutina_descifrar
	mov dx, offset saltolinea
	mov ah, 9h
	int 21h
	jmp mainbucle
	
	;Para acabar desinstalamos
	finalmain:
	mov dx, offset saltolinea
	mov ah, 9h
	int 21h
	mov dx, offset str3
	mov ah, 9h
	int 21h
	push ax
	push es
	xor ax,ax
	mov es,ax
	;Restauramos la interrupcion anterior
	cli
	mov ax,old_70h
	mov es:[70h*4],ax
	mov ax,old_70h+2
	mov es:[70h*4+2],ax
	sti
	;Libera la memoria
	mov es,cs:[2ch]
	mov ah,49h
	int 21h
	mov ax,cs
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	pop ax
	;Cierra programa
	mov AX, 4C00h
	int 21h	
INICIO ENDP

rutina_rtc proc far
	push ax
	sti
	;Leer el registro C del RTC
	mov al,0Ch
	out 70h,al
	in al,71h
	;Comprobar que es interrupcion periodica
	test al, 01000000b
	jz final
	;Como el reloj esta configurado a 2Hz usamos un flag intermedio
	cmp flagint, 0
	jne flagtotal
	mov flagint, 1
	jmp final
	flagtotal:
	mov flag, 1
	mov flagint, 0
	;Terminamos la interrupcion
	final:
	mov al, 20h
	out 20h, al ; Master PIC
	out 0A0h, al ; Slave PIC
	pop ax
	iret
rutina_rtc endp

confRTC PROC NEAR
	push ax
	mov al, 0Ah
	; FIJAR LA FRECUENCIA
	out 70h, al ; Accede a registro 0Ah
	mov al, 00100111b ; DV=010b, RS=1110b (7 == 2 Hz)
	out 71h, al ; Escribe registro 0Ah
	; ACTIVAR INTERRUPCIONES
	mov al, 0Bh
	out 70h, al ; Accede a registro 0Bh
	in al, 71h ; Lee registro 0Bh
	mov ah, al
	or ah, 01000000b ; Activa PIE
	mov al, 0Bh
	out 70h, al ; Accede a registro 0Bh
	mov al, ah
	out 71h, al ; Escribe registro 0Bh
	pop ax
	ret
confRTC ENDP


rutina_cifrar proc near
	push bx si
	mov si, dx
bucle:
	;Espera que el rtc le diga que ha pasado un segundo para imprimir letra
	waitloop:
	cmp flag, 1
	jne waitloop
	;Comprobar si es fin
	mov bl, [si]
	cmp bl, "$"
	je fin
	;Comprobar que es minuscula
	cmp bl, 61h
	jl imprimir
	cmp bl, 7Ah
	jg imprimir
	;Cifrar
	add bl, 16
	;Corregir pasarse del alfabeto
	cmp bl, 7Bh
	jb imprimir
	sub bl, 26
	;Imprimir
	imprimir:
	mov ah, 2h
	push dx
	mov dl, bl
	int 21h
	pop dx
	inc si
	mov flag, 0
	jmp bucle

fin:
	pop si bx
	ret		
rutina_cifrar endp
	
	
rutina_descifrar proc near
	push bx si
	mov si, dx
bucle2:
	;Espera que el rtc le diga que ha pasado un segundo para imprimir letra
	waitloop2:
	cmp flag, 1
	jne waitloop2
	;Comprobar si es fin
	mov bl, [si]
	cmp bl, '$'
	je fin2
	;Comprobar que es minuscula
	cmp bl, 61h
	jl imprimir2
	cmp bl, 7Ah
	jg imprimir2
	;Descifrar
	sub bl, 16
	;Corregir pasarse del alfabeto
	cmp bl, 60h
	ja imprimir2
	add bl, 26
	;Imprimir
	imprimir2:
	mov ah, 2h
	push dx
	mov dl, bl
	int 21h
	pop dx
	inc si
	mov flag,0
	jmp bucle2

fin2:
	pop si bx
	ret		
rutina_descifrar endp
	
CODE ENDS
; FIN DEL PROGRAMA INDICANDO DONDE COMIENZA LA EJECUCION
END INICIO 