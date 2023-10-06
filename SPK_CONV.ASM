
public	spk_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

spk_module	dw	spk_work_init
		dw	spk_detect_header
		dw	spk_reserve_header
		dw	spk_make_header
		dw	spk_get_data
		dw	spk_adpcm_pcm
		dw	spk_pcm_adpcm
		dw	spk_put_data
		db	1
		db	'SPK'
		db	'M'

spk_detect_header:
		ret
spk_reserve_header:
		ret
spk_make_header:
		ret

spk_get_data:
		lodsb
		ret
spk_put_data:
		stosb
		ret
spk_work_init:
		ret

spk_adpcm_pcm:
;entry		al
;exit		ax

		mov	ah,al
		xor	al,al
		sub	ax,8000h
		ret


spk_pcm_adpcm:
;entry		ax
;exit		al

		add	ax,8000h
		mov	al,ah
		ret


code	ends
	end

