code segment
assume cs:code
	
;Reservamos 100h bytes para el PSP
org 256
start: jmp inicio
;Variables del driver
old_60h dw 0,0
installing db "Instalando...$"
uninstalling db "Desinstalando...$"
si_inst db "El driver ya esta instalado.", 13, 10, "$"
no_inst db "El driver no esta instalado.", 13, 10, "$"
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
	push ds
	mov ax, 0
	mov ds, ax
	mov ax, ds:[60h*4+2]
	pop ds
	cmp ax, 0
	je no_instalado
	
	mov ah, 0h
	int 60h
	cmp ax, 0F0Fh
	je instalado
	no_instalado:
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
	MOV AX, 4C00H
	INT 21H
_hay_par:
	; comprobar que hay 3 letras en los parametros (espacio incluido)
	cmp dl, 3
	jne info
	
	; comprobar que el segundo es /
	mov al, es:[82h]
	cmp al, "/"
	jne info

	mov al, es:[83h] ; caracter despues de la barra
	cmp al, "I"
	jne comprobar_d
	
	; Comprobar que no esta instalado ya
	push ds
	mov ax, 0
	mov ds, ax
	mov ax, ds:[60h*4+2]
	pop ds
	cmp ax, 0
	je no_instalado2
	mov ah, 0h
	int 60h
	cmp ax, 0F0Fh
	je instalado
	
	no_instalado2:
	mov dx, offset installing
	mov ah, 9
	int 21h
	call instalar
	jmp fin
comprobar_d:
	cmp al, "D"
	jne info
	
	; Comprobar que esta instalado
	push ds
	mov ax, 0
	mov ds, ax
	mov ax, ds:[60h*4+2]
	pop ds
	cmp ax, 0
	je no_instalado
	mov ah, 0h
	int 60h
	cmp ax, 0F0Fh
	jne no_instalado
	
	mov dx, offset uninstalling
	mov ah, 9
	int 21h
	call desinstalar
	jmp fin

endp inicio

;Rutinas de Servicio
;Interrupción software 60h
rutina_driver proc far
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
	mov ax, 0F0Fh
	jmp driver_fin

driver_codificar:
	mov si, dx
bucle:
	;Comprobar si es fin
	mov bl, [si]
	cmp bl, "$"
	je driver_fin
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
	jmp bucle

driver_decodificar:
	mov si, dx
bucle2:
	;Comprobar si es fin
	mov bl, [si]
	cmp bl, '$'
	je driver_fin
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
	jmp bucle2
     
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

CODE ENDS

END start
