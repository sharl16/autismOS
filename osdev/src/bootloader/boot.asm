org 0x7C00
bits 16


%define ENDL 0x0D, 0x0A ; micro


;
; FAT12 header
;
jmp short start
nop

bdb_oem:					db 'MSWIN4.1'				; 8 bytes
bdb_bytes_per_sector:		dw 512
bdb_sectors_per_cluster: 	db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:				db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:			dw 2880
bdb_media_descriptor_type:  db 0F0h						; 3.5" floppy
bdb_sectors_per_fat:		dw 9
bdb_sectors_per_track:		dw 18
bdb_heads:					dw 2
bdb_hidden_sectors:			dd 0
bdb_large_sector_count:		dd 0

; extended boot record
ebr_drive_number:			db 0						; 0x00 floppy, 0x80 hdd				
							db 0
ebr_signature:				db 29h
ebr_volume_id:				db 12h, 34h, 56h, 78h
ebr_volume_label:			db 'AUTISM OS'				; 11 bytes
ebr_system_id:				db 'FAT12	' 				; 8 bytes

;
; Code goes here
;


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

	; read something from floppy
	mov [ebr_drive_number], dl

	mov ax, 1
	mov cl, 1
	mov bx, 0x7E00
	call disk_read


	;print message
	mov si, msg_hello
	call puts
	
	
	hlt

floppy_error:
	mov si, msg_read_failed
	call puts
	jmp	wait_key_and_reboot

wait_key_and_reboot:
	mov ah, 0
	int 16h				; wait for keypress
	jmp 0FFFFh:0        

.halt:					; disable interrupts
	cli
	hlt


;
; Disk routines
;					

; Converts an LBA address to a CHS address
; Parameters:
; 	-ax: LBA address
; Returns
;	-cx
;	-ck
;	-dh: head


lba_to_chs:

	push ax
	push dx

	xor dx, dx
	div word [bdb_sectors_per_track] 	; ax = LBA % SectorsPerTrack
										; dx = LBA -//-

	inc dx 								; dx = (LBA..+1)=sector
	mov cx, dx							; cx = sector

	xor dx, dx							; dx = 0
	div word[bdb_heads]					; ax = (lba..) % heads = cylinder
										; dx = lba % heads = head
	mov dh,dl							; dh = head
	mov ch, al							; ch = cylinder
	shl ah, 6
	or cl, ah

	pop ax
	mov dl, al							; restore dl
	pop ax
	ret

;
; Reads sectors from disk
; Parameters:
;	- ax: lba sectors
;	- cl: number to read up to 128
;	- dl: drive number
;	- es:bx: memory addres where to store read data
;
disk_read:

	push ax
	push bx
	push cx
	push dx
	push di



	push cx						; temporarily save cl
	call lba_to_chs				; compute chs
	pop ax						; al = number of sectors to read

	mov ah, 02h
	mov di, 3					; retry count

.retry:
	pusha						; save all registers
	stc							; set carry flag, incase bios doesnt set it
	int 13h						; carry flag cleared = success
	jnc .done					; jump if carry not set

	; failed
	popa
	call disk_reset

.fail:
	; all attempts failed
	jmp floppy_error

	dec di
	test di, di
	jnz .retry

.done:
	popa

	push di
	push dx
	push cx
	push bx
	push ax
	ret


;
; resets disk controller
; parameters: dl: drive number
;
disk_reset:
	pusha
	mov ah, 0
	stc
	int 13h
	jc floppy_error
	popa
	ret


msg_hello: 				db 'hello world', ENDL, 0
msg_read_failed: 		db 'Read from disk failed!', ENDL, 0

times 510-($-$$) db 0
dw 0AA55h
