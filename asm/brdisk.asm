Sdisk_error: db "Fatal disk error.",ENDL,0
Sdisk_params_error:	db "Cannot read disk parameters.",ENDL,0

; Convert LBA to CHS
; Arguments:
;   - ax The LBA address
;   - cx
;       [5:0] Sectors per track
;   - dh Number of heads
; Clobbers:
;   - cx (S) The sector
;   - al (C) The cylinder
;   - ah (H) The head
Plba2chs:
	and cx, 3fh		; cx = sectors per track
	div cl

	; al = LBA / sectorsPerTrack
	; ah = LBA % sectorsPerTrack

	xor cx, cx
	mov cl, ah
	inc cl
	; cx = (LBA % sectorsPerTrack) + 1

	and ax, 0xf		; strip remainder
	div dh			; /= numberOfHeads
	; CYLINDER: al = (LBA / sectorsPerTrack) / numberOfHeads
	; HEAD: ah = (LBA / sectorsPerTrack) % numberOfHeads

	ret

; Get BIOS disk parameters
; Arguments:
;   - dl Drive number
; Clobbers:
;   - ah BIOS call return code
;   - dl Number of HDDs
;   - dh Head count - 1
;   - cx
;       [7:6] [15:8] Cylinder count - 1
;       [5:0] Sectors per track
;   - cf 0
Pdiskparams:
	push es
	push di
	push bx

	mov ah, BIOS_DRIVE_PARAMETERS
	; reset es:di because of some buggy BIOS:s
	xor di, di
	mov es, di

	stc
	int BIOS_DISK_SERVICE
	jc .error
.epilogue:
	pop bx
	pop di
	pop es

	ret
.error:
	mov si, Sdisk_params_error
	call Pputs
	jmp Lfatal

; Load a number of sectors from disk
; Arguments:
;   - dl Drive number
;   - al Number of sectors to load
;   - cl Sector
;   - ch Cylinder
;   - dh Head
;   - es:bx Where to place sector data
; Clobbers:
;   - [es:bx] Sector data
;   - cf 0
Pdisk_load:
	pusha					; BIOS just decides to mess with registerpppps sometimes
	push ax					; The parameters will be overwritten when reading from disk
	push dx
	
	xor dx, dx
	mov dl, ch
	shr dx, 2
	and dx, 0xc0

	;call print_hex
	or cl, dl

	pop dx

	mov ah, BIOS_DISK_READ	; Disk read function in category 13h

	stc						; BIOS should set carry on error, but sometimes they dont clear it :/
	int BIOS_DISK_SERVICE	; Call BIOS disk services (read)
	mov si, Sdisk_error
	jc .error				; Carry will be set on BIOS error

	pop dx					; Restore arguments
	cmp al, dl				; BIOS sets al to # of sectors read
	jne .error				; The # of sectors read should match the argument we gave to BIOS
.epilogue:
	popa
	ret
.error:
	xor dx, dx
	mov dl, ah
	call print_hex
	call Pputs
	jmp Lfatal
