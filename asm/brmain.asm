; BIOS bootloader
;
; FIRST SECTOR OF 512 BYTES:
; --------------------- ----------------------
; | 510 bytes of code | | 0x0AA55h (2 bytes) |
; --------------------- ----------------------

org 0x7C00
; BIOS starts in real mode (e.g. 16-bit)
bits 16

%define ENDL 0x0D, 0x0A
%define BIOS_TTY_WRITE 0eh
%define BIOS_READ_CHARACTER 0h
%define BIOS_VIDEO_SERVICE 10h
%define BIOS_KBD_SERVICE 16h
%define BIOS_DISK_SERVICE 13h
%define BIOS_EXT_DISK_READ 42h

%define BLKSIZE 512
%define BLKCNT 127

%define KOFF 0x9000

struc dap
	.size	resb 1
	.magic	resb 1
	.blkcnt	resw 1
	.buf	resd 1
	.lba	resq 1
endstruc

start:
	jmp Lmain

Sstartup: db "XNK: Loading...",ENDL,0
Spress_to_reboot: db "XNK: Press any key to reboot...",ENDL,0
Sfatal: db "XNK: BIOS error: ",0
Sjump: db "J",ENDL,0
Sincompat: db "XNK: Incompatible disk device",ENDL,0
Sunknown_media: db "XNK: Could not detect boot media",ENDL,0
Sdone: db "XNK: Success",ENDL,0

gdap:
	istruc dap
		at .size,	db	10h
		at .magic,	db	0h
		at .blkcnt,	dw	BLKCNT
		at .buf,	dd	KOFF
		at .lba,	dq	1
	iend

; Print a string to BIOS TTY
; Parameters:
;   - ds:si The null-terminated string to print
; Clobbers:
;   - si (si + length)
;   - ax
Pputs:
	lodsb	; al = *si++

	and al, al
	jz .epilogue

    ;; BIOS interrupt to print character in al
	mov ah, BIOS_TTY_WRITE
	int BIOS_VIDEO_SERVICE

	jmp Pputs
.epilogue:
	ret

; Load sectors from disk
; Parameters are placed in the global DAP
; Clobbers:
;   - ah BIOS return code
;   - si Pointer to global DAP
Pload:
	mov ah, BIOS_EXT_DISK_READ
	mov si, gdap
	stc
	int BIOS_DISK_SERVICE
	jc Lfatal

	ret

%include "asm/gdt.asm"
Lmain:
	; zero-initialize segment registers
	xor ax, ax
	mov ds, ax
	mov es, ax

	; stack setup
	mov ss, ax			; first segment
	mov sp, 0x7C00		; usable stack memory

	; print startup message
	mov si, Sstartup
	call Pputs

	mov ah, 41h
	mov bx, 55AAh
	stc
	int BIOS_DISK_SERVICE
	jc Lincompat

	call Pload	; load first batch

	cli
	lgdt [gdt_descriptor]

	mov si, Sjump
	call Pputs

	mov eax, cr0
	or eax, 0x1
	mov cr0, eax

	jmp CODE_SEGOFF:init_pm
Lstop:
	cli
	hlt
	jmp Lstop
Lfatal:
	push ax
	mov si, Sfatal
	call Pputs
	pop ax
	xor dx, dx
	mov dl, ah
	call print_hex
	jmp Lstop
Lincompat:
	mov si, Sincompat
	call Pputs
	jmp Lstop

%include "asm/pm.asm"

; receiving the data in 'dx'
; For the examples we'll assume that we're called with dx=0x1234
print_hex:
    pusha

    mov cx, 0 ; our index variable

; Strategy: get the last char of 'dx', then convert to ASCII
; Numeric ASCII values: '0' (ASCII 0x30) to '9' (0x39), so just add 0x30 to byte N.
; For alphabetic characters A-F: 'A' (ASCII 0x41) to 'F' (0x46) we'll add 0x40
; Then, move the ASCII byte to the correct position on the resulting string
hex_loop:
    cmp cx, 4 ; loop 4 times
    je end
    
    ; 1. convert last char of 'dx' to ascii
    mov ax, dx ; we will use 'ax' as our working register
    and ax, 0x000f ; 0x1234 -> 0x0004 by masking first three to zeros
    add al, 0x30 ; add 0x30 to N to convert it to ASCII "N"
    cmp al, 0x39 ; if > 9, add extra 8 to represent 'A' to 'F'
    jle step2
    add al, 7 ; 'A' is ASCII 65 instead of 58, so 65-58=7

step2:
    ; 2. get the correct position of the string to place our ASCII char
    ; bx <- base address + string length - index of char
    mov bx, HEX_OUT + 5 ; base + length
    sub bx, cx  ; our index variable
    mov [bx], al ; copy the ASCII char on 'al' to the position pointed by 'bx'
    ror dx, 4 ; 0x1234 -> 0x4123 -> 0x3412 -> 0x2341 -> 0x1234

    ; increment index and loop
    add cx, 1
    jmp hex_loop

end:
    ; prepare the parameter and call the function
    ; remember that print receives parameters in 'bx'
    mov si, HEX_OUT
    call Pputs

    popa
    ret

HEX_OUT:
    db '0x0000',ENDL,0 ; reserve memory for our new string

; Pad code to 510 bytes
times 510-($-$$) db 0
; BIOS magic flag (2 bytes)

dw 0AA55h

sect2:
	mov si, Sdone
	call Pputs
	jmp Lstop

times 256 dw 0xdead
times 256 dw 0xbeef
