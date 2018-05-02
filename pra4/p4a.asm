code segment
	assume cs:code
	
	;Reservamos 100h bytes para el PSP
	org 100h

;Variables del driver
old_60h dw 0,0
si_inst db "El driver ya está instalado.", 13, 10, "$"
no_inst db "El driver no está instalado.", 13, 10, "$"
info_par db "Grupo 2301, pareja 13: Alejandro Cabana y Carlos Isasa",13, 10
instr1 db "p4a /I: instala el driver", 13, 10
instr2 db "p4a /D: desinstala el driver", 13, 10
instr3 db "int 60h, ah=11h: cifra la cadena en ds:dx con clave 16", 13, 10
instr4 db "int 60h, ah=12h: descifra la cadena en ds:dx con clave 16", 13, 10, "$"

inicio proc
	push ax dx

	xor dh,dh
	;ES apunta al PSP si no se ha cambiado
	mov dl,es:[80h] ;Número de bytes en los parámetros
	cmp dx,0 ;Si hay más de 1 seguimos
	jne _hay_par

	; Comprobar si esta instalado
	mov ah, 0h
	int 60h
	cmp ax, ABCDh
	je instalado
	mov dx, offset no_inst
	mov ah, 9
	int 21h
	jmp info
	instalado:
	mov dx, offset si_inst
	mov ah, 9
	int 21h 
	info:
	mov dx, offset info_par
	mov ah, 9
	int 21h
fin:
	pop dx ax
	ret
_hay_par:
	mov al, es:[83h] ; caracter despues de la barra
	cmp al, "I"
	jne comrpobar_d
	call instalar
	jmp fin
comrpobar_d:
	cmp al, "D"
	jne info
	call desinstalar
	jmp fin

endp inicio

;Rutinas de Servicio
;Interrupción software 60h
rutina_driver proc near
	push bx si

	cmp ah, 0h
	je comprobar_driver
	cmp ah,11h
	je driver_codificar
	cmp ah, 12h
	je driver_decodificar

driver_fin:
	pop si bx
	iret

comprobar_driver:
	mov ax, ABCDh
	jmp driver_fin

driver_codificar:
	mov si, 0
bucle:
	mov bl, dx[si]
	cmp bl, "$"
	je driver_fin
	add bl, 16
	cmp bl, 7Ah
	jng imprimir
	sub bl, 26
	imprimir:
	mov ah, 2h
	push dx
	mov dl, bl
	int 21h
	pop dx
	inc si
	jmp bucle

driver_decodificar:
	mov si, 0
bucle:
	mov bl, dx[si]
	cmp bl, '$'
	je driver_fin
	sub bl, 16
	cmp bl, 97h
	jnl imprimir
	add bl, 26
	imprimir:
	mov ah, 2h
	push dx
	mov dl, bl
	int 21h
	pop dx
	inc si
	jmp bucle

rutina_driver endp


instalar proc near
	push ax es
	xor ax,ax
	mov es,ax
	
	cli
	;Guardar vectores de interrupción inciales
	mov ax,es:[60h*4]
	mov old_60h,ax
	mov ax,es:[60h*4+2]
	mov old_60h+2,ax
	;Instalar los nuevos vectores de interrupción
	mov es:[60h*4],offset rutina_driver
	mov es:[60h*4+2],cs
	sti

	pop es ax

	mov dx,offset instalar
	int 27h
instalar endp

desinstalar proc near
	push ax
	push es
	xor ax,ax
	mov es,ax
	cli
	 ;Vector 65h
	mov ax,old_60h
	mov es:[60h*4],ax
	mov ax,old_60h+2
	mov es:[60h*4+2],ax
	sti
	mov es,cs:[2ch]
	mov ah,49h
	int 21h
	mov ax,cs
	mov es,ax
	mov ah,49h
	int 21h
	pop es
	pop ax
	ret
desinstalar endp
