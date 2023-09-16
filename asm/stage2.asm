%include "asm/gdt.asm"

stage2.entry:
	mov si, Ss2
	call Pputs
	jmp Lstop
	;; in al, 0x92
	;; or al, 2
	;; out 0x92, al

	;; cli
	;; lgdt [gdtr]
	
	;; mov eax, cr0
	;; or eax, 1
	;; mov cr0, eax

	;; jmp CODE_SEGOFF:init_pm


;%include "asm/pm.asm"
