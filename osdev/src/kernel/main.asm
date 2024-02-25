org 0x7C00
bits 16

%define ENDL 0x0D, 0x0A ; micro


start:
	jmp main 		; gt to puts: einai prin apo to main


;
; prints a string
; params:
;	- ds:si points to string
;
puts:
	; save registers we will modify
	push si
	push ax

.loop:
	lodsb			; loads next char in al register
	or al, al		; verify if next char is null
	jz .done		; an char einai null pame sto .done

	mov ah, 0x0e 		; bios int
	mov bh, 0 		
	int 0x10

	jmp .loop

.done: 
	pop ax
	pop si
	ret



main:

	; setup data segments (variables ktl)
	mov ax, 0    
	mov ds, ax
	mov es, ax

	; setup stack
	mov ss, ax
	mov sp, 0x7C00 		; gia na bgoume apo floppy disk, >512 bytes

	;print message
	mov si, msg_hello
	call puts
	
	
	hlt

.halt:
	jmp .halt


msg_hello: db 'hello world', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
