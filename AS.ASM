;
;    ASURA Status ver 1.00
;

ofs_tbl	equ	0c00h

mlk_top	equ	0dh
mlq_top	equ	14h

code	segment
	assume	CS:code,DS:code
	
	org	100h
start:
	mov	DX,offset mes_t1
	mov	AH,9
	int	21h
	
	xor	AX,AX
	mov	DS,AX
	mov	DS,[DS:018ah]
	mov	SI,0f0h
	
	mov	AX,CS
	mov	ES,AX
	mov	DI,0cf0h
	mov	CX,0588h
	cld
	
	cli
	rep movsw
	sti
	
	mov	DS,AX		;DS=CS
	
	mov	CH,[run_tsk]	;CH=run_tsk
	mov	BX,ofs_tbl+300h
t_loop:
	test	BL,0ch
	jnz	t_main0
	
	mov	AL,BL
	shr	AL,1
	shr	AL,1
	
	call	hex_cnv
	mov	word ptr mes_t2+8,AX
	
	mov	DX,offset mes_t2
	mov	AH,9
	int	21h
t_main0:
	mov	AX,[BX]	;AL=tskstat
				;AH=wupcnt+1
	
	and	AL,AL		;tskstat=noexsit?
	jnz	t_main1
	
	mov	DX,offset mes_t3n
	mov	AH,9
	int	21h
	
	jmp	t_int3
t_main1:
	test	AL,10h		;tskstat=dormant?
	jz	t_main2
	
	mov	DX,offset mes_t3d
	mov	AH,9
	int	21h
	
	mov	AL,[BX+3]	;AL=ipri
	mov	DX,offset mes_t3q
	jmp	t_int2
t_main2:
	cmp	BL,CH		;tskstat=run?
	jnz	t_main3
	
	mov	DX,offset mes_t3u
	mov	AH,9
	int	21h
	
	jmp	t_int1
t_main3:
	test	byte ptr [BX-1ffh],0ffh	;suspend?
	jz	t_main4
	
	mov	DX,offset mes_t3s
	mov	AH,9
	int	21h
	
	jmp	t_int1
t_main4:
	and	AH,AH		;sleep?
	jnz	t_main5
	
	mov	DX,offset mes_t3l
	mov	AH,9
	int	21h
	
	jmp	t_int1
t_main5:
	test	AL,4		;tskstat=wait?
	jz	t_main6
	
	mov	DX,offset mes_t3w
	mov	AH,9
	int	21h
	
	jmp	t_int1
t_main6:
	mov	DX,offset mes_t3r
	mov	AH,9
	int	21h
t_int1:
	mov	DX,[BX+2]	;DL=pri
				;DH=ipri
	
	mov	AL,DL
	sar	AL,1
	sar	AL,1
	
	call	hex_cnv
	mov	word ptr mes_t3p,AX
	
	mov	AL,DH
	mov	DX,offset mes_t3p
t_int2:
	sar	AL,1
	sar	AL,1
	
	call	hex_cnv
	mov	word ptr mes_t3q,AX
	
	mov	AH,9
	int	21h
t_int3:
	add	BL,4
	jz	t_end
	jmp	t_loop
t_end:
	mov	DX,offset mes_t4
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_r1d
	and	byte ptr dsp_flg,0ffh
	jnz	r_tit1
	
	mov	DX,offset mes_r1e
r_tit1:
	int	21h
	
	mov	CH,run_tsk
	mov	BX,ofs_tbl+103h		;pri=1‚Ìƒ|ƒCƒ“ƒ^
r_pri:
	mov	AL,[BX]	;AL=nxt_ptr
	xchg	AL,BL
	
	test	BL,3
	jnz	r_pri
	
			;‚»‚Ìpri ‚Ìæ“ªƒ^ƒXƒN
	shr	AL,1	;AL=Œ»pri
	shr	AL,1
	inc	AL
	and	AL,1fh
	call	hex_cnv
	mov	word ptr mes_r2p+6,AX
	
	mov	DX,offset mes_r2p
	mov	AH,9
	int	21h
r_p2t1:
	mov	DI,offset mes_r4a
	mov	byte ptr [DI],'$'
r_tsk:
	mov	DX,offset mes_t3u
	cmp	BL,CH		;CH=run_tsk
	jz	r_tsk1
	
	mov	DX,offset mes_t3r
	test	byte ptr [BX+1],0ffh	;suscnt
	jz	r_tsk1
	
	mov	DX,offset mes_t3s
r_tsk1:
	mov	AH,9
	int	21h
	
	mov	AL,BL		;BL=tskid
	shr	AL,1
	shr	AL,1
	call	hex_cnv
	
	mov	word ptr mes_t3q,AX
	mov	DX,offset mes_t3q
	mov	AH,9
	int	21h
	
	mov	byte ptr [DI],' '
	
	mov	AL,[BX+1]		;suscnt
	call	hex_cnv
	mov	word ptr [DI+0ah],AX
	
	mov	AL,[BX+201h]		;wupcnt
	dec	AL
	call	hex_cnv
	mov	word ptr [DI+05h],AX
	
	add	DI,0ch
	mov	byte ptr [DI],'$'
	
	mov	BL,[BX]
	test	BL,3
	jz	r_t2t
	
	mov	DX,offset mes_r4
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_cr
	int	21h
	
	cmp	BL,3
	jz	com__s
	
	jmp	r_pri
r_t2t:
	cmp	DI,offset mes_r4b
	jnz	r_tsk
	
	mov	DX,offset mes_r4
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_cr
	int	21h
	
	mov	DX,offset mes_r2n
	int	21h
	
	jmp	r_p2t1
	
com__s:
	mov	DX,offset mes_s1
	mov	AH,9
	int	21h
	
	mov	BX,ofs_tbl+183h	;semid=1
s_nxtsem:
	add	BL,4
	jc	s_end
	
	mov	AL,[BX]
	
	xor	AL,BL
	jz	s_notsk		;‘Ò‚¿ƒ^ƒXƒN‚ª‚È‚¢
	test	AL,3
	jnz	s_waiq
	
	jmp	s_nxtsem
s_end:
	jmp	com__f
	
s_notsk:
				;BL=semid
	mov	AL,BL
	and	AL,7fh
	shr	AL,1
	shr	AL,1
	call	hex_cnv
	mov	word ptr mes_s2p+6,AX
	
	mov	DX,offset mes_s2p
	mov	AH,9
	int	21h
	
	mov	AL,[BX+700h]
	call	hex_cnv
	mov	word ptr mes_s3c+7,AX
	
	mov	DX,offset mes_s3c
	mov	AH,9
	int	21h
	
	jmp	s_nxtsem
	
s_waiq:
				;BL=semid
	mov	AL,BL
	and	AL,7fh
	shr	AL,1
	shr	AL,1
	call	hex_cnv
	mov	word ptr mes_s2p+6,AX
	
	mov	DX,offset mes_s2p
	mov	AH,9
	int	21h
	
	mov	CL,0
s_waiq1:
	mov	BL,[BX]		;BL=nxt_lnk
	test	BL,3
	jnz	s_waiq5
	
	cmp	CL,5
	jnz	s_waiq2
	
	mov	CL,0
	mov	DX,offset mes_s2n
	mov	AH,9
	int	21h
s_waiq2:
	inc	CL
	
	test	byte ptr [BX+1],0ffh	;suscnt
	jz	s_waiq3
	
	mov	DX,offset mes_t3s
	jmp	s_waiq4
s_waiq3:
	mov	DX,offset mes_t3w
s_waiq4:
	mov	AH,9
	int	21h
	
	mov	AL,BL
	shr	AL,1
	shr	AL,1
	call	hex_cnv
	mov	word ptr mes_t3q,AX
	
	mov	DX,offset mes_t3q
	mov	AH,9
	int	21h
	
	jmp	s_waiq1
	
s_waiq5:
	mov	DX,offset mes_cr
	mov	AH,9
	int	21h
	
	jmp	s_nxtsem
	
com__f:
	mov	DX,offset mes_f1
	mov	AH,9
	int	21h
	
	mov	BX,ofs_tbl+0282h	;flgid=0
f_nxtflg:
	add	BL,4
	jc	f_end
	mov	CL,[BX]	;CL=nxt_ptr
	
	xor	CL,BL
	jz	f_head
	test	CL,3
	jnz	f_head
	
	jmp	f_nxtflg
f_end:
	jmp	com__m
	
f_head:
	xor	CL,BL		;CL=nxt_ptr
	
	mov	AL,BL
	and	AL,07fh
	shr	AL,1
	shr	AL,1
	
	call	hex_cnv
	
	mov	word ptr mes_f2p+6,AX
	
	mov	DX,offset mes_f2p
	mov	AH,9
	int	21h
	
	mov	DX,[BX+400h]	;AX=flgptn
	
	mov	AL,DH
	call	hex_cnv
	mov	word ptr mes_f4+3,AX
	
	mov	AL,DL
	call	hex_cnv
	mov	word ptr mes_f4+5,AX
	
	mov	AL,'m'
	test	byte ptr [BX+600h],8
	jnz	f_head2
	
	mov	AL,'s'
f_head2:
	mov	mes_f4+9,AL
	
	mov	DI,offset mes_f4a
	mov	byte ptr [DI],'$'
	
f_tsk:
	mov	BL,CL		;BL=nxt_ptr
	test	CL,3
	jz	f_tsk1
	
	mov	DX,offset mes_f4
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_cr
	mov	AH,9
	int	21h
	
	jmp	f_nxtflg
	
f_tsk1:
	mov	CX,[BX]		;CH=flgatr
				;CL=nxt_ptr
	
	cmp	DI,offset mes_f4b
	jnz	f_tsk2
	
	mov	DX,offset mes_f4
	mov	AH,9
	int	21h
	
	mov	AX,'  '
	
	mov	word ptr mes_f4+3,AX
	mov	word ptr mes_f4+5,AX
	mov	mes_f4+9,AL
	
	mov	DX,offset mes_s2n
	mov	AH,9
	int	21h
	
	mov	DI,offset mes_f4a
	mov	byte ptr [DI],'$'
	
f_tsk2:
	mov	DX,offset mes_t3w
	test	byte ptr [BX-0ffh],0ffh	;suscnt
	jz	f_tsk3
	
	mov	DX,offset mes_t3s
f_tsk3:
	mov	AH,9
	int	21h
	
	mov	AL,BL
	shr	AL,1
	shr	AL,1
	
	call	hex_cnv
	mov	word ptr mes_t3q,AX	;tskid
	
	mov	DX,offset mes_t3q
	mov	AH,9
	int	21h
	
	mov	byte ptr [DI],' '
	
	mov	DX,[BX+200h]	;flgptn
	
	mov	AL,DH
	call	hex_cnv
	mov	[DI+4],AX
	
	mov	AL,DL
	call	hex_cnv
	mov	[DI+6],AX
	
	mov	AX,' a'
	test	CH,1
	jz	f_tsk4
	mov	AH,'c'
f_tsk4:
	test	CH,2
	jz	f_tsk5
	mov	AL,'o'
f_tsk5:
	mov	[DI+0ah],AX
	
	add	DI,0ch
	mov	byte ptr [DI],'$'
	
	jmp	f_tsk
	
com__m:
	cli
	xor	AX,AX
	mov	ES,AX
	mov	AX,[018ah]
	mov	ES,AX
	
	mov	AX,400h		;04h for dBX, 00h for counter
	mov	BX,ofs_tbl+800h	;top_mlq
m_cnt1:
	cmp	BL,[BX]
	jnz	m_cnt2
	
	inc	AL
m_cnt2:
	sub	BL,AH
	jnz	m_cnt1
				;AL=free count
	call	hex_cnv
	
	mov	word ptr mes_m1+18h,AX
	mov	DX,offset mes_m1
	mov	AH,9
	int	21h
	
	mov	BX,ofs_tbl+0102h	;mbxid=0
m_nxtmbx:
	add	BL,4
	cmp	BL,80h
	jnc	m_end
	
	mov	AL,[BX]
	
	xor	AL,BL
	jz	m_notsk		;‘Ò‚¿ƒ^ƒXƒN‚ª‚È‚¢
	test	AL,3
	jnz	m_waiq
	
	jmp	m_nxtmbx
m_end:
	mov	AX,0
	int	21h
	
m_notsk:
	mov	AL,BL		;BL=flg_ptr
	shr	AL,1
	shr	AL,1
	
	call	hex_cnv
	
	mov	word ptr mes_m2p+6,AX
	mov	DX,offset mes_m2p
	mov	AH,9
	int	21h
	
	xor	CL,CL		;CL=counter
	mov	BH,mlq_top+1		;BH=mlq_top+1
m_msg1:
	mov	BL,[BX-100h]
	test	BL,3
	jnz	m_msg3
	
	cmp	CL,5
	jnz	m_msg2
	
	xor	CL,CL
	mov	DX,offset mes_s2n
	mov	AH,9
	int	21h
m_msg2:
	inc	CL
	mov	AL,[BX+3]
	call	hex_cnv
	mov	word ptr mes_m4+1,AX
	
	mov	AL,[BX+2]
	call	hex_cnv
	mov	word ptr mes_m4+3,AX
	
	mov	AL,[BX+1]
	call	hex_cnv
	mov	word ptr mes_m4+6,AX
	
	mov	AL,[BX]
	call	hex_cnv
	mov	word ptr mes_m4+8,AX
	
	mov	DX,offset mes_m4
	mov	AH,9
	int	21h
	
	jmp	m_msg1
m_msg3:
	mov	BH,mlk_top		;BH=mlk_top
	mov	DX,offset mes_cr
	int	21h
	jmp	m_nxtmbx
	
m_waiq:
	xor	AL,BL
	xchg	AL,BL
	shr	AL,1
	shr	AL,1
	
	call	hex_cnv
	
	mov	word ptr mes_m2p+6,AX
	mov	DX,offset mes_m2p
	mov	AH,9
	int	21h
	
	xor	CL,CL
m_tsk1:
	mov	AX,[BX]		;AL=nxt_ptr
				;AH=suscnt
	xchg	BL,AL
	mov	CH,AH
	shr	AL,1
	shr	AL,1
	call	hex_cnv
	
	mov	word ptr mes_t3q,AX
	mov	DX,offset mes_t3w
	
	and	CH,CH		;suspended?
	jz	m_tsk2
	
	mov	DX,offset mes_t3s
m_tsk2:
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_t3q
	mov	AH,9
	int	21h
	
	test	BL,3
	jnz	m_tsk3
	
	inc	CL
	cmp	CL,5
	jnz	m_tsk1
	
	xor	CL,CL
	mov	DX,offset mes_s2n
	mov	AH,9
	int	21h
	jmp	m_tsk1
m_tsk3:
	mov	DX,offset mes_cr
	mov	AH,9
	int	21h
	jmp	m_nxtmbx
	
	
hex_cnv	proc	near
		;entry  AL- Hex data
		;exit	AH- LSB ascii
		;       AL- MSB ascii
	
	mov	AH,AL
	shr	AH,1		;‚ ‚Æ‚Å XCHG ‚·‚é‚Ì‚ÅA‚±‚±‚Å‚Í AH ‚ª MSB
	shr	AH,1
	shr	AH,1
	shr	AH,1
	and	AX,0f0fh
	
	add	AL,90h
	daa
	adc	AL,40h
	daa
	
	xchg	AL,AH
	
	add	AL,90h
	daa
	adc	AL,40h
	daa
	
	ret
hex_cnv	endp
	
mes_t1	db	'@@^¡@¡PP¡@¡PP¡@¡_@Q@¡@ƒÊITRON 3.0 Žd—l@Ø±ÙÀ²Ñ¥ÏÙÁÀ½¸ÓÆÀ', 0dh, 0ah
	db	'@^@¡QQ¡@¡Q¡@¡QQ¡@_P@¡@Copyright (c) Mineyuki Kimoto 1994', 0dh, 0ah
	db	0dh, 0ah
	db	'@@@@@@@‚`‚r‚t‚q‚`|‚h ó‘Ô•\Ž¦ƒvƒƒOƒ‰ƒ€ ver 1.00.00 - ƒ¿'
	db	0dh, 0ah, 0dh, 0ah
	
	db	'task status', 0dh, 0ah, '        '
	db	'     +0   pri i     +1   pri i'
	db	'     +2   pri i     +3   pri i$'
        
mes_t2	db	0dh, 0ah
	db	'tskid=%% $'
	
mes_t3u	db	' P[^o^]d $'
mes_t3r	db	'  [^_^]  $'
mes_t3s	db	'  [> <]  $'
mes_t3w	db	'  [- -]  $'
mes_t3l	db	'  [_ _]  $'
mes_t3d	db	'  [O O]  -- $'
mes_t3n	db	'               $'
mes_t3p	db	'%% '
mes_t3q	db	'%% $'
	
mes_t4	db	0dh, 0ah, 0dh, 0ah
	
	db	'ready-que status (dispatch $'
mes_r1d	db	'disabled)', 0dh, 0ah, 0dh, 0ah, '$'
mes_r1e	db	'enabled)', 0dh, 0ah, 0dh, 0ah, '$'
	
mes_r2p	db	'pri = %% $'
	
mes_r4	db	0dh, 0ah
	db	'         '
mes_r4a	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
mes_r4b	db	' '
	
mes_s1	db	0dh, 0ah
	db	'semaphore status'
	db	0dh, 0ah
mes_cr	db	0dh, 0ah, '$'
mes_s2p	db	'semid=%% $'
mes_s2n	db	0dh, 0ah
mes_r2n	db	'         $'
	
mes_s3c	db	'semcnt=%%'
	db	0dh, 0ah, '$'
	
mes_f1	db	0dh, 0ah
	db	'ivent-flag status'
	db	0dh, 0ah, 0dh, 0ah, '$'
mes_f2p	db	'flgid=%% $'
	
mes_f4	db	0dh, 0ah
	db	' %%%%  % '
mes_f4a	db	'    %%%%  %%'
	db	'    %%%%  %%'
	db	'    %%%%  %%'
	db	'    %%%%  %%'
	db	'    %%%%  %%'
mes_f4b	db	' '
	
mes_m1	db	0dh, 0ah
	db	'mail-box status (free %%/40)'
	db	0dh, 0ah, 0dh, 0ah, '$'
	
mes_m2p	db	'mbxid=%% $'
	
mes_m4	db	' %%%%:%%%%  $'

	org	0cf0h
dsp_flg	db	?
run_tsk	db	?
	
code	ends
	end	start
