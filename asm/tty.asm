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
