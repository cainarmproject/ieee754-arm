// floatmul.s
// Authors: Evan Rittenhouse, Jacob Lutz, Nicholas Harman, Nisarga Patel

// currently set to multiply 2.5 and 30.5
// some bug in it, output is 38.0 when it should be 76.25
// works with smaller numbers though, like 2.5*4.5 = 11.25


@ FIR Filter
.text
.global _start

    LDR r1, =0x40200000     // 2.5 in IEEE754
    LDR r2, =0x41f40000     // 30.5 in IEEE754

    LDR r10, =0x00800000    // bitmask for adding/removing implied 1 to front of fraction 
    LDR r11, =0x80000000    // bitmask for extracting sign bit
    LDR r12, =0x007FFFFF    // bitmask for extracting fraction
    LDR r13, =0x7f800000    // bitmask for extracting exponent

ieee754multiply:    
    AND r3, r1, r13         // extract exponents

    LSR r3, #23             // clear trailing bits left over from fraction
    LSR r4, #23
    SUB r3, r3, #127        // remove exponent bias
    SUB r4, r4, #127

    ADD r5, r3, r4          // add exponents

    AND r3, r1, r12         // extract fractions
    AND r4, r2, r12
    ORR r3, r3, r10         // add implied 1 to front of fractions
    ORR r4, r4, r10

    AND r8, r3, #1          // check last bit of first fraction
    CMP r8, #0              // if not 0, jump to multiplication
    BNE mul
shiftloop1:                 // if equal to 0, shift right by 1 bit and check last bit again
    LSR r3, #1              
    AND r8, r3, #1          // if new last bit is equal to 0, shift again
    CMP r8, #0
    BEQ shiftloop1


    AND r8, r4, #1          // repeat the shifting process with the second fraction
    CMP r8, #0
    BNE mul
shiftloop2:
    LSR r4, #1
    AND r8, r4, #1
    CMP r8, #0
    BEQ shiftloop2

mul:
    UMULL r7, r6, r3, r4          // multiply the fractions
    LDR r9, =0              
    MOV r7, r6

get_shift:
    LSR r7, #1              // getting number of bits to shift left
    CMP r7, #0              // count the number of times we have to shfit right before we're left with 0
    BEQ done
    ADD r9, r9, #1
    B get_shift

done:
    mov r8, #23             // subtract the number of shifts from 23 (total bits in fraction)
    SUB r8, r8, r9
    LSL r6, r8              // shift left so that the fraction is left-justified
    BIC r6, r6, r10         // clear the implied 1 from the fraction

    AND r3, r1, r11         // extract the sign bits
    AND r4, r2, r11         
    EOR r7, r3, r4          // determine if signs cancel each other

    ADD r5, r5, #127        // re-add bias to the exponent
    LSL r5, #23             // shift exponent into its IEEE754 position
    ORR r0, r5, r6          // merge exponent with fraction
    ORR r0, r0, r7          // merge result with sign bit

finish:
    SWI 0x11
