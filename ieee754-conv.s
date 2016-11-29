; Names: Evan Rittenhouse, Jacob Lutz, Nicholas Harman, Nisarga Patel
; Policy: No one can use this code without explicit permission and credit given

@ FIR Filter
.text
.global _start
	
;	LDR r0, =0x5c035ba0 ;load literal like this example 23555.23456
	LDR r0, =0x00060006
	LDR r2, =0x0000ffff ; set the bits we want
	LDR r3, =0xffff0000
	AND r2, r0, r2
	AND r3, r0, r3
	MOV r3, r3, ROR#16
	MOV r11, #0
	MOV r7, #1
	LDR r4, =0b01
loop_pow_two:
	MOV r4, r4, LSL#1
	CMP r4, r3
	ADDLS r7, r7, #1
	BLS loop_pow_two

; now we have the number of binary digits in the first part
; for example 0x000a is 0b1010 which is 4 digits is stored in r7
; now we can do 23 - r7 to get the number of loop iterations for last part
loop_pow_ten:
	LDR r10, =pows_ten
	LDR r9, [r10, r11]
	ADD r11, r11, #4	
	CMP r9, r2
	BLS loop_pow_ten

    ; now we have the power of 10 to compare against stored in r9
	LDR r8, =0x18 ; 24 in hex is 0x18, 24 not 23 because # of digits - 1
	SUB r11, r8, r7
	LDR r8, =0x00000000
	; r11 contains number of next loop iterations
finish:
	SWI 0x11		
.data
	pows_ten: .word 0x1,  0xA, 0x64, 0x3E8, 0x2710, 0x186A0





