
public	phl_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

phl_module	dw	phl_work_init
		dw	phl_detect_header
		dw	phl_reserve_header
		dw	phl_make_header
		dw	phl_get_data
		dw	phl_adpcm_pcm
		dw	phl_pcm_adpcm
		dw	phl_put_data
		db	2
		db	'PHL'
		db	'H'


phl_detect_header:
		ret
phl_reserve_header:
		ret
phl_make_header:
		ret

phl_get_data:
		lodsw
		ret
phl_put_data:
		stosw
		ret
phl_work_init:
		ret

phl_adpcm_pcm:
;entry		ax
;exit		ax

		xchg	al,ah
		ret


phl_pcm_adpcm:
;entry		ax
;exit		ax

		xchg	al,ah
		ret


code	ends
	end

