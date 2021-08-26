; exported symbols
global sum_int64
global sum_float64
global pow_int64
global sum_int32
global sum_float32
global pow_int32
global unsigned_int64_to_string
global signed_int64_to_string
global unsigned_int32_to_string
global signed_int32_to_string
global float64_to_string
global print_to_stdout
global get_char


; these buffers are shared between all int->string variants
section .data
	int_to_string_ret:	dq 0		; points to start of string in storage
	int_to_string_storage:	times 21 db 0	; storage for string representation

	
section .text

; sum a set of 64-bit int values
;
; IN:  rcx = addr of first int
;      rdx = # of ints to sum
; OUT: rax = sum of ints
;
; TODO extend to learn about and use vector operations (SIMD)
sum_int64:
	push	rcx		; preserve registers
	push	rdx
	mov	rax, 0		; initialise sum

.loop:
	cmp	rdx, 0		; rdx stores # of ints still to add
	je	.done		; when it hits 0, we've added them all
	add	rax, [rcx]	
	add	rcx, 8		; point to next int in list
	dec	rdx		; decrement # of ints still to add
	jmp	.loop

.done:
	pop rdx			; restore registers
	pop rcx
	ret


section .text

; sum a set of 64-bit float values
;
; IN:  rcx = addr of first float
;      rdx = # of values to sum
; OUT: xmm0 = sum of floats
sum_float64:
	push	rcx		; preserve registers
	push	rdx
	vxorpd	xmm0, xmm0	; init sum to 0

.loop:
	cmp	rdx, 0
	je	.done
	addsd	xmm0, [rcx]
	add	rcx, 8
	dec	rdx
	jmp	.loop

.done:
	pop	rdx
	pop	rcx
	ret


section .text

; sum a set of 32-bit float values
;
; IN:  rcx = addr of first float
;      rdx = # of values to sum
; OUT: xmm0 = sum of floats
;
; TODO extend to learn about and use vector operations (SIMD)
sum_float32:
	push	rcx		; preserve registers
	push	rdx
	fldz

.loop:
	cmp	rdx, 0
	je	.done
	addss	xmm0, [rcx]
	add	rcx, 4
	dec	rdx
	jmp	.loop

.done:
	pop	rdx
	pop	rcx
	ret


section .text

; sum a set of 32-bit int values
;
; IN:  ecx = addr of first int
;      edx = # of ints to sum
; OUT: eax = sum of ints
sum_int32:
	push	rcx		; preserve registers
	push	rdx
	mov	eax, 0		; initialise sum

.loop:
	cmp	edx, 0		; edx stores # of ints still to add
	je	.done		; when it hits 0, we've added them all
	add	eax, [ecx]	
	add	ecx, 4		; point to next int in list
	dec	edx		; decrement # of ints still to add
	jmp	.loop		; re-start loop

.done:
	pop rdx			; restore registers
	pop rcx
	ret


section .text

; raise a 64-bit int to a given (64-bit int) power
;
; IN:  rax contains int to raise
;      rbx sontains power to raise it to
; OUT: rax contains result
pow_int64:
	push	rbx		; push regs we're going to use
	push	rcx
	push	rdx
	mov	rcx, rax	; stash original value for multiplication

.loop:
	sub	rbx, 1		; if power has reduced to 1, we have our result
	je	.done
	mul	rcx		; multiply accumulated result by original value
	jmp	.loop

.done:
	pop	rdx		; restore regs to call-time state
	pop	rcx
	pop	rbx
	ret


section .text

; raise a 32-bit int to a given (32-bit int) power
;
; IN:  rax contains int to raise
;      rbx sontains power to raise it to
; OUT: rax contains result
pow_int32:
	push	rbx		; push regs we're going to use
	push	rdx
	push	rdx
	mov	ecx, eax	; stash original value for multiplication

.loop:
	dec	ebx		; if power has reduced to 1, we have our result
	cmp	ebx, 0
	je	.done
	mul	ecx		; multiply accumulated result by original value
	jmp	.loop

.done:
	pop	rdx		; restore regs to call-time state
	pop	rcx
	pop	rbx
	ret


section .text

; read a byte from a file descriptor
;
; IN:  rdi the FD to read
; OUT: ai the byte read
get_char:
	push	rsi
	push	rdx
	push	rax
	sub	rsp, 1	; allocate byte on stack to receive char
	
	; call sys_read()
	xor	rax, rax
	mov	rsi, rsp
	mov	rdx, 1
	syscall

	mov	al, [rsp]
	add	rsp, 1
	pop	rax
	pop	rdx
	pop	rsi
	ret


section .text

; print a null-terminated string to stdout
;
; IN:  rcx ptr to null-terminated string
; OUT: nothing
print_to_stdout:
	push	rdx
	push	rbx
	push	rax
	mov	rdx, 0		; string length
	mov	rbx, rcx	; copy string address to work with

.count_loop:
	cmp	byte [rbx], 0	; if it's a null char, end of string so
	je	.write		; exit loop
	inc	rdx		; otherwise increment the char count
	inc	rbx		; and addr of char to test
	jmp	.count_loop	; and continue counting

.write:
	mov	rax, 4		; sys_write(): output fd in ebx, string data in ecx, char count in edx
	mov	rbx, 1		; fd for stdout (ecx and edx already set correctly)
	int	0x80		; execute syscall
	pop	rax
	pop	rbx
	pop	rdx
	ret


section .text

; obtain a decimal string representation of an unsigned 64-bit integer
;
; IN:  rax = int to convert
; OUT: rcx = ptr to null-terminated string
unsigned_int64_to_string:
	push	rsi
	push	rbx
	push	rdx
	push	rax
	mov	rsi, int_to_string_storage
	add	rsi, 20				; rsi contains addr of next char to write
	mov	byte [rsi], 0			; null terminate the return string
	dec	rsi
	mov	rbx, 10				; div instructions only divide rax by content of reg,
						; so store 10 in reg
.process_digit:
	mov	rdx, 0				; reset remainder to 0
	div	rbx				; stores remainder in rdx; rdx is therefore the next digit
	add	dl, '0'				; ASCII code for digit
	dec	rsi
	mov	[rsi], dl			; prepend ASCII char to returned string
	cmp	rax, 0				; if rax is 0, it has been fully converted
	jnz	.process_digit

	mov	[int_to_string_ret], rsi	; rsi points to start of string, so store it,
	pop	rax				; restore registers
	pop	rdx
	pop	rbx
	pop	rsi
	mov	rcx, [int_to_string_ret]	; then move return ptr into rcx
	ret


section .text

; obtain a string representation of a signed decimal integer
;
; IN:  rax = int to convert
; OUT: rcx = ptr to null-terminated string
signed_int64_to_string:
	bt	rax, 63				; test the sign bit
	pushf					; store flags: we use CF again to check whether we need a '-' char
	jae	.call_unsigned			; jump if CF not set (= unsigned value)
	neg	rax				; otherwise, turn rax into unsigned value of equal magnitude

.call_unsigned:
	call	unsigned_int64_to_string	; call unsigned version to create string
	popf					; we need to test CF flag again
	jae	.done				; skip the '-' char if not needed

	dec	rcx
	mov	byte [rcx], '-'
	neg	rax				; rax will have been negated, so restore it

.done:
	ret


section .text

; obtain a decimal string representation of a signed 32-bit integer
;
; IN:  eax = int to convert
; OUT: rcx = ptr to null-terminated string
signed_int32_to_string:
	push	rax
	cdqe
	call	unsigned_int64_to_string
	pop	rax
	ret


section .text

; obtain a decimal string representation of an unsigned 32-bit integer
;
; IN:  eax = int to convert
; OUT: rcx = ptr to null-terminated string
unsigned_int32_to_string:
	push	rax
	and	rax, 0x0000ffff
	call	signed_int64_to_string
	pop	rax
	ret


section .text

; obtain a string representation of a 64-bit floating point value
;
; this routine has yet to be implemented properly. for the time being, its 
; implementation converts the FP to an int and calls signed_int64_to_string
;
; IN:  xmm0 = value to convert
; OUT: rcx = ptr to null-terminated string
float64_to_string:
	push	rax				; preserve registers
	cvttsd2si	rax, xmm0
	call	signed_int64_to_string		; create the string
	pop	rax				; restore rax
	ret


section .text

; obtain a string representation of a 32-bit floating point value
;
; this routine has yet to be implemented properly. for the time being, its 
; implementation converts the FP to an int and calls signed_int64_to_string
;
; IN:  xmm0 = value to convert
; OUT: rcx = ptr to null-terminated string
float32_to_string:
	push	rax				; preserve registers
	cvttss2si	eax, xmm0
	call	signed_int32_to_string		; create the string
	pop	rax				; restore rax
	ret
