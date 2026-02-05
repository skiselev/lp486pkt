lp486pkt - MS-DOS Packet Driver for Intel i82596
================================================

Known machines featuring this controller:
* Intel Professional Workstation LP486SX/20E (PBA 515338)

82596CA High-Performance 32-Bit Local Area Network Coprocessor
--------------------------------------------------------------

The 82596CA is an intelligent, high-performance 32-bit Local Area Network
coprocessor. The 82596CA implements the CSMA/CD access method and can be
configured to support all existing IEEE 802.3 standards - TYPEs 10BASE-T,
10BASE5, 10BASE2, 1BASE5, and 10BROAD36. It can also be used to implement the
proposed standard TYPE 10BASE-F. The 82596CA performs high-level commands,
command chaining, and interprocessor communications via shared memory, thus
relieving the host CPU of many tasks associated with network control. All
time-critical functions are performed independently of the CPU, this increases
network performance and efficiency. The 82596CA bus interface is optimized for
Intel's i486(TM) SX, i486(TM) DX, i487(TM) SX, 80960CA, and 80960KB processors.

Documentation was available from Intel's Developers' Insight CD-ROM:
* [29021806.PDF](./29021806.PDF)

Linux kernel supported (as `lp486e`) this chip until version 3.7 and it was
removed in commit [5205939d0f15803cc402e32ac5b886dbb7c50b99](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=5205939d0f15803cc402e32ac5b886dbb7c50b99).
