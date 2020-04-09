	include	options.inc
	include	chip.inc
	include	defs.asm
	include	82596.inc
	include lp486e.inc

cgroup	group code, _text, init

code	segment para public 'code'
	assume	cs:cgroup, ds:cgroup

	even

extrn	is_eisa	: byte		;=0 if ISA, =1 if EISA
extrn	decout	: near
extrn	int_no 			: byte
extrn	int_num : word
extrn	set_ether : near
extrn	do_config : near
extrn	reset_chip : near
extrn	wait_27ms : near
NOWARN
extrn	wait : near
WARN
extrn	do_timeout : near
extrn	set_timeout : near

extrn	wait_scb_non_active : near
extrn	tx_buff_no : word
extrn	buff_ptrs : word
extrn	cmd_buff1 : byte
extrn	cmd_buff2 : byte
extrn	start_rfd : byte
extrn	start_rbd : byte
extrn	start_rx_buff : byte
extrn	first_rfd : word
extrn	last_rfd : word
extrn	first_rbd : word
extrn	last_rbd : word
	
extrn	scb_buff	: word

;any code after this will not be kept after initialization. Buffers
;used by the program, if any, are allocated from the memory between
;end_resident and end_free_mem.
	public end_resident,end_free_mem
end_resident	label	byte
end_free_mem	label	byte

	extrn	get_hex: near
	include	getea.asm
	include	messages.inc

eisa_config	db	320 dup (0)
eisa_sub_type	db	'NET,82596,SCSI,NCRC700'
	
cnvrt_to_phys_add	dw	?	; Address of subroutine to convert to physical add
	even
virtual_mem_struct:
		dd      0		;- 0 Region Size
		dd		0		;- 4 Region Offset
		dw		0		;- 8 Region Segment
		dw		0		;- A Buffer ID
		dw		0		;- C Low Physical Address
		dw		0		;- E High Physical Address
	
io_addr		dw	0,0		; I/O address specified on the command line

	ALIGN	16
self_test_buff	dd	0, -1		; Results of the self-test test placed here

	ALIGN	16
scp_buff	db	size SCP_STRUC dup (0)

	ALIGN	16
iscp_buff	db	size ISCP_STRUC dup (0)

	extrn	set_recv_isr: near

;enter with dx -> argument string, di -> wword to print.
	extrn	print_number: near

;-> the Ethernet address of the card.
	extrn	rom_address: byte

; Enter with si -> argument string.
; Skip spaces and tabs.  Exit with si -> first non-blank char.
	extrn	skip_blanks: near

	public	parse_args
parse_args:
; Exit with nc if all went well, cy otherwise.
	call	skip_blanks
	cmp	al, CR			; End of the arguments string?
	je	short parse_args_done
	stc				; Extra arguments, print usage
	jmp	short parse_args_exit
parse_args_done:
	clc
parse_args_exit:
	ret

	public	print_parameters
print_parameters:
;echo our auto-detected parameters
	mov		di, offset cgroup:int_no
	mov		dx, offset cgroup:int_no_name
	call	print_number
	mov		di, offset cgroup:io_addr
	mov		dx, offset cgroup:io_addr_name
	call	print_number
	ret

	public	etopen
etopen:
; Initialize the driver.
; Fill in rom_address with the assigned address of the board.
	assume	ds:code
	cmp		is_eisa, 1
	je		have_eisa_bus
	mov 	dx, offset cgroup:need_eisa_msg	; A EISA bus is required
	stc
	ret

have_eisa_bus:
	.386					; Must have >= 386
	call	check_virtual_mem_services
	call	etopen_chip
	jc		short exit_etopen
	mov		al, int_no		; Get board's interrupt vector
	add		al, 8
	cmp		al, 8+8			; Is it a slave 8259 interrupt?
	jb		short set_int_num		; No.
	add		al, 70h - 8 - 8	; Map it to the real interrupt.
set_int_num:
	xor		ah, ah			; Clear high byte
	mov		int_num, ax		; Set parameter_list int num.
	call	setup_receive	; Setup receive buffers & start reception
	call	set_recv_isr
	clc
exit_etopen:
	ret


check_virtual_mem_services	PROC	NEAR
	; Check to see if virtual DMA service is being provided.
	; Bit 5 of the Bios Flags at 40:7Bh is set if virtual services present
	; Sets the appropriate routine to use for conversion to physical addresses
    mov     ax, 40h
	mov		es, ax
	test	BYTE PTR es:[007bh], 20h
	jz		short no_virtual_services_found
	print 	virtual_services	; Announce virtual DMA services present
	mov		cnvrt_to_phys_add, offset cgroup:virtual_address_convert
	jmp		short exit_check_virtual_mem_services
no_virtual_services_found:
	print 	no_virtual_services	; Announce no virtual DMA services
	mov		cnvrt_to_phys_add, offset cgroup:linear_address_convert
exit_check_virtual_mem_services:
	ret
check_virtual_mem_services	ENDP


linear_address_convert	PROC	NEAR
	; Address to be converted is in es:si
	; Converted physical address is returned in eax
	xor		eax, eax
	mov		ax, es
	shl		eax, 4
	movzx	esi, si			; Make certain that top part of SI is clear
	add		eax, esi
	ret
linear_address_convert	ENDP

virtual_address_convert	PROC	NEAR
	mov     di, offset cgroup:virtual_mem_struct
	; Lock the memory,
	; which in turn returns the physical address in the DMA descriptor
	mov     word ptr [di], 200h
	mov     word ptr [di+2], 0
	mov     word ptr [di+4], si
	mov     word ptr [di+6], 0
	mov     [di+8], es

    mov     ax, 8103h		; Lock DMA region
    mov     dx, 0ch			; No alloc, no remap
    push    ds
    pop     es
    int     4Bh
	jc		short exit_virtual_address_convert

							; Now unlock the DMA region
    mov     ax, 8104h		; Unlock DMA region
    mov     dx, 0			; No copy
    int     4Bh
no_unlock:
    mov     eax, [di+0ch]
	clc
exit_virtual_address_convert:
	ret
virtual_address_convert	ENDP

etopen_chip	PROC	NEAR
	call	eisa_get_config
	jc	short exit_etopen_chip

config_io_addr:
	mov	ax, LP486E_PORT_ADDR
	mov	io_addr, ax
	call	reset_chip
	call	test_chip
	jc	short etopen_failed
	call	init_scp			; Initialize the SCP, ISCP, SCB
	jc	short etopen_failed

configure:
	call	setup_cmd_buffs		; Setup buffer for commands
	call	config_chip			; Configure chip
	jc	short exit_etopen_chip
	call	print_media
exit_etopen_chip:
	ret
etopen_failed:
	mov	dx, offset cgroup:init_error_msg
	stc							; Give up.
	ret
etopen_chip	ENDP

test_chip	PROC	NEAR
	print	self_test_msg			; Announce the start of the self test
	mov		ax, cs
	mov		es, ax
	mov		si, offset cgroup:self_test_buff
	call	cnvrt_to_phys_add
	jnc		short cnvrt_ok
	print	problem_in_phys_add
	stc
	jmp		short exit_test_chip
cnvrt_ok:
	or		al, SELF_TEST_CMD
	PORT
	STALL							; Hold things up - briefly
	mov		ax, 1					; Wait, if necessary, for about 27 mili-
	call	set_timeout				;    seconds (5 should be enough)
check_test_buff:
	cmp		self_test_buff, 0h	; Test both DWORDS in the buffer
	je		short not_passed		; Need to pass both tests
	cmp		self_test_buff+4, 0h
	jne		short not_passed
	print	self_test_ok_msg
	; 82557 self test resets the chip, need time to recover - 48h too small
	mov		ax, 50h					
	call	wait
	clc
	jmp		short exit_test_chip
not_passed:
	call	do_timeout				; Any more time left ?
	jnz		check_test_buff			; Continue to wait if so
	print	self_test_no_msg		; No - announce failure
	stc
exit_test_chip:
	ret
test_chip	ENDP

; Routines for the 82596
init_scp	PROC	NEAR
; Performs the alternate SCP and ISCP initialization for the 82596
	mov		ax, cs						; Set Up the Alternate SCP Address
	mov		es, ax
	mov		si, offset cgroup:scp_buff
	call	cnvrt_to_phys_add
	jc		error_init_scp
	or		al, ALT_SCP_CMD
	PORT
	STALL							; Hold things up - briefly
	mov		ax, 2
	call	wait					; Hold things up for 50ms

; Initialize the SYSBUS byte in System Configuration Pointer (SCP)
; Internal Triggering Of Timers, Active High Edge-Triggered Interrupt
	mov		ax, SYSBUS_CSW OR SYSBUS_LOCK_DIS OR SYSBUS_32_MODE OR SYSBUS_BIT_0
	mov     scp_buff.scp_sysbus, ax
	mov		si, offset cgroup:iscp_buff
	call	cnvrt_to_phys_add
	jc		error_init_scp

    mov     scp_buff.scp_iscp_add, eax
	mov		iscp_buff.iscp_busy, ISCP_BUSY_MARK
    mov     si, 0
	call	cnvrt_to_phys_add
	jc		short error_init_scp

    lea     si, scb_buff
    mov     iscp_buff.iscp_scb_offset, si
    mov     iscp_buff.iscp_scb_lo_add, ax
    shr     eax, 16
    mov     iscp_buff.iscp_scb_hi_add, ax
    mov     scb_buff.scb_status, 0h
    CA					; Issue a channel attention to the 82596

	mov		ax, 1					; Wait, if necessary, for about 27 mili-
	call	set_timeout				;    seconds (10 should be enough)
iscp_busy_wait:
	test	iscp_buff.iscp_busy, ISCP_BUSY_MARK
	jz		short iscp_success
	call	do_timeout				; Any more time left ?
	jnz		short iscp_busy_wait	; Continue to wait if so
	jmp		short iscb_problem

iscp_success:
	mov		ax, scb_buff.scb_status		;- Acknowledge any interrupts
	and		ax, SCB_STATUS_MASK
	mov		scb_buff.scb_command, ax
    CA					; Issue a channel attention to the 82596
	mov		ax, 1					; Minimum time out value
	call	wait_scb_non_active
	jc		short iscb_problem

    mov     ax, DEFAULT_T_OFF		; Load the Bus Throttle values.
    mov     scb_buff.scb_off_timer, ax
    mov     ax, DEFAULT_T_ON
    mov     scb_buff.scb_on_timer, ax
    mov     scb_buff.scb_command, CU_LD_B_T_R
    CA						; Issue a channel attention to the 82596
	mov		ax, 1					; Minimum time out value
	call	wait_scb_non_active
	jnc		short exit_init_scp
iscb_problem:
	print	iscp_init_problem		; Inform the user
	stc

exit_init_scp:
    ret
error_init_scp:
	print	problem_in_phys_add
error_init_iscp:
	stc
	jmp		short	exit_init_scp

init_scp	ENDP

eisa_get_config	PROC	NEAR
	xor	cx, cx			; CH = 0 (function 0), CL = 0 (slot 0)
eisa_next_func:
	mov	si, offset eisa_config
	mov	ax, 0D801h		; INT 15, AH=D801 - read function
	int	15h			; configuration information
	jnc	short eisa_int15_success
	mov	dx, offset eisa_config_error_msg
	stc
	jmp	short eisa_get_exit
eisa_int15_success:
	push	cx
	push	cs
	pop	es			; INT 15 trashes the ES, restore it
	mov	di, offset eisa_sub_type
	mov	si, offset eisa_config+23h ; function string for NIC config
	mov	cx, 22			; string length
	cld
	rep	cmpsb			; compare strings
	pop	cx
	je	short eisa_config_found
	inc	ch			; increment the function number
	jmp	short eisa_next_func	; check next EISA function
eisa_config_found:
	test	byte ptr [eisa_config+94h],0FFh	; non-zero if NIC is enabled
	jnz	short eisa_nic_enabled
	mov	dx, offset eisa_nic_disabled_msg
	stc
	jmp	short eisa_get_exit
eisa_nic_enabled:
	mov	al, eisa_config+93h	; get NIC IRQ number
	mov	int_no, al		; store it
	mov	eax, dword ptr [eisa_config+88h] ; MAC address bytes 0-3
	mov	dword ptr [rom_address], eax
	mov	ax, word ptr [eisa_config+8Ch]	; MAC address bytes 4-5
	mov	word ptr [rom_address+4], ax
	clc
eisa_get_exit:
	ret
eisa_get_config ENDP

print_media	PROC	NEAR
	mov	dx, 0C02h
	in	al, dx
	or	al, 40h
	jz	short print_aui
	print	media_tpe_msg
	jmp	short print_media_exit
print_aui:
	print	media_aui_msg
print_media_exit:
	ret
print_media	ENDP


setup_cmd_buffs	PROC	NEAR
; Setup buffer for commands
	mov		word ptr cmd_buff1, C_DONE_BIT	; Mark buffer as available
	mov		word ptr cmd_buff2, C_DONE_BIT	; Mark buffer as available
	mov		buff_ptrs[0], offset cgroup:cmd_buff1	; Settup buffer 'array'
	mov		buff_ptrs[2], offset cgroup:cmd_buff2
	mov		tx_buff_no, 0					; Set next buffer # to use
	ret
setup_cmd_buffs	ENDP

setup_receive	PROC	NEAR
	mov		cx, RBD_COUNT 			; Setup the receive buffer descriptors
	mov		ax, cs
	mov		es, ax
	mov		si, offset cgroup:start_rx_buff
	mov		bx, si					; Bx holds a copy of the virtual offset
	call	cnvrt_to_phys_add
	mov		esi, eax
	mov		di, offset cgroup:start_rbd
	mov		first_rbd, di
	mov		ax, di
next_rbd:
	mov		[di].rbd_status, 0
	add		ax, size rbd_struct				; Pointer to the next RBD
	mov		[di].rbd_link, ax
	mov		[di].rbd_ptr, esi				; Store physical address
	mov		[di].rbd_size, SIZE_ONE_DATA_BUFF
	mov		[di].rbd_filler1, 0
	mov		[di].rbd_voffset, bx			; Store the virtual offset
	add		esi, SIZE_ONE_DATA_BUFF			; Physical address of next buffer
	add		bx, SIZE_ONE_DATA_BUFF			; Virtual offset of next buffer
	mov		di, ax							; Advance to the next RBD
	loop	next_rbd

	sub		di, size rbd_struct				; Return to previous RBD
	mov		last_rbd, di
	or		[di].rbd_size, EL_BIT			; Mark end of chain
	mov		[di].rbd_link, offset cgroup:start_rbd

	mov		cx, RFD_COUNT 				; Setup the receive buffer descriptors
	mov		di, offset cgroup:start_rfd
	mov		first_rfd, di
	mov		ax, di
next_rfd:
	mov		[di].rfd_status, 0
	mov		[di].rfd_eol, FLEXIBLE_MODE
	add		ax, size rfd_struct		 		; Pointer to the next RFD
	mov		[di].rfd_link, ax
	mov		[di].rfd_ptr, -1
	mov		[di].rfd_cnt, 0
	mov		[di].rfd_size, 0
	mov		di, ax							; Advance to the next RFD
	loop	next_rfd

	sub		di, size rfd_struct				; Get back to last RFD
	mov		last_rfd, di
	mov		[di].rfd_eol, EL_BIT+FLEXIBLE_MODE	; Mark end of chain
	mov		[di].rfd_link, offset cgroup:start_rfd	; Wrap around to start
							; Setup the start rdf to point to the start rbd
	mov		[start_rfd].rfd_ptr, offset cgroup:start_rbd	

	WAIT_CMD_ACCEPTED 					; Wait for acceptance of last command
	mov		scb_buff.scb_rfa_add, offset cgroup:start_rfd
	mov		scb_buff.scb_command, RU_START
	CA
	ret
setup_receive	ENDP

config_chip	PROC	NEAR
	call	do_config
	mov		dx, offset cgroup:config_msg
	jc		short exit_config_chip	; Exit if there is a problem

	mov		ax, 8					; Wait for the command
	call	wait
; Set the Individual address registers with the Ethernet address
	mov		si, offset cgroup:rom_address
	call	set_ether
	jc		short exit_config_chip	; Exit if there is a problem
	clc
exit_config_chip:
	ret
config_chip	ENDP

code	ends

_text	segment para public 'code'
_text	ends

init	segment para public 'code'
init	ends

	END
