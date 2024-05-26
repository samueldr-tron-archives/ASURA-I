;
;  micro-ITRON 3.0    ASURA-I ver 1.01.00
;       Device driver for 86-asm
;
;   Copyright(c) Mineyuki Kimoto 1994
;

;　■■■　リターン関係マクロ　■■■

pop_wrk	macro
	pop	BX
	pop	CX
	pop	DS
	iret
	endm

pop_eok	macro
	xor	AX,AX
	pop_wrk

	endm

pop_err	macro	err
	mov	AX,&err
	pop_wrk

	endm


;　■■■　パラメータ評価マクロ　■■■

cnv_tid	macro	eid
		;BXは保存してあるものとする
		;DL=tskid（DHは見ない）
		;entry:1 to 63
	mov	BL,DL
	sal	BL,1
	jbe	&eid		;ZF or CF
	sal	BL,1
	jc	&eid
	endm

		;DLが0の時は、run_tskを取得する
cnv_tis	macro	eid
	local	cnv_tis2
		;BXは保存してあるものとする
		;DL=tskid（DHは見ない）
		;entry:1 to 63
	mov	BL,DL
	sal	BL,1
	jc	&eid
	sal	BL,1
	jc	&eid
	jnz	cnv_tis2
	mov	BL,run_tsk
cnv_tis2:
	endm

cnv_obj	macro	eid
		;BXは保存してあるものとする
		;extry:1 to 31
	mov	BL,DL
	test	BL,0e0h
	jnz	&eid
	sal	BL,1
	jz	&eid
	sal	BL,1
	endm

cnv_sid	macro	eid
		;DL=semid（DHは見ない）
	cnv_obj	&eid

	or	BL,83h
	endm

cnv_fid	macro	eid
		;DL=flgid（DHは見ない）
	cnv_obj	&eid

	or	BL,82h
	endm

cnv_mid	macro	eid
		;DL=flgid（DHは見ない）
	cnv_obj	&eid

	or	BL,2
	endm

	;mov	BX,SP
	;mov	AL,[BX]
cnv_pri	macro	epar, self
		;AL=pri
	test	AL,0e0h
	jnz	&epar
	sal	AL,1
	jz	&self
	sal	AL,1
	or	AL,3
	endm


;　■■■　システム状態確認マクロ　■■■

	;ectxを検出する
chk_ctx	macro
	local	chk_ctx1
	and	CX,CX
	jz	chk_ctx1
	pop_err	cctx
chk_ctx1:
	endm

	;mov	BH,mlk_top or +1
chk_lnk	macro	nolnk, noexs
	mov	AL,[BX]
	xor	AL,BL
	jz	&nolnk
	test	AL,3
	jz	&noexs
	endm
	;xor	BL,AL	to BL=nxt_ptr

	;mov	BH,mlk_top or +1
chk_nex	macro	eobj
	mov	AL,[BX]
	xor	AL,BL
	jz	&eobj
	test	AL,3
	jnz	&eobj
	endm
	;xor	AL,BL	to AL=nxt_ptr

	;mov	BH,mlk_top
	;mov	AL,[BX+200h]
chk_tst	macro	tskstat, eobj, enoexs
	and	AL,AL
	jz	&enoexs
	test	AL,&tskstat
	jz	&eobj
	endm


;　■■■　メインリンク操作マクロ　■■■

	;BLで示されるリンクを削除する（メインリンク）
	;mov	BH,mlk_top	;BH=メインリンクのアドレス
del_que	macro
	mov	AX,BX		;AL=BL
	inc	AH		;AH=mlk_top+1
	xchg	[BX],BL
	xchg	AX,BX		;AH=mlk_top, BH=blk_top+1
	xchg	[BX],BL
	xchg	AH,BH		;AH=mlk_top+1, BH=mlk_top
	mov	[BX],AL
	xchg	AX,BX		;AH=mlk_top, BH=mlk_top+1
	mov	[BX],AL
	endm
		;AH=mlk_top
		;AL=直前にあったリンク
		;BH=mlk_top+1
		;BL=直後にあったリンク

	;BLで示されるリンクの直後にALで示されるリンクを追加する
	;ALのリンクは非接続でなければならない
	;mov	BH,mlk_top	;BH=メインリンクのアドレス
add_que	macro
	mov	AH,AL
	xchg	[BX],AL
	xchg	BL,AH
	mov	[BX],AL
	inc	BH		;BH=mlk_top+1
	mov	[BX],AH
	xchg	BL,AL
	mov	[BX],AL
	endm
		;AH=元のBL
		;AL=保存
		;BL=次のリンク
		;BH=mlk_top+1

	;BLで示されるリンクの直前にALで示されるリンクを挿入する
	;ALのリンクは非接続でなければならない
	;mov	BH,mlk_top+1	;BH=バックリンクのアドレス
ins_que	macro
	mov	AH,AL
	xchg	[BX],AL
	xchg	BL,AH
	mov	[BX],AL
	dec	BH		;BH=mlk_top
	mov	[BX],AH
	xchg	BL,AL
	mov	[BX],AL
	endm
		;AH=元のBL
		;AL=保存
		;BL=前のリンク
		;BH=mlk_top

	;ALで示されるリンクを切り離し、BLで示されるリンクの
	;直後に追加する
	;ALは接続されたタスクのリンクでなければならない
	;mov	BH,mlk_top	;BH=メインリンクのアドレス
del_add	macro
	mov	AH,AL
	xchg	[BX],AL
	inc	BH
	xchg	BL,AH
	xchg	[BX],AH
	xchg	BL,AL
	mov	[BX],AL
	dec	BH
	xchg	BL,AL
	xchg	[BX],AL
	xchg	BL,AH
	mov	[BX],AL
	inc	BH
	xchg	BL,AL
	mov	[BX],AL
	endm
		;AH=元のAL
		;AL=元の直前のリンク
		;BH=mlk_top+1
		;BL=元の直後のリンク

	;ALで示されるリンクを切り離して、BLで示されるリンクの
	;直前に挿入する
	;ALは接続されたタスクのリンクでなければならない
	;mov	BH,mlk_top+1	;BH=バックリンクのアドレス
del_ins	macro
	mov	AH,AL
	xchg	[BX],AL
	dec	BH
	xchg	BL,AH
	xchg	[BX],AH
	xchg	BL,AL
	mov	[BX],AL
	inc	BH
	xchg	BL,AL
	xchg	[BX],AL
	xchg	BL,AH
	mov	[BX],AL
	xchg	BL,AL
	dec	BH
	mov	[BX],AL
	endm
		;AHは元のAL
		;ALは元の直後のリンク
		;BH=mlk_top
		;BLは元の直後のリンク


;　■■■　メールリンク操作マクロ　■■■

	;BLで示されるメールリンクを削除する
	;mov	BH,mlq_top
del_mlq	macro
	mov	AL,BL
	mov	AH,BL
	xchg	[BX],AX
	xchg	AH,BL
	mov	[BX],AL
	xchg	AL,BL
	mov	[BX+1],AL
	endm
		;AH=元のBL
		;AL=直前のリンク
		;BH=mlq_top
		;BL=直後のリンク

	;BLで示されるメールエントリの直前にALのリンクを挿入する
	;mov	BH,mlq_top
ins_mlq	macro
	mov	AH,AL
	xchg	AL,[BX+1]
	xchg	AL,BL
	mov	[BX],AH
	xchg	AH,BL
	mov	[BX],AX
	endm
		;AH=ひとつ前のリンク
		;AL=元のBL
		;BH=mlq_top
		;BL=元のAL


;　■■■　リンク操作複合マクロ　■■■

	;BLのキューに、実行中タスクを接続して待ちに入る
	;mov	BH,mlk_top+1
ent_wai	macro
	mov	AL,run_tsk
	del_ins
	mov	BL,AH		;AH=run_tsk
	mov	byte ptr [BX+200h],4	;tskstat=wait
	xor	AX,AX
	jmp	disp
	endm

	;ALのタスクを待ち行列から外してレディキューにつなぐ
	;BH=mlk_top+1
ext_wai	macro
	mov	BL,AL
	mov	byte ptr [BX+100h],2	;tskstat=ready
	mov	BL,[BX+102h]	;BL=tskpri
	del_ins
	endm
		;AH=元のAL

	;regをディスパッチフラグとしてeokで終了する
ext_eok	macro	reg
	local	ext_eok1
	xor	AX,AX
	and	&reg,&reg
	jnz	ext_eok1
	jmp	disp
ext_eok1:
	pop_wrk
	endm




code	segment
	assume	CS:code,DS:code

		;デバイスドライバ管理作業領域
devheader       dd      -1
devattr         dw      8000h
                dw      strategy
                dw      interrupt
                db      '$ASURA_I'

packet          dd      0

s_packet        struc
cmd_len         db      ?               ;command pakent の長さ
unit            db      ?               ;block device の unit 番号
cmd             db      ?               ;command
status          dw      ?               ;status
                db      8 dup (?)       ;予約
                                        ;---- ここまで固定
unit_num        db      ?               ;Block device が support するunit数
break_adr       dd      ?               ;常駐するaddress
bpb             dd      ?               ;BPB配列へのpointer
drv             db      ?               ;Block device の drive 番号
s_packet        ends


	;デバイスドライバの管理

strategy	proc	far
	mov	word ptr CS:[packet],BX
	mov	word ptr CS:[packet+2],ES
	ret
strategy	endp


interrupt	proc    far
	push	AX
	push	BX
	push	CX
	push	DX
	push	DS
	push	SI
	push	DI
	
	mov	AX,CS
	mov	DS,AX
	
	cli
	
	lds	BX,CS:[packet]
	mov	AL,[BX].s_packet.cmd
	mov     [BX].s_packet.status,100h
	and	AL,AL
	jnz	noinit

	mov	word ptr [BX].s_packet.break_adr+2,cs
	mov	word ptr [BX].s_packet.break_adr,8600h+offset bottom
	
	
	jmp	near ptr ini_tcb
noinit:
	sti
	
	pop     DI
	pop     SI
	pop     DS
	pop     DX
	pop	CX
	pop     BX
	pop     AX
	
	ret
interrupt	endp



;
;　優先度について
;
;	・優先度が高い方から pri=1,2,3,........,30,31,0 である。
;	・tskid=0 は、システムが提供する無限ループタスクである。pri=0 
;	　　（最低優先度）であり、予約されている。
;　　　　・キューエントリは、それぞれの優先度の最後尾にある
;
;　リンクについて
;
;	・存在していないセマフォ・イベントフラグ・メールボックスは、そ
;	　　れぞれのID=0のエントリにリンクする。
;	・非接続のリンクは、自分自身を指すようにする。
;	・メインリンクは、次ポインタをそのまま格納する。
;	・イベントフラグ待ちキューのみ、逆順で格納する（先頭リンクに追
;	　　加し、最後尾リンクから取り出す）。
;
;　タイマードライバについて
;
;
;　　　　・待ちに入るときに、必ずリンクを設定する
;　　　　・待ちから抜けるときは、リンクを解除しない
;　　　　・dly_tsk は、AXにe_tmout を入れておく（他のシステムコールはe_ok）
;　　　　・タイムアウト時は、tskstat がwaitだったらe_tmout をＸＯＲする
;　　　　・タイムアウトの発生するシステムコールは次のとおり。
;　　　　　　tslp_tsk
;　　　　　　twai_sem
;　　　　　　twai_flg
;　　　　　　trcv_msg
;　　　　　　dly_tsk
;
;wupcnt:
;	01h:normal
;	>01h:nested wup
;	00h:now sleeping
;tskstat:
;	b1(02h):ready/run/(suspend)
;	b2(04h):wait/(suspend)
;	b4(10h):dorment
;priority:
;	pointing ready-que-entry
;
;
;
;    >  00  10  20  30  40  50  60  70|  80  90  a0  b0  c0  d0  e0  f0<
;00h                 デバイスドライバ管理領域                      ---- 
;  i                                                               ---- 
;  j                                                               ---- 
;  k                                                               ---- 
;
;01h  link for tskid=0 to 63 -------------(forward link)--------------- 
;  i  suscnt for tskid=0 to 63 ---------------------------------------- 
;  j  MBX-que for mbxid=0 to 31 ------|FLG-que for flgid=0 to 31 ------ 
;  k  ready-que for pri=0 to 31 ------|SEM-que for semid=0 to 31 ------ 
;
;02h  link for tskid=0 to 63 -------------(backward link)-------------- 
;  i  wait flgattr for tskid=0 to 63 ---------------------------------- 
;  j  MBX-que for mbxid=0 to 31 ------|FLG-que for flgid=0 to 31 ------ 
;  k  ready-que for pri=0 to 31 ------|SEM-que for semid=0 to 31 ------ 
;
;03h  tskstat for tskid=0 to 63 --------------------------------------- 
;  i  wupcnt+1 for tskid=0 to 63 -------------------------------------- 
;  j  priority for tskid=0 to 63 -------------------------------------- 
;  k  initial priority for tskid=0 to 63 ------------------------------ 
;
;    >  00  10  20  30  40  50  60  70|  80  90  a0  b0  c0  d0  e0  f0<
;04h  wait FLG-pattern for tskid=0 to 63 ------------------------------ 
;  i  ----------------------------------------------------------------- 
;  j  AX for tskid=0 to 63 -------------------------------------------- 
;  k  ----------------------------------------------------------------- 
;
;05h  SP for tskid=0 to 63 -------------------------------------------- 
;  i  ----------------------------------------------------------------- 
;  j  SS for tskid=0 to 63 -------------------------------------------- 
;  k  ----------------------------------------------------------------- 
;
;06h  exinf for semid=0 to 31 --------|//////////////////////////////// 
;  i  --------------------------------|//////////////////////////////// 
;  j  --------------------------------|FLG-pattern for flgid=0 to 31 -- 
;  k  --------------------------------|-------------------------------- 
;
;07h  initial IP for tskid=0 to 63 ------------------------------------ 
;  i  ----------------------------------------------------------------- 
;  j  initial CS for tskid=0 to 63 ------------------------------------ 
;  k  ----------------------------------------------------------------- 
;
;    >  00  10  20  30  40  50  60  70|  80  90  a0  b0  c0  d0  e0  f0<
;08h  link for mail-id=0 to 63 -----------(forward link)--------------- 
;  i  link for mail-id=0 to 63 -----------(backward link)-------------- 
;  j  MBX-sent-que for mbxid=0 to 31 -|flgattr for flgid=0 to 31 ------ 
;  k  MBX-sent-que for mbxid=0 to 31 -|SEM counter for semid=0 to 31 -- 
;
;09h  SI for mail-id=0 to 63 ------------------------------------------ 
;  i  ----------------------------------------------------------------- 
;  j  DS for mail-id=0 to 63 ------------------------------------------ 
;  k  ----------------------------------------------------------------- 
;
;0ah  initial SP for tskid=0 to 63 ------------------------------------ 
;  i  ----------------------------------------------------------------- 
;  j  initial SS for tskid=0 to 63 ------------------------------------ 
;  k  ----------------------------------------------------------------- 
;
;0bh  exinf for tskid=0 to 63 ----------------------------------------- 
;  i  ----------------------------------------------------------------- 
;  j  ----------------------------------------------------------------- 
;  k  ----------------------------------------------------------------- 
;
;    >  00  10  20  30  40  50  60  70|  80  90  a0  b0  c0  d0  e0  f0<
;0ch  exinf for mbxid=0 to 31 --------|exinf for flgid=0 to 31--------- 
;  i  --------------------------------|-------------------------------- 
;  j  --------------------------------|-------------------------------- 
;  k  --------------------------------|-------------------------------- 
;
;0dh  tskatr for tskid=0 to 63 ---------------------------------------- 
;  i  ///////////////////////////////////////////////////////////////// 
;  j  ///////////////////////////////////////////////////////////////// 
;  k  ///////////////////////////////////////////////////////////////// 
;
;0eh  link for tskid=0 to 63 -------------(forward link)--------------- 
;  i  timer-que for LSB=0 to 126 -------------------------------------- 
;  j  timer-que for MSB=0 to 63 --------------------------------------- 
;  k  timer-que for LSB=1 to 127 -------------------------------------- 
;
;0fh  link for tskid=0 to 63 -------------(backward link)-------------- 
;  i  timer-que for LSB=0 to 126 -------------------------------------- 
;  j  timer-que for MSB=0 to 63 --------------------------------------- 
;  k  timer-que for LSB=1 to 127 -------------------------------------- 
;
;    >  00  10  20  30  40  50  60  70|  80  90  a0  b0  c0  d0  e0  f0<
;10h                 システムコール解析テーブル                         
;  i                                                                    
;  j                                                                    
;  k                                                                    
;
;11h                                                                    
;  i                                                                    
;  j                                                                    
;  k                                                                    
;
;12h                 ＯＳ格納領域                                       
;  i                                                                    
;  j                                                                    
;  k                                                                    
;
;13h                                                                    
;  i                                                                    
;  j                                                                    
;  k                                                                    
;

	org	0f0h
dsp_flg	db	0		;ディスパッチ禁止フラグ
run_tsk	db	4		;実行中タスクのポインタ

mlk_top	equ	1

	org	103h
sca_top	db	?

mes_ini	db	0dh, 0ah
	db	'　　／■　■￣￣■　■￣￣■　■＼　＿　■'
	db	'　μITRON 3.0 仕様　ﾘｱﾙﾀｲﾑ･ﾏﾙﾁﾀｽｸﾓﾆﾀ', 0dh, 0ah
	db	'　／　■＿＿■　■＿■　■＿＿■　＼￣　■'
	db	'　Copyright (c) Mineyuki Kimoto 1994', 0dh, 0ah
	db	0dh, 0ah
	db	'　　　　　　　　　　　　ＡＳＵＲＡ－Ｉ ver 1.01.00'
	db	0dh, 0ah, '$'


tcb_top	equ	5

mlq_top	equ	8

	;tmr_top	equ	0ah


	;エラーコード
cnospt	equ	-17
crsfn	equ	-20
crsatr	equ	-24
cpar	equ	-33
cid	equ	-35
cnoexs	equ	-52
cobj	equ	-63
cctx	equ	-69
cqovr	equ	-73
cdlt	equ	-81
ctmout	equ	-85
crlwai	equ	-86


	org	1000h
fnc_top	equ	08h		;２で割っておく

	;00
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;04
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;08
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;0c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;10
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;14
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;18
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;1c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;20
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;24
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;28
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;2c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;30	putlin	getlin	putchr	getchr
	dw	enospt,	enospt,	enospt,	enospt
	;34			ctlcio	refcio
	dw	ersfn,	ersfn,	enospt,	enospt
	;38	reqgio
	dw	enospt,	ersfn,	ersfn,	ersfn
	;3c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;40
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;44
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;48
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;4c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;50	tacppor	tcalpol	trcvmbf	tsndmbf
	dw	enospt,	enospt,	enospt,	enospt
	;54
	dw	trcvmsg,twaisem,twaiflg,ersfn
	;58	tgetblk	tgetblf
	dw	enospt,	enospt,	ersfn,	ersfn
	;5c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;60			rcvmbf	sndmbf
	dw	ersfn,	ersfn,	enospt,	enospt
	;64	refmbf		delmbf	crembf
	dw	enospt,	ersfn,	enospt,	enospt
	;68	fwdpor	rplrdv	acppor	calpor
	dw	enospt,	enospt,	enospt,	enospt
	;6c	refpor	refrdv	delpol	crepor
	dw	enospt,	enospt,	enospt,	enospt
	;70
	dw	enospt,	enospt,	enospt,	enospt
	;74
	dw	enospt,	enospt,	enospt,	enospt
	;78
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;7c
	dw	ersfn,	ersfn,	ersfn,	ersfn
	;80		i		ipsndmbf
	dw	ersfn,	relwai,	ersfn,	enospt
	;84	i	i	i	i
	dw	sndmsg,	sigsem,	setflg,	wuptsk
	;88			i	i
	dw	enospt,	enospt,	rotrdq,	chgpri
	;8c	i	i		i
	dw	frsmtsk,rsmtsk,	ersfn,	sustsk
	;90	pacppor	pcalpor	prcvmbf	psndmbf
	dw	enospt,	enospt,	enospt,	enospt
	;94		
	dw	prcvmsg,preqsem,polflg,	ersfn
	;98	pgetblk	pgetblf	
	dw	enospt,	enospt,	ersfn,	ersfn
	;9c	nwridat	nreadat	ngetver	ngetnod
	dw	enospt,	enospt,	enospt,	enospt
	;0a0			actcyc	rettmr
	dw	ersfn,	ersfn,	enospt,	enospt
	;0a4	refcyc	refalm	defcyc	defalm
	dw	enospt,	enospt,	enospt,	enospt
	;0a8	cancyc	cycwup
	dw	enospt,	enospt,	ersfn,	dlytsk
	;0ac	gettim	settim
	dw	enospt,	enospt,	ersfn,	ersfn
	;0b0	relblk	relblk	getblk	getblk
	dw	enospt,	enospt,	enospt,	enospt
	;0b4	refmpf	refblf	delmpf	crempf
	dw	enospt,	enospt,	enospt,	enospt
	;0b8	disint	enaint	retwup	retint
	dw	enospt,	enospt,	enospt,	enospt
	;0bc	refiXX	chgiXX		
	dw	enospt,	enospt,	ersfn,	defint
	;0c0				
	dw	sndmsg,	sndmsg,	rcvmsg,	rcvmsg
	;0c4				
	dw	refmbx,	ersfn,	delmbx,	crembx
	;0c8				
	dw	sigsem,	sigsem,	waisem,	waisem
	;0cc				
	dw	refsem,	ersfn,	delsem,	cresem
	;0d0				
	dw	setflg,	clrflg,	waiflg,	waiflg
	;0d4				
	dw	refflg,	ersfn,	delflg,	creflg
	;0d8				
	dw	canwup,	wuptsk,	slptsk,	tslptsk
	;0dc				
	dw	frsmtsk,rsmtsk,	ersfn,	sustsk
	;0e0	rasext			
	dw	enospt,	relwai,	disdsp,	enadsp
	;0e4			abotsk	
	dw	rotrdq,	chgpri,	enospt,	tertsk
	;0e8				
	dw	gettid,	statsk, exdtsk,	exttsk
	;0ec		hdrsts		
	dw	reftsk,	enospt,	deltsk,	cretsk
	;0f0			refcfg	retsvc
	dw	getver,	ersfn,	enospt,	enospt
	;0f4	refsys	defexc	defsvc	delsvc
	dw	enospt,	enospt,	enospt,	enospt
	;0f8	loccpu	unlcpu
	dw	enospt,	enospt,	ersfn,	ersfn
	;0fc
	dw	ersfn,	ersfn,	ersfn,	ersfn


	org	1200h
int62h:
	push	DS
	push	CX
	push	BX
	mov	BX,CS
	mov	DS,BX
	mov	BX,SP
			;stack
			; SS:SP	BX
			;  +2	CX
			;  +4	DS
			;  +6	IP
			;  +8	CS
			;  +0a	flags
	
	mov	AH,fnc_top
	sal	AX,1
	
	test	byte ptr SS:[BX+0bh],2	;check IF
	mov	CH,0ffh
	jz	bra_sys
	sti
	not	CH
bra_sys:
	mov	CL,dsp_flg
	xchg	AX,BX			;AX=SP
	jmp	word ptr [BX]

enospt:
trcvmsg:
twaisem:
twaiflg:
dlytsk:
tslptsk:
	pop_err	cnospt

ersfn:
	pop_err	crsfn



		;ディスパッチ制御に関するシステムコール

disdsp:
	;	entry AX-0ffe2h
	;	exit  AX-ercd
	;	          E_OK
	;	          E_CTX
	and	CH,CH
	jnz	ectx		;IF=0 ならば e_ctx
	mov	dsp_flg,0ffh
	pop_eok


enadsp:
	;	entry AX-0ffe3h
	;	exit  AX-ercd
	;	          E_OK
	;	          E_CTX
	and	CH,CH
	jnz	ectx		;IF=0 ならば e_ctx
	xor	AX,AX
	mov	dsp_flg,AL	;AL=0
	cli
	jmp	disp

ectx:
	pop_err	cctx



		;タスク起床に関係するシステムコール

slptsk:
	;	entry AX-0ffdah
	;	exit  AX-ercd
	;	          E_OK
	;	          E_RLWAI
	;	          E_CTX
	and	CX,CX
	jnz	ectx
	
	mov	BL,run_tsk
	mov	BH,mlk_top+2	;BH=wupcntのアドレス
	
	cli
	dec	byte ptr [BX+1]
	jnz	slptsk1
	
	mov	byte ptr [BX],4	;tskstat is wait
	
	mov	BH,mlk_top	;BH=メインリンク
	del_que

	xor	AX,AX
	jmp	disp
slptsk1:
	pop_eok



canwup:
	;	entry AX-0ffd8h
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	      BX-wupcnt
	
	cnv_tis	eid

	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	AX,[BX]		;AL=tskstat
				;AH=wupcnt+1
	chk_tst	6, eobj, enoexs

	and	AH,AH
	jz	canwup1		;now sleeping
	dec	AH		;BX=wupcnt
	mov	byte ptr [BX+1],1	;wupcntをクリア
canwup1:
	mov	BL,AH
	xor	AX,AX
	mov	BH,AL		;AL=0
	inc	SP
	inc	SP
	pop	CX
	pop	DS
	iret
	

eid:
	pop_err	cid

eobj:
	pop_err	cobj

epar:
	pop_err	cpar

enoexs:
	pop_err	cnoexs

eqovr:
	pop_err	cqovr



wuptsk:
	;	entry AX-0ffd9h
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_QOVR
	
	cnv_tid	eid

		;BL=タスクのリンクポインタ
	mov	BH,mlk_top+2	;BH=wupcnt+1/tskstat
	cli
	mov	AX,[BX]		;AL=tskstat
				;AH=wupcnt+1
	chk_tst	6, eobj, enoexs

	and	AH,AH
	jz	wuptsk1
	inc	AH
	jz	eqovr
	mov	[BX+1],AH	;wupcntを書き込み
	pop_eok

wuptsk1:
	mov	AL,BL
	mov	word ptr [BX],102h	;tskstat=ready
	mov	BL,[BX+2]	;BL=tskpri
	dec	BH		;BH=mlk_top+1
	ins_que

	ext_eok	CX



		;優先度に関係するシステムコール

rotrdq:
	;	entry AX-0ffe4h
	;	      BX-tskpri
	;	exit  AX-ercd
	;	          E_OK
	;	          E_PAR
	
	mov	BX,SP
	mov	AL,SS:[BX]
	cnv_pri	epar, rotrdq2

	mov	BL,run_tsk
	mov	BH,mlk_top+2
	
	cli
	cmp	[BX+2],AL
	jz	rotrdq3		;自タスクの優先度
	
	mov	BH,mlk_top	;BH=メインリンクのアドレス
	mov	BL,AL		;AL=pri
	sub	BL,4
	mov	BL,[BX]		;priの先頭のタスク
	
	cmp	AL,BL		;その優先度のタスクがない
	jz	rotrdq1
	
	xchg	AL,BL		;BL=pri
				;AL=先頭タスク
	inc	BH		;BH=バックリンクのアドレス
	cmp	[BX],AL		;レディキューが変化する
	jnz	del_insx	;レディキューの更新
rotrdq1:
	pop_eok

rotrdq2:
	mov	BL,run_tsk
	mov	BH,mlk_top+2
	cli
	mov	AL,[BX+2]	;AL=pri
rotrdq3:
	dec	BH		;BH=バックリンクのアドレス
	xchg	BL,AL		;AL=tskid
				;BL=pri
	cmp	[BX],AL
	jz	rotrdq1		;自タスクのみ
	jmp	del_insx

chgpri:
	;	entry AX-0ffe5h
	;	      DX-tskid
	;	      BX-tskpri
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_PAR
	mov	BX,SP
	mov	AL,SS:[BX]
	cnv_tis	eid1

		;BL=タスクのリンクポインタ
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	cnv_pri	epar1, chgpri1

	jmp	chgpri2
chgpri1:
	mov	AL,[BX+3]	;ipriを読みとり
chgpri2:
	mov	AH,[BX]		;AH=tskstat
	test	AH,10h
	jnz	eobj1		;対象タスクがdorment	;chg_pri
	and	AH,AH
	jz	enoexs1		;対象タスクがno-exist	;chg_pri
	
	mov	[BX+2],AL	;AL=pri
	
	test	AH,2h
	jz	chgpri3		;tskstat is wait
	
	dec	BH		;BH=バックリンクのアドレス
	xchg	AL,BL		;BL=pri
				;AL=tsk
	cmp	[BX],AL
	jz	chgpri3		;実行しても変化なし
	

del_insx:
	del_ins

	and	CX,CX
	jnz	chgpri3
	xor	AX,AX
	jmp	disp
chgpri3:
	pop_eok


eid1:
	pop_err	cid

eobj1:
	pop_err	cobj

epar1:
	pop_err	cpar

enoexs1:
	pop_err	cnoexs



tertsk:
	;	entry AX-0ffe7h
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	
	cnv_tid	eid1

		;BL=タスクのリンクポインタ
	cmp	BL,run_tsk
	jz	eobj1
	
			;（tskstat チェック）
	cli
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	mov	AL,[BX]		;AL=tskstat
	chk_tst	6, eobj1, enoexs1

	mov	byte ptr [BX],10h	;tskstat=dorment
	
		;BLで示されるリンクを削除する（メインリンク）
		;もし、起床待ちであっても、悪影響はない
	
	mov	BH,mlk_top	;BH=メインリンクのアドレス
	del_que

	pop_eok


statsk:
	;	entry AX-0ffe9h
	;	      DX-tskid
	;	      BX-stacd
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	
	or	CH,CL
	mov	BX,SP
	mov	AX,SS:[BX]		;AX=stacd
	
	cnv_tid	eid1

		;BL=タスクのリンクポインタ
			;（tskstat チェック）
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	CL,[BX]		;CL=tskstat
	and	CL,CL
	jz	enoexs1		;対象タスクがno-exist
	test	CL,10h
	jz	eobj1		;対象タスクがdorment でない
	
	mov	[BX+102h],AX	;起動タスクのＡＸ＝stacd
	
	mov	word ptr [BX],0102h	;tskstat=02h(ready), wupcnt+1=1
	mov	CL,[BX+3]	;CL=itskpri
	mov	[BX+2],CL	;tskpri=itskpri
	
	mov	AL,BL		;AL=tsk_ptr
	mov	BL,CL		;BL=tskpri
	dec	BH		;BH=バックリンクのアドレス
	ins_que

	mov	BL,AL		;BL=元々のBL
	
	mov	byte ptr [BX+1],0	;suscnt=0
	
	and	CH,CH		;ディスパッチフラグ
	pushf
	push	ES
	
	test	byte ptr [BX+0c00h],1	;tskatr	ここからフラグ変更禁止
							;｜
	les	AX,[BX+900h]	;ES:AX=initial SS:SP	;｜
							;｜
	mov	[BX+400h],AX	;SP			;｜
	mov	CX,ES					;｜
	mov	[BX+402h],CX	;SS			;｜
							;｜
	mov	CX,[BX+602h]	;CX:BX=initial CS:IP	;｜
	mov	BX,[BX+600h]				;｜
	xchg	AX,BX					;｜
							;｜
	mov	ES:[BX+10h],AX	;IPスタックに書き込み	;｜
	mov	ES:[BX+12h],CX	;CS			;｜
	mov	word ptr ES:[BX+14h],7202h	;flags	;｜
							;｜
	jz	statsk1	;tskatr=TA_ASM			;ここまで
	mov	CX,ES		;SS（ここではES）を基準レジスタにする
statsk1:
	mov	ES:[BX+4],CX	;ES
	mov	ES:[BX+0eh],CX	;DS
	
	mov	CX,CS		;RETF用
	mov	word ptr ES:[BX+16h],offset hlng_ret
	mov	ES:[BX+18h],CX
	
	pop	ES
	popf
	jz	statsk2		;ディスパッチ可能
	pop_eok

statsk2:
	xor	AX,AX
	jmp	disp


hlng_ret:
	push	DS		;スタックに積む必要はないが、
	push	CX		;デバッグ時のスタックトレース
	push	BX		;を考慮
	mov	BX,CS
	mov	DS,BX

exttsk:
	;	entry AX-0ffebh
	;	exit  
	
		;ディスパッチ状態は、いっさい考慮しない
	
	mov	BH,mlk_top	;BH=メインリンクのアドレス
	mov	BL,run_tsk
	
	cli
	mov	byte ptr [BX+200h],10h	;tskstat=dorment
	del_que

	mov	dsp_flg,0	;ディスパッチ許可
	jmp	disp

exdtsk:
	;	entry AX-0ffeah
	;	exit  
	
		;ディスパッチ状態は、いっさい考慮しない
	
	mov	BH,mlk_top	;BH=メインリンクのアドレス
	mov	BL,run_tsk
	cli
	mov	byte ptr [BX+200h],0	;tskstat=no-exist
	del_que

	mov	dsp_flg,0	;ディスパッチ許可
	jmp	disp

gettid:
	;	entry AX-0ffe8h
	;	exit  AX-ercd
	;	          E_OK
	;	      DX-tskid
	
	mov	DL,run_tsk
	shr	DL,1
	shr	DL,1
	xor	AX,AX
	mov	DH,AL
	pop_wrk


cretsk:
	;	entry AX-0ffefh
	;	      DX-tsk_id
	;	      ES:SI-pk_ctsk
	;	          exinf1
	;	          exinf2
	;	          tskatr
	;	            b0-TA_HLNG（stackを直接指定）
	;	          task(offset,segment)
	;	          itskpri
	;	          stksz
	;	          stack(offset,segment)
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_RSATR
	;	          E_OBJ
	;	          E_PAR
	
	cnv_tid	eid1a

		;BL=tsk_ptr
			;（tskstat チェック）
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	test	byte ptr [BX],0ffh	;AL=tskstat
	jnz	eobj1a		;対象タスクがすでに存在する
	
	mov	AL,ES:[SI+0ah]	;itskpri
	cnv_pri	epar2, epar2
	
	mov	CX,ES:[SI+4]	;tskatr
	
	test	CX,0fffeh
	jnz	ersatr2
	
	mov	[BX+3],AL	;itskpri
	mov	byte ptr [BX],10h	;tskstat=dorment
	
	mov	[BX+0a00h],CL	;tskatrをＴＣＢに格納
	and	CX,CX		;tskatr
	jz	cretsk1		;TA_ASM
			;TA_HLNG （指定スタックを使用）
	
	mov	AX,ES:[SI+0eh]	;initial SP
	mov	CX,ES:[SI+10h]	;initial SS
	sub	AX,1ah		;コンテキストが退避された状態として扱う
	
	jmp	cretsk2
cretsk1:
				;TA_ASM （内部スタックを使用）
	mov	AH,BL		;BL=tskid*4
	shr	AH,1		;AH=tskid*2
	inc	AH
	inc	AH
	add	AH,high offset bottom	;AXはスタックエンド-14h
	xor	AL,AL
				;AX=initial SP
	mov	CX,CS		;initial SS
cretsk2:
	mov	[BX+700h],AX
	mov	[BX+702h],CX	;stackをＴＣＢに格納
	
	mov	AX,ES:[SI+6]	;initial-IP
	mov	CX,ES:[SI+8]	;initial-CS
	
	mov	[BX+400h],AX
	mov	[BX+402h],CX	;taskをＴＣＢに格納
	
	mov	AX,ES:[SI]	;exinf-low
	mov	CX,ES:[SI+2]	;exinf-high
	mov	[BX+800h],AX
	mov	[BX+802h],CX	;exinfをＴＣＢに格納
	
	pop_eok


eid1a:
	pop_err	cid

eobj1a:
	pop_err	cobj

epar2:
	pop_err	cpar

ersatr2:
	pop_err	crsatr



deltsk:
	;	entry AX-0ffeeh
	;	      DX-tsk_id
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	
	cnv_tid	eid1a

		;BL=タスクのリンクポインタ
			;（tskstat チェック）
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	AL,[BX]		;AL=tskstat
	chk_tst	10h, eobj2, enoexs2

	xor	AX,AX
	mov	[BX],AL		;tskstat=no-exist
	pop_wrk


enoexs2:
	pop_err	cnoexs

eqovr2:
	pop_err	cqovr


defint:
	;	entry AX-0ffbfh
	;	      BX-dintno
	;	      ES:SI-pk_dint
	;	          intatr
	;	              b0-TA_HLNG
	;	          inthdr
	;	exit  AX-ercd
	;	          E_OK
	;	          E_RSATR
	;	          E_PAR
	
	mov	BX,SP
	mov	BL,SS:[BX]
	xor	BH,BH
	
	sal	BX,1			;times 4
	sal	BX,1
	
	test	word ptr ES:[SI],0ffffh
	jnz	ersatr2
	lds	AX,ES:[SI+2]	;IP
	
	push	DS
	xor	CX,CX
	mov	DS,CX		;DS=0
	pop	CX		;CX=CS
	
	cli
	mov	[BX],AX
	mov	[BX+2],CX
	
	pop_eok


eid2:
	pop_err	cid

eobj2:
	pop_err	cobj



sustsk:
	;	entry AX-0ffdfh
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_QOVR
	
	cnv_tid	eid2

		;BL=タスクのリンクポインタ
			;（tskstat チェック）
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	AL,[BX]		;AL=tskstat
	chk_tst	6, eobj2, enoexs2

	mov	BH,mlk_top
	mov	AL,[BX+1]	;AL=suscnt
	inc	AL
	jz	eqovr2
	mov	[BX+1],AL
	
	pop_eok


rsmtsk:
	;	entry AX-0ffddh
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	cnv_tid	eid3

		;BL=タスクのリンクポインタ
			;（tskstat チェック）
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	AL,[BX]		;AL=tskstat
	chk_tst	6, eobj3, enoexs3

	mov	BH,mlk_top
	mov	AL,[BX+1]	;AL=suscnt
	and	AL,AL
	jz	eobj3		;not suspended
	dec	AL
	mov	[BX+1],AL
	
	jnz	rsmtsk1		;suspend 状態が継続
	and	CX,CX
	jnz	rsmtsk1
	xor	AX,AX
	jmp	disp
rsmtsk1:
	pop_eok


frsmtsk:
	;	entry AX-0ffdch
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_OACV
	
	cnv_tid	eid3

		;BL=タスクのリンクポインタ
			;（tskstat チェック）
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	AL,[BX]		;AL=tskstat
	chk_tst	6, eobj3, enoexs3

	mov	BH,mlk_top
	xor	AX,AX
	xchg	[BX+1],AL	;AL=suscnt
				;suscnt=0
	and	AL,AL
	jz	eobj3		;not suspended
	ext_eok	CX


eid3:
	pop_err	cid

eobj3:
	pop_err	cobj

eqovr3:
	pop_err	cqovr

enoexs3:
	pop_err	cnoexs



sigsem:
	;	entry AX-0ffc9h
	;	      DX-semid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_QOVR
	cnv_sid	eid3

	mov	BH,mlk_top
	cli
	chk_lnk	sigsem1, enoexs3

	xor	AL,BL		;AL=先頭のセマフォ待ちタスク
	inc	BH		;BH=mlk_top+1
	ext_wai

	ext_eok	CX

sigsem1:
	mov	BH,mlq_top
	mov	AL,[BX]
	inc	AL
	jz	eqovr3
	mov	[BX],AL
	
	pop_eok


waisem:
	;	entry AX-0ffcbh
	;	      DX-semid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_RLWAI
	;	          E_DLT
	;	          E_CTX
	chk_ctx

	cnv_sid	eid4

	mov	BH,mlk_top+1
	cli
	chk_lnk	waisem2, enoexs4

			;セマフォ待ちタスクが存在する
waisem1:
	ent_wai

waisem2:
	mov	AL,[BX+600h]
	and	AL,AL
	jz	waisem1		;semcnt=0
	dec	AL
	mov	[BX+600h],AL
	pop_eok


eid4:
	pop_err	cid

eobj4:
	pop_err	cobj

etmout4:
	pop_err	ctmout

ersatr4:
	pop_err	crsatr

enoexs4:
	pop_err	cnoexs


preqsem:
	;	entry AX-0ff95h
	;	      DX-semid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_TMOUT
	;	          E_PAR
	cnv_sid	eid4

	mov	BH,mlk_top+1
	cli
	chk_lnk	preqsem1, enoexs4

	jmp	etmout4		;セマフォ待ちタスクが存在する
preqsem1:
	mov	BH,mlq_top
	mov	AL,[BX]		;AL=semcnt
	and	AL,AL
	jz	etmout4		;semcnt=0
	
	dec	AL
	mov	[BX],AL
	pop_eok


cresem:
	;	entry AX-0ffcfh
	;	      DX-semid
	;	      ES:SI-pk_csem
	;	          exinf1
	;	          exinf2
	;	          sematr
	;	          isemcnt
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_RSATR
	;	          E_OBJ
	cnv_sid	eid4

	mov	BH,mlk_top
	cli
	chk_nex	eobj4

	test	word ptr ES:[SI+4],0ffffh
	jnz	ersatr4
	
	mov	AX,ES:[SI]	;exinf-low
	mov	CX,ES:[SI+2]	;exinf-high
	mov	[BX+47dh],AX
	mov	[BX+47fh],CX
	
	mov	AL,ES:[SI+6]	;AL=isemcnt
	mov	[BX+700h],AL
				;BH=メインリンクのアドレス
	del_que

	pop_eok


delsem:
	;	entry AX-0ffceh
	;	      DX-semid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	or	CH,CL
	cnv_sid	eid5

	mov	BH,mlk_top
	cli
	chk_lnk	delsem2, enoexs5

	xor	BL,AL		;BL=nxt_ptr
delsem1:
	mov	CL,[BX]		;CL=nxt_ptr
	mov	byte ptr [BX+200h],2	;tskstat=ready
	mov	word ptr [BX+302h],cdlt	;AX=e_dlt
	
	mov	AL,[BX+202h]	;AL=tskpri
	xchg	AL,BL		;AL=tsk_ptr
				;BL=tskpri
	inc	BH		;BH=mlk_top+1
	ins_que			;リンクは強制的に切る

	mov	BL,CL
	test	BL,3
	jz	delsem1
delsem2:
	mov	AL,BL
	mov	BL,83h		;semid=0
	inc	BH		;BH=バックリンクのアドレス
	ins_que

	ext_eok	CH


eid5:
	pop_err	cid

eobj5:
	pop_err	cobj
enoexs5:
	pop_err	cnoexs



relwai:
	;	entry AX-0ffe1h
	;	      DX-tskid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	cnv_tid	eid5

		;BL=タスクのリンクポインタ
	mov	BH,mlk_top+2	;BH=tskstat/wupcnt+1
	cli
	mov	AX,[BX]		;AL=tskstat
				;AH=wupcnt+1
	chk_tst	4, eobj5, enoexs5

	mov	word ptr [BX+102h],crlwai	;エラーコード
	mov	AL,[BX+2]	;pri を読み込み
	
	and	AH,AH		;AH=wupcnt+1
	jnz	relwai2
	
			;slp_tsk の解除
	
	mov	word ptr [BX],0102h	;wupcnt=1
					;tskstat is ready
	xchg	AL,BL		;BL=pri, AL=tsk
	dec	BH		;BH=バックリンクのアドレス
	ins_que

	jmp	relwai3
relwai2:
			;セマフォ待ち・他の解除
	mov	byte ptr [BX],2	;tskstat is ready
	xchg	AL,BL		;BL=pri, AL=tsk
	dec	BH		;BH=バックリンクのアドレス
	del_ins

relwai3:
	ext_eok	CX


ersatr7:
	pop_err	crsatr

eid7:
	pop_err	cid

eobj7:
	pop_err	cobj



creflg:
	;	entry AX-0ffd7h
	;	      DX-flgid
	;	      ES:SI-pk_cflg
	;	          exinf1
	;	          exinf2
	;	          flgatr
	;	              b0-TA_WMUL
	;	          iflgptn
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_RSATR
	;	          E_OBJ
	;	          E_PAR
	cnv_fid	eid7

	mov	BH,mlk_top
	cli
	chk_nex	eobj7

	mov	CX,ES:[SI+4]	;CX=flgatr
	test	CX,0fff7h
	jnz	ersatr7
	mov	[BX+700h],CL	;flgattr@TCB を更新
	
	mov	AX,ES:[SI]	;exinf-low
	mov	CX,ES:[SI+2]	;exinf-high
	mov	[BX+0afeh],AX
	mov	[BX+0b00h],CX
	
	mov	CX,ES:[SI+6]	;CX=iflgptn
	mov	[BX+500h],CX	;FLG-pattern@TCB を更新
	del_que

	pop_eok


enoexs7:
	pop_err	cnoexs


delflg:
	;	entry AX-0ffd6h
	;	      DX-flgid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	or	CH,CL
	cnv_fid	eid7

	mov	BH,mlk_top+1	;フラグは逆方向リンク
	cli
	chk_lnk	delflg2, enoexs7

	xor	BL,AL		;BL=nxt_ptr
delflg1:
	mov	CL,[BX]		;CL=nxt_ptr
	mov	byte ptr [BX+100h],2	;tskstat=ready
	mov	word ptr [BX+202h],cdlt	;AX=e_dlt
	
	mov	AL,[BX+102h]	;AL=tskpri
	xchg	AL,BL		;AL=tsk_ptr
				;BL=tskpri
	ins_que			;リンクは強制的に切る

	inc	BH		;BH=mlk_top+1
	
	mov	BL,CL
	test	BL,3
	jz	delflg1
delflg2:
	mov	AL,BL
	mov	BL,82h		;flgid=0
	ins_que

	ext_eok	CH


polflg:
	;	entry AX-0ff96h
	;	      DX-flgid
	;	      DI-waiptn
	;	      BX-wfmode
	;	          b0-TWF_CLR
	;	          b1-TWF_ORF
	;	      CX-tmout
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_TMOUT
	;	          E_PAR
	;	      DI-flgptn
	cnv_fid	eid8

	mov	BH,mlk_top
	cli
	chk_lnk	polflg2, enoexs8

	test	byte ptr [BX+700h],8	;複数待ち可？
	jz	eobj8
polflg2:
	and	DI,DI
	jz	epar8
	
	mov	CX,[BX+500h]	;CX=FLG-pattern@TCB
	mov	AX,BX		;AL=flg_ptr
	
	mov	BX,SP
	mov	BX,SS:[BX]
	
	test	BX,0fffch
	jnz	epar8
	
	test	BL,2		;TWF_ORF
	jz	polflg3
	
	test	DI,CX
	jz	etmout8
	jmp	polflg4		;ok
polflg3:
	not	CX
	test	DI,CX
	not	CX
	
	jnz	etmout8
polflg4:
	mov	DI,CX
	test	BL,1		;TWF_CLR
	jz	polflg5
	
	xor	BX,BX
	xchg	BX,AX		;AX=0, BX=flg_ptr
	mov	[BX+500h],AX	;FLG-pattern@TCB=0
	pop_wrk

polflg5:
	pop_eok


etmout8:
	pop_err	ctmout

eid8:
	pop_err	cid

enoexs8:
	pop_err	cnoexs

eobj8:
	pop_err	cobj

epar8:
	pop_err	cpar


waiflg:
	;	entry AX-0ffd2h
	;	      DX-flgid
	;	      DI-waiptn
	;	      BX-wfmode
	;	          b0-TWF_CLR
	;	          b1-TWF_ORF
	;	      CX-tmout
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_OBJ
	;	          E_DLT
	;	          E_RLWAI
	;	          E_PAR
	;	          E_CTX
	;	      DI-flgptn
	chk_ctx

	cnv_fid	eid8

	mov	BH,mlk_top	;フラグキューは、前後が逆になる
	cli
	chk_lnk	waiflg2, enoexs8

	test	byte ptr [BX+700h],8	;複数待ち可？
	jz	eobj8
waiflg2:
	and	DI,DI
	jz	epar9
	
	mov	CX,[BX+500h]	;CX=FLG-pattern@TCB
	mov	AX,BX		;AX=flgptr
	
	mov	BX,SP
	mov	BX,SS:[BX]
	
	test	BX,0fffch
	jnz	epar9
	
	test	BL,2		;TWF_ORF
	jz	waiflg3
	
	test	DI,CX
	jz	waiflg6		;wai
	jmp	waiflg4		;ok
waiflg3:
	not	CX
	test	DI,CX
	not	CX
	
	jnz	waiflg6		;wai
waiflg4:
	mov	DI,CX
	test	BL,1		;TWF_CLR
	jz	waiflg5
	
	xor	BX,BX
	xchg	BX,AX		;AX=0, BX=flg_ptr
	mov	word ptr [BX+500h],AX	;FLG-pattern@TCB=0
	pop_wrk

waiflg5:
	pop_eok

waiflg6:
	mov	CX,BX		;CX=wfmode
	mov	BH,mlk_top
	mov	BL,run_tsk
				;ALはflg_ptr
	
	mov	[BX+101h],CL	;CL=wfmode
	mov	byte ptr [BX+200h],4	;tskstat=wait
	mov	[BX+300h],DI
	mov	word ptr [BX+302h],0	;リターンパラメータ
	
	xchg	AL,BL		;AL=run_tsk
				;BL=flg_ptr
	del_add

	xor	AX,AX
	jmp	disp
	
epar9:
	pop_err	cpar

eid9:
	pop_err	cid

enoexs9:
	pop_err	cnoexs


clrflg:
	;	entry AX-0ffd1h
	;	      DX-flgid
	;	      DI-clrptn
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	cnv_fid	eid9

	mov	BH,mlk_top+1
	cli
	chk_lnk	clrflg1, enoexs9

clrflg1:
	and	[BX+400h],DI	;FLG-pattern@TCB
	pop_eok


setflg:
	;	entry AX-0ffd0h
	;	      DX-flgid
	;	      DI-setptn
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	cnv_fid	eid9

	mov	BH,mlk_top+1
	cli
	mov	AL,[BX]
	mov	AH,AL
	xor	AH,BL
	jnz	setflg1
				;待ちタスクがない
	or	[BX+400h],DI	;FLG-pattern@TCB
	pop_eok

setflg1:
	test	AH,3
	jz	enoexs9
	
	push	DX	;+8	;ディスパッチ用意
	push	BP	;+4
	push	ES	;+6
	push	SI	;+2
	push	DI	;SS:SP
	
	or	DI,[BX+400h]	;DI=FLG-pattern@TCB
	mov	[BX+400h],DI	;FLG-pattern@TCBを更新
	mov	SI,200h
	
	or	CH,CL		;ディスパッチ禁止フラグ
	and	CH,1
	or	CH,BL		;CH=flg_ptr
				;    b0:０でディスパッチ許可
				;    b1:０でディスパッチ要求
	mov	CL,2
	mov	DL,AL		;DL=次のポインタ
setflg2:
	test	DL,CL		;CL=2
	jnz	setflg5		;キューの終わり
	mov	BL,DL
	mov	DX,[BX]		;DH=flgatr
				;DL=次のポインタ
	test	DH,CL		;CL=2
	jz	setflg3
			;or待ち
	test	[BX+SI],DI
	jz	setflg2		;条件不成立
	jmp	setflg4
setflg3:
			;and 待ち
	not	DI
	test	[BX+SI],DI
	not	DI
	jnz	setflg2		;条件不成立
setflg4:
			;条件成立処理
	mov	AL,BL		;AL=tskid
	inc	BH		;BH=tskstat/wupcnt+1
	mov	[BX],CL		;CL=2 (tskstat = ready)
	les	BP,[BX+SI]	;[BX+SI] = tcb_top
	mov	ES:[BP],DI	;ES:[BP]=DI
	mov	BL,[BX+2]	;BL=tskpri
			;ＡＸは、待ちにはいるときに０にしてある
	dec	BH		;BH=バックリンクのアドレス
	del_ins

	inc	BH		;BH=mlk_top+1
	
	and	CH,0fdh		;CH b1=0  ディスパッチ要求
	test	DH,1
	jz	setflg2		;クリア指定なし
	
	mov	BL,CH
	and	BL,0feh
	or	BL,CL		;CL=2
				;BL=flg_ptr
	xor	AX,AX
	mov	[BX+400h],AX	;FLG-pattern@TCB=0
setflg5:
	xor	AX,AX
	test	CH,3
	jnz	setflg8
				;要ディスパッチ＆ディスパッチ可能
	
	dec	BH		;BH=メインリンク
	mov	BL,sca_top	;pri=1 のポインタ
	mov	DX,0ff03h	;0ffh for suscnt, 03h for pointer
setflg6:
	mov	CX,[BX]		;(CH=suscnt)
				;CL=次のポインタ
	
	xchg	CL,BL		;BL=次のポインタ
				;CL=現ポインタ
	test	CX,DX
	jnz	setflg6		;suspended or point ready-que
	
			;CL= 実行すべきタスク
	
	mov	BL,run_tsk	;BL= 現在実行中のタスク
	cmp	BL,CL		;要ディスパッチ？
	jz	setflg7
	
	mov	BH,tcb_top	;スタックポインタを保存
	mov	[BX-0feh],AX	;タスクのスタックにレジスタを退避
	mov	AX,SS
	mov	[BX],SP
	mov	[BX+2],AX	;AX=SS
	
	mov	BL,CL		;BL= run状態のタスク
	
		;BX point the task which status is run
	
	les	SP,[BX]		;スタックを切り替える
	mov	AX,ES
	mov	SS,AX
setflg7:		;BL= run状態のタスク
	mov	run_tsk,BL
	mov	BH,tcb_top+1
	mov	AX,[BX]
setflg8:
	pop	DI
	pop	SI
	pop	ES
	pop	BP
	pop	DX
	pop_wrk



rcvmsg:
	;	entry AX-0ffc3h
	;	      DX-mbxid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_RLWAI
	;	          E_TMOUT
	;	          E_DLT
	;	          E_CTX
	;	      ES:SI-pk_msg
	chk_ctx

	cnv_mid	eid10

	mov	BH,mlk_top
	cli
	chk_lnk	rcvmsg3, enoexs10

rcvmsg2:
			;メッセージ待ちに入る
	mov	BH,mlk_top+1
	ent_wai
rcvmsg3:
			;待ちタスクがない
	mov	BH,mlq_top
	mov	AL,[BX]		;AL=nxtlnk
	cmp	AL,BL
	jz	rcvmsg2
	
	mov	BL,AL
	les	SI,[BX+100h]	;ES:SIにメッセージを受け取る
	del_mlq

	pop_eok


eid10:
	pop_err	cid

enoexs10:
	pop_err	cnoexs


prcvmsg:
	;	entry AX-0ff94h
	;	      DX-mbxid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_TMOUT
	;	      ES:SI-pk_msg
	cnv_mid	eid10

	mov	BH,mlk_top
	cli
	chk_lnk	prcvmsg2, enoexs10

prcvmsg1:
	pop_err	ctmout

prcvmsg2:
	mov	BH,mlq_top
	mov	AL,[BX]		;AL=nxtlnk
	cmp	AL,BL
	jz	prcvmsg1
	
	mov	BL,AL
	les	SI,[BX+100h]	;ES:SIにメッセージを受け取る
	del_mlq

	pop_eok


sndmsg:
	;	entry AX-0ffc1h
	;	      DX-mbxid
	;	      ES:SI-pk_msg
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	          E_QOVR
	
	cnv_mid	eid10

	mov	BH,mlk_top
	cli
	chk_lnk	sndmsg1, enoexs10

	xor	BL,AL		;BL=nxt_ptr
	mov	AL,BL
	lds	BX,[BX+400h]	;スタックポインタ
	mov	[BX+2],SI	;メッセージを渡す
	mov	[BX+4],ES
	
	mov	BX,CS
	mov	DS,BX
	mov	BH,mlk_top+1
	ext_wai

	ext_eok	CX

sndmsg1:
	mov	BH,mlq_top
	mov	AL,BL		;AL=mbx_ptr
	
	xor	BL,BL
	mov	AH,4		;サーチ用増分
sndmsg2:
			;メールリンクのあきサーチ
	cmp	[BX],BL
	jz	sndmsg3
	
	sub	BL,AH		;次のリンク
	jnz	sndmsg2
	pop_err	cqovr

sndmsg3:
	mov	[BX+100h],SI	;メッセージを保存
	mov	[BX+102h],ES
				;AL=mbx_ptr
				;BL=メールエントリ
	xchg	AL,BL
	ins_mlq

	pop_eok


delmbx:
	;	entry AX-0ffc6h
	;	      DX-mbxid
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	or	CH,CL
	cnv_mid	eid11

	mov	BH,mlk_top
	cli
	chk_lnk	delmbx2, enoexs11

	xor	BL,AL		;BL=nxt_ptr
delmbx1:
	mov	CL,[BX]		;CL=nxt_ptr
	mov	byte ptr [BX+200h],2	;tskstat=ready
	mov	word ptr [BX+302h],cdlt	;AX=e_dlt
	
	mov	AL,[BX+202h]	;AL=tskpri
	xchg	AL,BL		;AL=tsk_ptr
				;BL=tskpri
	inc	BH		;BH=mlk_top+1
	ins_que			;リンクは強制的に切る

	mov	BL,CL
	test	BL,3
	jz	delmbx1
	inc	BH		;BH=mlk_top+1
	jmp	delmbx4
delmbx2:
	mov	AL,BL
	mov	BH,mlq_top
	mov	CL,2
delmbx3:
	mov	AH,AL		;AH=AL=BL
	xchg	AX,[BX]
	mov	BL,AL
	
	test	AL,CL		;CL=2
	jz	delmbx3
	
	mov	BH,mlk_top+1
delmbx4:
	mov	AL,BL
	mov	BL,2		;mbxid=0
	ins_que

	ext_eok	CH


eid11:
	pop_err	cid

enoexs11:
	pop_err	cnoexs

eobj11:
	pop_err	cobj

ersatr11:
	pop_err	crsatr


crembx:
	;	entry AX-0ffc7h
	;	      DX-mbxid
	;	      ES:SI-pk_cmbx
	;	          exinf1
	;	          exinf2
	;	          mbxatr
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_RSATR
	;	          E_OBJ
	cnv_mid	eid11

	mov	BH,mlk_top
	cli
	chk_nex	eobj11

	test	word ptr ES:[SI+4],0ffffh
	jnz	ersatr11
	
	mov	AX,ES:[SI]	;exinf-low
	mov	CX,ES:[SI+2]	;exinf-high
	mov	[BX+0afeh],AX
	mov	[BX+0b00h],CX
	
	del_que

	pop_eok



getver:
	;	entry AX-0fff0h
	;	      ES:SI-pk_ver
	;	exit  AX-ercd
	;	          E_OK
	;	      ES:SI-pk_ver
	;	          maker
	;	          id
	;	          spver
	;	          prver
	;	          prno0
	;	          prno1
	;	          prno2
	;       	  prno3
	;	          cpu
	;	          var
	
	mov	AX,ES
	mov	DS,AX
	
	mov	word ptr [SI],0		;maker = 実験システム
	mov	word ptr [SI+2],-1	;id    = 未定義
	mov	word ptr [SI+4],5300h	;spver = μITRON 3.00
	mov	word ptr [SI+6],-1	;prver = 未定義
	mov	word ptr [SI+8],-1	;prno0 = 未定義
	mov	word ptr [SI+0ah],-1	;prno1 = 未定義
	mov	word ptr [SI+0ch],-1	;prno2 = 未定義
	mov	word ptr [SI+0eh],-1	;prno3 = 未定義
	mov	word ptr [SI+10h],60h	;cpu   = 8086
	mov	word ptr [SI+12h],4000h	;var   = レベルR
	
	pop_eok


refsem:
	;	entry AX-0ffcch
	;	      DX-semid
	;	      ES:SI-pk_rsem
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	      ES:SI-pk_rsem
	;	          exinf1
	;	          exinf2
	;	          wtsk
	;	          semcnt
	;	          unuid
	cnv_sid	eid12

	mov	BH,mlk_top
	cli
	chk_lnk	refsem1, enoexs12	;nolnkの時、AL=0になる

	xor	AL,BL		;AL=nxt_ptr
	shr	AL,1
	shr	AL,1
refsem1:
	xor	AH,AH
	mov	ES:[SI+4],AX	;wtsk
	
	mov	AX,[BX+47dh]	;exinf1
	mov	CX,[BX+47fh]	;exinf2
	mov	ES:[SI],AX
	mov	ES:[SI+2],CX
	
	mov	AL,[BX+700h]	;semcnt
	xor	AH,AH
	mov	ES:[SI+6],AX
	
	mov	AL,DS:[183h]	;sem_top
	shr	AL,1
	shr	AL,1
	and	AX,01fh
	mov	ES:[SI+8],AX	;AX=unuid
	
	pop_eok


eid12:
	pop_err	cid

enoexs12:
	pop_err	cnoexs


refflg:
	;	entry AX-0ffd4h
	;	      DX-flgid
	;	      ES:SI-pk_rflg
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	      ES:SI-pk_rflg
	;	          exinf1
	;	          exinf2
	;	          wtsk
	;	          flgptn
	;	          unuid
	cnv_fid	eid12

	mov	BH,mlk_top+1	;wtskを考慮して、後ろから見る
	cli
	chk_lnk	refflg1, enoexs12

	xor	AL,BL		;AL=nxt_ptr
	shr	AL,1
	shr	AL,1		;AL=wtsk
refflg1:
	xor	AH,AH
	mov	ES:[SI+4],AX	;wtsk
	
	mov	AX,[BX+9feh]	;exinf1
	mov	CX,[BX+0a00h]	;exinf2
	mov	ES:[SI],AX
	mov	ES:[SI+2],CX
	
	mov	AX,[BX+400h]	;flgptn
	mov	ES:[SI+6],AX
	
	mov	AL,DS:[282h]	;flg_top
	shr	AL,1
	shr	AL,1
	and	AX,01fh
	mov	ES:[SI+8],AX	;AX=unuid
	
	pop_eok


refmbx:
	;	entry AX-0ffc4h
	;	      DX-mbxid
	;	      ES:SI-pk_rmbx
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	      ES:SI-pk_rmbx
	;	          exinf1
	;	          exinf2
	;	          wtsk
	;	          msgcnt
	;	          unuid
	;	          o_pk_msg
	;	          s_pk_msg
	;	          mbxfre
	cnv_mid	eid12

	mov	BH,mlk_top
	cli
	chk_lnk	refmbx1, enoexs12

	xor	AL,BL		;AL=nxt_ptr
	shr	AL,1
	shr	AL,1		;AL=wtsk
refmbx1:
	xor	AH,AH
	mov	ES:[SI+4],AX	;wtsk
	
	mov	AX,[BX+0afeh]	;exinf1
	mov	CX,[BX+0b00h]	;exinf2
	mov	ES:[SI],AX
	mov	ES:[SI+2],CX
	
	mov	AL,DS:[102h]	;mbx_top
	shr	AL,1
	shr	AL,1
	and	AX,01fh
	mov	ES:[SI+8],AX	;unuse
	
	mov	CX,200h		;CH=2, CL=msgcnt
	mov	BH,mlq_top
	mov	BL,[BX]		;nxt_ptr
	test	BL,CH		;   is msg?
	jnz	refmbx3		;No messege
	
	mov	AX,[BX+100h]	;o_pk_msg
	mov	ES:[SI+0ah],AX
	mov	AX,[BX+102h]	;s_pk_msg
	mov	ES:[SI+0ch],AX
refmbx2:
	inc	CL
	mov	BL,[BX]		;nxt_ptr
	test	BL,CH		;   is msg?
	jz	refmbx2
	
refmbx3:
	xor	CH,CH
	mov	ES:[SI+6],CX	;msgcnt
	mov	AX,400h		;AH=4, AL=counter
	mov	BL,CH		;BL=mlq_top
	mov	CL,40h		;loop counter
	
refmbx4:
	add	BL,AH		;AH=4
	cmp	[BX],BL
	jnz	refmbx5
	inc	AL
refmbx5:
	loop	refmbx4
	
	mov	AH,CH		;CH=0
	mov	ES:[SI+0eh],AX	;mbxfre
	pop_eok


eid13:
	pop_err	cid

enoexs13:
	pop_err	cnoexs


reftsk:
	;	entry AX-0ffech
	;	      DX-tskid
	;	      ES:SI-pk_rtsk
	;	exit  AX-ercd
	;	          E_OK
	;	          E_ID
	;	          E_NOEXS
	;	      ES:SI-pk_rtsk
	;	          exinf1
	;	          exinf2
	;	          tskpri
	;	          tskstat
	;	              b0-RUN
	;	              b1-READY
	;	              b2-WAIT
	;	              b3-SUSPEND
	;	              b4-DORMENT
	;	          unuid
	;	          itskpri
	;	          wupcnt
	;	          suscnt
	cnv_tis	eid13

	mov	BH,mlk_top
	cli
	
	mov	AX,[BX+200h]	;AL=tskstat
				;AH=wupcnt+1
	and	AL,AL
	jz	enoexs13
	
	mov	CX,[BX+202h]	;CL=tskpri
				;CH=itskpri
	test	AL,6
	jnz	reftsk1		;not dormant
	
		;dormant
	xor	AH,AH		;wupcnt は無視する
	mov	ES:[SI+6],AX	;tskstat
	
	mov	AL,CH		;itskpri
	shr	AL,1
	shr	AL,1		;AX=itskpri
	mov	ES:[SI+4],AX	;tskpri
	mov	ES:[SI+0ah],AX	;itskpri
	
	mov	AL,AH		;AX=0
	mov	ES:[SI+0ch],AX	;wupcnt
	mov	ES:[SI+0eh],AX	;suscnt
	
	jmp	reftsk5
	
reftsk1:
		;not dormant
	push	AX
	mov	AL,CH		;CH=itskpri
	xor	AH,AH
	shr	AL,1
	shr	AL,1		;AX=itskpri
	mov	ES:[SI+0ah],AX	;itskpri
	
	mov	CH,AH		;AH=0
	shr	CL,1
	shr	CL,1		;AX=itskpri
	mov	ES:[SI+4],CX	;CX=tskpri
	pop	AX
	
	and	AH,AH		;AH=wupcnt+1
	jz	reftsk2
	dec	AH		;AH=wupcnt
reftsk2:
	mov	CL,AH		;CH=0
	mov	ES:[SI+0ch],CX	;CX=wupcnt
	
	mov	CL,[BX+1]	;CL=suscnt
	mov	ES:[SI+0eh],CX	;suscnt
	mov	AH,CH		;CH=0
	
	cmp	BL,run_tsk
	jnz	reftsk3
	
	mov	AL,1		;tskstat=run
	jmp	reftsk4
reftsk3:
	and	CX,CX
	jz	reftsk4
	
	or	AL,8		;suspend
	and	AL,0fdh
reftsk4:
	mov	ES:[SI+6],AX
reftsk5:
	mov	AX,[BX+0a00h]	;exinf1
	mov	CX,[BX+0a02h]	;exinf2
	mov	ES:[SI],AX
	mov	ES:[SI+2],CX
	
	mov	CX,40h		;repeat counter
	mov	AX,4
	mov	BX,300h		;tskstat for tskid=0
reftsk6:
	add	BL,AL
	or	[BX],AH		;tskstat=no-exist?
	jz	reftsk7
	loop	reftsk6
reftsk7:
	mov	AL,BL		;AH=0
	shr	AL,1
	shr	AL,1		;AX=unuid
	mov	ES:[SI+8],AX
	
	pop_eok



int63h:			;ret_int
	add	SP,6
	test	CS:dsp_flg,0ffh
	jz	int63h2
	
	iret
	
int63h2:
	push	DS	;+0eh
	push	CX	;+0ch
	push	BX	;+0ah
	mov	BX,CS
	mov	DS,BX


disp:		;DS,BX,CX は保存されているものとする
		;AXは設定すること
	
		;レディキューを走査
	push	DX
	
	mov	BH,mlk_top	;メインリンク
	mov	BL,sca_top	;pri=1 の次のポインタ
	mov	DX,0ff03h	;0ffh for suscnt, 03h for pointer
	
disp2:
	mov	CX,[BX]		;(CH=suscnt)
				;CL=次のポインタ
	
	xchg	CL,BL		;BL=次のポインタ
				;CL=現ポインタ
	
	test	CX,DX
	jnz	disp2		;suspended or point ready-que
	
			;CL= 実行すべきタスク
	
	mov	BL,run_tsk	;BL= 現在実行中のタスク
	cmp	BL,CL		;要ディスパッチ？
	jz	disp3
				;TCBにAXを退避
	
	mov	BH,tcb_top	;スタックポインタを保存
	mov	[BX-0feh],AX	;タスクのスタックにレジスタを退避
	push	BP	;+6
	push	ES	;+4
	push	SI	;+2
	push	DI	;SS:SP
	
	mov	AX,SS
	mov	[BX],SP
	mov	[BX+2],AX	;AX=SS
	
	mov	BL,CL		;BL= run状態のタスク
	mov	run_tsk,CL
	
		;BX point the task which status is run
	
	les	SP,[BX]		;スタックを切り替える
	mov	AX,ES
	mov	SS,AX
	
	mov	BH,tcb_top-1
	
	mov	AX,[BX+2]
	
	pop	DI		;タスクのレジスタを復旧
	pop	SI
	pop	ES
	pop	BP
	
disp3:
	pop	DX
	pop_wrk


tskid0:
				;実行するタスクがないときのダミー処理用
	jmp	tskid0



		;ここからスタックエリア
bottom:
	;db	64*512+18h dup (?)
	

ini_tcb:	;ＴＣＢ初期化
		;AX,BX,CX,DX,SI,DI,DSは破壊される
	
	mov	AX,CS
	mov	DS,AX
	
	sti
	
	mov	DX,offset mes_ini	;起動メッセージ表示
	mov	AH,9
	int	21h
	
	cli
	
	mov	AX,0706h
	mov	BH,mlk_top		;BX=メインリンク
	xor	BL,BL
	mov	CX,0020h
	mov	DX,0404h
	mov	SI,7f7fh
	mov	DI,8080h
ini_tcb1:
	mov	[BX],BL		;tsk_ptr
	mov	[BX+1],CH	;suscnt
	mov	[BX+2],AX	;mbx_ptr & ready-que
	mov	[BX+200h],CH	;tskstat
	add	AX,DX
	and	AX,SI
	add	BL,DL
	loop	ini_tcb1
	
	mov	AX,08786h
	mov	CX,0020h
ini_tcb2:
	mov	[BX],BL		;tsk_ptr
	mov	[BX+1],CH	;suscnt
	mov	[BX+2],AX	;flg_ptr & sem_ptr
	mov	[BX+200h],CH	;tskstat
	and	AX,SI
	add	AX,DX
	or	AX,DI
	add	BL,DL
	loop	ini_tcb2
	
	inc	BH
	mov	AX,7f7eh
	mov	CX,0020h
ini_tcb3:
	mov	[BX],BL
	mov	[BX+1],CH
	mov	[BX+2],AX
	add	AX,DX
	and	AX,SI
	add	BL,DL
	loop	ini_tcb3
	
	mov	AX,0fffeh
	mov	CX,0020h
ini_tcb4:
	mov	[BX],BL
	mov	[BX+1],CH
	mov	[BX+2],AX
	and	AX,SI
	add	AX,DX
	or	AX,DI
	add	BL,DL
	loop	ini_tcb4
	
	mov	BH,mlq_top
	xor	BL,BL
ini_tcb5:
	mov	[BX],BL
	mov	[BX+1],BL
	inc	BL
	inc	BL
	jnz	ini_tcb5
	
	mov	BL,3
	mov	AL,0
	
	mov	BH,mlk_top+1	;BH=バックリンクのアドレス
	ins_que

	mov	BL,7fh
	mov	AL,4
	
	inc	BH		;BH=バックリンクのアドレス
	ins_que

	mov	BH,tcb_top
	xor	BL,BL
	mov	word ptr [BX-200h],102h	;tskid0=ready
	mov	word ptr [BX-1feh],303h	;tskid0 pri=0
	mov	word ptr [BX-1fch],102h	;tskid1=ready
	mov	word ptr [BX-1fah],7f7fh	;tskid1 pri=31
	
			;以下tskid=0の設定
	mov	CX,CS
	mov	AH,high offset bottom
	add	AH,2
	xor	AL,AL
	
	mov	[BX],AX		;スタックを設定
	mov	[BX+2],CX
	
	xchg	AX,BX
	mov	[BX+10h],offset tskid0	;IP
	mov	[BX+12h],CX	;CS
	mov	word ptr [BX+14h],7202h	;flags
	
	xor	AX,AX
	mov	DS,AX
	
	mov	BX,0188h
	
	mov	[BX],offset int62h
	mov	[BX+2],CX
	mov	[BX+4],offset int63h
	mov	[BX+6],CX
	
	jmp	near ptr noinit
	

code	ends
	end
