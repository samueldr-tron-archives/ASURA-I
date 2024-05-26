;
;　ＡＳＵＲＡ−Ｉ　サンプルプログラム　　／　　簡易ターミナルソフト
;
;            copyright (c) Mineyuki Kimoto 1994
;

include	asura_i.inc

code	segment
	assume	CS:code,DS:code,SS:code
	org	100h
	
		;tskid=1 キーボード入力＆送信タスク
		;tskid=2 受信データを画面に出力するタスク
		;semid=1 int21hの排他用セマフォ
	
	
start:			;RS-232Cのセットアップ
	chk_ai	err_nex
	mov	AX,CS
	mov	DS,AX
	
	loc_cpu
	
	cre_tsk_i	2, <offset pk_ct>
	and	AX,AX
	jnz	err_ct
	jmp	start1
	
err_nex:
	mov	AX,CS
	mov	DS,AX
	mov	DX,offset mes_nex
	mov	AH,9
	int	21h
	
	mov	AX,0
	int	21h
err_ct:
	mov	DX,offset mes_ct
	jmp	err_mes
	
start1:
	sta_tsk
	and	AX,AX
	jnz	err_ct
	
	mov	AL,0b6h		;通信速度の設定
	out	77h,AL
	jmp	$+2
	jmp	$+2
	mov	AX,0
	mov	DS,AX
	mov	AL,byte ptr DS:[501h]
	test	AL,80h
	jz	clk_5
	mov	AL,13
	jmp	next
clk_5:
	mov	AL,16
next:
	out	75h,AL
	jmp	$+2
	jmp	$+2
	mov	AL,0
	out	75h,AL
	
	mov	AL,0
	out	32h,AL
	mov	CX,16
	loop	$
	out	32h,AL
	mov	CX,16
	loop	$
	out	32h,AL
	mov	CX,16
	loop	$
	mov	AL,40h
	out	32h,AL
	mov	CX,16
	loop	$
	mov	AL,4eh
	out	32h,AL
	mov	CX,16
	loop	$
	mov	AL,37h
	out	32h,AL
	
	in	AL,2		;割り込みコントローラの設定
	and	AL,0efh
	out	2,AL
	
	in	AL,35h		;割り込みマスクの設定
	jmp	$+2
	and	AL,0fch
	or	AL,1
	out	35h,AL
	
	mov	AX,CS		;ベクタの書き換え
	mov	DS,AX
	mov	ES,AX
	
	def_int_i	0ch, <offset pk_di>
	and	AX,AX
	jnz	err_di
	
	cre_sem_i	1, <offset pk_cs>
	and	AX,AX
	jnz	err_cs
	
	unl_cpu
inp:
	wai_sem_i	1
	
	mov	DL,0ffh
	mov	AH,6
	int	21h		;key sence
	
	push	AX
	sig_sem_i	1
	pop	AX
	
	and	AL,AL
	jz	inp
	
	cmp	AL,3
	jz	ext
	cmp	AL,5
	jz	ext
	
	mov	CL,AL
	
tx:
	in	AL,32h
	test	AL,1
	jz	tx
	
	mov	AL,CL
	out	30h,AL
	
	jmp	inp
	
rx:
	mov	BX,400h
rx2:
	slp_tsk
	
	wai_sem_i	1
	
	push	BX
	
	mov	DX,BX
	mov	BX,2
	mov	CX,1
	mov	AH,40h
	int	21h
	
	pop	BX
	
	mov	DL,[BX]
	inc	BL
	
	mov	AH,2
	int	21h
	
	sig_sem_i	1
	
	jmp	rx2
	
err_di:
	mov	DX,offset mes_di
	jmp	err_mes
err_cs:
	mov	DX,offset mes_cs
err_mes:
	mov	AH,9
	int	21h
ext:
	loc_cpu
	
	in	AL,35h
	and	AL,0f8h
	out	35h,AL
	
	ter_tsk_i	2
	del_tsk
	
	del_sem_i	1
	
	unl_cpu
	
	mov	AH,0
	int	21h
	
rsrcv_int:
	push	AX
	push	BX
	push	DX
	
	in	AL,32h
	test	AL,2
	jz	ret
	
	in	AL,30h
	mov	BL,CS:wri_ptr
	mov	BH,4
	mov	CS:[BX],AL
	
	inc	BL
	mov	CS:wri_ptr,BL
	
	wup_tsk_i	2
ret:
	mov	AL,20h
	out	0,AL
	
	pop	DX
	pop	BX
	pop	AX
	
	ret_int
	
mes_nex	db	'ＡＳＵＲＡ−Ｉが常駐していません。', 0dh, 0ah, '$'
	
mes_di	db	'割り込みハンドラの登録に失敗しました。（異常終了）'
	db	0dh, 0ah, '$'
	
mes_ct	db	'タスクの生成に失敗しました。（異常終了）', 0dh, 0ah, '$'
	
mes_cs	db	'セマフォの生成に失敗しました。（異常終了）', 0dh, 0ah, '$'
	
pk_di	pk_dint	<,rsrcv_int,>
	
pk_ct	pk_ctsk	<,,0,rx,,1eh>
	
pk_cs	pk_csem	<,,,1>
	
wri_ptr	db	0
	
	org	400h
buffer	db	256 dup ('e')
	
code	ends
	end start
