@ fir filter
.text
.global _start

    ldr r1, =0x40200000 ; 2.5 in ieee754
    ldr r2, =0x41f40000 ; 30.5 in ieee754

; r0 = r1 - r2
subfloat:
    ldr r10, =0x80000000
    eor r2, r2, r10             ; Exclusive or r2 with 0x80000000 to toggle the sign bit
    bl addfloat
    swi 0x11

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
    mOV pc, lr                  ; Return to caller
