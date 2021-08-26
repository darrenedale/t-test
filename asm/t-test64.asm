; TODO load data from file

; libc
extern strtod
extern printf
extern puts
extern exit

; (internal) lib
extern sum_int64
extern sum_float64
extern pow_int64
extern signed_int64_to_string
extern float64_to_string
extern print_to_stdout

; (internal) libttest
extern libttest_sum_sq_diffs
extern libttest_sum_diffs
extern libttest_sum_diffs_sq
extern libttest_paired_t


; UTF8 sequences
%define CHAR_EXP_2 0xc2, 0xb2
%define CHAR_UPPER_SIGMA 0xce, 0xa3

%define DATA_ARRAY_CAPACITY 50

; sys_open flags
%define O_RDONLY 0x0000


section .data
	; all string data UTF8
	ttest_newline:		db 10, 0
	ttest_sp:		db 32, 0
	ttest_sum_prefix:	db CHAR_UPPER_SIGMA, ": ", 0
	ttest_sumdiff_prefix:	db CHAR_UPPER_SIGMA, "d    = ", 0
	ttest_sumsqdiff_prefix:	db CHAR_UPPER_SIGMA, "(d", CHAR_EXP_2, ") = ", 0
	ttest_sumdiffsq_prefix:	db "(", CHAR_UPPER_SIGMA, "d)", CHAR_EXP_2, " = ", 0
	ttest_t_prefix:		db "t    = ", 0
 	data_size:		dq 0
 	data_max:		dq DATA_ARRAY_CAPACITY
 	int_format:		db "%d", 10, 0
 	float_format:		db "%0.3lf", 10,  0
 	float_pair_format:	db "%0.3lf %0.3lf", 10,  0
 	usage_msg:		db "ttest: perform a paired t-test", 10, "Usage: %s <datafile>", 10, 0
 	err_missing_arg:	db "Data filename must be given", 0
 	err_read_failed:	db "Failed to open file", 0
 	err_t_failed:		db "Failed to calculate t", 0
 	no_data_msg:		db "No data to calcualte with", 0


section .bss
 	data1:			resq DATA_ARRAY_CAPACITY
 	data2:			resq DATA_ARRAY_CAPACITY


section .text

global main
; global _start


main:
; _start:
	; rdi is argc, rsi is argv
 	sub	rsp, 8			; align top of stack for c abi
; 	push	rbp
; 	mov	rbp, rsp
	
	cmp	rdi, 2
	jl	.missing_arg

	; TODO load data from file
	lea	rdi, [rsi]
	call	readfile
	cmp	rax, 0
	jne	.read_fail

	call	paired_t
	jc	.t_fail

.done:
; 	mov	rsp, rbp
; 	pop	rbp
	add	rsp, 8

	; return 0
	xor	rax, rax
	ret

.missing_arg:
	lea	rdi, [err_missing_arg]
	jmp	.print_err

.read_fail:
	lea	rdi, [err_read_failed]
	jmp	.print_err

.t_fail:
	lea	rdi, [err_t_failed]
	jmp	.print_err

.print_err:
	push	rsi
	call	puts
	pop	rsi
	jmp	usage 


; IN : rdi contains FD
; OUT: xmm0 contains value
;
; CF set on error, clear on success
%define ENDPTR	[rsp]
readvalue:
	sub	rsp, 56		; allocate stack:
				; 40 bytes for value string
				; 8 bytes for ENDPTR to use in strtod() call
				; (8 bytes to align for c abi)
	lea	rsi, rsp + 8	; rsi tracks where in str read char belongs

.skip_hspace_1:
	call	get_char
	cmp	al, ' '
	je	.skip_hspace_1
	cmp	al, 9
	je	.skip_hspace_1

.next_char:
	; TODO only allow '-' at start
	mov	[rsi], al
	inc	rsi
	cmp	ai, '-'
	je	.next_char
	cmp	ai, '.'
	je	.next_char
	cmp	ai, '0'
	jl	.parse_value
	cmp	ai, '9'
	jg	.parse_value

	call	get_char
	jmp	.next_char

.skip_hspace_2:
	call	get_char
	cmp	al, ' '
	je	.skip_hspace_2
	cmp	al, 9
	je	.skip_hspace_2

.parse_value:
	mov	[rsi], 0	; null terminate string
	lea	rdi, [rsp + 8]
	mov	rsi, ENDPTR
	call	strtod

	cmp	rdi, ENDPTR
	je	.on_error

	; call lseek to "put back" delimiter char
	mov	rax, 8
	mov	rsi, -1
	mov	rdx, SEEK_CUR
	syscall

	cmp	rax, -1
	je	.on_error
	
	add	rsp, 48
	clc
	ret

.on_error:
	add	rsp, 48
	stc
	ret


; read the data in a file
;
; TODO rewrite to use readvalue()
;
; IN : rdi contains filename
; OUT: rax is 0 on success, non-0 on fail
%define	READ_BUFFER_SIZE 50
%define ERR_READFILE_OPEN_FAIL 1
%define ERR_READFILE_READ_FAIL 2
%define ERR_READFILE_INVALID_VALUE 3
%define ERR_READFILE_TOO_MUCH_DATA 4

section .data
	read_buffer:		times READ_BUFFER_SIZE db 0

section .text

readfile:
%define IN_FD	[rsp]
%define ENDPTR	[rsp + 8]
	; stack
	; TOP:
	sub	rsp, 24		; allocate 16 bytes and align stack for c abi
	mov	rax, 0x02	; sys_open
	mov	rbx, rdi	; filename
	mov	rcx, O_RDONLY	; flags
	xor	rdx, rdx	; mode is irrelevant for O_RDONLY
	syscall

	cmp	rax, -1
	je	.err_open

	; FD on stack
	; read buffer in r12
	; item count in r13
	; available buffer space in r14
	push	rax
	lea	r12, [read_buffer]
	xor	r13, r13
	mov	r14, READ_BUFFER_SIZE - 1

	; TODO read the content
	; rsi MUST point to the first empty char in the read buffer
.read_loop:
	; fill the read buffer
	xor	rax, rax	; 0 = sys_read
	mov	rdi, IN_FD
	mov	rsi, r14
	syscall

	; check for error
	cmp	rax, -1
	je	.err_read

	; check for eof
	cmp	rax, 0
	je	.done		; TODO need to do one last parse to empty the buffer

	; r15 <- pointer to first char past end of buffer content
	mov	r15, rsi
	add	r15, rax
	mov	[r15], 0	; null terminate buffer

.parse_loop:
	; is there space for more data?
	cmp	r13, DATA_ARRAY_CAPACITY
	jge	.err_too_much_data

	; parse item 1
	; call c lib strtod
	mov	rdi, r12
	lea	rsi, ENDPTR
	call	strtod

	; did we parse a valid float?
	cmp	rdi, ENDPTR
	je	.err_invalid_value

	mov	r12, ENDPTR

	; skip whitespace: space, tab are considered whitespace
	dec	r12

.skip_whitespace_1:
	inc	r12
	; TODO check buffer overflow
	cmp	[r12], byte ' '
	je	.skip_whitespace_1
	cmp	[r12], byte 9
	je	.skip_whitespace_1

	jmp	.err_invalid_value

.check_delimiter_1:
	; did we end item 1 with ','
	cmp	[r12], byte ','
	jne	.err_invalid_value

	; store parsed value in array
	movq	data1 + r13, xmm0

	; parse item 2
	inc	r12
	; TODO check buffer overflow
	; call c lib strtod
	mov	rdi, r12
	lea	rsi, ENDPTR
	call	strtod

	; did we parse a valid float?
	cmp	rdi, ENDPTR
	je	.err_invalid_value

	; skip whitespace: space, tab are considered whitespace
	dec	r12

.skip_whitespace_2:
	inc	r12
	; TODO check buffer overflow
	cmp	[r12], byte ' '
	je	.skip_whitespace_2
	cmp	[r12], byte 9
	je	.skip_whitespace_2

	jmp	.err_invalid_value

.check_delimiter_2:
	; did we end item 2 with LF
	cmp	[r12], byte 10
	jne	.err_invalid_value

	; store in second data array, increment data item count and
	; read the next
	movq	data2 + r13, xmm0
	inc	r13

	jmp	.parse_loop

.parse_done:
	; TODO move any un-parsed content to the start of the buffer
	; TODO set rsi to the first unused char in the buffer
	; TODO set r14 to the available buffer space
	jmp .read_loop

.done:
	; store the final item count
	mov	data_size, r13
	
	mov	rax, 0x03	; sys_close
	mov	rdi, r12	; fd
	syscall

	xor	rax, rax
	add	rsp, 24		; deallocate and remove stack padding
	ret

.err_open:
	mov	rax, ERR_READFILE_OPEN_FAIL
	add	rsp, 24		; deallocate and remove stack padding
	ret

.err_read:
	mov	rax, ERR_READFILE_READ_FAIL
	add	rsp, 24		; deallocate and remove stack padding
	ret

.err_invalid_value:
	mov	rax, ERR_READFILE_INVALID_VALUE
	add	rsp, 24		; deallocate and remove stack padding
	ret

.err_too_much_data:
	mov	rax, ERR_READFILE_TOO_MUCH_DATA
	add	rsp, 24		; deallocate and remove stack padding
	ret

%undef IN_FD
%undef ENDPTR


section .text

; usage calls exit and therefore never returns
usage:
	; argv must still be in rsi
	mov	rdi, usage_msg
	mov	rsi, [rsi]
	call	printf
	mov	rdi, 1
	call	exit


paired_t:
	sub	rsp, 8		; align stack for c ABI calls
	cmp	rbx, 0
	jg	.print_values

	; no data to work with
	lea	rdi, [no_data_msg]
	call	puts
	stc
	add	rsp, 8		; undo stack alignment pad
	ret

.print_values:
	mov	rbx, [data_size]
	lea	r12, [data1]
	lea	r13, [data2]

.print_values_loop:
	cmp	rbx, 0		; check if we've any ints left to print
	je	.print_stats	; if not, print the stats

	lea	rdi, [float_pair_format]
	movq	xmm0, [r12]
	movq	xmm1, [r13]
	mov	rax, 2		; for variadic, # of FP args is provided in rax
	call	printf

	add	r12, 8		; point to next 64-bit int in array
	add	r13, 8		; point to next 64-bit int in array
	dec	rbx		; one less float still to print
	jmp	.print_values_loop

.print_stats:
	; output sum
 	lea	rcx, [ttest_sum_prefix]
	call	print_to_stdout

	lea	rcx, [data2]
	mov	rdx, [data_size]
	call	sum_float64	; sum is returned in xmm0
	movsd	xmm1, xmm0
	lea	rcx, [data1]
	mov	rdx, [data_size]
	call	sum_float64	; sum is returned in xmm0

	; two sums are now in xmm0 and xmm1
	lea	rdi, [float_pair_format]
	mov	rax, 2		; for variadic, # of FP args is provided in rax
	call	printf

; 	; output sum diffs
 	lea	rcx, [ttest_sumdiff_prefix]
 	call	print_to_stdout
 	lea	rdi, [data1]
 	lea	rsi, [data2]
 	mov	rdx, [data_size]
 	call	libttest_sum_diffs

 	lea	rdi, [float_format]
 	mov	rax, 1		; for variadic, # of FP args is provided in rax
 	call	printf

; 	; output sum squared diffs
 	lea	rcx, [ttest_sumsqdiff_prefix]
 	call	print_to_stdout
 	lea	rdi, [data1]
 	lea	rsi, [data2]
 	mov	rdx, [data_size]
 	call	libttest_sum_sq_diffs

	lea	rdi, [float_format]
	mov	rax, 1		; for variadic, # of FP args is provided in rax
	call	printf

; 	; output sum diffs squared
 	lea	rcx, [ttest_sumdiffsq_prefix]
 	call	print_to_stdout
 	lea	rdi, [data1]
 	lea	rsi, [data2]
 	mov	rdx, [data_size]
 	call	libttest_sum_diffs_sq

	lea	rdi, [float_format]
	mov	rax, 1		; for variadic, # of FP args is provided in rax
	call	printf

; 	; output t
 	lea	rcx, [ttest_t_prefix]
 	call	print_to_stdout
 	lea	rdi, [data1]
 	lea	rsi, [data2]
 	mov	rdx, [data_size]
 	call	libttest_paired_t

	lea	rdi, [float_format]
	mov	rax, 1		; for variadic, # of FP args is provided in rax
	call	printf

	add	rsp, 8		; undo stack alignment pad

	ret
