if LANGUAGE eq US_ENGLISH
	public	usage_msg, copyright_msg

usage_msg	label	byte
	db "usage: ",short_name
 	db " [options] <packet_int_no>",CR,LF,'$'
copyright_msg	label byte
	db "Packet driver for ",long_name,", version "
	db '0'+(majver / 10),'0'+(majver mod 10),".",'0'+version,CR,LF
	db "Portions written by Sergey Kiselev and Morien W. Roberts; ",CR,LF,'$'

need_eisa_msg		db	"An EISA BIOS is required for this driver.",CR,LF,'$'
self_test_msg		db	"Performing self test of chip.... ",'$'
self_test_ok_msg	db	"PASSED.",CR,LF,'$'
self_test_no_msg	db	"FAILED.",CR,LF,'$'
virtual_services	db	"Using virtual memory services of memory manager.",CR,LF,'$'
no_virtual_services	db	"Not using any memory manager services.",CR,LF,'$'
problem_in_phys_add	db	"Problem with virtual memory services.",CR,LF,'$'
iscp_init_problem	db	"Problem with ISCP command.",CR,LF,'$'
config_msg 		db	"Config failure - config operation failed.",CR,LF,'$'
ether_add_msg		db	"Config failure - setting ethernet address.",CR,LF,'$'
dummy_msg		db	'$'
int_no_name		db	"Interrupt number ",'$'
io_addr_name		db	"I/O port ",'$'

init_error_msg		db	"Failed to initialize Ethernet controller",CR,LF,'$'
eisa_config_error_msg	db	"Unable to read on-board Ethernet configuration from EISA BIOS",CR,LF,'$'
eisa_nic_disabled_msg	db	"On-board Ethernet controller is disabled",CR,LF,'$'
media_tpe_msg		db	"Using twisted pair cable",0Dh,0Ah,'$'
media_aui_msg		db	"Using AUI interface",0Dh,0Ah,'$'

	public ether_add_msg1, ether_add_msg2
ether_add_msg1		db	"Config failure - ethernet 1.",CR,LF,'$'
ether_add_msg2		db	"Config failure - ethernet 2.",CR,LF,'$'
endif
