; write ints and their sum

section .text

global _start


_start:
	mov	ebx, [int_array_size]
	mov	edx, int_array
.print_values_loop:
	cmp	ebx, 0		; check if we've any ints left to print
	je	.print_sum	; if not, print the sum
	mov	eax, [edx]	; int_to_string wants int in eax
	call	int_to_string
	call	print_to_stdout
	mov	ecx, ttest_newline
	call	print_to_stdout
	dec	ebx		; one less int still to print
	add	edx, 4		; point to next 32-bit int in array
	jmp	.print_values_loop
.print_sum:
	mov	ecx, ttest_print_sum_prefix
	call	print_to_stdout
	; sum_signed_ints expects ptr to first int in ecx, # of ints in edx
	mov	ecx, int_array
	mov	edx, [int_array_size]
	call	sum_int32
	call	int_to_string
	call	print_to_stdout
	mov	ecx, ttest_newline
	call	print_to_stdout

	mov	eax, 1		; sys_exit(): ebx = exit code
	mov	ebx, 0
	int	0x80

section .data
	ttest_newline		db 10, 0
	ttest_print_sum_prefix	db "Sum: ", 0
	int_array		dd 12, 10, 11, 12, 10, 10, 13, 11, 8, 10, 9, 12
	int_array_size		dd 12


%include "lib32.asm"
