@ FIR Filter
.text
.global _start

    LDR r1, =0x40200000 //2.5 in IEEE754
    LDR r2, =0x40900000 //4.5 in IEEE754

    LDR r10, =0x00800000
    LDR r11, =0x80000000
    LDR r12, =0x007fffff
    LDR r13, =0x7f800000

ieee754multiply:    
    AND r3, r1, r13
    AND r4, r2, r13

    LSR r3, #23
    LSR r4, #23
    SUB r3, r3, #127
    SUB r4, r4, #127

    ADD r5, r3, r4

    AND r3, r1, r12
    AND r4, r2, r12
    ORR r3, r3, r10
    ORR r4, r4, r10

    


//mul_loop:
  //  ADD r6, r6, r3
    //SUB r4, r4, #1
   // CMP r4, #0
    //BNE mul_loop

    AND r3, r1, r11
    AND r4, r2, r11
    ADD r7, r3, r4

    ADD r5, r5, #127
    LSL r5, #23
    ORR r0, r5, r6
    ORR r0, r0, r4