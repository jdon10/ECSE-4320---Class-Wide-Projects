00000000000035a0 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)>:
    35a0:	endbr64
    35a4:	mov    %rsi,%rdx
    35a7:	mov    %rcx,%rsi
    35aa:	cmp    $0x1,%r8
    35ae:	je     35f0 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x50>
    35b0:	test   %rcx,%rcx
    35b3:	je     35eb <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x4b>
    35b5:	vmovss 0x5a47(%rip),%xmm1        # 9004 <_IO_stdin_used+0x4>
    35bd:	shl    $0x2,%r8
    35c1:	xor    %eax,%eax
    35c3:	xor    %ecx,%ecx
    35c5:	data16 cs nopw 0x0(%rax,%rax,1)
    35d0:	vmovss (%rdi,%rax,1),%xmm0
    35d5:	inc    %rcx
    35d8:	vfmadd213ss (%rdx,%rax,1),%xmm1,%xmm0
    35de:	vmovss %xmm0,(%rdx,%rax,1)
    35e3:	add    %r8,%rax
    35e6:	cmp    %rcx,%rsi
    35e9:	jne    35d0 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x30>
    35eb:	vxorps %xmm0,%xmm0,%xmm0
    35ef:	ret
    35f0:	test   %rcx,%rcx
    35f3:	je     35eb <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x4b>
    35f5:	lea    -0x1(%rcx),%rax
    35f9:	cmp    $0x6,%rax
    35fd:	jbe    3705 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x165>
    3603:	vbroadcastss 0x59f8(%rip),%ymm1        # 9004 <_IO_stdin_used+0x4>
    360c:	shr    $0x3,%rcx
    3610:	xor    %eax,%eax
    3612:	shl    $0x5,%rcx
    3616:	cs nopw 0x0(%rax,%rax,1)
    3620:	vmovups (%rdi,%rax,1),%ymm0
    3625:	vfmadd213ps (%rdx,%rax,1),%ymm1,%ymm0
    362b:	vmovups %ymm0,(%rdx,%rax,1)
    3630:	add    $0x20,%rax
    3634:	cmp    %rcx,%rax
    3637:	jne    3620 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x80>
    3639:	mov    %rsi,%rax
    363c:	and    $0xfffffffffffffff8,%rax
    3640:	test   $0x7,%sil
    3644:	je     36fd <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x15d>
    364a:	vzeroupper
    364d:	mov    %rsi,%rcx
    3650:	sub    %rax,%rcx
    3653:	lea    -0x1(%rcx),%r8
    3657:	cmp    $0x2,%r8
    365b:	jbe    3692 <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0xf2>
    365d:	lea    0x0(,%rax,4),%r9
    3665:	vbroadcastss 0x5996(%rip),%xmm0        # 9004 <_IO_stdin_used+0x4>
    366e:	lea    (%rdx,%r9,1),%r8
    3672:	vmovups (%r8),%xmm2
    3677:	vfmadd132ps (%rdi,%r9,1),%xmm2,%xmm0
    367d:	vmovups %xmm0,(%r8)
    3682:	test   $0x3,%cl
    3685:	je     35eb <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x4b>
    368b:	and    $0xfffffffffffffffc,%rcx
    368f:	add    %rcx,%rax
    3692:	lea    0x0(,%rax,4),%rcx
    369a:	vmovss 0x5962(%rip),%xmm0        # 9004 <_IO_stdin_used+0x4>
    36a2:	lea    (%rdx,%rcx,1),%r8
    36a6:	vmovss (%rdi,%rcx,1),%xmm1
    36ab:	vfmadd213ss (%r8),%xmm0,%xmm1
    36b0:	vmovss %xmm1,(%r8)
    36b5:	lea    0x1(%rax),%r8
    36b9:	cmp    %rsi,%r8
    36bc:	jae    35eb <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x4b>
    36c2:	lea    0x4(%rdx,%rcx,1),%r8
    36c7:	vmovss 0x4(%rdi,%rcx,1),%xmm1
    36cd:	add    $0x2,%rax
    36d1:	vfmadd213ss (%r8),%xmm0,%xmm1
    36d6:	vmovss %xmm1,(%r8)
    36db:	cmp    %rsi,%rax
    36de:	jae    35eb <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x4b>
    36e4:	lea    0x8(%rdx,%rcx,1),%rax
    36e9:	vmovss (%rax),%xmm3
    36ed:	vfmadd132ss 0x8(%rdi,%rcx,1),%xmm3,%xmm0
    36f4:	vmovss %xmm0,(%rax)
    36f8:	vxorps %xmm0,%xmm0,%xmm0
    36fc:	ret
    36fd:	vzeroupper
    3700:	jmp    35eb <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0x4b>
    3705:	xor    %eax,%eax
    3707:	jmp    364d <float saxpy<float>(float*, float*, float*, unsigned long, unsigned long)+0xad>
    370c:	nopl   0x0(%rax)

0000000000003710 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3710:	endbr64
    3714:	mov    %rdi,%r9
    3717:	mov    %rsi,%rdi
    371a:	mov    %rdx,%rsi
    371d:	cmp    $0x1,%r8
    3721:	je     3750 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x40>
    3723:	shl    $0x2,%r8
    3727:	xor    %eax,%eax
    3729:	xor    %edx,%edx
    372b:	test   %rcx,%rcx
    372e:	je     374b <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3b>
    3730:	vmovss (%r9,%rax,1),%xmm0
    3736:	inc    %rdx
    3739:	vmulss (%rdi,%rax,1),%xmm0,%xmm0
    373e:	vmovss %xmm0,(%rsi,%rax,1)
    3743:	add    %r8,%rax
    3746:	cmp    %rdx,%rcx
    3749:	jne    3730 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x20>
    374b:	vxorps %xmm0,%xmm0,%xmm0
    374f:	ret
    3750:	test   %rcx,%rcx
    3753:	je     374b <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3b>
    3755:	lea    -0x1(%rcx),%rax
    3759:	cmp    $0x6,%rax
    375d:	jbe    3837 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x127>
    3763:	mov    %rcx,%rdx
    3766:	xor    %eax,%eax
    3768:	shr    $0x3,%rdx
    376c:	shl    $0x5,%rdx
    3770:	vmovups (%rdi,%rax,1),%ymm1
    3775:	vmulps (%r9,%rax,1),%ymm1,%ymm0
    377b:	vmovups %ymm0,(%rsi,%rax,1)
    3780:	add    $0x20,%rax
    3784:	cmp    %rdx,%rax
    3787:	jne    3770 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x60>
    3789:	mov    %rcx,%rax
    378c:	and    $0xfffffffffffffff8,%rax
    3790:	test   $0x7,%cl
    3793:	je     382f <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x11f>
    3799:	vzeroupper
    379c:	mov    %rcx,%rdx
    379f:	sub    %rax,%rdx
    37a2:	lea    -0x1(%rdx),%r8
    37a6:	cmp    $0x2,%r8
    37aa:	jbe    37d2 <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0xc2>
    37ac:	lea    0x0(,%rax,4),%r8
    37b4:	vmovups (%r9,%r8,1),%xmm2
    37ba:	vmulps (%rdi,%r8,1),%xmm2,%xmm0
    37c0:	vmovups %xmm0,(%rsi,%r8,1)
    37c6:	test   $0x3,%dl
    37c9:	je     374b <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3b>
    37cb:	and    $0xfffffffffffffffc,%rdx
    37cf:	add    %rdx,%rax
    37d2:	lea    0x0(,%rax,4),%rdx
    37da:	lea    0x1(%rax),%r8
    37de:	vmovss (%r9,%rdx,1),%xmm0
    37e4:	vmulss (%rdi,%rdx,1),%xmm0,%xmm0
    37e9:	vmovss %xmm0,(%rsi,%rdx,1)
    37ee:	cmp    %rcx,%r8
    37f1:	jae    374b <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3b>
    37f7:	vmovss 0x4(%rdi,%rdx,1),%xmm0
    37fd:	add    $0x2,%rax
    3801:	vmulss 0x4(%r9,%rdx,1),%xmm0,%xmm0
    3808:	vmovss %xmm0,0x4(%rsi,%rdx,1)
    380e:	cmp    %rcx,%rax
    3811:	jae    374b <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3b>
    3817:	vmovss 0x8(%r9,%rdx,1),%xmm0
    381e:	vmulss 0x8(%rdi,%rdx,1),%xmm0,%xmm0
    3824:	vmovss %xmm0,0x8(%rsi,%rdx,1)
    382a:	vxorps %xmm0,%xmm0,%xmm0
    382e:	ret
    382f:	vzeroupper
    3832:	jmp    374b <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x3b>
    3837:	xor    %eax,%eax
    3839:	jmp    379c <float mul<float>(float*, float*, float*, unsigned long, unsigned long)+0x8c>
    383e:	xchg   %ax,%ax

0000000000003840 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)>:
    3840:	endbr64
    3844:	cmp    $0x1,%r8
    3848:	je     3880 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x40>
    384a:	test   %rcx,%rcx
    384d:	je     3990 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x150>
    3853:	shl    $0x2,%r8
    3857:	xor    %eax,%eax
    3859:	xor    %edx,%edx
    385b:	vxorps %xmm1,%xmm1,%xmm1
    385f:	nop
    3860:	vmovss (%rdi,%rax,1),%xmm0
    3865:	inc    %rdx
    3868:	vmulss (%rsi,%rax,1),%xmm0,%xmm0
    386d:	add    %r8,%rax
    3870:	vaddss %xmm0,%xmm1,%xmm1
    3874:	cmp    %rdx,%rcx
    3877:	jne    3860 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x20>
    3879:	vmovaps %xmm1,%xmm0
    387d:	ret
    387e:	xchg   %ax,%ax
    3880:	test   %rcx,%rcx
    3883:	je     3990 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x150>
    3889:	lea    -0x1(%rcx),%rax
    388d:	cmp    $0x6,%rax
    3891:	jbe    39a1 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x161>
    3897:	mov    %rcx,%rdx
    389a:	xor    %eax,%eax
    389c:	vxorps %xmm0,%xmm0,%xmm0
    38a0:	shr    $0x3,%rdx
    38a4:	shl    $0x5,%rdx
    38a8:	nopl   0x0(%rax,%rax,1)
    38b0:	vmovups (%rsi,%rax,1),%ymm4
    38b5:	vmulps (%rdi,%rax,1),%ymm4,%ymm1
    38ba:	add    $0x20,%rax
    38be:	vaddps %ymm1,%ymm0,%ymm0
    38c2:	cmp    %rax,%rdx
    38c5:	jne    38b0 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x70>
    38c7:	vextractf128 $0x1,%ymm0,%xmm3
    38cd:	mov    %rcx,%rax
    38d0:	vaddps %xmm0,%xmm3,%xmm1
    38d4:	and    $0xfffffffffffffff8,%rax
    38d8:	vaddps %xmm3,%xmm0,%xmm0
    38dc:	vmovhlps %xmm1,%xmm1,%xmm2
    38e0:	vaddps %xmm1,%xmm2,%xmm2
    38e4:	vshufps $0x55,%xmm2,%xmm2,%xmm1
    38e9:	vaddps %xmm2,%xmm1,%xmm1
    38ed:	test   $0x7,%cl
    38f0:	je     3999 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x159>
    38f6:	vzeroupper
    38f9:	mov    %rcx,%rdx
    38fc:	sub    %rax,%rdx
    38ff:	lea    -0x1(%rdx),%r8
    3903:	cmp    $0x2,%r8
    3907:	jbe    3935 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0xf5>
    3909:	vmovups (%rdi,%rax,4),%xmm5
    390e:	vfmadd231ps (%rsi,%rax,4),%xmm5,%xmm0
    3914:	vmovhlps %xmm0,%xmm0,%xmm1
    3918:	vaddps %xmm0,%xmm1,%xmm0
    391c:	vshufps $0x55,%xmm0,%xmm0,%xmm1
    3921:	vaddps %xmm0,%xmm1,%xmm1
    3925:	test   $0x3,%dl
    3928:	je     3879 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x39>
    392e:	and    $0xfffffffffffffffc,%rdx
    3932:	add    %rdx,%rax
    3935:	vmovss (%rdi,%rax,4),%xmm6
    393a:	lea    0x1(%rax),%r8
    393e:	lea    0x0(,%rax,4),%rdx
    3946:	vfmadd231ss (%rsi,%rax,4),%xmm6,%xmm1
    394c:	cmp    %rcx,%r8
    394f:	jae    3879 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x39>
    3955:	vmovss 0x4(%rsi,%rdx,1),%xmm7
    395b:	add    $0x2,%rax
    395f:	vfmadd231ss 0x4(%rdi,%rdx,1),%xmm7,%xmm1
    3966:	cmp    %rcx,%rax
    3969:	jae    3879 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x39>
    396f:	vmovss 0x8(%rdi,%rdx,1),%xmm7
    3975:	vfmadd231ss 0x8(%rsi,%rdx,1),%xmm7,%xmm1
    397c:	vmovaps %xmm1,%xmm0
    3980:	ret
    3981:	data16 cs nopw 0x0(%rax,%rax,1)
    398c:	nopl   0x0(%rax)
    3990:	vxorps %xmm1,%xmm1,%xmm1
    3994:	vmovaps %xmm1,%xmm0
    3998:	ret
    3999:	vzeroupper
    399c:	jmp    3879 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0x39>
    39a1:	vxorps %xmm0,%xmm0,%xmm0
    39a5:	xor    %eax,%eax
    39a7:	vxorps %xmm1,%xmm1,%xmm1
    39ab:	jmp    38f9 <float dot<float>(float*, float*, float*, unsigned long, unsigned long)+0xb9>

00000000000039b0 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)>:
    39b0:	endbr64
    39b4:	mov    %rsi,%rdx
    39b7:	mov    %rcx,%rsi
    39ba:	cmp    $0x1,%r8
    39be:	je     3a00 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x50>
    39c0:	test   %rcx,%rcx
    39c3:	je     39fb <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x4b>
    39c5:	vmovsd 0x5b6b(%rip),%xmm1        # 9538 <_IO_stdin_used+0x538>
    39cd:	shl    $0x3,%r8
    39d1:	xor    %eax,%eax
    39d3:	xor    %ecx,%ecx
    39d5:	data16 cs nopw 0x0(%rax,%rax,1)
    39e0:	vmovsd (%rdi,%rax,1),%xmm0
    39e5:	inc    %rcx
    39e8:	vfmadd213sd (%rdx,%rax,1),%xmm1,%xmm0
    39ee:	vmovsd %xmm0,(%rdx,%rax,1)
    39f3:	add    %r8,%rax
    39f6:	cmp    %rcx,%rsi
    39f9:	jne    39e0 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x30>
    39fb:	vxorpd %xmm0,%xmm0,%xmm0
    39ff:	ret
    3a00:	test   %rcx,%rcx
    3a03:	je     39fb <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x4b>
    3a05:	lea    -0x1(%rcx),%rax
    3a09:	cmp    $0x2,%rax
    3a0d:	jbe    3ac8 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x118>
    3a13:	vbroadcastsd 0x5b1c(%rip),%ymm1        # 9538 <_IO_stdin_used+0x538>
    3a1c:	shr    $0x2,%rcx
    3a20:	xor    %eax,%eax
    3a22:	shl    $0x5,%rcx
    3a26:	cs nopw 0x0(%rax,%rax,1)
    3a30:	vmovupd (%rdi,%rax,1),%ymm0
    3a35:	vfmadd213pd (%rdx,%rax,1),%ymm1,%ymm0
    3a3b:	vmovupd %ymm0,(%rdx,%rax,1)
    3a40:	add    $0x20,%rax
    3a44:	cmp    %rcx,%rax
    3a47:	jne    3a30 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x80>
    3a49:	mov    %rsi,%rax
    3a4c:	and    $0xfffffffffffffffc,%rax
    3a50:	test   $0x3,%sil
    3a54:	je     3ac0 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x110>
    3a56:	vzeroupper
    3a59:	sub    %rax,%rsi
    3a5c:	cmp    $0x1,%rsi
    3a60:	je     3a95 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0xe5>
    3a62:	lea    0x0(,%rax,8),%r8
    3a6a:	vmovddup 0x5ac6(%rip),%xmm0        # 9538 <_IO_stdin_used+0x538>
    3a72:	lea    (%rdx,%r8,1),%rcx
    3a76:	vmovupd (%rcx),%xmm3
    3a7a:	vfmadd132pd (%rdi,%r8,1),%xmm3,%xmm0
    3a80:	vmovupd %xmm0,(%rcx)
    3a84:	test   $0x1,%sil
    3a88:	je     39fb <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x4b>
    3a8e:	and    $0xfffffffffffffffe,%rsi
    3a92:	add    %rsi,%rax
    3a95:	shl    $0x3,%rax
    3a99:	add    %rax,%rdx
    3a9c:	vmovsd (%rdi,%rax,1),%xmm0
    3aa1:	vmovsd (%rdx),%xmm2
    3aa5:	vfmadd132sd 0x5a8a(%rip),%xmm2,%xmm0        # 9538 <_IO_stdin_used+0x538>
    3aae:	vmovsd %xmm0,(%rdx)
    3ab2:	vxorpd %xmm0,%xmm0,%xmm0
    3ab6:	ret
    3ab7:	nopw   0x0(%rax,%rax,1)
    3ac0:	vzeroupper
    3ac3:	jmp    39fb <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0x4b>
    3ac8:	xor    %eax,%eax
    3aca:	jmp    3a59 <double saxpy<double>(double*, double*, double*, unsigned long, unsigned long)+0xa9>
    3acc:	nopl   0x0(%rax)

0000000000003ad0 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)>:
    3ad0:	endbr64
    3ad4:	mov    %rdx,%r9
    3ad7:	cmp    $0x1,%r8
    3adb:	je     3b10 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x40>
    3add:	shl    $0x3,%r8
    3ae1:	xor    %eax,%eax
    3ae3:	xor    %edx,%edx
    3ae5:	test   %rcx,%rcx
    3ae8:	je     3b0b <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3b>
    3aea:	nopw   0x0(%rax,%rax,1)
    3af0:	vmovsd (%rdi,%rax,1),%xmm0
    3af5:	inc    %rdx
    3af8:	vmulsd (%rsi,%rax,1),%xmm0,%xmm0
    3afd:	vmovsd %xmm0,(%r9,%rax,1)
    3b03:	add    %r8,%rax
    3b06:	cmp    %rdx,%rcx
    3b09:	jne    3af0 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x20>
    3b0b:	vxorpd %xmm0,%xmm0,%xmm0
    3b0f:	ret
    3b10:	test   %rcx,%rcx
    3b13:	je     3b0b <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3b>
    3b15:	lea    -0x1(%rcx),%rax
    3b19:	cmp    $0x2,%rax
    3b1d:	jbe    3ba8 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0xd8>
    3b23:	mov    %rcx,%rdx
    3b26:	xor    %eax,%eax
    3b28:	shr    $0x2,%rdx
    3b2c:	shl    $0x5,%rdx
    3b30:	vmovupd (%rsi,%rax,1),%ymm1
    3b35:	vmulpd (%rdi,%rax,1),%ymm1,%ymm0
    3b3a:	vmovupd %ymm0,(%r9,%rax,1)
    3b40:	add    $0x20,%rax
    3b44:	cmp    %rdx,%rax
    3b47:	jne    3b30 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x60>
    3b49:	mov    %rcx,%rax
    3b4c:	and    $0xfffffffffffffffc,%rax
    3b50:	test   $0x3,%cl
    3b53:	je     3ba0 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0xd0>
    3b55:	vzeroupper
    3b58:	sub    %rax,%rcx
    3b5b:	cmp    $0x1,%rcx
    3b5f:	je     3b85 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0xb5>
    3b61:	lea    0x0(,%rax,8),%rdx
    3b69:	vmovupd (%rdi,%rdx,1),%xmm2
    3b6e:	vmulpd (%rsi,%rdx,1),%xmm2,%xmm0
    3b73:	vmovupd %xmm0,(%r9,%rdx,1)
    3b79:	test   $0x1,%cl
    3b7c:	je     3b0b <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3b>
    3b7e:	and    $0xfffffffffffffffe,%rcx
    3b82:	add    %rcx,%rax
    3b85:	shl    $0x3,%rax
    3b89:	vmovsd (%rdi,%rax,1),%xmm0
    3b8e:	vmulsd (%rsi,%rax,1),%xmm0,%xmm0
    3b93:	vmovsd %xmm0,(%r9,%rax,1)
    3b99:	vxorpd %xmm0,%xmm0,%xmm0
    3b9d:	ret
    3b9e:	xchg   %ax,%ax
    3ba0:	vzeroupper
    3ba3:	jmp    3b0b <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x3b>
    3ba8:	xor    %eax,%eax
    3baa:	jmp    3b58 <double mul<double>(double*, double*, double*, unsigned long, unsigned long)+0x88>
    3bac:	nopl   0x0(%rax)

0000000000003bb0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)>:
    3bb0:	endbr64
    3bb4:	cmp    $0x1,%r8
    3bb8:	je     3bf0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x40>
    3bba:	test   %rcx,%rcx
    3bbd:	je     3ca0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xf0>
    3bc3:	shl    $0x3,%r8
    3bc7:	xor    %eax,%eax
    3bc9:	xor    %edx,%edx
    3bcb:	vxorpd %xmm1,%xmm1,%xmm1
    3bcf:	nop
    3bd0:	vmovsd (%rdi,%rax,1),%xmm0
    3bd5:	inc    %rdx
    3bd8:	vmulsd (%rsi,%rax,1),%xmm0,%xmm0
    3bdd:	add    %r8,%rax
    3be0:	vaddsd %xmm0,%xmm1,%xmm1
    3be4:	cmp    %rdx,%rcx
    3be7:	jne    3bd0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x20>
    3be9:	vmovsd %xmm1,%xmm1,%xmm0
    3bed:	ret
    3bee:	xchg   %ax,%ax
    3bf0:	test   %rcx,%rcx
    3bf3:	je     3ca0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xf0>
    3bf9:	lea    -0x1(%rcx),%rax
    3bfd:	cmp    $0x2,%rax
    3c01:	jbe    3cb8 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x108>
    3c07:	mov    %rcx,%rdx
    3c0a:	xor    %eax,%eax
    3c0c:	vxorpd %xmm0,%xmm0,%xmm0
    3c10:	shr    $0x2,%rdx
    3c14:	shl    $0x5,%rdx
    3c18:	nopl   0x0(%rax,%rax,1)
    3c20:	vmovupd (%rsi,%rax,1),%ymm4
    3c25:	vmulpd (%rdi,%rax,1),%ymm4,%ymm1
    3c2a:	add    $0x20,%rax
    3c2e:	vaddpd %ymm1,%ymm0,%ymm0
    3c32:	cmp    %rax,%rdx
    3c35:	jne    3c20 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x70>
    3c37:	vextractf128 $0x1,%ymm0,%xmm3
    3c3d:	mov    %rcx,%rax
    3c40:	vaddpd %xmm0,%xmm3,%xmm2
    3c44:	and    $0xfffffffffffffffc,%rax
    3c48:	vaddpd %xmm3,%xmm0,%xmm0
    3c4c:	vunpckhpd %xmm2,%xmm2,%xmm1
    3c50:	vaddpd %xmm2,%xmm1,%xmm1
    3c54:	test   $0x3,%cl
    3c57:	je     3cb0 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x100>
    3c59:	vzeroupper
    3c5c:	sub    %rax,%rcx
    3c5f:	cmp    $0x1,%rcx
    3c63:	je     3c88 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xd8>
    3c65:	vmovupd (%rdi,%rax,8),%xmm6
    3c6a:	vfmadd231pd (%rsi,%rax,8),%xmm6,%xmm0
    3c70:	vunpckhpd %xmm0,%xmm0,%xmm1
    3c74:	vaddpd %xmm0,%xmm1,%xmm1
    3c78:	test   $0x1,%cl
    3c7b:	je     3be9 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x39>
    3c81:	and    $0xfffffffffffffffe,%rcx
    3c85:	add    %rcx,%rax
    3c88:	vmovsd (%rdi,%rax,8),%xmm5
    3c8d:	vfmadd231sd (%rsi,%rax,8),%xmm5,%xmm1
    3c93:	vmovsd %xmm1,%xmm1,%xmm0
    3c97:	ret
    3c98:	nopl   0x0(%rax,%rax,1)
    3ca0:	vxorpd %xmm1,%xmm1,%xmm1
    3ca4:	jmp    3be9 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x39>
    3ca9:	nopl   0x0(%rax)
    3cb0:	vzeroupper
    3cb3:	jmp    3be9 <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0x39>
    3cb8:	vxorpd %xmm0,%xmm0,%xmm0
    3cbc:	xor    %eax,%eax
    3cbe:	vxorpd %xmm1,%xmm1,%xmm1
    3cc2:	jmp    3c5c <double dot<double>(double*, double*, double*, unsigned long, unsigned long)+0xac>
    3cc4:	cs nopw 0x0(%rax,%rax,1)
    3cce:	xchg   %ax,%ax

