@ FIR Filter
.text
.global _start

    LDR r1, =0x40200000 ; 2.5 in IEEE754
    LDR r2, =0x41f40000 ; 30.5 in IEEE754

; r0 = r1 + r2
start:
    AND r4, r1, #0x7f800000     ; Use a bitmask to capture the first number's exponent
    AND r5, r2, #0x7f800000     ; Use a bitmask to capture the second number's exponent
    CMP r4, r5

    MOVCC r3, r1
    MOVCC r1, r2
    MOVCC r2, r3                ; Swap r1 with r2 if r2 has the higher exponent
    ANDCC r4, r1, #0x7f800000 
    ANDCC r5, r2, #0x7f800000   ; Update exponents if swapped

    SUB r3, r4, r5              ; Subtract exponents to get shift amount
    AND r5, r1, #0x007FFFFF     ; Grab first number's fractional part
    AND r6, r1, #0x007FFFFF     ; Grab second number's fractional part
    ORR r5, r5, #0x00800000     ; Add implied 1 to first fractional part
    ORR r6, r6, #0x00800000     ; Add implied 1 to second fractional part
    MOV r6, r6, LSR r3          ; Shift r6 to the right by the difference in exponents