
public	spc_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

spc_module	dw	spc_work_init
		dw	spc_detect_header
		dw	spc_reserve_header
		dw	spc_make_header
		dw	spc_get_data
		dw	spc_adpcm_pcm
		dw	spc_pcm_adpcm
		dw	spc_put_data
		db	1
		db	'SPC'
		db	'N'

spb_work	struc
work_buf	db	?
nible_flg	db	?
spb_work	ends

spc_detect_header:
		ret
spc_reserve_header:
		ret
spc_make_header:
		ret

spc_get_data:
		xor	[bp + nible_flg],0ffh
		jz	spc_glow_nible
		mov	al,ds:[si]
		shr	al,1
		shr	al,1
		shr	al,1
		shr	al,1
		ret
spc_glow_nible:
		lodsb
		and	al,00001111b
		ret

spc_put_data:
		xor	[bp + nible_flg],0ffh
		jz	spc_plow_nible
		shl	al,1
		shl	al,1
		shl	al,1
		shl	al,1
		mov	[bp + work_buf],al
		ret
spc_plow_nible:
		or	al,[bp + work_buf]
		stosb
		ret

spc_work_init:
		mov	[bp + nible_flg],0
		ret


spc_adpcm_pcm:
;entry		al
;exit		ax

		mov	ah,al
		xor	al,al
		shl	ax,1
		shl	ax,1
		shl	ax,1
		shl	ax,1
		sub	ax,8000h
		ret


spc_pcm_adpcm:
;entry		ax
;exit		al

		add	ax,8000h
		mov	al,ah
		shr	al,1
		shr	al,1
		shr	al,1
		shr	al,1
		ret


code	ends
	end


