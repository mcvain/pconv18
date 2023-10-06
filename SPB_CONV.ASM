
public	spb_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

spb_module	dw	spb_work_init
		dw	spb_detect_header
		dw	spb_reserve_header
		dw	spb_make_header
		dw	spb_get_data
		dw	spb_adpcm_pcm
		dw	spb_pcm_adpcm
		dw	spb_put_data
		db	1
		db	'SPB'
		db	'A'


spb_work	struc
delta_n		dw	?
delta_x		dw	?
delta_x2	dw	?
work_buf	db	?
nible_flg	db	?
spb_work	ends


spb_detect_header:
		ret
spb_reserve_header:
		ret
spb_make_header:
		ret

spb_get_data:
		xor	[bp + nible_flg],0ffh
		jz	spb_glow_nible
		mov	al,ds:[si]
		shr	al,1
		shr	al,1
		shr	al,1
		shr	al,1
		ret
spb_glow_nible:
		lodsb
		and	al,00001111b
		ret

spb_put_data:
		xor	[bp + nible_flg],0ffh
		jz	spb_plow_nible
		shl	al,1
		shl	al,1
		shl	al,1
		shl	al,1
		mov	[bp + work_buf],al
		ret
spb_plow_nible:
		or	al,[bp + work_buf]
		stosb
		ret


spb_work_init:
		mov	[bp + delta_n],127
		mov	[bp + delta_x],0
		mov	[bp + delta_x2],0
		mov	[bp + nible_flg],0
		ret


spb_adpcm_pcm:
;entry		al	adpcm data
;exit		ax	pcm data

		xor	ah,ah
		mov	bx,ax

		and	al,00000111b
		shl	al,1
		inc	al
		mul	word ptr [bp + delta_n]

		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1

		test	bl,00001000b
		jz	atop_deltap
		sub	word ptr [bp + delta_x],ax
		sbb	word ptr [bp + delta_x2],0
		jns	not_bound_over
		cmp	word ptr [bp + delta_x],8000h
		jnc	not_bound_over
		mov	word ptr [bp + delta_x],8000h
		mov	word ptr [bp + delta_x2],-1
		jmp	not_bound_over
atop_deltap:
		add	word ptr [bp + delta_x],ax
		adc	word ptr [bp + delta_x2],0
		js	not_bound_over
		cmp	word ptr [bp + delta_x],8000h
		jc	not_bound_over
		mov	word ptr [bp + delta_x],7fffh
		mov	word ptr [bp + delta_x2],0
not_bound_over:
		xor	dx,dx
		mov	ax,[bp + delta_n]
		shl	bx,1
		mul	word ptr [move_f + bx]

		shl	ax,1
		rcl	dx,1
		shl	ax,1
		rcl	dx,1
		mov	al,ah
		mov	ah,dl

		cmp	ax,127
		jc	atop_less_dn
		cmp	ax,24577
		jnc	atop_over_dn
		mov	[bp + delta_n],ax
		mov	ax,[bp + delta_x]
		ret
atop_less_dn:
		mov	word ptr [bp + delta_n],127
		mov	ax,[bp + delta_x]
		ret
atop_over_dn:
		mov	word ptr [bp + delta_n],24576
		mov	ax,[bp + delta_x]
		ret



spb_pcm_adpcm:
;entry		ax	pcm data
;exit		al	adpcm data

		xor	bx,bx
		sub	ax,[bp + delta_x]
		jge	opna_dp
		neg	ax
		mov	bl,00001000b
opna_dp:
		mov	cx,[bp + delta_n]
		shr	cx,1
		shr	cx,1			;	1/4
		xor	dx,dx
		div	cx
		cmp	ax,8
		jc	opna_tu
		mov	ax,7
opna_tu:
		or	bl,al
		mov	cl,bl			;	cl:adpcm data

		shl	al,1
		inc	al
		mul	[bp + delta_n]

		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1			;	1/8

		test	cl,00001000b
		jz	ptoa_deltap
		neg	ax
ptoa_deltap:
		add	[bp + delta_x],ax
		xor	dx,dx
		mov	ax,[bp + delta_n]
		shl	bx,1
		mul	word ptr [move_f + bx]

		shl	ax,1
		rcl	dx,1
		shl	ax,1
		rcl	dx,1
		mov	al,ah
		mov	ah,dl

		cmp	ax,127
		jc	ptoa_less_dn
		cmp	ax,24577
		jnc	ptoa_over_dn
		mov	[bp + delta_n],ax
		mov	al,cl
		ret
ptoa_less_dn:
		mov	word ptr [bp + delta_n],127
		mov	al,cl
		ret
ptoa_over_dn:
		mov	word ptr [bp + delta_n],24576
		mov	al,cl
		ret

	even
move_f		dw	 57, 57, 57, 57, 77,102,128,153
		dw	 57, 57, 57, 57, 77,102,128,153


code	ends
	end

