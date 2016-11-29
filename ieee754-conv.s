; Names: Evan Rittenhouse, Jacob Lutz, Nicholas Harman, Nisarga Patel
; Policy: No one can use this code without explicit permission and credit given

@ FIR Filter
.text
.global _start
	
	LDR r0, =0x5c035ba0 ; load literal like this example 23555.23456
	LDR r2, =0x0000ffff ; set the bits we want
	LDR r3, =0x00000000
	AND r2, r0, r2
	MOV r11, #0
loop_pow_ten:
	LDR r10, =pows_ten
	LDR r9, [r10, r11]
	ADD r11, r11, #4	
	CMP r9, r2
	BLT loop_pow_ten
; at this point the power of 10 that is greater than decimal part is in r9
next:
	; now we can do the shift left by 1 loop and compare against r9
	SWI 0x11		
.data
	pows_ten: .word 0x1, 0xA, 0x64, 0x3E8, 0x2710, 0x186A0





