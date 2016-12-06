; floatmul.s
; Authors: Evan Rittenhouse, Jacob Lutz, Nicholas Harman, Nisarga Patel

@ FIR Filter
.text
.global _start

    ;LDR r1, =0x40900000     ; 4.5 in IEEE754
    ;LDR r2, =0x41f40000     ; 30.5 in IEEE754

    
    ;LDR r1, =0x40200000     ; 2.5 in IEEE754
    ;LDR r2, =0x40900000     ; 4.5

    LDR r1, =0xc2fa4000      ;-125.125
    LDR r2, =0x42484000      ;50.0625

    LDR r10, =0x00800000    ; bitmask for adding/removing implied 1 to front of fraction 
    LDR r11, =0x80000000    ; bitmask for extracting sign bit
    LDR r12, =0x007FFFFF    ; bitmask for extracting fraction
    LDR r13, =0x7f800000    ; bitmask for extracting exponent

ieee754multiply:
    AND r3, r1, r11         ; extract sign of operand1
    AND r4, r2, r11         ; extract sign of operand2

    EOR r0, r3, r4          ; get the new sign bit

    AND r3, r1, r13         ; extract exponents
    AND r4, r2, r13         ; extract exponents

    MOV R3, R3, LSR #23
    MOV R4, R4, LSR #23
    SUB r3, r3, #127        ; remove exponent bias
    SUB r4, r4, #127

    ADD r5, r3, r4          ; add exponents, r5 now holds the new exponent

    AND r3, r1, r12         ; extract fractions from operand1
    AND r4, r2, r12         ; extract fractions from operand2
    ORR r3, r3, r10         ; add implied 1 to front of fraction one
    ORR r4, r4, r10         ; add implied 1 to front of fraction one

mul:
    UMULL r7, r6, r3, r4          ; multiply the fractions           

;if bit 48 from the multiplication is 1 then we need to shift right one and add one to the exponent 
creatFraction:
    LDR r11,  =0x00008000    ; bitask for checking if bit 16 is a 1
    ANDS r8, r6, r11         ; check to see if bit 16 of the hi bits 
    
    ; bit 48 of multiplication was a one so add one to the exponent and create fraction
    ADDNE r5, r5, #1         ; If NE is true that means the ANDS above resulted in a non-zero value indicating the 16th bit was a 1
    MOVNE r6, r6, LSL #16    ; make room to pull in low bits from multiply, if bit 16 was 1 shift 16
    MOVNE r7, r7, LSR #16     ; move the low bits right so they can be merged with the high bits
    
    ; no normalization necessary just combine the first 23 bits from high and low
    MOVEQ r6, r6, LSL #17    ; make room to pull in low bits from multiply, if bit 16 was not 1 shift 17  
    MOVEQ r7, r7, LSR #15     ; move the low bits right so they can be merged with the high bits
    
    ; or the fraction parts together
    ORR r6, r6, r7           ; put the fraction halves together
    MOV r6, r6, LSR #8       ; make the fraction only use 24 bits
    BIC r6, r6, r10         ; clear the implied 1 from the fraction

done:
    ADD r5, r5, #127        ; re-add bias to the exponent
    MOV r5, r5, LSL #23     ; shift exponent into its IEEE754 position
    ORR r0, r0, r5          ; merge exponent into the result register r0
    ORR r0, r0, r6          ; merge fraction into the result register r0

finish:
    SWI 0x11