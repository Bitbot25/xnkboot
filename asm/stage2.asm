%include "asm/gdt.asm"

stage2.entry:
	mov si, Ss2
	call puts

    ; enable A20
	in al, 0x92
	or al, 2
	out 0x92, al

    ; remove interrupts
	cli
    ; load GDT
	lgdt [gdtr]



    ; enter protected mode
	mov eax, cr0
	or eax, 1
	mov cr0, eax

    ; jump to protected mode start in GDT
	jmp CODE_SEGSEL:pm_start


%include "asm/pm.asm"
