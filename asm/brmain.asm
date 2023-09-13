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
%define BIOS_DRIVE_PARAMETERS 08h
%define BIOS_DISK_READ 02h
%define FLOPPY_DRIVENUM 0h
%define HDD_DRIVENUM 80h

start:
	jmp Lmain

Sstartup: db "XNK: loading...",ENDL,0
Spress_to_reboot: db "XNK: Press any key to reboot...",ENDL,0
Sfatal: db "XNK: fatal error",0
Sunknown_media: db "XNK: could not detect boot media",ENDL,0
Smedia_floppy: db "XNK: floppy device detected",ENDL,0
Smedia_hdd:	db "XNK: hdd device detected",ENDL,0
Sdone: db "XNK: Success",ENDL,0

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

	mov si, Sunknown_media

	; Check for floppy
	cmp dl, FLOPPY_DRIVENUM
	mov ax, Smedia_floppy
	cmove si, ax

	; Check for HDD
	cmp dl, HDD_DRIVENUM
	mov ax, Smedia_hdd
	cmove si, ax

	call Pputs	; print boot media
	
	push dx
	call Pdiskparams

	pop ax
	mov dl, al

	inc dh

%define LBA 1
%define DEST_ADDR 0x9000
%define NLOAD 2
	mov ax, LBA
	call Plba2chs

	; mov bx, DEST_ADDR
	; mov cx, 2
	; mov ch, 0
	; mov dh, 0
	; mov al, 2

	; DH IS WRONG!!
	mov bx, DEST_ADDR
			; Sector is already set in cx
	mov ch, al	; Set cylinder
	mov dh, ah	; Set head
	mov al, NLOAD
	call Pdisk_load

	mov dx, [DEST_ADDR]
	call print_hex

	mov dx, [DEST_ADDR+512]
	call print_hex

	mov si, Sdone
	call Pputs
Lstop:
	cli
	hlt
	jmp Lstop
Lfatal:
	mov si, Sfatal
	call Pputs
	jmp Lstop

Lwait_key_and_reboot:
	mov ah, BIOS_READ_CHARACTER
	int BIOS_KBD_SERVICE		; Wait for keypress
	jmp 0FFFFh:0				; Jump to beginning of BIOS. Should reboot.

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
times 256 dw 0xdead
times 256 dw 0xbeef
