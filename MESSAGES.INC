if LANGUAGE eq US_ENGLISH
	public	usage_msg, copyright_msg

bad_key_msg	db	"Unknown keyword on the command line.", CR,LF
usage_msg	label	byte
	db "usage: ",short_name
 	db " [options] <packet_int_no> {irq_no}",CR,LF,'$'
copyright_msg	label byte
	db "Packet driver for ",long_name,", version "
	db '0'+(majver / 10),'0'+(majver mod 10),".",'0'+version,CR,LF
	db "Portions written by Sergey Kiselev and Morien W. Roberts; ",CR,LF,'$'

need_eisa_msg		db	"An EISA BIOS is required for this driver.",CR,LF,'$'
self_test_msg		db	"Performing self test of chip....",'$'
self_test_ok_msg	db	"     PASSED.",CR,LF,'$'
self_test_no_msg	db	"     FAILED.",CR,LF,'$'
virtual_services	db	"Using virtual memory services of memory manager."
					db	CR,LF,'$'
no_virtual_services	db	"Not using any memory manager services.",CR,LF,'$'
problem_in_phys_add	db	"Problem with virtual memory services.",CR,LF,'$'
iscp_init_problem	db	"Problem with ISCP command.",CR,LF,'$'
config_msg 			db	"Config failure - config operation failed.",CR,LF,'$'
ether_add_msg		db	"Config failure - setting ethernet address.",CR,LF,'$'
dummy_msg			db	'$'
int_no_name			db	"Interrupt number ",'$'
io_addr_name		db	"I/O port ",'$'

init_error_msg	db	"Failed to initialize Ethernet controller",CR,LF,'$'
no_mac_msg	db	"Cannot find MAC address in EISA configuration area",CR,LF,'$'

	public ether_add_msg1, ether_add_msg2
ether_add_msg1		db	"Config failure - ethernet 1.",CR,LF,'$'
ether_add_msg2		db	"Config failure - ethernet 2.",CR,LF,'$'
endif