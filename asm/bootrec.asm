; BIOS bootloader
;
; FIRST SECTOR OF 512 BYTES:
; --------------------- ----------------------
; | 510 bytes of code | | 0x0AA55h (2 bytes) |
; --------------------- ----------------------

; BIOS loads program at 0x7C00
org 0x7C00
; Computer starts in real mode
bits 16

%define BIOS_TTY_WRITE 0eh
%define BIOS_READ_CHARACTER 0h
%define BIOS_VIDEO_SERVICE 10h
%define BIOS_KBD_SERVICE 16h
%define BIOS_DISK_SERVICE 13h
%define BIOS_EXT_DISK_READ 42h

%define BLKSIZE 512
%define BLKCNT 16

%define ENDL 0x0D, 0x0A

struc dap
	.size	resb 1
	.magic	resb 1
	.blkcnt	resw 1
	.bufo	resw 1
	.bufs	resw 1
	.lba	resq 1
endstruc

start:
	jmp stage1.entry

Sstartup: db "XNK: S1 loaded.",ENDL,0
Ss2: db "XNK: S2 loaded.",ENDL,0
Sfatal: db "XNK: BIOS error: ",0
Sincompat: db "XNK: Incompatible disk device",ENDL,0
Sdone: db "XNK: Success",ENDL,0

%include "asm/tty.asm"

stage1:
%include "asm/stage1.asm"
.end:

stage2:
%include "asm/stage2.asm"
.end:
