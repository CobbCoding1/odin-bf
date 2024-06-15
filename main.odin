package main

import "core:fmt"
import "core:os"

INSTS :: enum {
	INC_DP,
	DEC_DP,
	INC_DATA,
	DEC_DATA,
	OUT_DATA,
	INPUT_DATA,
	JMP_F,
	JMP_B,
}

ip: u64 = 0
instructions: [dynamic]INSTS
dp: u64 = 0
data: [128]int
f_stack: [dynamic]u64
b_stack: [dynamic]u64

main :: proc() {
	program := "++>+++++[<+>-]++++++++[<++++++>-]<."
	//program =  "+[-]."
    program = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
	for c in program {
		switch c {
			case '>':
				append(&instructions, INSTS.INC_DP)
			case '<':
				append(&instructions, INSTS.DEC_DP)			
			case '+':
				append(&instructions, INSTS.INC_DATA)						
			case '-':
				append(&instructions, INSTS.DEC_DATA)						
			case '.':
				append(&instructions, INSTS.OUT_DATA)									
			case ',':
				append(&instructions, INSTS.INPUT_DATA)												
			case '[':
				append(&instructions, INSTS.JMP_F)
			case ']':
				append(&instructions, INSTS.JMP_B)			
		}
	}
	size := cast(u64)len(instructions)
	for ; ip < size; ip += 1 {
		switch instructions[ip] {
			case INSTS.INC_DP:
				dp += 1
			case INSTS.DEC_DP:
				dp -= 1
			case INSTS.INC_DATA:
				data[dp] += 1
			case INSTS.DEC_DATA:
				data[dp] -= 1			
			case INSTS.OUT_DATA:
				fmt.printf("%c", data[dp])
			case INSTS.INPUT_DATA:
				buf: [1]byte
				n, err := os.read(os.stdin, buf[:])
				if err < 0 {
					os.exit(1)
				}
				data[dp] = cast(int)buf[0]
			case INSTS.JMP_F:
				append(&f_stack, ip)
				if data[dp] == 0 {
					if len(b_stack) == 0 {
						fmt.eprintln("Unmatched f brackets")
						os.exit(1)
					}
					ip = b_stack[len(b_stack)-1]				
				} else {
					if len(b_stack) != 0 {
						pop(&b_stack)				
					}
				}
			case INSTS.JMP_B:
				append(&b_stack, ip)			
				if data[dp] != 0 {
					if len(f_stack) == 0 {
						fmt.eprintln("Unmatched b brackets")
						os.exit(1)
					}
					ip = f_stack[len(f_stack)-1]
				} else {
					if len(f_stack) != 0 {
						pop(&f_stack)				
					}
				}
		}
	}
}
