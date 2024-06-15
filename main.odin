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
	
Program :: struct {
	ip: u64,
	dp: u64,
	data: [128]int,
}
	
read_file :: proc(file: string) -> string {
	data, ok := os.read_entire_file(file, context.allocator)
	if !ok {
		fmt.eprintln("Could not read from file: ", file)
	}
	return cast(string)data
}

parse_program :: proc(program: string) -> ([dynamic]INSTS, u64) {
	instructions: [dynamic]INSTS
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
	return instructions, cast(u64)len(instructions)
}
	
interpret_program :: proc(instructions: []INSTS, size: u64) {
	program: Program
	f_stack: [dynamic]u64
	b_stack: [dynamic]u64
	
	for ; program.ip < size; program.ip += 1 {
		switch instructions[program.ip] {
			case INSTS.INC_DP:
				program.dp += 1
			case INSTS.DEC_DP:
				program.dp -= 1
			case INSTS.INC_DATA:
				program.data[program.dp] += 1
			case INSTS.DEC_DATA:
				program.data[program.dp] -= 1			
			case INSTS.OUT_DATA:
				fmt.printf("%c", program.data[program.dp])
			case INSTS.INPUT_DATA:
				buf: [1]byte
				n, err := os.read(os.stdin, buf[:])
				if err < 0 {
					os.exit(1)
				}
				program.data[program.dp] = cast(int)buf[0]
			case INSTS.JMP_F:
				append(&f_stack, program.ip)
				if program.data[program.dp] == 0 {
					if len(b_stack) == 0 {
						fmt.eprintln("Unmatched f brackets")
						os.exit(1)
					}
					program.ip = b_stack[len(b_stack)-1]				
				} else {
					if len(b_stack) != 0 {
						pop(&b_stack)				
					}
				}
			case INSTS.JMP_B:
				append(&b_stack, program.ip)			
				if program.data[program.dp] != 0 {
					if len(f_stack) == 0 {
						fmt.eprintln("Unmatched b brackets")
						os.exit(1)
					}
					program.ip = f_stack[len(f_stack)-1]
				} else {
					if len(f_stack) != 0 {
						pop(&f_stack)				
					}
				}
		}
	}
}

main :: proc() {
	if len(os.args) < 2 {
		fmt.eprintf("Usage: %s <filename.bf>\n", os.args[0])
		os.exit(1)
	}
	program := read_file(os.args[1])
	instructions, size := parse_program(program)
	interpret_program(instructions[:], size)
}
