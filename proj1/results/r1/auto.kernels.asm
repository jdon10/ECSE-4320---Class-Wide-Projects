0000000000003540 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3540:	endbr64
    3544:	mov    %rsi,%rdx
    3547:	mov    %rcx,%rsi
    354a:	cmp    $0x1,%r8
    354e:	je     3590 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x50>
    3550:	test   %rcx,%rcx
    3553:	je     3587 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x47>
    3555:	movss  0x5fd3(%rip),%xmm1        # 9530 <_IO_stdin_used+0x530>
    355d:	shl    $0x2,%r8
    3561:	xor    %eax,%eax
    3563:	xor    %ecx,%ecx
    3565:	nopl   (%rax)
    3568:	movss  (%rdi,%rax,1),%xmm0
    356d:	add    $0x1,%rcx
    3571:	mulss  %xmm1,%xmm0
    3575:	addss  (%rdx,%rax,1),%xmm0
    357a:	movss  %xmm0,(%rdx,%rax,1)
    357f:	add    %r8,%rax
    3582:	cmp    %rcx,%rsi
    3585:	jne    3568 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x28>
    3587:	pxor   %xmm0,%xmm0
    358b:	ret
    358c:	nopl   0x0(%rax)
    3590:	test   %rcx,%rcx
    3593:	je     3587 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x47>
    3595:	lea    -0x1(%rcx),%rax
    3599:	cmp    $0x2,%rax
    359d:	jbe    363e <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0xfe>
    35a3:	movss  0x5f85(%rip),%xmm1        # 9530 <_IO_stdin_used+0x530>
    35ab:	shr    $0x2,%rcx
    35af:	xor    %eax,%eax
    35b1:	shl    $0x4,%rcx
    35b5:	shufps $0x0,%xmm1,%xmm1
    35b9:	nopl   0x0(%rax)
    35c0:	movups (%rdi,%rax,1),%xmm0
    35c4:	movups (%rdx,%rax,1),%xmm2
    35c8:	mulps  %xmm1,%xmm0
    35cb:	addps  %xmm2,%xmm0
    35ce:	movups %xmm0,(%rdx,%rax,1)
    35d2:	add    $0x10,%rax
    35d6:	cmp    %rcx,%rax
    35d9:	jne    35c0 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x80>
    35db:	mov    %rsi,%rax
    35de:	and    $0xfffffffffffffffc,%rax
    35e2:	test   $0x3,%sil
    35e6:	je     3587 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x47>
    35e8:	sub    %rax,%rsi
    35eb:	cmp    $0x1,%rsi
    35ef:	je     3620 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0xe0>
    35f1:	movq   0x5f37(%rip),%xmm1        # 9530 <_IO_stdin_used+0x530>
    35f9:	movq   (%rdi,%rax,4),%xmm0
    35fe:	lea    (%rdx,%rax,4),%rcx
    3602:	mulps  %xmm1,%xmm0
    3605:	movq   (%rcx),%xmm1
    3609:	addps  %xmm1,%xmm0
    360c:	movlps %xmm0,(%rcx)
    360f:	test   $0x1,%sil
    3613:	je     3587 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x47>
    3619:	and    $0xfffffffffffffffe,%rsi
    361d:	add    %rsi,%rax
    3620:	lea    (%rdx,%rax,4),%rdx
    3624:	movss  0x5f04(%rip),%xmm0        # 9530 <_IO_stdin_used+0x530>
    362c:	mulss  (%rdi,%rax,4),%xmm0
    3631:	addss  (%rdx),%xmm0
    3635:	movss  %xmm0,(%rdx)
    3639:	pxor   %xmm0,%xmm0
    363d:	ret
    363e:	xor    %eax,%eax
    3640:	jmp    35e8 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0xa8>
    3642:	cs nopw 0x0(%rax,%rax,1)
    364c:	nopl   0x0(%rax)

0000000000003650 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3650:	endbr64
    3654:	mov    %rsi,%r9
    3657:	mov    %rdx,%rsi
    365a:	cmp    $0x1,%r8
    365e:	je     3698 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x48>
    3660:	shl    $0x2,%r8
    3664:	xor    %eax,%eax
    3666:	xor    %edx,%edx
    3668:	test   %rcx,%rcx
    366b:	je     368c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3c>
    366d:	nopl   (%rax)
    3670:	movss  (%rdi,%rax,1),%xmm0
    3675:	mulss  (%r9,%rax,1),%xmm0
    367b:	add    $0x1,%rdx
    367f:	movss  %xmm0,(%rsi,%rax,1)
    3684:	add    %r8,%rax
    3687:	cmp    %rdx,%rcx
    368a:	jne    3670 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x20>
    368c:	pxor   %xmm0,%xmm0
    3690:	ret
    3691:	nopl   0x0(%rax)
    3698:	test   %rcx,%rcx
    369b:	je     368c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3c>
    369d:	lea    -0x1(%rcx),%rax
    36a1:	cmp    $0x2,%rax
    36a5:	jbe    3719 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0xc9>
    36a7:	mov    %rcx,%rdx
    36aa:	xor    %eax,%eax
    36ac:	shr    $0x2,%rdx
    36b0:	shl    $0x4,%rdx
    36b4:	nopl   0x0(%rax)
    36b8:	movups (%r9,%rax,1),%xmm0
    36bd:	movups (%rdi,%rax,1),%xmm2
    36c1:	mulps  %xmm2,%xmm0
    36c4:	movups %xmm0,(%rsi,%rax,1)
    36c8:	add    $0x10,%rax
    36cc:	cmp    %rdx,%rax
    36cf:	jne    36b8 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x68>
    36d1:	mov    %rcx,%rax
    36d4:	and    $0xfffffffffffffffc,%rax
    36d8:	test   $0x3,%cl
    36db:	je     368c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3c>
    36dd:	sub    %rax,%rcx
    36e0:	cmp    $0x1,%rcx
    36e4:	je     3704 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0xb4>
    36e6:	movq   (%rdi,%rax,4),%xmm0
    36eb:	movq   (%r9,%rax,4),%xmm1
    36f1:	mulps  %xmm1,%xmm0
    36f4:	movlps %xmm0,(%rsi,%rax,4)
    36f8:	test   $0x1,%cl
    36fb:	je     368c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3c>
    36fd:	and    $0xfffffffffffffffe,%rcx
    3701:	add    %rcx,%rax
    3704:	movss  (%rdi,%rax,4),%xmm0
    3709:	mulss  (%r9,%rax,4),%xmm0
    370f:	movss  %xmm0,(%rsi,%rax,4)
    3714:	pxor   %xmm0,%xmm0
    3718:	ret
    3719:	xor    %eax,%eax
    371b:	jmp    36dd <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x8d>
    371d:	nopl   (%rax)

0000000000003720 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3720:	endbr64
    3724:	mov    %rsi,%rdx
    3727:	cmp    $0x1,%r8
    372b:	je     3940 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x220>
    3731:	test   %rcx,%rcx
    3734:	je     39f0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2d0>
    373a:	lea    -0x1(%rcx),%rax
    373e:	push   %rbx
    373f:	cmp    $0xc,%rax
    3743:	jbe    39f9 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2d9>
    3749:	mov    %rcx,%rbx
    374c:	lea    0x0(,%r8,8),%r11
    3754:	xorps  %xmm1,%xmm1
    3757:	xor    %eax,%eax
    3759:	shl    $0x2,%r8
    375d:	shr    $1,%rbx
    3760:	lea    (%rsi,%r8,1),%r9
    3764:	lea    (%rdi,%r8,1),%r10
    3768:	xor    %esi,%esi
    376a:	nopw   0x0(%rax,%rax,1)
    3770:	movss  (%r10,%rax,1),%xmm2
    3776:	movss  (%rdi,%rax,1),%xmm0
    377b:	add    $0x1,%rsi
    377f:	movss  (%r9,%rax,1),%xmm3
    3785:	unpcklps %xmm2,%xmm0
    3788:	movss  (%rdx,%rax,1),%xmm2
    378d:	add    %r11,%rax
    3790:	unpcklps %xmm3,%xmm2
    3793:	mulps  %xmm2,%xmm0
    3796:	addps  %xmm0,%xmm1
    3799:	cmp    %rsi,%rbx
    379c:	jne    3770 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x50>
    379e:	movaps %xmm1,%xmm0
    37a1:	shufps $0xe5,%xmm1,%xmm1
    37a5:	addss  %xmm1,%xmm0
    37a9:	test   $0x1,%cl
    37ac:	je     3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    37b2:	mov    %rcx,%rax
    37b5:	and    $0xfffffffffffffffe,%rax
    37b9:	mov    %rax,%rsi
    37bc:	imul   %r8,%rsi
    37c0:	movss  (%rdi,%rsi,1),%xmm1
    37c5:	mulss  (%rdx,%rsi,1),%xmm1
    37ca:	lea    0x1(%rax),%rsi
    37ce:	addss  %xmm1,%xmm0
    37d2:	cmp    %rcx,%rsi
    37d5:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    37db:	imul   %r8,%rsi
    37df:	movss  (%rdi,%rsi,1),%xmm1
    37e4:	mulss  (%rdx,%rsi,1),%xmm1
    37e9:	lea    0x2(%rax),%rsi
    37ed:	addss  %xmm1,%xmm0
    37f1:	cmp    %rcx,%rsi
    37f4:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    37fa:	imul   %r8,%rsi
    37fe:	movss  (%rdi,%rsi,1),%xmm1
    3803:	mulss  (%rdx,%rsi,1),%xmm1
    3808:	lea    0x3(%rax),%rsi
    380c:	addss  %xmm1,%xmm0
    3810:	cmp    %rcx,%rsi
    3813:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3819:	imul   %r8,%rsi
    381d:	movss  (%rdi,%rsi,1),%xmm1
    3822:	mulss  (%rdx,%rsi,1),%xmm1
    3827:	lea    0x4(%rax),%rsi
    382b:	addss  %xmm1,%xmm0
    382f:	cmp    %rcx,%rsi
    3832:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3838:	imul   %r8,%rsi
    383c:	movss  (%rdi,%rsi,1),%xmm1
    3841:	mulss  (%rdx,%rsi,1),%xmm1
    3846:	lea    0x5(%rax),%rsi
    384a:	addss  %xmm1,%xmm0
    384e:	cmp    %rcx,%rsi
    3851:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3857:	imul   %r8,%rsi
    385b:	movss  (%rdi,%rsi,1),%xmm1
    3860:	mulss  (%rdx,%rsi,1),%xmm1
    3865:	lea    0x6(%rax),%rsi
    3869:	addss  %xmm1,%xmm0
    386d:	cmp    %rcx,%rsi
    3870:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3876:	imul   %r8,%rsi
    387a:	movss  (%rdi,%rsi,1),%xmm1
    387f:	mulss  (%rdx,%rsi,1),%xmm1
    3884:	lea    0x7(%rax),%rsi
    3888:	addss  %xmm1,%xmm0
    388c:	cmp    %rcx,%rsi
    388f:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3895:	imul   %r8,%rsi
    3899:	movss  (%rdi,%rsi,1),%xmm1
    389e:	mulss  (%rdx,%rsi,1),%xmm1
    38a3:	lea    0x8(%rax),%rsi
    38a7:	addss  %xmm1,%xmm0
    38ab:	cmp    %rcx,%rsi
    38ae:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    38b4:	imul   %r8,%rsi
    38b8:	movss  (%rdi,%rsi,1),%xmm1
    38bd:	mulss  (%rdx,%rsi,1),%xmm1
    38c2:	lea    0x9(%rax),%rsi
    38c6:	addss  %xmm1,%xmm0
    38ca:	cmp    %rcx,%rsi
    38cd:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    38cf:	imul   %r8,%rsi
    38d3:	movss  (%rdi,%rsi,1),%xmm1
    38d8:	mulss  (%rdx,%rsi,1),%xmm1
    38dd:	lea    0xa(%rax),%rsi
    38e1:	addss  %xmm1,%xmm0
    38e5:	cmp    %rcx,%rsi
    38e8:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    38ea:	imul   %r8,%rsi
    38ee:	movss  (%rdi,%rsi,1),%xmm1
    38f3:	mulss  (%rdx,%rsi,1),%xmm1
    38f8:	lea    0xb(%rax),%rsi
    38fc:	addss  %xmm1,%xmm0
    3900:	cmp    %rcx,%rsi
    3903:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3905:	imul   %r8,%rsi
    3909:	add    $0xc,%rax
    390d:	movss  (%rdi,%rsi,1),%xmm1
    3912:	mulss  (%rdx,%rsi,1),%xmm1
    3917:	addss  %xmm1,%xmm0
    391b:	cmp    %rcx,%rax
    391e:	jae    3934 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x214>
    3920:	imul   %rax,%r8
    3924:	movss  (%rdi,%r8,1),%xmm1
    392a:	mulss  (%rdx,%r8,1),%xmm1
    3930:	addss  %xmm1,%xmm0
    3934:	pop    %rbx
    3935:	ret
    3936:	cs nopw 0x0(%rax,%rax,1)
    3940:	test   %rcx,%rcx
    3943:	je     39f0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2d0>
    3949:	lea    -0x1(%rcx),%rax
    394d:	cmp    $0x2,%rax
    3951:	jbe    3a0c <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2ec>
    3957:	mov    %rcx,%rsi
    395a:	xor    %eax,%eax
    395c:	pxor   %xmm1,%xmm1
    3960:	shr    $0x2,%rsi
    3964:	shl    $0x4,%rsi
    3968:	nopl   0x0(%rax,%rax,1)
    3970:	movups (%rdx,%rax,1),%xmm0
    3974:	movups (%rdi,%rax,1),%xmm4
    3978:	add    $0x10,%rax
    397c:	mulps  %xmm4,%xmm0
    397f:	addps  %xmm0,%xmm1
    3982:	cmp    %rax,%rsi
    3985:	jne    3970 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x250>
    3987:	movaps %xmm1,%xmm0
    398a:	mov    %rcx,%rax
    398d:	movhlps %xmm1,%xmm0
    3990:	and    $0xfffffffffffffffc,%rax
    3994:	addps  %xmm0,%xmm1
    3997:	movaps %xmm1,%xmm0
    399a:	shufps $0x55,%xmm1,%xmm0
    399e:	addps  %xmm1,%xmm0
    39a1:	test   $0x3,%cl
    39a4:	je     39f8 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2d8>
    39a6:	movss  (%rdi,%rax,4),%xmm1
    39ab:	mulss  (%rdx,%rax,4),%xmm1
    39b0:	lea    0x1(%rax),%r8
    39b4:	lea    0x0(,%rax,4),%rsi
    39bc:	addss  %xmm1,%xmm0
    39c0:	cmp    %rcx,%r8
    39c3:	jae    39ef <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2cf>
    39c5:	movss  0x4(%rdi,%rsi,1),%xmm1
    39cb:	mulss  0x4(%rdx,%rsi,1),%xmm1
    39d1:	add    $0x2,%rax
    39d5:	addss  %xmm1,%xmm0
    39d9:	cmp    %rcx,%rax
    39dc:	jae    39ef <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x2cf>
    39de:	movss  0x8(%rdx,%rsi,1),%xmm1
    39e4:	mulss  0x8(%rdi,%rsi,1),%xmm1
    39ea:	addss  %xmm1,%xmm0
    39ee:	ret
    39ef:	ret
    39f0:	pxor   %xmm0,%xmm0
    39f4:	ret
    39f5:	nopl   (%rax)
    39f8:	ret
    39f9:	xor    %eax,%eax
    39fb:	pxor   %xmm0,%xmm0
    39ff:	lea    0x0(,%r8,4),%r8
    3a07:	jmp    37b9 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x99>
    3a0c:	xor    %eax,%eax
    3a0e:	pxor   %xmm0,%xmm0
    3a12:	jmp    39a6 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x286>
    3a14:	cs nopw 0x0(%rax,%rax,1)
    3a1e:	xchg   %ax,%ax

0000000000003a20 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)>:
    3a20:	endbr64
    3a24:	mov    %rsi,%rdx
    3a27:	cmp    $0x1,%r8
    3a2b:	je     3a70 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x50>
    3a2d:	test   %rcx,%rcx
    3a30:	je     3a67 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x47>
    3a32:	movsd  0x5afe(%rip),%xmm1        # 9538 <_IO_stdin_used+0x538>
    3a3a:	shl    $0x3,%r8
    3a3e:	xor    %eax,%eax
    3a40:	xor    %esi,%esi
    3a42:	nopw   0x0(%rax,%rax,1)
    3a48:	movsd  (%rdi,%rax,1),%xmm0
    3a4d:	add    $0x1,%rsi
    3a51:	mulsd  %xmm1,%xmm0
    3a55:	addsd  (%rdx,%rax,1),%xmm0
    3a5a:	movsd  %xmm0,(%rdx,%rax,1)
    3a5f:	add    %r8,%rax
    3a62:	cmp    %rsi,%rcx
    3a65:	jne    3a48 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x28>
    3a67:	pxor   %xmm0,%xmm0
    3a6b:	ret
    3a6c:	nopl   0x0(%rax)
    3a70:	test   %rcx,%rcx
    3a73:	je     3a67 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x47>
    3a75:	cmp    $0x1,%rcx
    3a79:	je     3ade <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0xbe>
    3a7b:	movsd  0x5ab5(%rip),%xmm1        # 9538 <_IO_stdin_used+0x538>
    3a83:	mov    %rcx,%rsi
    3a86:	xor    %eax,%eax
    3a88:	shr    $1,%rsi
    3a8b:	shl    $0x4,%rsi
    3a8f:	unpcklpd %xmm1,%xmm1
    3a93:	nopl   0x0(%rax,%rax,1)
    3a98:	movupd (%rdi,%rax,1),%xmm0
    3a9d:	movupd (%rdx,%rax,1),%xmm2
    3aa2:	mulpd  %xmm1,%xmm0
    3aa6:	addpd  %xmm2,%xmm0
    3aaa:	movups %xmm0,(%rdx,%rax,1)
    3aae:	add    $0x10,%rax
    3ab2:	cmp    %rsi,%rax
    3ab5:	jne    3a98 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x78>
    3ab7:	test   $0x1,%cl
    3aba:	je     3a67 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x47>
    3abc:	and    $0xfffffffffffffffe,%rcx
    3ac0:	lea    (%rdx,%rcx,8),%rax
    3ac4:	movsd  0x5a6c(%rip),%xmm0        # 9538 <_IO_stdin_used+0x538>
    3acc:	mulsd  (%rdi,%rcx,8),%xmm0
    3ad1:	addsd  (%rax),%xmm0
    3ad5:	movsd  %xmm0,(%rax)
    3ad9:	pxor   %xmm0,%xmm0
    3add:	ret
    3ade:	xor    %ecx,%ecx
    3ae0:	jmp    3ac0 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0xa0>
    3ae2:	cs nopw 0x0(%rax,%rax,1)
    3aec:	nopl   0x0(%rax)

0000000000003af0 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)>:
    3af0:	endbr64
    3af4:	mov    %rsi,%r9
    3af7:	mov    %rdx,%rsi
    3afa:	cmp    $0x1,%r8
    3afe:	je     3b38 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x48>
    3b00:	shl    $0x3,%r8
    3b04:	xor    %eax,%eax
    3b06:	xor    %edx,%edx
    3b08:	test   %rcx,%rcx
    3b0b:	je     3b2c <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3c>
    3b0d:	nopl   (%rax)
    3b10:	movsd  (%rdi,%rax,1),%xmm0
    3b15:	mulsd  (%r9,%rax,1),%xmm0
    3b1b:	add    $0x1,%rdx
    3b1f:	movsd  %xmm0,(%rsi,%rax,1)
    3b24:	add    %r8,%rax
    3b27:	cmp    %rdx,%rcx
    3b2a:	jne    3b10 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x20>
    3b2c:	pxor   %xmm0,%xmm0
    3b30:	ret
    3b31:	nopl   0x0(%rax)
    3b38:	test   %rcx,%rcx
    3b3b:	je     3b2c <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3c>
    3b3d:	cmp    $0x1,%rcx
    3b41:	je     3b8a <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x9a>
    3b43:	mov    %rcx,%rdx
    3b46:	xor    %eax,%eax
    3b48:	shr    $1,%rdx
    3b4b:	shl    $0x4,%rdx
    3b4f:	nop
    3b50:	movupd (%r9,%rax,1),%xmm0
    3b56:	movupd (%rdi,%rax,1),%xmm1
    3b5b:	mulpd  %xmm1,%xmm0
    3b5f:	movups %xmm0,(%rsi,%rax,1)
    3b63:	add    $0x10,%rax
    3b67:	cmp    %rdx,%rax
    3b6a:	jne    3b50 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x60>
    3b6c:	test   $0x1,%cl
    3b6f:	je     3b2c <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3c>
    3b71:	and    $0xfffffffffffffffe,%rcx
    3b75:	movsd  (%r9,%rcx,8),%xmm0
    3b7b:	mulsd  (%rdi,%rcx,8),%xmm0
    3b80:	movsd  %xmm0,(%rsi,%rcx,8)
    3b85:	pxor   %xmm0,%xmm0
    3b89:	ret
    3b8a:	xor    %ecx,%ecx
    3b8c:	jmp    3b75 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x85>
    3b8e:	xchg   %ax,%ax

0000000000003b90 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)>:
    3b90:	endbr64
    3b94:	mov    %rcx,%rdx
    3b97:	cmp    $0x1,%r8
    3b9b:	je     3c60 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xd0>
    3ba1:	test   %rcx,%rcx
    3ba4:	je     3cc8 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x138>
    3baa:	lea    -0x1(%rcx),%rax
    3bae:	push   %rbx
    3baf:	cmp    $0x1,%rax
    3bb3:	jbe    3ccd <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x13d>
    3bb9:	mov    %rcx,%rbx
    3bbc:	mov    %r8,%r11
    3bbf:	shl    $0x3,%r8
    3bc3:	xor    %eax,%eax
    3bc5:	shr    $1,%rbx
    3bc8:	shl    $0x4,%r11
    3bcc:	lea    (%rdi,%r8,1),%r10
    3bd0:	lea    (%rsi,%r8,1),%r9
    3bd4:	xor    %ecx,%ecx
    3bd6:	pxor   %xmm2,%xmm2
    3bda:	nopw   0x0(%rax,%rax,1)
    3be0:	movsd  (%rdi,%rax,1),%xmm0
    3be5:	movsd  (%rsi,%rax,1),%xmm1
    3bea:	add    $0x1,%rcx
    3bee:	movhpd (%r10,%rax,1),%xmm0
    3bf4:	movhpd (%r9,%rax,1),%xmm1
    3bfa:	add    %r11,%rax
    3bfd:	mulpd  %xmm1,%xmm0
    3c01:	addpd  %xmm0,%xmm2
    3c05:	cmp    %rbx,%rcx
    3c08:	jne    3be0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x50>
    3c0a:	movapd %xmm2,%xmm0
    3c0e:	unpckhpd %xmm2,%xmm0
    3c12:	addpd  %xmm2,%xmm0
    3c16:	test   $0x1,%dl
    3c19:	je     3c54 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xc4>
    3c1b:	mov    %rdx,%rax
    3c1e:	and    $0xfffffffffffffffe,%rax
    3c22:	mov    %r8,%rcx
    3c25:	imul   %rax,%rcx
    3c29:	add    $0x1,%rax
    3c2d:	movsd  (%rdi,%rcx,1),%xmm1
    3c32:	mulsd  (%rsi,%rcx,1),%xmm1
    3c37:	addsd  %xmm1,%xmm0
    3c3b:	cmp    %rdx,%rax
    3c3e:	jae    3c54 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xc4>
    3c40:	imul   %rax,%r8
    3c44:	movsd  (%rdi,%r8,1),%xmm1
    3c4a:	mulsd  (%rsi,%r8,1),%xmm1
    3c50:	addsd  %xmm1,%xmm0
    3c54:	pop    %rbx
    3c55:	ret
    3c56:	cs nopw 0x0(%rax,%rax,1)
    3c60:	test   %rcx,%rcx
    3c63:	je     3cc8 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x138>
    3c65:	cmp    $0x1,%rcx
    3c69:	je     3ce0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x150>
    3c6b:	shr    $1,%rcx
    3c6e:	xor    %eax,%eax
    3c70:	pxor   %xmm1,%xmm1
    3c74:	shl    $0x4,%rcx
    3c78:	nopl   0x0(%rax,%rax,1)
    3c80:	movupd (%rsi,%rax,1),%xmm0
    3c85:	movupd (%rdi,%rax,1),%xmm3
    3c8a:	add    $0x10,%rax
    3c8e:	mulpd  %xmm3,%xmm0
    3c92:	addpd  %xmm0,%xmm1
    3c96:	cmp    %rax,%rcx
    3c99:	jne    3c80 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xf0>
    3c9b:	movapd %xmm1,%xmm0
    3c9f:	unpckhpd %xmm1,%xmm0
    3ca3:	addpd  %xmm1,%xmm0
    3ca7:	test   $0x1,%dl
    3caa:	je     3cc0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x130>
    3cac:	and    $0xfffffffffffffffe,%rdx
    3cb0:	movsd  (%rsi,%rdx,8),%xmm1
    3cb5:	mulsd  (%rdi,%rdx,8),%xmm1
    3cba:	addsd  %xmm1,%xmm0
    3cbe:	ret
    3cbf:	nop
    3cc0:	ret
    3cc1:	nopl   0x0(%rax)
    3cc8:	pxor   %xmm0,%xmm0
    3ccc:	ret
    3ccd:	xor    %eax,%eax
    3ccf:	pxor   %xmm0,%xmm0
    3cd3:	lea    0x0(,%r8,8),%r8
    3cdb:	jmp    3c22 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x92>
    3ce0:	xor    %edx,%edx
    3ce2:	pxor   %xmm0,%xmm0
    3ce6:	jmp    3cb0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x120>
    3ce8:	nopl   0x0(%rax,%rax,1)

