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

start:
	jmp Lmain

Sstartup: db "XNK loading...",ENDL,0
Spress_to_reboot: db "Press any key to reboot...",ENDL,0
Sfatal: db "Fatal error: press any key to reboot...",ENDL,0
Ssectors_error: db "BIOS read wrong number of sectors.",ENDL,0
Ssuccess: db "Success!",ENDL,0
Sunknown_media: db "XNK: Could not detect boot media",ENDL,0
Smedia_floppy: db "XNK: Floppy device detected",ENDL,0
Smedia_hdd:	db "XNK: HDD device detected",ENDL,0

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
	mov ah, 0x0e
    int 0x10

	jmp Pputs
.epilogue:
	ret
	
Lmain:
	; zero-initialize segment registers
	xor ax, ax
	mov ds, ax
	mov es, ax

	; stack setup
	mov ss, ax		; first segment
	mov sp, 0x7C00	; usable stack memory (bios starts after)

	; print startup message
	mov si, Sstartup
    call Pputs

	; Code to display boot media
	mov si, Sunknown_media

	; Check for floppy
	cmp dl, 0h
	mov ax, Smedia_floppy
	cmove si, ax

	; Check for HDD
	cmp dl, 80h
	mov ax, Smedia_hdd
	cmove si, ax
	
	call Pputs
	
	mov dh, 1		; # of sectors
	mov bx, 9000h	; Where to place sector data
	call Pdisk_load

	mov dx, [9000h]
	call print_hex

	mov si, Ssuccess
	call Pputs

	nop
Lstop:
	cli
	hlt
	jmp Lstop
Lfatal:
	mov si, Sfatal
	call Pputs
	jmp Lstop

Lwait_key_and_reboot:
	mov ah, 0
	int 16h			; Wait for keypress
	jmp 0FFFFh:0	; Jump to beginning of BIOS. Should reboot.

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

%include "asm/brdisk.asm"

; Pad code to 510 bytes
times 510-($-$$) db 0
; BIOS magic flag (2 bytes)
dw 0AA55h
