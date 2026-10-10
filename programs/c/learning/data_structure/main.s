	.file	"main.c"
	.text
	.globl	main
	.type	main, @function
main:
.LFB0:
	.cfi_startproc
	pushq	%rbp
	.cfi_def_cfa_offset 16
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
	xorl	%eax, %eax
	movq	$0, -16(%rbp)
	leaq	-16(%rbp), %rax
	movl	$5, %esi
	movq	%rax, %rdi
	call	push_back@PLT
	leaq	-16(%rbp), %rax
	movl	$10, %esi
	movq	%rax, %rdi
	call	push_back@PLT
	leaq	-16(%rbp), %rax
	movl	$15, %esi
	movq	%rax, %rdi
	call	push_back@PLT
	leaq	-16(%rbp), %rax
	movl	$20, %esi
	movq	%rax, %rdi
	call	push_back@PLT
	leaq	-16(%rbp), %rax
	movl	$25, %esi
	movq	%rax, %rdi
	call	push_back@PLT
	leaq	-16(%rbp), %rax
	movl	$0, %esi
	movq	%rax, %rdi
	call	push_front@PLT
	leaq	-16(%rbp), %rax
	movl	$-5, %esi
	movq	%rax, %rdi
	call	push_front@PLT
	leaq	-16(%rbp), %rax
	movl	$-10, %esi
	movq	%rax, %rdi
	call	push_front@PLT
	movq	-16(%rbp), %rax
	movq	%rax, %rdi
	call	print_list@PLT
	movq	-16(%rbp), %rax
	movq	%rax, %rdi
	call	free_list@PLT
	movl	$0, %eax
	movq	-8(%rbp), %rdx
	subq	%fs:40, %rdx
	je	.L3
	call	__stack_chk_fail@PLT
.L3:
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE0:
	.size	main, .-main
	.ident	"GCC: (GNU) 16.2.1 20260810"
	.section	.note.GNU-stack,"",@progbits
