Sdisk_error: db "Fatal disk error.",ENDL,0
Sdisk_params_error:	db "Cannot read disk parameters.",ENDL,0

; Convert LBA to CHS
; Arguments:
;   - ax The LBA address
; Clobbers:
;   - ch (C) The cylinder
; 	- dh (H) The head
;	- cl (S) The sector
Plba2chs:
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
;   - dh Number of sectors to load
;	- es:bx Where to place sector data
; Clobbers:
; 	- [es:bx] Sector data
;   - cf 0
Pdisk_load:
	pusha					; BIOS just decides to mess with registers sometimes
	push dx					; The parameters will be overwritten when reading from disk

	mov ah, BIOS_DISK_READ	; Disk read function in category 13h
	mov al, dh				; Number of sectors to read
	mov cl, 02h				; The first sector to read (1 = boot sector, 2 = beginning of other data)
	mov ch, 0h				; Cylinder
							; Drive number is already in dl
	mov dh, 0h				; Head number

	stc						; BIOS should set carry on error, but sometimes they dont clear it :/
	int BIOS_DISK_SERVICE	; Call BIOS disk services (read)
	mov si, Sdisk_error
	jc .error				; Carry will be set on BIOS error

	pop dx					; Restore arguments
	cmp al, dh				; BIOS sets al to # of sectors read
	mov si, Ssectors_error
	jne .error				; The # of sectors read should match the argument we gave to BIOS
.epilogue:
	popa
	ret
.error:
	call Pputs
	jmp Lfatal
