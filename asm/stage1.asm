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
dload:
	mov ah, BIOS_EXT_DISK_READ
	mov si, gdap
	stc
	int BIOS_DISK_SERVICE
	jc fatal

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
	call puts

	mov ah, 41h
	mov bx, 55AAh
	stc
	int BIOS_DISK_SERVICE
	jc incompat

	call dload

	jmp stage2.entry

; panic routines
stop:
	cli
	hlt
	jmp stop
fatal:
    ; concatenates "BIOS error:" with error code
	push ax
	mov si, Sfatal
	call puts
    
	pop ax
	xor dx, dx
	mov dl, ah
	call hex_puts
    
	jmp stop
incompat:
	mov si, Sincompat
	call puts
	jmp stop

; Pad code to 510 bytes
times 510-($-$$) db 0

; BIOS magic flag (2 bytes)
dw 0AA55h
