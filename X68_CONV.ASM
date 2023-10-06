
public	x68_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

x68_module	dw	x68_work_init
		dw	x68_detect_header
		dw	x68_reserve_header
		dw	x68_make_header
		dw	x68_get_data
		dw	x68_adpcm_pcm
		dw	x68_pcm_adpcm
		dw	x68_put_data
		db	1
		db	'PCM'
		db	'X'


x68_work	struc
s_level		dw	?
a_level		dw	?
work_buf	db	?
nible_flg	db	?
x68_work	ends


x68_detect_header:
		ret
x68_reserve_header:
		ret
x68_make_header:
		ret

x68_get_data:
		xor	[bp + nible_flg],0ffh
		jz	x68_glow_nible
		mov	al,ds:[si]
		and	al,00001111b
		ret
x68_glow_nible:
		lodsb
		shr	al,1
		shr	al,1
		shr	al,1
		shr	al,1
		ret

x68_put_data:
		xor	[bp + nible_flg],0ffh
		jz	x68_plow_nible
		mov	[bp + work_buf],al
		ret
x68_plow_nible:
		shl	al,1
		shl	al,1
		shl	al,1
		shl	al,1
		or	al,[bp + work_buf]
		stosb
		ret




x68_work_init:
		mov	word ptr [bp + s_level],0
		mov	word ptr [bp + a_level],0
		mov	word ptr [bp + nible_flg],0
		ret


x68_pcm_adpcm:
;entry		ax	pcm data
;exit		al	adpcm data

		sar	ax,1
		sar	ax,1
		sar	ax,1
		sar	ax,1
		sar	ax,1
		sar	ax,1

		xor	cl,cl
		sub	ax,[bp + a_level]	;	前回との差分
		jns	pcm_vup
		mov	cl,00001000b
		neg	ax
pcm_vup:
		xor	dx,dx
		mov	bx,[bp + s_level]
		mov	bx,[scl_tbl + bx]
		shr	bx,1
		shr	bx,1
		shr	bx,1
		div	bx
		cmp	ax,16
		jc	pcm_mlt
		mov	al,7
		or	al,cl
		push	ax
		call	x68_adpcm_pcm		;	次回の用意
		pop	ax
		ret
pcm_mlt:
		dec	al
		js	pcm_mmin
		shr	al,1
		or	al,cl
		push	ax
		call	x68_adpcm_pcm		;	次回の用意
		pop	ax
		ret
pcm_mmin:
		mov	al,cl
		push	ax
		call	x68_adpcm_pcm		;	次回の用意
		pop	ax
		ret


x68_adpcm_pcm:
;entry		al	adpcm data
;exit		ax	pcm data

		mov	cl,al
		mov	bx,[bp + s_level]
		and	al,00000111b
		shl	al,1
		inc	al
		cbw
		mul	word ptr [scl_tbl + bx]
		shr	ax,1
		shr	ax,1
		shr	ax,1			;	1/8

		mov	dx,[bp + a_level]
		test	cl,00001000b
		jz	pcm_addt
		neg	ax
pcm_addt:
		add	ax,dx
		js	pcm_less0
		cmp	ax,512
		jc	pcm_com
		mov	ax,511
		jmp	pcm_com
pcm_less0:
		cmp	ax,-512
		jnc	pcm_com
		mov	ax,-512
pcm_com:
		mov	[bp + a_level],ax	;	pcm level
		shl	ax,1
		shl	ax,1
		shl	ax,1
		shl	ax,1
		shl	ax,1
		shl	ax,1

		mov	dx,bx			;	s_level

		mov	bl,cl
		shl	bx,1			;	bh は常に 0
		add	dx,[scl_chg + bx]
		js	slv_subt
		cmp	dx,48*2 + 1
		jnc	slv_addt
		mov	[bp + s_level],dx
		ret
slv_subt:
		mov	word ptr [bp + s_level],0
		ret
slv_addt:
		mov	word ptr [bp + s_level],48*2
		ret


	even
scl_chg		dw	-1*2
		dw	-1*2
		dw	-1*2
		dw	-1*2
		dw	+2*2
		dw	+4*2
		dw	+6*2
		dw	+8*2

		dw	-1*2
		dw	-1*2
		dw	-1*2
		dw	-1*2
		dw	+2*2
		dw	+4*2
		dw	+6*2
		dw	+8*2

scl_tbl		dw	0010h,0011h,0013h,0015h
		dw	0017h,0019h,001ch,001fh
		dw	0022h,0025h,0029h,002dh
		dw	0032h,0037h,003ch,0042h
		dw	0049h,0050h,0058h,0061h
		dw	006bh,0076h,0082h,008fh
		dw	009dh,00adh,00beh,00d1h
		dw	00e6h,00fdh,0117h,0133h
		dw	0151h,0173h,0198h,01c1h
		dw	01eeh,0220h,0256h,0292h
		dw	02d4h,031ch,036ch,03c3h
		dw	0424h,048eh,0502h,0583h
		dw	0610h

code	ends
	end

