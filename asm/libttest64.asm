; exported symbols
global libttest_sum_sq_diffs
global libttest_sum_diffs
global libttest_sum_diffs_sq
global libttest_paired_t

%use fp

section .text

; libttest_sum_sq_diffs(double[], double[], int)
;
; sum the squares of the differences between two arrays of 64-bit floats
;
; IN:  rdi = addr of first value in first array
;      rsi = addr of first value in second array
;      rdx = # of values to compute with
; OUT: xmm0 = sum of squared diffs
;
; CLOBBERED: xmm1, rax, CFLAGS
;
; CF set on error, clear on success
libttest_sum_sq_diffs:
	; must sum at least 1 value
	cmp	rdx, 1
	jl	.invalid_count

	mov	rax, rdx
	xorpd	xmm0, xmm0	; init sum to 0

.sum_next:
	cmp	rax, 0
	je	.done
	movsd	xmm1, [rdi]	; load the first of the next pair of values
	subsd	xmm1, [rsi]	; calculate diff -> xmm1
	mulsd	xmm1, xmm1	; sqaure the diff
	addsd	xmm0, xmm1	; add it to the sum

	add	rdi, 8
	add	rsi, 8
	dec	rax
	jmp	.sum_next

.done:
	; no cleanup - following sysV ABI, have only clobbered xmm1, rax
	clc
	ret

.invalid_count:
	stc
	ret


; libttest_sum_diffs(double[], double[], int)
;
; sum the the differences between two arrays of 64-bit floats
;
; IN:  rdi = addr of first value in first array
;      rsi = addr of first value in second array
;      rdx = # of values to compute with
; OUT: xmm0 = sum of diffs
;
; CLOBBERED: xmm1, rax, CFLAGS
;
; CF set on error, clear on success
libttest_sum_diffs:
	; must sum at least 1 value
	cmp	rdx, 1
	jl	.invalid_count

	mov	rax, rdx
	xorpd	xmm0, xmm0	; init sum to 0

.sum_next:
	cmp	rax, 0
	je	.done
	movsd	xmm1, [rdi]	; load the first of the next pair of values
	subsd	xmm1, [rsi]	; calculate diff -> xmm1
	addsd	xmm0, xmm1	; add it to the sum

	add	rdi, 8
	add	rsi, 8
	dec	rax
	jmp	.sum_next

.done:
	; no cleanup - following sysV ABI & have only clobbered xmm1, rax
	clc
	ret

.invalid_count:
	stc
	ret


; libttest_sum_diffs(double[], double[], int)
;
; sum the the differences between two arrays of 64-bit floats and square it
;
; IN:  rdi = addr of first value in first array
;      rsi = addr of first value in second array
;      rdx = # of values to compute with
; OUT: xmm0 = squared sum of diffs
;
; CLOBBERED: xmm1, rax, CFLAGS
;
; CF set on error, clear on success
libttest_sum_diffs_sq:
	call	libttest_sum_diffs
	jc	.on_error
	mulsd	xmm0, xmm0
	clc
	ret

.on_error:
	stc
	ret


; libttest_sum_diffs(double[], double[], int)
;
; sum the the differences between two arrays of 64-bit floats and square it
;
; IN:  rdi = addr of first value in first array
;      rsi = addr of first value in second array
;      rdx = # of values to compute with
; OUT: xmm0 = squared sum of diffs
;
; CLOBBERED: xmm1, xmm5, xmm6, xmm7, rax, CFLAGS
;
; TODO consider portability of switching to use AVX versions of subsd, mulsd etc.
; (AVX first available in Sandy Bridge CPUs)
; TODO review now that calculation is verified as correct
;
; CF set on error, clear on success
libttest_paired_t:
	; t is undefined for N < 2
	cmp	rdx, 2
	jl	.undefined_t

	push	rdi
	push	rsi
%define ARRAY_1 [rsp + 8]
%define ARRAY_2 [rsp]

	; xmm1 is used as scratch space

	; N in xmm6
	xorpd		xmm6, xmm6	; ensure reg is empty because
	cvtsi2sd	xmm6, rdx	; this only alters lower 64-bits

	; df in xmm5
	; df = N - 1
	mov	rax, __float64__(1.0)
	movq	xmm1, rax
	movsd	xmm5, xmm6
	subsd	xmm5, xmm1

	; t in xmm7
	; t = E(d2) * N
	call	libttest_sum_sq_diffs
	mulsd	xmm0, xmm6
	movsd	xmm7, xmm0

	; t = t - (Ed)2
	mov	rdi, ARRAY_1
	mov	rsi, ARRAY_2
	call	libttest_sum_diffs_sq
	subsd	xmm7, xmm0

	; t = t / df
	divsd	xmm7, xmm5
	; don't need to check for inf: we know df >= 1 because
	; we ensure N >= 2 on entry

	; t = sqrt(t)
	sqrtsd	xmm7, xmm7

	; if t is 0, return t = infinity
	mov	rax, __float64__(0.0)
	movq	xmm1, rax
	comisd	xmm0, xmm1
	je	.infinite_t

	; t = Ed / t
	; NOTE t is now in xmm0
	mov	rdi, ARRAY_1
	mov	rsi, ARRAY_2
	call libttest_sum_diffs
	divsd	xmm0, xmm7

	; t = |t|
	mov	rax, __float64__(0.0)
	movq	xmm1, rax
	comisd	xmm0, xmm1
	jl	.done
	mov	rax, __float64__(-1.0)
	movq	xmm1, rax
	mulsd	xmm0, xmm1

.done:
	add 	rsp, 16		; remove two array ptrs off stack
	clc
	ret

.infinite_t:
	mov	rax, __float64__(__Infinity__)
	movq	xmm0, rax
	add 	rsp, 16		; remove two array ptrs off stack
	clc
	ret

.undefined_t:
	add 	rsp, 16		; remove two array ptrs off stack
	stc
	ret
