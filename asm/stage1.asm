gdap:
	istruc dap
		at .size,	db	10h
		at .magic,	db	0h
		at .blkcnt,	dw	BLKCNT
		at .bufo,	dw	stage2
		at .bufs,	dw	0
		at .lba,	dq	1
	iend

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

stage1.entry:
	; zero-initialize segment registers
	xor ax, ax
	mov ds, ax
	mov es, ax

	; stack setup
	mov ss, ax			; first segment
	mov sp, 0x7C00		; usable stack memory
	
	; initialize CS
	push ax
	push word .set_cs
	retf
.set_cs:
	; print startup message
	mov si, Sstartup
	call Pputs

	mov ah, 41h
	mov bx, 55AAh
	stc
	int BIOS_DISK_SERVICE
	jc Lincompat

	call Pload	; load first batch

	jmp stage2.entry
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
