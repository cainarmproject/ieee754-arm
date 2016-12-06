// floatmul.s
// authors: evan rittenhouse, jacob lutz, nicholas harman, nisarga patel

@ fir filter
.text
.global _start

    // ldr r1, =0x40900000     // 4.5 in ieee754
    // ldr r2, =0x41f40000     // 30.5 in ieee754

    
    // ldr r1, =0x40200000     // 2.5 in ieee754
    // ldr r2, =0x40900000     // 4.5

    ldr r1, =0xc2fa4000      // -125.125
    ldr r2, =0x42484000      // 50.0625

ieee754multiply:
    and r3, r1, #0x80000000         // extract sign of operand1
    and r4, r2, #0x80000000         // extract sign of operand2

    eor r0, r3, r4                  // get the new sign bit

    ldr r9, =0x7f800000
    and r3, r1, r9                  // extract exponents
    and r4, r2, r9                  // extract exponents

    mov r3, r3, lsr #23
    mov r4, r4, lsr #23
    sub r3, r3, #127        // remove exponent bias
    sub r4, r4, #127

    add r5, r3, r4          // add exponents, r5 now holds the new exponent

    ldr r9, =0x007fffff
    and r3, r1, r9                  // extract fractions from operand1
    and r4, r2, r9                  // extract fractions from operand2
    orr r3, r3, #0x00800000         // add implied 1 to front of fraction one
    orr r4, r4, #0x00800000         // add implied 1 to front of fraction one

mul:
    umull r7, r6, r3, r4          // multiply the fractions           

// if bit 48 from the multiplication is 1 then we need to shift right one and add one to the exponent 
creatfraction:
    ands r8, r6, #0x00008000         // check to see if bit 16 of the hi bits 
    
    // bit 48 of multiplication was a one so add one to the exponent and create fraction
    addne r5, r5, #1         // if ne is true that means the ands above resulted in a non-zero value indicating the 16th bit was a 1
    movne r6, r6, lsl #16    // make room to pull in low bits from multiply, if bit 16 was 1 shift 16
    movne r7, r7, lsr #16     // move the low bits right so they can be merged with the high bits
    
    // no normalization necessary just combine the first 23 bits from high and low
    moveq r6, r6, lsl #17    // make room to pull in low bits from multiply, if bit 16 was not 1 shift 17  
    moveq r7, r7, lsr #15     // move the low bits right so they can be merged with the high bits
    
    // or the fraction parts together
    orr r6, r6, r7           // put the fraction halves together
    mov r6, r6, lsr #8       // make the fraction only use 24 bits
    bic r6, r6, #0x00800000         // clear the implied 1 from the fraction

done:
    add r5, r5, #127        // re-add bias to the exponent
    mov r5, r5, lsl #23     // shift exponent into its ieee754 position
    orr r0, r0, r5          // merge exponent into the result register r0
    orr r0, r0, r6          // merge fraction into the result register r0

finish:
    swi 0x11