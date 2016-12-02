@ fir filter
.text
.global _start
	
	ldr r1, =0x4000000
	ldr r2, =0x64
	
	mov r0, #0
	mov r3, #1
start:
	cmp r2, r1
	movls r2, r2, lsl#1
	movls r3, r3, lsl#1
	bls start
next:
	cmp r1, r2
	subcs r1, r1, r2
	addcs r0, r0, r3
	movs r3, r3, lsr#1
	movcc r2, r2, lsr#1
	bcc next
	swi 0x11
