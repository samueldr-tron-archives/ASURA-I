;
;　　　　ＡＳＵＲＡ−Ｉ　カーネルデバッグ支援プログラム
;
;                  Copyright (c) 1994 Mineyuki Kimoto
;

code	segment
	assume	CS:code,DS:code,ES:code

dsp_flg	equ	0f0h
run_tsk	equ	0f1h

include	asura_i.inc

	org	100h
start:
	chk_ai	err_nex
	mov	AX,CS
	mov	DS,AX
	
	sti
	mov	AX,CS
	mov	pk_ct.s_task,AX
	
	mov	DX,2
	mov	SI,offset pk_ct
loop1:
	cre_tsk
	and	AX,AX
	jnz	err_ct
	
	sta_tsk
	and	AX,AX
	jnz	err_ct
	
	inc	DX
	cmp	DX,9
	jnz	loop1
	
	mov	DX,1
	mov	SI,offset pk_cs
	jmp	loop2

err_nex:
	mov	AX,CS
	mov	DS,AX
	mov	DX,offset mes_nex	;異常終了メッセージ
	mov	AH,9
	int	21h
	
	mov	AX,0
	int	21h
err_ct:
	mov	DX,offset mes_ct	;異常終了メッセージ
	mov	AH,9
	int	21h
	
	mov	AX,0
	int	21h

loop2:
	cre_sem
	and	AX,AX
	jnz	err_cs
	
	inc	DX
	cmp	DX,5
	jnz	loop2
	
	mov	SI,offset pk_cf1
	mov	DX,1
	cre_flg
	and	AX,AX
	jnz	err_cf
	
	mov	DX,2
	cre_flg
	and	AX,AX
	jnz	err_cf
	
	mov	SI,offset pk_cf2
	mov	DX,3
	cre_flg
	and	AX,AX
	jnz	err_cf
	
	mov	DX,4
	cre_flg
	and	AX,AX
	jnz	err_cf
	
	mov	SI,offset pk_cm
	mov	DX,1
loop3:
	cre_mbx
	and	AX,AX
	jnz	err_cm
	
	inc	DX
	cmp	DL,5
	jnz	loop3
	
	mov	DX,offset mes_opn
	mov	AH,9
	int	21h
	
	jmp	cmd
	
err_cs:
	mov	DX,offset mes_cs	;異常終了メッセージ
	mov	AH,9
	int	21h
	
	mov	AX,0
	int	21h
err_cf:
	mov	DX,offset mes_cf	;異常終了メッセージ
	mov	AH,9
	int	21h
	
	mov	AX,0
	int	21h
err_cm:
	mov	DX,offset mes_cm	;異常終了メッセージ
	mov	AH,9
	int	21h
	
	mov	AX,0
	int	21h
	
	
	
cmd:
	mov	AX,CS
	mov	DS,AX
	mov	ES,AX
	
	get_tid
	
	mov	AL,DL		;tskid をプロンプトに表示
	call	hex_cnv
	mov	word ptr mes_pmt+7,AX
	
	mov	DX,offset mes_pmt
	mov	AH,9
	int	21h
	
	mov	DX,offset pk_com	;コマンドを入力
	mov	AH,0ah
	int	21h
	
	mov	DX,offset mes_cr
	mov	AH,9
	int	21h
	
	mov	BL,pk_com+1	;BL=文字数
	
	cmp	BL,1
	jz	com_sin
	
	cmp	BL,7
	jnc	sys_cal
	
err_com:
	mov	DX,offset mes_ukc	;コマンドエラー
	mov	AH,9
	int	21h
	
	jmp	cmd
	
com_sin:
			;１文字コマンド
	mov	AL,pk_com+2
	cmp	AL,'q'
	jz	com__q
	
	cmp	AL,'r'
	jnz	com_sin2
	jmp	com__r
	
com_sin2:
	cmp	AL,'s'
	jnz	com_sin3
	jmp	com__s
	
com_sin3:
	cmp	AL,'f'
	jnz	com_sin4
	jmp	com__f
	
com_sin4:
	cmp	AL,'t'
	jnz	com_sin5
	jmp	com__t
	
com_sin5:
	cmp	AL,'m'
	jnz	err_com
	jmp	com__m
	
	
com__q:
	mov	DX,offset mes_ext	;正常終了
	mov	AH,9
	int	21h
	
	mov	AH,0
	int	21h
	
sys_cal:
	mov	AX,8
	mov	DI,offset tbl_com
	
sys_cal1:
	mov	SI,offset pk_com+2
	push	DI
	mov	CX,8
	repz	cmpsb
	pop	DI
	
	and	CX,CX
	jz	sys_cal2
	
	add	DI,AX
	cmp	DI,offset btm_com
	jc	sys_cal1
	jmp	err_com
	
sys_cal2:
	mov	AL,[DI+7]
	
	mov	CL,BL		;CL=コマンドの文字数
	cmp	CL,0ah
	jc	sys_int
	
	mov	DX,word ptr pk_com+0ah
	call	wrd_cnv
	
	and	DH,DH
	jnz	err_par
	
	mov	BX,DX
	cmp	CL,0dh
	jc	sys_int
	
	mov	DX,word ptr pk_com+0dh
	call	wrd_cnv
	
	and	DH,DH
	jnz	err_par
	jmp	sys_int
err_par:
	mov	DX,offset mes_ukp
	mov	AH,9
	int	21h
	
	jmp	cmd
	
sys_int:
	mov	DI,0ffffh
	int	62h
	
	and	AX,AX
	jnz	dis_err
	
	mov	AL,BH
	call	hex_cnv
	mov	word ptr mes_sts+11h,AX
	
	mov	AL,BL
	call	hex_cnv
	mov	word ptr mes_sts+13h,AX
	
	mov	AL,DH
	call	hex_cnv
	mov	word ptr mes_sts+1dh,AX
	
	mov	AL,DL
	call	hex_cnv
	mov	word ptr mes_sts+1fh,AX
	
	mov	DX,offset mes_sts
	mov	AH,9
	int	21h
	
	jmp	cmd
	
dis_err:
	cmp	AX,-86
	jnc	dis_err2
dis_err1:
	mov	SI,AX
	call	hex_cnv
	mov	word ptr mes_uke+13h,AX
	
	mov	AX,SI
	mov	AL,AH
	call	hex_cnv
	mov	word ptr mes_uke+11h,AX
	
	mov	DX,offset mes_uke
	mov	AH,9
	int	21h
	
	jmp	cmd
	
dis_err2:
	mov	SI,AX
	shl	SI,1
	mov	DX,tbl_err[SI]
	cmp	DX,offset eunk
	jz	dis_err1
	
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_cr
	int	21h
	
	jmp	cmd
	
	
com__r:
	cli
	xor	AX,AX
	mov	ES,AX
	mov	AX,[ES:018ah]
	mov	ES,AX
	
	mov	DX,offset mes_r1
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_r1d
	and	byte ptr [ES:dsp_flg],0ffh
	jnz	r_tit1
	
	mov	DX,offset mes_r1e
r_tit1:
	int	21h
	
	mov	CH,[ES:run_tsk]
	mov	BX,103h		;pri=1のポインタ
r_pri:
	mov	AL,ES:[BX]	;AL=nxt_ptr
	xchg	AL,BL
	
	test	BL,3
	jnz	r_pri
	
			;そのpri の先頭タスク
	shr	AL,1	;AL=現pri
	shr	AL,1
	inc	AL
	and	AL,1fh
	call	hex_cnv
	mov	word ptr mes_r2p+6,AX
	
	mov	DX,offset mes_r2p
	mov	AH,9
	int	21h
r_p2t1:
	mov	SI,offset mes_r4a
	mov	byte ptr [SI],'$'
r_tsk:
	mov	DX,offset mes_t3u
	cmp	BL,CH		;CH=run_tsk
	jz	r_tsk1
	
	mov	DX,offset mes_t3r
	test	byte ptr ES:[BX+1],0ffh	;suscnt
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
	
	mov	byte ptr [SI],' '
	
	mov	AL,ES:[BX+1]		;suscnt
	call	hex_cnv
	mov	word ptr [SI+0ah],AX
	
	mov	AL,ES:[BX+201h]		;wupcnt
	dec	AL
	call	hex_cnv
	mov	word ptr [SI+05h],AX
	
	add	SI,0ch
	mov	byte ptr [SI],'$'
	
	mov	BL,ES:[BX]
	test	BL,3
	jz	r_t2t
	
	mov	DX,offset mes_r4
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_cr
	int	21h
	
	cmp	BL,3
	jz	r_end
	
	jmp	r_pri
r_t2t:
	cmp	SI,offset mes_r4b
	jnz	r_tsk
	
	mov	DX,offset mes_r4
	mov	AH,9
	int	21h
	
	mov	DX,offset mes_cr
	int	21h
	
	mov	DX,offset mes_r2n
	int	21h
	
	jmp	r_p2t1
	
r_end:
	sti
	mov	AX,CS
	mov	ES,AX
	
	jmp	cmd
	
	
com__s:
	cli
	xor	AX,AX
	mov	ES,AX
	mov	AX,[ES:018ah]
	mov	ES,AX
	
	mov	DX,offset mes_s1
	mov	AH,9
	int	21h
	
	mov	BX,0183h	;semid=0
s_nxtsem:
	add	BL,4
	jc	s_end
	
	mov	AL,ES:[BX]
	
	xor	AL,BL
	jz	s_notsk		;待ちタスクがない
	test	AL,3
	jnz	s_waiq
	
	jmp	s_nxtsem
s_end:
	sti
	mov	AX,CS
	mov	ES,AX
	
	jmp	cmd
	
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
	
	mov	AL,ES:[BX+700h]
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
	mov	BL,ES:[BX]		;BL=nxt_lnk
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
	
	test	byte ptr ES:[BX+1],0ffh	;suscnt
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
	cli
	xor	AX,AX
	mov	ES,AX
	mov	AX,[ES:018ah]
	mov	ES,AX
	
	mov	DX,offset mes_f1
	mov	AH,9
	int	21h
	
	mov	BX,0282h	;flgid=0
f_nxtflg:
	add	BL,4
	jc	f_end
	mov	CL,ES:[BX]	;CL=nxt_ptr
	
	xor	CL,BL
	jz	f_head
	test	CL,3
	jnz	f_head
	
	jmp	f_nxtflg
f_end:
	sti
	
	mov	AX,CS
	mov	ES,AX
	
	jmp	cmd
	
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
	
	mov	DX,ES:[BX+400h]	;AX=flgptn
	
	mov	AL,DH
	call	hex_cnv
	mov	word ptr mes_f4+3,AX
	
	mov	AL,DL
	call	hex_cnv
	mov	word ptr mes_f4+5,AX
	
	mov	AL,'m'
	test	byte ptr ES:[BX+600h],8
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
	mov	CX,ES:[BX]	;CH=flgatr
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
	test	byte ptr ES:[BX-0ffh],0ffh	;suscnt
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
	
	mov	DX,ES:[BX+200h]	;flgptn
	
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
	
	
com__t:
	cli
	xor	AX,AX
	mov	ES,AX
	mov	AX,[ES:018ah]
	mov	ES,AX
	
	mov	DX,offset mes_t1
	mov	AH,9
	int	21h
	
	mov	CH,[ES:run_tsk]	;CH=run_tsk
	mov	BX,300h
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
	mov	AX,ES:[BX]	;AL=tskstat
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
	
	mov	AL,ES:[BX+3]	;AL=ipri
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
	test	byte ptr ES:[BX-1ffh],0ffh	;suspend?
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
	mov	DX,ES:[BX+2]	;DL=pri
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
	
	sti
	
	mov	AX,CS
	mov	ES,AX
	
	jmp	cmd
	
com__m:
	cli
	xor	AX,AX
	mov	ES,AX
	mov	AX,[ES:018ah]
	mov	ES,AX
	
	mov	AX,400h		;04h for dBX, 00h for counter
	mov	BX,800h		;top_mlq
m_cnt1:
	cmp	BL,ES:[BX]
	jnz	m_cnt2
	
	inc	AL
m_cnt2:
	sub	BL,AH
	jnz	m_cnt1
				;AL=free count
	call	hex_cnv
	
	mov	word ptr mes_m1+16h,AX
	mov	DX,offset mes_m1
	mov	AH,9
	int	21h
	
	mov	BX,0102h	;mbxid=0
m_nxtmbx:
	add	BL,4
	cmp	BL,80h
	jnc	m_end
	
	mov	AL,ES:[BX]
	
	xor	AL,BL
	jz	m_notsk		;待ちタスクがない
	test	AL,3
	jnz	m_waiq
	
	jmp	m_nxtmbx
m_end:
	sti
	mov	AX,CS
	mov	ES,AX
	
	jmp	cmd
	
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
	mov	BH,9		;BH=mlq_top+1
m_msg1:
	mov	BL,ES:[BX-100h]
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
	mov	AL,ES:[BX+3]
	call	hex_cnv
	mov	word ptr mes_m4+1,AX
	
	mov	AL,ES:[BX+2]
	call	hex_cnv
	mov	word ptr mes_m4+3,AX
	
	mov	AL,ES:[BX+1]
	call	hex_cnv
	mov	word ptr mes_m4+6,AX
	
	mov	AL,ES:[BX]
	call	hex_cnv
	mov	word ptr mes_m4+8,AX
	
	mov	DX,offset mes_m4
	mov	AH,9
	int	21h
	
	jmp	m_msg1
m_msg3:
	mov	BH,1			;BH=mlk_top
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
	mov	AX,ES:[BX]	;AL=nxt_ptr
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
	shr	AH,1		;あとで XCHG するので、ここでは AH が MSB
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
	
wrd_cnv	proc	near
		;entry	DL - MSB ascii
		;	DH - LSB ascii
		;exit	DX - Hex
	
	sub	DL,30h
	jc	wrd_cnv3
	cmp	DL,0ah
	jc	wrd_cnv1
	sub	DL,27h
	jc	wrd_cnv3
	cmp	DL,10h
	jnc	wrd_cnv3
wrd_cnv1:
	shl	DL,1
	shl	DL,1
	shl	DL,1
	shl	DL,1
	
	sub	DH,30h
	jc	wrd_cnv3
	cmp	DH,0ah
	jc	wrd_cnv2
	sub	DH,27h
	jc	wrd_cnv3
	cmp	DH,10h
	jnc	wrd_cnv3
wrd_cnv2:
	or	DL,DH
	mov	DH,0
	
	ret
	
wrd_cnv3:
	mov	DH,0ffh
	ret
	
wrd_cnv	endp
	
	
mes_opn	db	0dh, 0ah
	db	'　　／■　■‾‾■　■‾‾■　■＼　＿　■　μITRON 3.0 仕様　リアルタイム・マルチタスクモニタ', 0dh, 0ah
	db	'　／　■＿＿■　■＿■　■＿＿■　＼‾　■　Copyright (c) Mineyuki Kimoto 1994', 0dh, 0ah
	db	0dh, 0ah
	db	'　　　　　　ＡＳＵＲＡ−Ｉ システムコール　ＣＬＩ ver 0.14.00 - α'
	db	0dh, 0ah, '$'
	
mes_nex	db	'ＡＳＵＲＡ−Ｉが常駐していません。', 0dh, 0ah, '$'
	
mes_ct	db	'タスクの生成に失敗しました。（異常終了）', 0dh, 0ah, '$'
	
mes_cs	db	'セマフォの生成に失敗しました。（異常終了）', 0dh, 0ah, '$'
	
mes_cf	db	'イベントフラグの生成に失敗しました。（異常終了）'
	dw	0dh, 0ah, '$'
	
mes_cm	db	'メールボックスの生成に失敗しました。（異常終了）'
	
mes_cr	db	0dh, 0ah, '$'
	
mes_pmt	db	'tskid= %% > $'
		;0123456789abcdef01234
	
mes_ukc	db	'コマンドが分かりません。'
	db	0dh, 0ah, '$'
	
mes_ukp	db	'数値の表記が正しくありません。　コマンド書式 : ???_??? ?? ??'
	db	0dh, 0ah, '$'
	
mes_sts	db	'eok         BX = %%%% / DX = %%%%'
		;0123456789abcdef0123456789abcdef01
	db	0dh, 0ah, '$'
	
mes_uke	db	'不正エラーコード AX = %%%%'
		;0123456789abcdef012345
	db	0dh, 0ah, '$'
	
mes_ext	db	'終了しました。お疲れさまでした。'
	db	0dh, 0ah, '$'
	
mes_r1	db	'ready-que status (dispatch $'
mes_r1d	db	'disabled)', 0dh, 0ah, 0dh, 0ah, '$'
mes_r1e	db	'enabled)', 0dh, 0ah, 0dh, 0ah, '$'
	
mes_r2p	db	'pri = %% $'
mes_r2n	db	'         $'

mes_r4	db	0dh, 0ah
	db	'         '
mes_r4a	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
	db	'   w=%% s=%%'
mes_r4b	db	' '
	
mes_s1	db	'semaphore status'
	db	0dh, 0ah, 0dh, 0ah, '$'
mes_s2p	db	'semid=%% $'
mes_s2n	db	0dh, 0ah
	db	'         $'
	
mes_s3c	db	'semcnt=%%'
	db	0dh, 0ah, '$'
	
mes_f1	db	'ivent-flag status'
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
	
mes_t1	db	'task status', 0dh, 0ah, '        '
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
	
mes_t4	db	0dh, 0ah, 0dh, 0ah, '$'
	
mes_m1	db	'mail-box status (free %%/40)'
	db	0dh, 0ah, 0dh, 0ah, '$'
	
mes_m2p	db	'mbxid=%% $'
	
mes_m4	db	' %%%%:%%%%  $'
	
	
	
pk_com	db	40
	db	256 dup (?)
	
pk_ct	pk_ctsk	<,,0,cmd,,1fh>
	
pk_cs	pk_csem	<,,0,1>
	
pk_cf1	pk_cflg	<,,0,0>
	
pk_cf2	pk_cflg	<,,8,0>
	
pk_cm	pk_cmbx	<,,0>
	
tbl_com	db	'ref_mbx', 0c4h
	db	'pol_msg', 094h
	db	'rcv_msg', 0c3h
	db	'snd_msg', 0c1h
	db	'del_mbx', 0c6h
	db	'cre_mbx', 0c7h
	db	'ref_flg', 0d4h
	db	'pol_flg', 096h
	db	'wai_flg', 0d2h
	db	'set_flg', 0d0h
	db	'clr_flg', 0d1h
	db	'del_flg', 0d6h
	db	'cre_flg', 0d7h
	db	'ref_sem', 0cch
	db	'pol_sem', 095h
	db	'wai_sem', 0cbh
	db	'sig_sem', 0c9h
	db	'del_sem', 0ceh
	db	'cre_sem', 0cfh
	db	'can_wup', 0d8h
	db	'wup_tsk', 0d9h
	db	'slp_tsk', 0dah
	db	'frm_tsk', 0dch
	db	'rsm_tsk', 0ddh
	db	'sus_tsk', 0dfh
	db	'ref_tsk', 0ech
	db	'get_tid', 0e8h
	db	'rel_wai', 0e1h
	db	'rot_rdq', 0e4h
	db	'chg_pri', 0e5h
	db	'ena_dsp', 0e3h
	db	'dis_dsp', 0e2h
	db	'ter_tsk', 0e7h
	db	'exd_tsk', 0eah
	db	'ext_tsk', 0ebh
	db	'sta_tsk', 0e9h
	db	'del_tsk', 0eeh
	db	'cre_tsk', 0efh
	
btm_com	db	0
	
eunk	db	'e_unk $'
eok	db	'eok   $'
enospt	db	'enospt$'
ersfn	db	'ersfn $'
ersatr	db	'ersatr$'
epar	db	'epar  $'
eid	db	'eid   $'
enoexs	db	'enoexs$'
eobj	db	'eobj  $'
ectx	db	'ectx  $'
eqovr	db	'eqovr $'
edlt	db	'edlt  $'
etmout	db	'etmout$'
erlwai	db	'erlwai$'
	
	
	dw	erlwai	;-86
	dw	etmout	;-85
	dw	eunk	;-84
	dw	eunk	;-83
	dw	eunk	;-82
	dw	edlt	;-81
	dw	eunk	;-80
	dw	eunk	;-79
	dw	eunk	;-78
	dw	eunk	;-77
	dw	eunk	;-76
	dw	eunk	;-75
	dw	eunk	;-74
	dw	eqovr	;-73
	dw	eunk	;-72
	dw	eunk	;-71
	dw	eunk	;-70
	dw	ectx	;-69
	dw	eunk	;-68
	dw	eunk	;-67
	dw	eunk	;-66
	dw	eunk	;-65
	dw	eunk	;-64
	dw	eobj	;-63
	dw	eunk	;-62
	dw	eunk	;-61
	dw	eunk	;-60
	dw	eunk	;-59
	dw	eunk	;-58
	dw	eunk	;-57
	dw	eunk	;-56
	dw	eunk	;-55
	dw	eunk	;-54
	dw	eunk	;-53
	dw	enoexs	;-52
	dw	eunk	;-51
	dw	eunk	;-50
	dw	eunk	;-49
	dw	eunk	;-48
	dw	eunk	;-47
	dw	eunk	;-46
	dw	eunk	;-45
	dw	eunk	;-44
	dw	eunk	;-43
	dw	eunk	;-42
	dw	eunk	;-41
	dw	eunk	;-40
	dw	eunk	;-39
	dw	eunk	;-38
	dw	eunk	;-37
	dw	eunk	;-36
	dw	eid	;-35
	dw	eunk	;-34
	dw	epar	;-33
	dw	eunk	;-32
	dw	eunk	;-31
	dw	eunk	;-30
	dw	eunk	;-29
	dw	eunk	;-28
	dw	eunk	;-27
	dw	eunk	;-26
	dw	eunk	;-25
	dw	ersatr	;-24
	dw	eunk	;-23
	dw	eunk	;-22
	dw	eunk	;-21
	dw	ersfn	;-20
	dw	eunk	;-19
	dw	eunk	;-18
	dw	enospt	;-17
	dw	eunk	;-16
	dw	eunk	;-15
	dw	eunk	;-14
	dw	eunk	;-13
	dw	eunk	;-12
	dw	eunk	;-11
	dw	eunk	;-10
	dw	eunk	;- 9
	dw	eunk	;- 8
	dw	eunk	;- 7
	dw	eunk	;- 6
	dw	eunk	;- 5
	dw	eunk	;- 4
	dw	eunk	;- 3
	dw	eunk	;- 2
	dw	eunk	;- 1
tbl_err	dw	eok	;  0
	
	
	
	
	
	
code	ends
	end	start
