# IEEE 754 ARMSim Conversion, Addition, Subtraction, Multiplication

By: Nisarga Patel, Evan Rittenhouse, Nicholas Harman, Jacob Lutz

The main code is in `float-merged-code.s`

## Introduction

The goal of this project was to implement IEEE 754 floating point math using ARM assembly without the use of floating point operations or floating point registers.  The code accepts input in the form of two 32-bit numbers representing a combination of sign, integer, and fraction representations.  For example, given the number -32767.65535 as input,  the binary representation appears as 1 sign bit (since the number is negative, the first bit is 1), 15 bits to hold the integer (111111111111111 represents 32767), and 16 bits to hold the decimal (1111111111111111 represents 0.65535).
Given the two operands, our goal was to then convert the operands to the IEEE 754 format and perform addition, subtraction and multiplication on the two values.

## Related Work

The IEEE 754 floating-point format is an industry standard for representation of binary numbers with fractions, and as such, numerous sources have published tutorials on the concept of IEEE 754 conversion and arithmetic.  We referenced the floating point tutorial by RF Wireless World mainly for information on IEEE 754 arithmetic.  We particularly needed this tutorial for implementing multiplication, as it described a pattern in results that fixed a major bug in our code.
