; Intel Professional Workstation Specific I/O addresses and IRQ
LP486E_PORT_ADDR	equ	0CB0h		; Port commands address
LP486E_CA_ADDR		equ	0CB4h		; Channel Attention address
LP486E_CLEAR_INT_ADDR	equ	0CB8h		; Clear interrupt address

; Issue a Port command to the 82596
PORT	MACRO
	mov	dx, LP486E_PORT_ADDR
	out	dx, ax			; Out low 16 bits
	inc	dx
	inc	dx
	shr	eax, 16			; Out high 16 bits
	out	dx, ax
	ENDM

; Issue a channel attention to the 82596	
CA	MACRO
	mov	dx, LP486E_CA_ADDR
	xor	ax, ax
	out	dx, ax
	ENDM
