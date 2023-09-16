bits 32

%define CHVIDEO_MEMORY 0xb8000
%define COL 0x0f
%define CHVIDEO_H 80
%define CHVIDEO_V 25

pm_start:
	mov ax, DATA_SEGSEL
	mov ds, ax
	mov ss, ax
	mov es, ax
	mov fs, ax
	mov gs, ax

	mov ebp, 0x90000
	mov esp, ebp

	call clear_screen

	mov ebx, Spm
	call pm_puts
.halt:
	cli
	hlt
	jmp .halt

clear_screen:
	pusha
	mov edx, CHVIDEO_MEMORY
.loop:
	cmp edx, CHVIDEO_MEMORY+CHVIDEO_H*CHVIDEO_V*2
	jnb .epi

	mov word [edx], 0
	add edx, 2
	jmp .loop
.epi:
	popa
	ret

pm_puts:
	pusha
	mov edx, CHVIDEO_MEMORY
.loop:
	mov al, [ebx]
	mov ah, COL
	
	cmp al, 0
	je .epi

	mov [edx], ax

	add ebx, 1
	add edx, 2

	jmp .loop
.epi:
	popa
	ret

Spm: db "XNK: Protected mode enabled",0
