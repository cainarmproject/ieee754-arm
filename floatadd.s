@ FIR Filter
.text
.global _start

    LDR r1, =0x40200000 //2.5 in IEEE754
    LDR r2, =0x41f40000 //30.5 in IEEE754

//r0 = r1 + r2
addfloat:
    LDR r10, =0x7f800000
    AND r4, r1, r10             //Use a bitmask to capture the first number's exponent
    AND r5, r2, r10             //Use a bitmask to capture the second number's exponent
    CMP r4, r5

    MOVCC r3, r1
    MOVCC r1, r2
    MOVCC r2, r3                //Swap r1 with r2 if r2 has the higher exponent
    ANDCC r4, r1, r10 
    ANDCC r5, r2, r10           //Update exponents if swapped

    MOV r4, r4, LSR #23
    MOV r5, r5, LSR #23         //Move exponents to least significant position

    SUB r3, r4, r5              //Subtract exponents to get shift amount
    LDR r10, =0x007FFFFF     
    AND r5, r1, r10             //Grab first number's fractional part
    AND r6, r2, r10             //Grab second number's fractional part
    LDR r10, =0x00800000
    ORR r5, r5, r10             //Add implied 1 to first fractional part
    ORR r6, r6, r10             //Add implied 1 to second fractional part
    MOV r6, r6, LSR r3          //Shift r6 to the right by the difference in exponents

    LDR r10, =0x80000000
    ANDS r0, r1, r10            //Check MSB for negative bit
    MOVNE r0, r5                //This "not equal" works because the "ANDS" will set the zero flag if the result is zero
    BLNE twos_complement        //Two's complement fractional first number if it's supposed to be negative
    MOVNE r5, r0

    ANDS r0, r2, r10             //Check MSB for negative bit
    MOVNE r0, r6
    BLNE twos_complement        //Two's complement fractional second number if it's supposed to be negative
    MOVNE r6, r0

    ADD r5, r5, r6              //Add the fractional portions. r5 contains the result.

    ANDS r0, r5, r10             //Check MSB to see if the result is negative
    MOVNE r0, r5
    BLNE twos_complement        //Two's complement result if negative
    MOVNE r5, r0
    LDRNE r0, =0x80000000       //Put a 1 as result's MSB if the result was negative
    MOVEQ r0, #0                //Put a 0 as result's MSB if the result was positive

    MOV r3, #0
    LDR r10, =0x80000000

count_sigbit_loop:
    CMP r10, r5
    ADDHI r3, r3, #1
    MOVHI r10, r10, LSR #1
    BHI count_sigbit_loop       //Count how many times you have to shift before hitting a 1 in the result

    CMP r3, #8                  //If it's shifted 8 times it's already in the right place
    SUBHI r3, r3, #8            //If it needs shifting left, determine how many times
    MOVHI r5, r5, LSL r3        //Shift as needed
    SUBHI r4, r4, r3            //Subtract shift amount from exponent to reflect shift
    MOVCC r10, #8
    SUBCC r3, r10, r3           //If it needs shifting right, determine how many times
    MOVCC r5, r5, LSR r3        //Shift as needed
    ADDCC r4, r4, r3            //Add shift amount to exponent to relfect shift

    MOV r4, r4, LSL #23         //Shift exponent into place
    ORR r0, r0, r4              //OR exponent into number
    LDR r10, =0x007FFFFF
    AND r5, r5, r10             //Get rid of implied 1 in fraction
    ORR r0, r0, r5              //Attach fractional part

    SWI 0x11

//r0 = -r0
twos_complement:
    MVN r0, r0                  //Negate r0
    ADD r0, r0, #1              //Add 1
    MOV pc, lr                  //Return to caller
