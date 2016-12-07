; floatmul.s
; authors: evan rittenhouse, jacob lutz, nicholas harman, nisarga patel

@ fir filter
.text
.global _start

    ; ldr r1, =0x40900000     ; 4.5 in ieee754
    ; ldr r2, =0x41f40000     ; 30.5 in ieee754

    
    ; ldr r1, =0x40200000     ; 2.5 in ieee754
    ; ldr r2, =0x40900000     ; 4.5

    ldr r1, =0xc2fa4000      ; -125.125
    ldr r2, =0x42484000      ; 50.0625

ieee754multiply:
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
    swi 0x11