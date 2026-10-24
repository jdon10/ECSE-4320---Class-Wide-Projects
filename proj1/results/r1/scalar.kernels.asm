0000000000003560 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3560:	endbr64
    3564:	mov    %rsi,%rdx
    3567:	cmp    $0x1,%r8
    356b:	je     35b0 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x50>
    356d:	test   %rcx,%rcx
    3570:	je     35a7 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x47>
    3572:	movss  0x4a8a(%rip),%xmm1        # 8004 <_IO_stdin_used+0x4>
    357a:	shl    $0x2,%r8
    357e:	xor    %eax,%eax
    3580:	xor    %esi,%esi
    3582:	nopw   0x0(%rax,%rax,1)
    3588:	movss  (%rdi,%rax,1),%xmm0
    358d:	add    $0x1,%rsi
    3591:	mulss  %xmm1,%xmm0
    3595:	addss  (%rdx,%rax,1),%xmm0
    359a:	movss  %xmm0,(%rdx,%rax,1)
    359f:	add    %r8,%rax
    35a2:	cmp    %rsi,%rcx
    35a5:	jne    3588 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x28>
    35a7:	pxor   %xmm0,%xmm0
    35ab:	ret
    35ac:	nopl   0x0(%rax)
    35b0:	test   %rcx,%rcx
    35b3:	je     35a7 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x47>
    35b5:	movss  0x4a47(%rip),%xmm1        # 8004 <_IO_stdin_used+0x4>
    35bd:	xor    %eax,%eax
    35bf:	nop
    35c0:	movss  (%rdi,%rax,4),%xmm0
    35c5:	mulss  %xmm1,%xmm0
    35c9:	addss  (%rdx,%rax,4),%xmm0
    35ce:	movss  %xmm0,(%rdx,%rax,4)
    35d3:	add    $0x1,%rax
    35d7:	cmp    %rax,%rcx
    35da:	jne    35c0 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x60>
    35dc:	pxor   %xmm0,%xmm0
    35e0:	ret
    35e1:	cs nopw 0x0(%rax,%rax,1)
    35eb:	nopl   0x0(%rax,%rax,1)

00000000000035f0 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)>:
    35f0:	endbr64
    35f4:	mov    %rsi,%r9
    35f7:	cmp    $0x1,%r8
    35fb:	je     3638 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x48>
    35fd:	shl    $0x2,%r8
    3601:	xor    %eax,%eax
    3603:	xor    %esi,%esi
    3605:	test   %rcx,%rcx
    3608:	je     362c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3c>
    360a:	nopw   0x0(%rax,%rax,1)
    3610:	movss  (%rdi,%rax,1),%xmm0
    3615:	mulss  (%r9,%rax,1),%xmm0
    361b:	add    $0x1,%rsi
    361f:	movss  %xmm0,(%rdx,%rax,1)
    3624:	add    %r8,%rax
    3627:	cmp    %rsi,%rcx
    362a:	jne    3610 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x20>
    362c:	pxor   %xmm0,%xmm0
    3630:	ret
    3631:	nopl   0x0(%rax)
    3638:	test   %rcx,%rcx
    363b:	je     362c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3c>
    363d:	xor    %eax,%eax
    363f:	nop
    3640:	movss  (%rdi,%rax,4),%xmm0
    3645:	mulss  (%r9,%rax,4),%xmm0
    364b:	movss  %xmm0,(%rdx,%rax,4)
    3650:	add    $0x1,%rax
    3654:	cmp    %rax,%rcx
    3657:	jne    3640 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x50>
    3659:	pxor   %xmm0,%xmm0
    365d:	ret
    365e:	xchg   %ax,%ax

0000000000003660 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3660:	endbr64
    3664:	cmp    $0x1,%r8
    3668:	je     36a0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x40>
    366a:	test   %rcx,%rcx
    366d:	je     36d0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x70>
    366f:	shl    $0x2,%r8
    3673:	xor    %eax,%eax
    3675:	pxor   %xmm1,%xmm1
    3679:	xor    %edx,%edx
    367b:	nopl   0x0(%rax,%rax,1)
    3680:	movss  (%rdi,%rax,1),%xmm0
    3685:	mulss  (%rsi,%rax,1),%xmm0
    368a:	add    $0x1,%rdx
    368e:	add    %r8,%rax
    3691:	addss  %xmm0,%xmm1
    3695:	cmp    %rdx,%rcx
    3698:	jne    3680 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x20>
    369a:	movaps %xmm1,%xmm0
    369d:	ret
    369e:	xchg   %ax,%ax
    36a0:	test   %rcx,%rcx
    36a3:	je     36d0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x70>
    36a5:	xor    %eax,%eax
    36a7:	pxor   %xmm1,%xmm1
    36ab:	nopl   0x0(%rax,%rax,1)
    36b0:	movss  (%rdi,%rax,4),%xmm0
    36b5:	mulss  (%rsi,%rax,4),%xmm0
    36ba:	add    $0x1,%rax
    36be:	addss  %xmm0,%xmm1
    36c2:	cmp    %rax,%rcx
    36c5:	jne    36b0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x50>
    36c7:	movaps %xmm1,%xmm0
    36ca:	ret
    36cb:	nopl   0x0(%rax,%rax,1)
    36d0:	pxor   %xmm1,%xmm1
    36d4:	movaps %xmm1,%xmm0
    36d7:	ret
    36d8:	nopl   0x0(%rax,%rax,1)

00000000000036e0 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)>:
    36e0:	endbr64
    36e4:	mov    %rsi,%rdx
    36e7:	cmp    $0x1,%r8
    36eb:	je     3730 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x50>
    36ed:	test   %rcx,%rcx
    36f0:	je     3727 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x47>
    36f2:	movsd  0x4e3e(%rip),%xmm1        # 8538 <_IO_stdin_used+0x538>
    36fa:	shl    $0x3,%r8
    36fe:	xor    %eax,%eax
    3700:	xor    %esi,%esi
    3702:	nopw   0x0(%rax,%rax,1)
    3708:	movsd  (%rdi,%rax,1),%xmm0
    370d:	add    $0x1,%rsi
    3711:	mulsd  %xmm1,%xmm0
    3715:	addsd  (%rdx,%rax,1),%xmm0
    371a:	movsd  %xmm0,(%rdx,%rax,1)
    371f:	add    %r8,%rax
    3722:	cmp    %rsi,%rcx
    3725:	jne    3708 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x28>
    3727:	pxor   %xmm0,%xmm0
    372b:	ret
    372c:	nopl   0x0(%rax)
    3730:	test   %rcx,%rcx
    3733:	je     3727 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x47>
    3735:	movsd  0x4dfb(%rip),%xmm1        # 8538 <_IO_stdin_used+0x538>
    373d:	xor    %eax,%eax
    373f:	nop
    3740:	movsd  (%rdi,%rax,8),%xmm0
    3745:	mulsd  %xmm1,%xmm0
    3749:	addsd  (%rdx,%rax,8),%xmm0
    374e:	movsd  %xmm0,(%rdx,%rax,8)
    3753:	add    $0x1,%rax
    3757:	cmp    %rax,%rcx
    375a:	jne    3740 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x60>
    375c:	pxor   %xmm0,%xmm0
    3760:	ret
    3761:	cs nopw 0x0(%rax,%rax,1)
    376b:	nopl   0x0(%rax,%rax,1)

0000000000003770 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)>:
    3770:	endbr64
    3774:	mov    %rsi,%r9
    3777:	cmp    $0x1,%r8
    377b:	je     37b8 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x48>
    377d:	shl    $0x3,%r8
    3781:	xor    %eax,%eax
    3783:	xor    %esi,%esi
    3785:	test   %rcx,%rcx
    3788:	je     37ac <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3c>
    378a:	nopw   0x0(%rax,%rax,1)
    3790:	movsd  (%rdi,%rax,1),%xmm0
    3795:	mulsd  (%r9,%rax,1),%xmm0
    379b:	add    $0x1,%rsi
    379f:	movsd  %xmm0,(%rdx,%rax,1)
    37a4:	add    %r8,%rax
    37a7:	cmp    %rsi,%rcx
    37aa:	jne    3790 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x20>
    37ac:	pxor   %xmm0,%xmm0
    37b0:	ret
    37b1:	nopl   0x0(%rax)
    37b8:	test   %rcx,%rcx
    37bb:	je     37ac <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3c>
    37bd:	xor    %eax,%eax
    37bf:	nop
    37c0:	movsd  (%rdi,%rax,8),%xmm0
    37c5:	mulsd  (%r9,%rax,8),%xmm0
    37cb:	movsd  %xmm0,(%rdx,%rax,8)
    37d0:	add    $0x1,%rax
    37d4:	cmp    %rax,%rcx
    37d7:	jne    37c0 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x50>
    37d9:	pxor   %xmm0,%xmm0
    37dd:	ret
    37de:	xchg   %ax,%ax

00000000000037e0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)>:
    37e0:	endbr64
    37e4:	cmp    $0x1,%r8
    37e8:	je     3820 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x40>
    37ea:	test   %rcx,%rcx
    37ed:	je     3850 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x70>
    37ef:	shl    $0x3,%r8
    37f3:	xor    %eax,%eax
    37f5:	pxor   %xmm1,%xmm1
    37f9:	xor    %edx,%edx
    37fb:	nopl   0x0(%rax,%rax,1)
    3800:	movsd  (%rdi,%rax,1),%xmm0
    3805:	mulsd  (%rsi,%rax,1),%xmm0
    380a:	add    $0x1,%rdx
    380e:	add    %r8,%rax
    3811:	addsd  %xmm0,%xmm1
    3815:	cmp    %rdx,%rcx
    3818:	jne    3800 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x20>
    381a:	movapd %xmm1,%xmm0
    381e:	ret
    381f:	nop
    3820:	test   %rcx,%rcx
    3823:	je     3850 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x70>
    3825:	xor    %eax,%eax
    3827:	pxor   %xmm1,%xmm1
    382b:	nopl   0x0(%rax,%rax,1)
    3830:	movsd  (%rdi,%rax,8),%xmm0
    3835:	mulsd  (%rsi,%rax,8),%xmm0
    383a:	add    $0x1,%rax
    383e:	addsd  %xmm0,%xmm1
    3842:	cmp    %rax,%rcx
    3845:	jne    3830 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x50>
    3847:	movapd %xmm1,%xmm0
    384b:	ret
    384c:	nopl   0x0(%rax)
    3850:	pxor   %xmm1,%xmm1
    3854:	movapd %xmm1,%xmm0
    3858:	ret
    3859:	nopl   0x0(%rax)

