@ FIR Filter
.text
.global _start
	
	LDR R1, =0x4000000
	LDR R2, =0x64
	
	MOV R0, #0
	MOV R3, #1
start:
	CMP R2, R1
	MOVLS R2, R2, LSL#1
	MOVLS R3, R3, LSL#1
	BLS start
next:
	CMP R1, R2
	SUBCS R1, R1, R2
	ADDCS R0, R0, R3
	MOVS R3, R3, LSR#1
	MOVCC R2, R2, LSR#1
	BCC next
	SWI 0x11
