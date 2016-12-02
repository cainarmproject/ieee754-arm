; names: evan rittenhouse, jacob lutz, nicholas harman, nisarga patel
; policy: no one can use this code without explicit permission and credit given

@ fir filter
.text
.global _start

	;ldr r0, =0x5c035ba0 ;load literal like this example 23555.23456
	ldr r0, =0x80030001 ; -3.1
	;ldr r0, =0x00030001
	mov r8, r0 ; save the original
	bic r0, r0, #0x80000000
	;ldr r0, =0x00060006
	;ldr r0, =0x00040020
	ldr r2, =0x0000ffff ; set the bits we want
	ldr r3, =0xffff0000
	and r2, r0, r2
	and r3, r0, r3
	mov r3, r3, ror#16
	mov r11, #0
	mov r7, #1
	ldr r4, =0b01
loop_pow_two:
	mov r4, r4, lsl#1
	cmp r4, r3
	addls r7, r7, #1
	bls loop_pow_two

; now we have the number of binary digits in the first part
; for example 0x000a is 0b1010 which is 4 digits is stored in r7
; now we can do 23 - r7 to get the number of loop iterations for last part
loop_pow_ten:
	ldr r10, =pows_ten
	ldr r9, [r10, r11]
	add r11, r11, #4
	cmp r9, r2
	bls loop_pow_ten

    ; now we have the power of 10 to compare against stored in r9
	mov r6, r8 ; save the original
	ldr r8, =0x18 ; 24 in hex is 0x18, 24 not 23 because # of digits - 1
	sub r11, r8, r7
	ldr r8, =0x00000000
	; r11 contains number of next loop iterations
	; r2 contains lower half of the number
	; r9 contains the power of 10
	; r7 contains the exponent + 1
	mov r4, r2 ; r4 contains lower
	mov r5, r3 ; r5 contains upper
	mov r5, r5, ror #16
	mov r2, r2, lsl r11

	; r2, and r9
	mov r1, r2
	mov r2, r9

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

	mov r5, r5, ror#16
	mov r3, r6 ; save original value
	ldr r6, =0
	ldr r8, =0x1
	mov r9, r7
	sub r7, r7, #1

mask_set:
	add r6, r8, r6
	mov r8, r8, lsl#1
	sub r7, r7, #1
	cmp r7, #0
	bne mask_set

	mov r4, r9 ; save the exponent
	and r5, r5, r6
	ldr r8, =0x18
	sub r9, r8, r9
	mov r5, r5, lsl r9
	add r0, r5, r0
	ldr r8, =0x7e
	add r8, r4, r8
	mov r8, r8, lsl#23
	add r0, r0, r8
	; mask sign bit from original # and or to result
	ldr r6, =0x80000000
	and r6, r3, r6
	orr r0, r6, r0

finish:
	swi 0x11
.data
	pows_ten: .word 0x1,  0xA, 0x64, 0x3E8, 0x2710, 0x186A0
