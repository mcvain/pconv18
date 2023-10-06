
public	pc8_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

pc8_module	dw	pc8_work_init
		dw	pc8_detect_header
		dw	pc8_reserve_header
		dw	pc8_make_header
		dw	pc8_get_data
		dw	pc8_adpcm_pcm
		dw	pc8_pcm_adpcm
		dw	pc8_put_data
		db	1
		db	'PC8'
		db	'B'

pc8_detect_header:
		ret
pc8_reserve_header:
		ret
pc8_make_header:
		ret


pc8_get_data:
		lodsb
		ret
pc8_put_data:
		stosb
		ret
pc8_work_init:
		ret

pc8_adpcm_pcm:
;entry		al
;exit		ax

		mov	ah,al
		xor	al,al
		ret


pc8_pcm_adpcm:
;entry		ax
;exit		al

		mov	al,ah
		ret


code	ends
	end

