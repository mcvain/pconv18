
public	wav_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

extrn	src_header:near
extrn	dst_header:near

wav_module	dw	wav_work_init
		dw	wav_detect_header
		dw	wav_reserve_header
		dw	wav_make_header
		dw	wav_get_data
		dw	wav_adpcm_pcm
		dw	wav_pcm_adpcm
		dw	wav_put_data
		db	2
		db	'WAV'
		db	'V'

wav_header	struc
wav_riff	db	4 dup(?)
wav_file_size	dd	?
wav_wavefmt	db	8 dup(?)
wav_head_size	dd	?
wav_data_type	dw	?
wav_channels1	dw	?
wav_rate	dd	?
wav_rate_avg	dd	?
wav_channels2	dw	?
wav_smpl_bits	dw	?
wav_data	db	4 dup(?)
wav_pcm_size	dd	?
wav_header	ends


wav_work	struc
pcm_count	dd	?
pcm_bits	dw	?
pcm_channels	db	?
wav_work	ends

wav_work_init:
		mov	word ptr [bp + pcm_count],0
		mov	word ptr [bp + pcm_count + 2],0
		mov	word ptr [bp + pcm_bits],8
		mov	byte ptr [bp + pcm_channels],1
		ret


wav_detect_header:
;entry		ds:si	data adr.
;exit		si

		xor	ah,ah
		mov	al,byte ptr [src_header + wav_smpl_bits]
		mov	[bp + pcm_bits],ax
		mov	al,byte ptr [src_header + wav_channels1]
		mov	[bp + pcm_channels],al
		mov	ax,word ptr [src_header + wav_rate]
		add	si,2ch
		ret

wav_reserve_header:
;entry		es:di	data adr.
;exit		di

		add	di,2ch
		ret


wav_make_header:
;entry		es:di	header adr.
;exit		di,cx

		mov	si,offset header_sample
		mov	cx,002ch
		rep	movsb

		mov	word ptr [dst_header + wav_rate],ax
		mov	word ptr [dst_header + wav_rate + 2],0

		mul	word ptr [bp + pcm_bits]
		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1
		mov	word ptr [dst_header + wav_rate_avg],ax
		mov	word ptr [dst_header + wav_rate_avg + 2],dx

		mov	al,byte ptr [bp + pcm_bits]
		mov	byte ptr [dst_header + wav_smpl_bits],al

		mov	dx,word ptr [bp + pcm_count + 2]
		mov	ax,word ptr [bp + pcm_count]
		mov	word ptr [dst_header + wav_pcm_size],ax
		mov	word ptr [dst_header + wav_pcm_size + 2],dx
		add	ax,0024h
		adc	dx,0
		mov	word ptr [dst_header + wav_file_size],ax
		mov	word ptr [dst_header + wav_file_size + 2],dx
		mov	cx,002ch
		ret

wav_get_data:
		cmp	word ptr [bp + pcm_bits],16
		jz	wav_get_data_16bit
		add	word ptr [bp + pcm_count],1
		adc	word ptr [bp + pcm_count + 2],0
		cmp	byte ptr [bp + pcm_channels],1
		jz	wav_get_8bit_mono
		push	bx
		lodsb
		xor	bh,bh
		mov	bl,al
		xor	ah,ah
		lodsb
		add	ax,bx
		pop	bx
		js	wav_get_8bit_under
		cmp	ax,100h
		jnc	wav_get_8bit_over
		mov	ah,al
		xor	al,al
		sub	ax,8000h
		ret
wav_get_8bit_over:
		mov	ax,7fffh
		ret
wav_get_8bit_under:
		mov	ax,8000h
		ret
wav_get_8bit_mono:
		lodsb
		mov	ah,al
		xor	al,al
		sub	ax,8000h
		ret


wav_get_data_16bit:
		add	word ptr [bp + pcm_count],2
		adc	word ptr [bp + pcm_count + 2],0
		cmp	byte ptr [bp + pcm_channels],1
		jz	wav_get_16bit_mono
		push	bx
		lodsw
		mov	bx,ax
		lodsw
		cwd
		add	ax,bx
		pop	bx
		adc	dx,0
		js	wav_get_16bit_under
		or	dx,dx
		jnz	wav_get_16bit_over
		ret
wav_get_16bit_over:
		mov	ax,7fffh
		ret
wav_get_16bit_under:
		mov	ax,8000h
		ret
wav_get_16bit_mono:
		lodsw
		ret


wav_put_data:
		cmp	word ptr [bp + pcm_bits],16
		jz	wav_put_data_16bit
		add	ax,8000h
		mov	al,ah
		stosb
		add	word ptr [bp + pcm_count],1
		adc	word ptr [bp + pcm_count + 2],0
		ret
wav_put_data_16bit:
		stosw
		add	word ptr [bp + pcm_count],2
		adc	word ptr [bp + pcm_count + 2],0
		ret



wav_adpcm_pcm:
;entry		ax
;exit		ax

		ret


wav_pcm_adpcm:
;entry		ax
;exit		ax

		ret


header_sample	db	'RIFF'			;
		dd	?			;
		db	'WAVEfmt '		;
		dd	10h			;header size
		dw	1			;wave type
		dw	1			;channels
		dd	22050			;rate
		dd	44100			;byte/sec
		dw	1			;tracks.
		dw	16			;bit/sample
		db	'data'			;
		dd	?			;

code	ends
	end

