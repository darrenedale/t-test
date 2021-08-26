section .text

; sum a set of (unsigned) 32-bit int values
;
; IN:  ecx = addr of first int
;      edx = # of ints to sum
; OUT: eax = sum of ints
;
; TODO extend to learn about and use vector operations (SIMD)
sum_int32:
	push	ecx
	push	edx
	mov	eax, 0
.loop:
	cmp	edx, 0		; edx stores # of ints still to add
	je	.done		; when it hits 0, we've added them all
	add	eax, [ecx]	
	add	ecx, 4		; point to next int in list
	dec	edx		; decrement # of ints still to add
	jmp	.loop		; re-start loop
.done:
	pop edx			; restore all used registers except
	pop ecx			; eax, which contains the retval
	ret


section .text

; print a null-terminated string to stdout
;
; IN:  ecx ptr to null-terminated string
; OUT: nothing
print_to_stdout:
	pusha
	mov	edx, 0		; string length
	mov	ebx, ecx	; copy string address to work with
.count_loop:
	cmp	byte [ebx], 0	; if it's a null char, end of string so
	je	.write		; exit loop
	inc	edx		; otherwise increment the char count
	inc	ebx		; and addr of char to test
	jmp	.count_loop	; and continue counting
.write:
	mov	eax, 4		; sys_write(): output fd in ebx, string data in ecx, char count in edx
	mov	ebx, 1		; fd for stdout (ecx and edx already set correctly)
	int	0x80		; int 0x80
	popa
	ret


section .text

; obtain a string representation of a decimal integer
;
; IN:  eax = int to convert
; OUT: ecx = ptr to null-terminated string
int_to_string:
	pusha
	mov	esi, int_to_string_storage
	add	esi, 9				; esi contains addr of next char to write
	mov	byte [esi], 0			; null terminate the return string
	dec	esi
	mov	ebx, 10				; div instructions only divide eax by content of reg,
						; so store 10 in reg
.process_digit:
	mov	edx, 0				; reset remainder to 0
	div	ebx				; stores remainder in edx; edx is therefore the next digit
	add	dl, '0'				; ASCII code for digit
	dec	esi
	mov	[esi], dl			; prepend ASCII char to returned string
	cmp	eax, 0				; if eax is 0, it has been fully converted
	jnz	.process_digit

	mov	[int_to_string_ret], esi	; esi points to start of string, so store it,
	popa					; restore registers,
	mov	ecx, [int_to_string_ret]	; then move return ptr into ecx
	ret


section .data
	int_to_string_ret dd 0			; points to start of string in storage
	int_to_string_storage times 10 db 0	; storage for string representation
