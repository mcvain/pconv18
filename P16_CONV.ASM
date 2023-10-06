
public	p16_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

p16_module	dw	p16_work_init
		dw	p16_detect_header
		dw	p16_reserve_header
		dw	p16_make_header
		dw	p16_get_data
		dw	p16_adpcm_pcm
		dw	p16_pcm_adpcm
		dw	p16_put_data
		db	2
		db	'P16'
		db	'W'


p16_detect_header:
		ret
p16_reserve_header:
		ret
p16_make_header:
		ret

p16_get_data:
		lodsw
		ret
p16_put_data:
		stosw
		ret
p16_work_init:
		ret

p16_adpcm_pcm:
;entry		ax
;exit		ax

		ret


p16_pcm_adpcm:
;entry		ax
;exit		ax

		ret


code	ends
	end

