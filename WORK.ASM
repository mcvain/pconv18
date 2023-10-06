
public	src_file,dst_file,src_work,dst_work,src_data_buf,dst_data_buf
public	src_header,dst_header
public	stack_top

code	segment	public 'CODE'

src_file	db	64 dup(?)
dst_file	db	64 dup(?)

src_work	db	64 dup(?)
dst_work	db	64 dup(?)

src_data_buf	db	1000h dup(?)
dst_data_buf	db	1000h dup(?)

src_header	db	100h dup(?)
dst_header	db	100h dup(?)


		db	200h dup(?)
stack_top:

code	ends
	end
