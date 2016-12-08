; Some example numbers
; 12561.001953125  is 0x0x31110080 and its IEEE 754 value is 0x46444402
; 150 is 0x00960000 and its IEEE 754 value is 0x43160000
; 5.625 is 0x0005A000 and its IEEE 754 value is 0x40b40000
; -5.625 is 0x8005A000 and its IEEE 754 value is 0xc0b40000
; 0.625 is 0x0000A000 and its IEEE 754 value is 0x3f200000
; ldr r0, =0x7FFF0000	    ; Loads dumb fmt number into mem

main:
    ldr r0, =0x0005A000                    ; Load number in dumb fmt to convert
    bl convert_ieee                        ; Convert first value to IEEE
    mov r1, r0                             ; Move return value into r1

    stmfd sp!, {r1}                        ; Save the first return value on the stack
    ldr r0, =0x0000A000                    ; Load second value in dumb format
    bl convert_ieee                        ; Convert second value to IEEE
    ldmfd sp!, {r1}                        ; Restore r1 value
    mov r2, r0                             ; Move second converted value to r2. R1 and R2 are now operands

    stmfd sp!, {r1-r2}
    bl addfloat                            ; Add the two numbers
    ldmfd sp!, {r1-r2}
    stmfd sp!, {r0}                        ; Store the result on the stack


    stmfd sp!, {r1-r2}
    bl subfloat                            ; Subtract the two numbers
    ldmfd sp!, {r1-r2}
    stmfd sp!, {r0}                        ; Store the result on the stack

    stmfd sp!, {r1-r2}
    bl ieee754multiply                     ; Multiply the two numbers
    ldmfd sp!, {r1-r2}
    stmfd sp!, {r0}                        ; Store the result on the stack

    fmsr s1, r1
    fmsr s2, r2
    fadds s0, s1, s2
    fmrs r0, s0
    fsubs s0, s1, s2
    fmrs r1, s0
    fmuls s0, s1, s2
    fmrs r2, s0
    stmfd sp!, {r0-r2}

    swi 0x11

convert_ieee:
    stmfd sp!, {lr}                        ; Save link register on the stack
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
    orr r0, r6, r0                      ; The final IEEE 754 number is in register r0 now

    ldmfd sp!, {lr}
    mov pc, lr                          ; Retrieve link register from stack and return

; r0 = r1 * r2
ieee754multiply:
    stmfd sp!, {lr}
    and r3, r1, #0x80000000         ; extract sign of operand1
    and r4, r2, #0x80000000         ; extract sign of operand2

    eor r0, r3, r4                  ; get the new sign bit

    ldr r9, =0x7f800000
    and r3, r1, r9                  ; extract exponents
    and r4, r2, r9                  ; extract exponents

    mov r3, r3, lsr #23
    mov r4, r4, lsr #23
    sub r3, r3, #127        ; remove exponent bias
    sub r4, r4, #127

    add r5, r3, r4          ; add exponents, r5 now holds the new exponent

    ldr r9, =0x007fffff
    and r3, r1, r9                  ; extract fractions from operand1
    and r4, r2, r9                  ; extract fractions from operand2
    orr r3, r3, #0x00800000         ; add implied 1 to front of fraction one
    orr r4, r4, #0x00800000         ; add implied 1 to front of fraction one

; r6 high r7 low = r3 * r4. r9 is used as high sigbits for r4
    stmfd sp!, {r3-r4, r8-r9}              ; Save r8 and r9 registers
    mov r6, #0
    mov r7, #0                      
    mov r9, #0                      ; Zero out r6 and r7 for result

mul:
    ands r8, r3, #1                 ; Test to see if there's a 1 in the LSB. r8 is used temporarily here for the test
    beq no_add                      ; Ands will set the zero flag if the LSB doesn't exist. "eq" jumps when the zero flag is present

    adds r7, r7, r4
    adc r6, r6, r9                   ; Add r4 to the low significance register if the LSB in r3 is a 1, then add carry to high reg along with high sig register

no_add:
    mov r9, r9, lsl #1
    movs r4, r4, lsl #1
    adc r9, r9, #0                 ; Shift r4 to the left, move carry bit and add overflow into r9

    movs r3, r3, lsr #1             ; Shift r3 to the right and set flags
    bne mul                         ; The previous movs will set the zero flag if we move zero into r3, causing a branch if r3 is not yet zero

    ldmfd sp!, {r3-r4, r8-r9}       ; Restore previously saved values

; if bit 48 from the multiplication is 1 then we need to shift right one and add one to the exponent 
creatfraction:
    ands r8, r6, #0x00008000         ; check to see if bit 16 of the hi bits 
    
    ; bit 48 of multiplication was a one so add one to the exponent and create fraction
    addne r5, r5, #1         ; if ne is true that means the ands above resulted in a non-zero value indicating the 16th bit was a 1
    movne r6, r6, lsl #16    ; make room to pull in low bits from multiply, if bit 16 was 1 shift 16
    movne r7, r7, lsr #16     ; move the low bits right so they can be merged with the high bits
    
    ; no normalization necessary just combine the first 23 bits from high and low
    moveq r6, r6, lsl #17    ; make room to pull in low bits from multiply, if bit 16 was not 1 shift 17  
    moveq r7, r7, lsr #15     ; move the low bits right so they can be merged with the high bits
    
    ; or the fraction parts together
    orr r6, r6, r7           ; put the fraction halves together
    mov r6, r6, lsr #8       ; make the fraction only use 24 bits
    bic r6, r6, #0x00800000         ; clear the implied 1 from the fraction

done:
    add r5, r5, #127        ; re-add bias to the exponent
    mov r5, r5, lsl #23     ; shift exponent into its ieee754 position
    orr r0, r0, r5          ; merge exponent into the result register r0
    orr r0, r0, r6          ; merge fraction into the result register r0

finish:
    ldmfd sp!, {lr}
    mov pc, lr              ; Return to caller


; r0 = r1 - r2
subfloat:
    stmfd sp!, {lr}
    ldr r10, =0x80000000
    eor r2, r2, r10             ; Exclusive or r2 with 0x80000000 to toggle the sign bit
    bl addfloat
    ldmfd sp!, {lr}
    mov pc, lr                  ; Return to caller

; r0 = r1 + r2
addfloat:
    ldr r10, =0x7f800000
    and r4, r1, r10             ; use a bitmask to capture the first number's exponent
    and r5, r2, r10             ; use a bitmask to capture the second number's exponent
    cmp r4, r5

    movcc r3, r1
    movcc r1, r2
    movcc r2, r3                ; swap r1 with r2 if r2 has the higher exponent
    andcc r4, r1, r10 
    andcc r5, r2, r10           ; update exponents if swapped

    mov r4, r4, lsr #23
    mov r5, r5, lsr #23         ; move exponents to least significant position

    sub r3, r4, r5              ; subtract exponents to get shift amount
    ldr r10, =0x007fffff     
    and r5, r1, r10             ; grab first number's fractional part
    and r6, r2, r10             ; grab second number's fractional part
    ldr r10, =0x00800000
    orr r5, r5, r10             ; add implied 1 to first fractional part
    orr r6, r6, r10             ; add implied 1 to second fractional part
    mov r6, r6, lsr r3          ; shift r6 to the right by the difference in exponents

    ldr r10, =0x80000000
    ands r0, r1, r10            ; check msb for negative bit
    movne r0, r5                ; this "not equal" works because the "ands" will set the zero flag if the result is zero
    stmnefd sp!, {lr}
    blne twos_complement        ; two's complement fractional first number if it's supposed to be negative
    ldmnefd sp!, {lr}
    movne r5, r0

    ands r0, r2, r10             ; check msb for negative bit
    movne r0, r6
    stmnefd sp!, {lr}
    blne twos_complement        ; two's complement fractional second number if it's supposed to be negative
    ldmnefd sp!, {lr}
    movne r6, r0

    add r5, r5, r6              ; add the fractional portions. r5 contains the result.

    ands r0, r5, r10             ; check msb to see if the result is negative
    movne r0, r5
    stmnefd sp!, {lr}
    blne twos_complement        ; two's complement result if negative
    ldmnefd sp!, {lr}
    movne r5, r0
    ldrne r0, =0x80000000       ; put a 1 as result's msb if the result was negative
    moveq r0, #0                ; put a 0 as result's msb if the result was positive

    mov r3, #0
    ldr r10, =0x80000000

count_sigbit_loop:
    cmp r10, r5
    addhi r3, r3, #1
    movhi r10, r10, lsr #1
    bhi count_sigbit_loop       ; count how many times you have to shift before hitting a 1 in the result

    cmp r3, #8                  ; if it's shifted 8 times it's already in the right place
    subhi r3, r3, #8            ; if it needs shifting left, determine how many times
    movhi r5, r5, lsl r3        ; shift as needed
    subhi r4, r4, r3            ; subtract shift amount from exponent to reflect shift
    movcc r10, #8
    subcc r3, r10, r3           ; if it needs shifting right, determine how many times
    movcc r5, r5, lsr r3        ; shift as needed
    addcc r4, r4, r3            ; add shift amount to exponent to relfect shift

    mov r4, r4, lsl #23         ; shift exponent into place
    orr r0, r0, r4              ; or exponent into number
    ldr r10, =0x007fffff
    and r5, r5, r10             ; get rid of implied 1 in fraction
    orr r0, r0, r5              ; attach fractional part

    mov pc, lr

; r0 = -r0
twos_complement:
    mvn r0, r0                  ; negate r0
    add r0, r0, #1              ; add 1
    mov pc, lr                  ; Return to caller
