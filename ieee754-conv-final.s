
; Some example numbers
; 12561.001953125  is 0x0x31110080 and its IEEE 754 value is 0x46444402
; 150 is 0x00960000 and its IEEE 754 value is 0x43160000
; 5.625 is 0x0005A000 and its IEEE 754 value is 0x40b40000
; -5.625 is 0x8005A000 and its IEEE 754 value is 0xc0b40000
; 0.625 is 0x0000A000 and its IEEE 754 value is 0x3f200000
; ldr r0, =0x7FFF0000	    ; Loads dumb fmt number into mem

ldr r0, =0x31110080                    ; Load number in dumb fmt to convert
mov r8, r0                             ; Save the original
bic r0, r0, #0x80000000                ; Clears out first bit
ldr r1, =0x40000000	                   ; Loads initial pos to check
mov r3, #1                             ; Incrementer to get sig bit pos

loop_until_find_sig:
	and r2, r1, r0                       ; Grab sig bit
	cmp r2, r1                           ; Compare r2 and r1
	mov r1, r1, lsr #1                   ; Moves the sig bit to the right
	add r3, r3, #1                       ; Adds one to the position finder
	bne loop_until_find_sig              ; Branches until sig bit is found

; At this point we have the position of the bit in the r3 register
mov r1, #16                            ; Move 16 into r1
sub r1, r1, r3                         ; Subtract from 16 the pos value

; The lowest possible exponent value will be 0xFFFFFF0 because overflow
; Therefore if the value of the exponent is greater than 0xFFFFFEF
; it is less than 0
; If the exponent is less than 0
; (0xFFFFFFFF - 0xFFFFFFFE) + 1 + 7 will get the amt to shift left by
; If the exponent is less than 7 shift by 7 - exponent
mov r5, #127                           ; Move bias to r5
check_against_seven:
	cmp r1, #7                           ; Check against seven
	blt calc_mantissa_if_less            ; Branch to mantissa calc less than
	bgt calc_mantissa_if_greater         ; Branch to mantissa calc if gt
	beq calc_bias_seven                  ; Calc bias if its seven
calc_mantissa_if_less:
	mov r4, #7
	add r5, r5, r1                       ; Calculate bias as 127 - exponent
	sub r1, r4, r1                       ; Do 7 - exponent to get shift amt
	mov r0, r0, lsl r1                   ; Shift left by value in r1
	bl finalize_mantissa
calc_mantissa_if_greater:
	add r5, r5, r1                       ; Calculate bias as 127 + exponent
	sub r1, r1, #7                       ; Do exponent - 7 to get shift amt
	mov r0, r0, lsr r1                   ; Shift right by value in r1
	bl finalize_mantissa
calc_bias_seven:
	add r5, r5, #7                       ; Calculate bias as 127 + 7
finalize_mantissa:
	ldr r4, =0x007FFFFF                  ; To get 23 bits
	and r0, r4, r0

; At this point the biased exponent is stored in r5 and mantissa in r0
mov r5, r5, lsl#23
add r0, r0, r5

; mask sign bit from original # and or to result
ldr r6, =0x80000000
and r6, r8, r6
orr r0, r6, r0

; The final IEEE 754 number is in register r0 now
swi 0x11
