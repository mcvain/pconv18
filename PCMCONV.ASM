

code	segment	public 'CODE'
	assume	cs:code,ds:code,es:code

bel		equ	07h
tab		equ	09h
lf		equ	0ah
cr		equ	0dh
eof		equ	1ah
ecr		equ	1bh
eos		equ	'$'


VER_NUM		equ	'1.8'
REV_CHR		equ	''
TYPE_MAX	equ	9	;	ｻﾎﾟｰﾄしてるPCMフォーマットの種類


module		struc
work_init	dw	?	;	fileから読みだし
detect_header	dw	?	;	ヘッダを読む
reserve_header	dw	?	;	ヘッダ分確保する
make_header	dw	?	;	ヘッダを作る
get_data	dw	?	;	データを拾う
get_pcm		dw	?	;	ADPCM=>PCMルーチン
get_adpcm	dw	?	;	PCM=>ADPCMルーチン
put_adpcm	dw	?	;	データを格納
data_size	db	?	;	最小サイズ
ext_name	db	3 dup(?);	拡張子名
opt_chr		db	?	;	オプションキャラクタ
module		ends


	org	0100h
start:

		cld
		mov	ax,cs
		mov	ds,ax
		mov	es,ax
		mov	ss,ax
		mov	sp,offset stack_top - 2

		mov	ah,09h
		mov	dx,offset msg_title
		int	21h

		call	main_work_init

		mov	si,0080h
		lodsb
		or	al,al
		jz	put_hlp

		call	get_files
		jc	err_end

		call	file_open
		jc	err_end
		call	init_pcm_module
		call	pcm_convert
		call	file_close
		mov	ax,4c00h
		int	21h

put_hlp:
		mov	ah,09h
		mov	dx,offset msg_hlp
		int	21h
forced_end:
		mov	ax,4c00h
		int	21h			;	terminate process

err_end:
		push	cs
		pop	ds
		push	dx
		mov	ah,09h
		mov	dx,offset msg_err
		int	21h
		pop	dx
		int	21h			;	display message
		mov	ax,4c01h
		int	21h			;	terminate process


skip_spc	proc	near

		lodsb
		cmp	al,' '
		jz	skip_spc
		cmp	al,tab
		jz	skip_spc
		cmp	al,cr
		jz	not_argv
		dec	si
		clc
		ret
not_argv:
		dec	si
		stc
		ret
skip_spc	endp


get_files	proc	near

		call	skip_spc
		call	get_num
		jc	vol_level_omit
		mov	[vol_level],ax
vol_level_omit:
		mov	di,offset src_file
		call	get_type_name
		jc	get_file_err
		mov	[src_module],bx
		call	get_num
		mov	[src_freq],ax
		mov	di,offset dst_file
		call	get_type_name
		mov	[dst_module],bx
		jc	get_file_err
		call	get_num
		mov	[dst_freq],ax

		mov	ax,[src_module]
		cmp	[dst_module],ax
		jnz	chk_dst_name
		cmp	byte ptr [dst_file],'.'
		jz	dst_file_omit
chk_dst_name:
		cmp	byte ptr [dst_file],'.'
		jz	set_dst_name
		cmp	byte ptr [dst_file],00h
		jnz	dst_file_exist
set_dst_name:
		mov	si,offset src_file
		mov	di,offset dst_file
copy_src_namel:
		lodsb
		stosb
		cmp	al,'.'
		jnz	copy_src_namel
		mov	ax,word ptr [bx + ext_name]
		stosw
		xor	ah,ah
		mov	al,byte ptr [bx + ext_name + 2]
		stosw
dst_file_exist:
		clc
		ret
get_file_err:
		mov	dx,offset msg_err_fname
		stc
		ret

dst_file_omit:
		mov	dx,offset msg_err_fdst
		stc
		ret

get_files	endp


get_type_name	proc	near
;entry			si:	source adr.
;			di:	file name adr.
		call	skip_spc
		cmp	al,'-'
		jz	get_pcm_type_opt
		cmp	al,'/'
		jnz	get_pcm_file_name
get_pcm_type_opt:
		lodsb
		lodsb
		call	chk_pcmtype_opt
		jnc	set_pcm_type
		ret				;	option 間違い
set_pcm_type:
		push	bx
		call	skip_spc
		call	get_file_name
		pop	bx
		or	ah,ah
		jz	recover_option		;	opsion 補完
		ret
recover_option:
		mov	byte ptr [di - 1],'.'
		mov	ax,word ptr [bx + ext_name]
		stosw
		xor	ah,ah
		mov	al,byte ptr [bx + ext_name + 2]
		stosw
		ret

get_pcm_file_name:
		call	get_file_name
		or	ah,ah
		jnz	chk_ext_type		;	拡張子よりﾀｲﾌﾟ判定
		stc
		ret
chk_ext_type:
		call	chk_pcmtype_ext
		ret

get_type_name	endp


get_file_name	proc	near
;entry			si:	src. adr.
;exit			di:	dst. adr.
;			bx:	ext. adr.
;			ah:	ext.flag
		xor	ah,ah
get_fn_loop:
		lodsb
		cmp	al,' '
		jz	get_fn_end
		cmp	al,tab
		jz	get_fn_end
		cmp	al,cr
		jz	get_fn_end
		cmp	al,'.'
		jz	get_fn_eadr
		stosb
		jmp	get_fn_loop
get_fn_eadr:
		mov	ah,0ffh
		mov	bx,si
		stosb
		jmp	get_fn_loop
get_fn_end:
		xor	al,al
		stosb
		ret

get_file_name	endp


chk_pcmtype_opt	proc	near
;entry			al:	option chr
;exit			bx:	module adr.

		push	ax
		push	cx
		push	dx
		push	si

		call	ucase
		mov	dl,al			;	option chr
		mov	cx,TYPE_MAX
		mov	si,offset module_tbl
chk_opt_lop:
		lodsw
		mov	bx,ax
		cmp	[bx + opt_chr],dl
		jz	find_opt_chr
		loop	chk_opt_lop
		stc
find_opt_chr:
		pop	si
		pop	dx
		pop	cx
		pop	ax
		ret


chk_pcmtype_opt	endp


chk_pcmtype_ext	proc	near
;entry			bx:	extention adr.
;exit			bx:	module adr.

		push	ax
		push	cx
		push	si
		push	di

		mov	di,bx			;	ext. adr.
		mov	cx,TYPE_MAX
		mov	si,offset module_tbl
chk_ext_lop:
		lodsw
		mov	bx,ax
		mov	al,[di]
		call	ucase
		cmp	byte ptr [bx + ext_name + 0],al
		jnz	chk_ext_next

		mov	al,[di + 1]
		call	ucase
		cmp	byte ptr [bx + ext_name + 1],al
		jnz	chk_ext_next

		mov	al,[di + 2]
		call	ucase
		cmp	byte ptr [bx + ext_name + 2],al
		jz	find_ext_chr
chk_ext_next:
		loop	chk_ext_lop
		stc
find_ext_chr:
		pop	di
		pop	si
		pop	cx
		pop	ax
		ret

chk_pcmtype_ext	endp


ucase		proc	near
		cmp	al,'a'
		jc	skip_large
		cmp	al,'z'
		ja	skip_large
		and	al,0dfh
skip_large:
		ret
ucase		endp


get_num		proc	near
;entry		ds:si	source	address
;exit		ax:	number (0 - 65535)
;		si:	source	next	address

		push	bx
		push	cx
		push	dx
		push	si

		xor	ax,ax
		xor	bx,bx
		mov	cx,10
get_numl:
		mov	bl,ds:[si]
		sub	bl,'0'
		cmp	bl,10
		jnc	get_nume
		inc	si
		mul	cx
		add	ax,bx
		jmp	get_numl

get_nume:
		pop	dx
		cmp	si,dx
		jz	get_numn	;	省略された
		pop	dx
		pop	cx
		pop	bx
		clc
		ret
get_numn:
		mov	si,dx
		pop	dx
		pop	cx
		pop	bx
		mov	ax,0ffffh
		stc
		ret
get_num		endp


init_pcm_module	proc	near

		mov	bx,[src_module]
		mov	bp,offset src_work
		call	[bx + work_init]

		mov	bx,[dst_module]
		mov	bp,offset dst_work
		call	[bx + work_init]
		ret

init_pcm_module	endp


file_open	proc	near

		mov	ax,3d00h
		mov	cx,0000h
		mov	dx,offset src_file
		int	21h			;	open handle
		mov	dx,offset msg_err_fopen
		jc	file_open_err
		mov	[src_handle],ax

		mov	ax,3c00h
		mov	cx,0000h
		mov	dx,offset dst_file
		int	21h			;	create handle
		mov	dx,offset msg_err_fcreate
		jc	file_open_err
		mov	[dst_handle],ax
		clc
		ret

file_open_err:
		stc
		ret

file_open	endp


file_close	proc	near

		mov	ah,3eh
		mov	bx,[src_handle]
		int	21h			;	close handle
		mov	bx,[dst_handle]
		int	21h			;	close handle
		clc
		ret

file_close	endp


main_work_init	proc	near
		mov	byte ptr [src_end],0
		mov	byte ptr [src_last],0
		mov	byte ptr [dst_status],0
		mov	word ptr [dst_data_adr],offset dst_data_buf
		mov	word ptr [dst_end_adr],offset dst_data_buf + 1000h
		mov	word ptr [abs_time],0
		mov	word ptr [src_diff],0
		mov	word ptr [dst_diff],0
		mov	word ptr [src_level],0
		mov	word ptr [dst_level],0
		ret
main_work_init	endp



pcm_convert	proc	near

		call	src_data_read
		jnc	not_min_sread
		or	byte ptr [src_last],0ffh
not_min_sread:
		mov	si,offset src_data_buf
		mov	di,offset src_header
		mov	cx,100h
		rep	movsb

		mov	bx,[src_module]
		mov	bp,offset src_work
		mov	si,[src_data_adr]
		mov	ax,[src_freq]
		call	[bx + detect_header]
		mov	[src_data_adr],si
		cmp	word ptr [src_freq],0ffffh
		jnz	src_freq_omit
		mov	[src_freq],ax
src_freq_omit:
		cmp	word ptr [dst_freq],0ffffh
		jnz	dst_freq_omit
		mov	[dst_freq],ax
dst_freq_omit:
		push	word ptr [src_freq]
		push	word ptr [dst_freq]

		mov	ax,[src_freq]
		or	ax,[dst_freq]
		jns	skip_div_freq
		shr	word ptr [src_freq],1
		shr	word ptr [dst_freq],1
skip_div_freq:
		mov	ax,[src_freq]
		xchg	ax,[dst_freq]
		mov	[src_freq],ax

		mov	bx,[dst_module]
		mov	bp,offset dst_work
		mov	di,[dst_data_adr]
		call	[bx + reserve_header]
		mov	[dst_data_adr],di

		call	read_pcm_src
normal_main:
		mov	ax,[abs_time]
		add	ax,[dst_freq]
		mov	[abs_time],ax

normal_main2:
		mov	ax,[abs_time]
		cmp	ax,[src_freq]
		jc	pcm_complement
		sub	ax,[src_freq]
		mov	[abs_time],ax

		mov	ax,[src_diff]
		add	[src_level],ax		;	変位
		call	read_pcm_src
		jmp	normal_main2

pcm_complement:
		mov	ax,[src_diff]		;	傾き
		imul	word ptr [abs_time]	;	分子
		idiv	word ptr [src_freq]	;	分母
		add	ax,[src_level]		;	最終変位

		imul	word ptr [vol_level]
		or	dx,dx
		mov	al,ah
		mov	ah,dl
		js	chk_min_level
		cmp	dx,0080h
		jc	set_level
		mov	ax,7fffh		;	最高レベル
		jmp	set_level
chk_min_level:
		cmp	dx,0ff80h
		jnc	set_level
		mov	ax,8000h		;	最低レベル
set_level:
		mov	bx,[dst_module]
		mov	bp,offset dst_work
		call	[bx + get_adpcm]
		mov	bx,[dst_module]
		mov	bp,offset dst_work
		mov	di,[dst_data_adr]
		call	[bx + put_adpcm]
		mov	[dst_data_adr],di

		cmp	[dst_end_adr],di
		jnz	nc_skip_dwrite
		call	dst_data_write
		jnc	nc_skip_dwrite
		or	byte ptr [dst_status],0ffh
nc_skip_dwrite:
		mov	al,[src_end]
		or	al,[dst_status]
		jnz	pcm_conv_end
		jmp	normal_main
pcm_conv_end:
		xor	ax,ax
		mov	bx,[dst_module]
		mov	bp,offset dst_work
		call	[bx + get_adpcm]
		mov	bx,[dst_module]
		mov	bp,offset dst_work
		mov	di,[dst_data_adr]
		call	[bx + put_adpcm]
		mov	[dst_data_adr],di

		pop	word ptr [dst_freq]
		pop	word ptr [src_freq]

		mov	bx,[dst_module]
		mov	di,[dst_data_adr]
	;	xor	ah,ah
	;	mov	al,[bx + data_size]
	;	add	di,ax
		call	dst_data_write

		mov	ax,4200h
		mov	bx,[dst_handle]
		xor	cx,cx
		xor	dx,dx
		int	21h

		mov	bx,[dst_module]
		mov	bp,offset dst_work
		xor	cx,cx
		mov	ax,[dst_freq]
		mov	di,offset dst_header
		call	[bx + make_header]
		or	cx,cx
		jz	skip_write_header

		mov	ah,40h
		mov	bx,[dst_handle]
		mov	dx,offset dst_header
		int	21h
skip_write_header:
		ret

pcm_convert	endp


read_pcm_src	proc	near

		mov	bx,[src_module]
		mov	bp,offset src_work
		mov	si,[src_data_adr]
		call	[bx + get_data]
		mov	[src_data_adr],si

		cmp	[src_end_adr],si
		ja	nc_skip_sread
		cmp	byte ptr [src_last],00h
		jz	nc_next_sread
		or	byte ptr [src_end],0ffh
		jmp	nc_skip_sread
nc_next_sread:
		call	src_data_read
		jnc	nc_skip_sread
		or	byte ptr [src_last],0ffh
		or	bx,bx
		jnz	nc_skip_sread
		or	byte ptr [src_end],0ffh
nc_skip_sread:
		mov	bx,[src_module]
		mov	bp,offset src_work
		call	[bx + get_pcm]
		sub	ax,[src_level]		;	ax:	変移
		mov	[src_diff],ax

		ret

read_pcm_src	endp


src_data_read	proc	near
		push	ax
		mov	ah,3fh
		mov	bx,[src_handle]
		mov	cx,1000h
		mov	dx,offset src_data_buf
		int	21h
		mov	bx,ax
		mov	si,offset src_data_buf
		lea	ax,[si + bx]
		mov	[src_end_adr],ax
		mov	[src_data_adr],si
		cmp	bx,1000h
		pop	ax
		ret
src_data_read	endp


dst_data_write	proc	near
		push	ax
		mov	ah,40h
		mov	bx,[dst_handle]
		mov	cx,di
		mov	dx,offset dst_data_buf
		sub	cx,dx
		int	21h
		mov	di,offset dst_data_buf
		mov	[dst_data_adr],di
		mov	[dst_end_adr],offset dst_data_buf + 1000h
		cmp	ax,1000h
		pop	ax
		ret
dst_data_write	endp



msg_title	db	'PCM converter PCMCONV ver'
		db	VER_NUM,REV_CHR
		db	' (c)T.K',cr,lf,eos

msg_hlp	db	'usage: PCMCONV [level][src opt.] src file [src freq.]',cr,lf
	db	'                      [dst opt.][dst file][dst freq.]',cr,lf
	db	'level:          PCM volume(1/256)',cr,lf
	db	'src&dst opt.:   /a   OPNA ADPCM type',cr,lf
	db	'                /x   X68k ADPCM type',cr,lf
	db	'                /m    Mac  PCM  type',cr,lf
	db	'                /s   TOWNS PCM  type',cr,lf
	db	'                /n    4bit PCM  type',cr,lf
	db	'                /b    8bit PCM  type',cr,lf
	db	'                /w   16bit(l,h) type',cr,lf
	db	'                /h   16bit(h,l) type',cr,lf
;	db	'                /v   MS-Windows type',cr,lf
	db	'frequency:      PCM sampling rate',cr,lf
	db	eos

msg_err		db	'error:',eos
msg_err_fopen	db	"can't open source file.",cr,lf,eos
msg_err_fcreate	db	"can't create distnation file.",cr,lf,eos
msg_err_fname	db	'invalid file name.',cr,lf,eos
msg_err_fdst	db	'too few command line parameters',cr,lf,eos

extrn		spb_module:near		;	OPNA	タイプ
extrn		x68_module:near		;	M6258	タイプ
extrn		snd_module:near		;	R5FC	タイプ
extrn		spk_module:near		;	MAC	タイプ
extrn		spc_module:near		;	SSGPCM	タイプ
extrn		pc8_module:near		;	8bitPCM	タイプ
extrn		p16_module:near		;	16bitPCMタイプ
extrn		phl_module:near		;	16bitPCMタイプ
extrn		wav_module:near		;	MS-Windowsタイプ

	even
module_tbl	dw	spb_module	;	OPNA	タイプ
		dw	x68_module	;	M6258	タイプ
		dw	snd_module	;	R5FC	タイプ
		dw	spk_module	;	MAC     タイプ
		dw	spc_module	;	SSGPCM	タイプ
		dw	pc8_module	;	8bitPCM	タイプ
		dw	p16_module	;	16bitPCMタイプ
		dw	phl_module	;	16bitPCMタイプ
		dw	wav_module	;	Windows waveタイプ


src_module	dw	?
dst_module	dw	?
src_end		db	?
src_last	db	?
dst_status	db	?

	even
vol_level	dw	256

src_freq	dw	0ffffh
dst_freq	dw	0ffffh

abs_time	dw	?
src_level	dw	?
dst_level	dw	?
src_diff	dw	?
dst_diff	dw	?

lastpcm_l	dw	?
lastpcm_h	dw	?

src_handle	dw	?
dst_handle	dw	?

src_data_adr	dw	?
src_end_adr	dw	?
dst_data_adr	dw	?
dst_end_adr	dw	?

extrn		src_file:near		;入力ファイル名
extrn		dst_file:near		;出力ファイル名
extrn		src_work:near		;ソースワーク
extrn		dst_work:near		;ﾃﾞｨｽﾄﾈワーク
extrn		src_data_buf:near	;ソースバッファ
extrn		dst_data_buf:near	;ﾃﾞｨｽﾄﾈバッファ
extrn		src_header:near		;ソースヘッダ
extrn		dst_header:near		;ﾃﾞｨｽﾄﾈヘッダ
extrn		stack_top:near		;スタック上限

code	ends
	end	start


