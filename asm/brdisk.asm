Sdisk_error: db "Fatal disk error.",ENDL,0

sectors_per_track:	

; Convert LBA to CHS
; Arguments:
;   - ax The LBA address
; Clobbers:
;   - ch (C) The cylinder
; 	- dh (H) The head
;	- cl (S) The sector
Plba2chs:
	ret 

; Load a number of sectors from disk
; Arguments:
;   - dl Drive number
;   - dh Number of sectors to load
;	- es:bx Where to place sector data
; Clobbers:
; 	- [es:bx] Sector data
Pdisk_load:
	pusha				; BIOS just decides to mess with registers sometimes
	push dx				; The parameters will be overwritten when reading from disk

	mov ah, 02h			; Disk read function in category 13h
	mov al, dh			; Number of sectors to read
	mov cl, 02h			; The first sector to read (1 = boot sector, 2 = beginning of other data)
	mov ch, 0h			; Cylinder
						; Drive number is already in dl
	mov dh, 0h			; Head number

	stc					; BIOS should set carry on error, but sometimes they dont clear it :/
	int 13h				; Call BIOS disk services (read)
	jc .disk_error		; Carry will be set on BIOS error

	; TODO: Use just one popa and pusha instead??
	pop dx				; Restore arguments
	cmp al, dh			; BIOS sets al to # of sectors read
	jne .sectors_error	; The # of sectors read should match the argument we gave to BIOS
.epilogue:
	popa
	ret
.disk_error:
	mov si, Sdisk_error
	call Pputs
	jmp Lfatal
.sectors_error:
	mov si, Ssectors_error
	call Pputs
	jmp Lfatal