
public	snd_module

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

extrn	src_header:near
extrn	dst_header:near
extrn	dst_file:near

snd_module	dw	snd_work_init
		dw	snd_detect_header
		dw	snd_reserve_header
		dw	snd_make_header
		dw	snd_get_data
		dw	snd_adpcm_pcm
		dw	snd_pcm_adpcm
		dw	snd_put_data
		db	1
		db	'SND'
		db	'S'

snd_header	struc
snd_name	db	8 dup(?)	;8文字の名前
snd_id		dd	?		;BIOS内のサウンド管理識別用ID
snd_size	dd	?		;ｻﾝﾌﾟﾘﾝｸﾞﾃﾞｰﾀの総バイト数
snd_lpoint	dd	?		;ループの開始点
snd_lleng	dd	?		;ループの長さ(0のときはループなし)
snd_rate	dw	?		;ｻﾝﾌﾟﾘﾝｸﾞ時のｻﾝﾌﾟﾘﾝｸﾞ周波数
snd_rate_fix	dw	?		;ｻﾝﾌﾟﾘﾝｸﾞ周波数に対する加減算値
snd_note	db	?		;ｻｳﾝﾄﾞﾃﾞｰﾀの基本音階
		db	?		;0にする
		dw	?		;0にする
snd_header	ends

wav_work	struc
pcm_count	dd	?
wav_work	ends


snd_work_init:
		mov	word ptr [bp + pcm_count],0
		mov	word ptr [bp + pcm_count + 2],0
		ret


snd_detect_header:
;entry		ds:si	data adr.
;exit		si
		xor	dx,dx
		mov	ax,word ptr [src_header + snd_rate]
		mov	bx,1000
		mul	bx
		mov	bx,62h
		div	bx
		add	si,20h
		ret

snd_reserve_header:
;entry		es:di	data adr.
;exit		di
		add	di,20h
		ret

snd_make_header:
;entry		es:di	header adr.
;exit		di,cx

		push	ax
		mov	cx,8
		mov	al,' '
		rep	stosb
		xor	al,al
		mov	cx,24
		rep	stosb
		pop	ax
		mov	bx,62h
		mul	bx
		mov	bx,1000
		div	bx
		mov	word ptr [dst_header + snd_rate],ax

		mov	byte ptr [dst_header + snd_note],3ch

		mov	word ptr [dst_header + snd_id],9f88h
		mov	word ptr [dst_header + snd_id + 2],0fc94h

		mov	dx,word ptr [bp + pcm_count + 2]
		mov	ax,word ptr [bp + pcm_count]
		mov	word ptr [dst_header + snd_size + 2],dx
		mov	word ptr [dst_header + snd_size],ax

		mov	si,offset dst_file
		mov	di,offset dst_header + snd_name
copy_snd_name_lop:
		lodsb
		cmp	al,'.'
		jz	copy_snd_name_end
		stosb
		jmp	copy_snd_name_lop
copy_snd_name_end:
		mov	cx,20h
		ret

snd_get_data:
		add	word ptr [bp + pcm_count],1
		adc	word ptr [bp + pcm_count + 2],0
		lodsb
		ret
snd_put_data:
		add	word ptr [bp + pcm_count],1
		adc	word ptr [bp + pcm_count + 2],0
		stosb
		ret


snd_adpcm_pcm:
;entry		al
;exit		ax

		or	al,al
		js	snd_plus0
		not	al
		mov	ah,al
		xor	al,al
		ret
snd_plus0:
		and	al,07fh
		mov	ah,al
		xor	al,al
		ret


snd_pcm_adpcm:
;entry		ax
;exit		al

		mov	al,ah
		or	al,al
		jns	snd_plus1
		not	al
		ret
snd_plus1:
		or	al,80h
		cmp	al,0ffh
		jz	snd_max
		ret
snd_max:
		mov	al,0feh
		ret


code	ends
	end

