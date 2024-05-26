;
;    ASURA-I    include macro file   rel 1.00.00
;        Copyright (c) Mineyuki Kimoto 1994
;


;　レジスタ関係一覧表
;
;
;　・タスク起動時（TA_ASM）のレジスタ状態
;
;　　　　ＡＸ＝stacd
;　　　　ＣＳ＝ＤＳ＝ＥＳ
;　　　　ＳＳ：ＳＰ＝ASURA-I 内部スタック
;
;　・タスク起動時（TA_HLNG）のレジスタ状態
;
;　　　　ＡＸ＝stacd
;　　　　ＳＳ＝ＤＳ＝ＥＳ
;　　　　ＳＳ：ＳＰ＝cre_tsk で指定したstack
;
;　・タスク終了時のレジスタ指定
;
;　　　　レジスタは参照されない（RETFでも可）
;
;　・システムコール呼出時（ret_int 以外）のレジスタ指定
;
;　　　　ＡＸ＝システムコール番号
;　　　　ＢＸ＝汎用パラメータ
;　　　　ＣＸ＝（タイムアウト）　／未実装
;　　　　ＤＸ＝ＩＤ
;　　　　ＥＳ：ＳＩ＝パケットアドレス
;　　　　ＤＩ＝フラグパターン
;
;　・ret_int 呼出時のレジスタ指定
;
;　　　　ＣＳ：ＩＰとフラグを除く全レジスタを、割り込みハンドラ起動時の
;　　　状態に復旧する
;



	;エラーコード
	;
	;システムコール発行後、ＡＸレジスタに返される

e_ok	equ	0	;正常終了
e_nospt	equ	-17	;システムコール番号の異常
e_rsfn	equ	-20	;　　　〃
e_rsatr	equ	-24	;cre_??? や def_int で ???atr が異常
e_par	equ	-33	;汎用パラメータが異常
e_id	equ	-35	;???idが範囲外
e_noexs	equ	-52	;???idが存在しない（未生成／既削除）
e_obj	equ	-63	;???idの状態に違反（タスク状態／フラグ属性違反）
e_ctx	equ	-69	;コンテキスト状態違反（割り込み／ディスパッチ禁止状態）
e_qovr	equ	-73	;カウンタやキューがオーバーフロー
e_dlt	equ	-81	;待ち状態で???idが削除された
e_tmout	equ	-85	;ポーリングに失敗／（タイムアウト）
e_rlwai	equ	-86	;待ち状態でrel_waiされた



	;その他定数

ta_asm	equ	0
ta_hlng	equ	1
ta_wsgl	equ	0
ta_wmul	equ	8
ta_tfifo	equ	0
ta_mfifo	equ	0

tpri_run	equ	0
tsk_self	equ	0

tts_run	equ	1
tts_rdy	equ	2
tts_wai	equ	4
tts_sus	equ	8
tts_was	equ	0ch
tts_dmt	equ	10h

twf_andw	equ	0
twf_orw	equ	2
twf_clr	equ	1

;tmo_pol	equ	0
;tmo_fevr	equ	-1



	;構造体
	;pk_t1	pk_ctsk <?,?,1,task1,?,10h,,200h,?>	;のように使用する

pk_dmy	struc		;共通要素名を使用するためのダミー構造体
exinf1	dw	-1
exinf2	dw	-1
wtsk	dw	?
	dw	?
unuid	dw	?	;未使用ＩＤ
itskpri	dw	?
pk_dmy	ends

pk_ctsk	struc
	dw	-1	;exinf1
	dw	-1	;exinf2
tskatr	dw	0	;ta_asm | ta_hlng
o_task	dw	?
s_task	dw	?
	dw	?	;itskpri
	dw	?	;未使用
o_stack	dw	?	;ta_hlngのみ有効
s_stack	dw	?	;　　　〃
pk_ctsk	ends

pk_csem	struc
	dw	-1	;exinf1
	dw	-1	;exinf2
sematr	dw	0	;ta_tfifoのみ
isemcnt	dw	?
pk_csem	ends

pk_cflg	struc
	dw	-1	;exinf1
	dw	-1	;exinf2
flgatr	dw	?	;ta_wsgl | ta_wmul
iflgptn	dw	?
pk_cflg	ends

pk_cmbx	struc
	dw	-1
	dw	-1
mbxatr	dw	0	;ta_tfifo + ta_mfifo
pk_cmbx	ends

pk_dint	struc
intatr	dw	0	;ta_asm
o_inthdr	dw	?
s_inthdr	dw	?
pk_dint	ends

pk_ver	struc
maker	dw	?
id	dw	?
spver	dw	?
prver	dw	?
prno1	dw	?
prno2	dw	?
prno3	dw	?
prno4	dw	?
cpu	dw	?
var	dw	?
pk_ver	ends

pk_rtsk	struc
	dw	?	;exinf1
	dw	?	;exinf2
tskpri	dw	?
tskstat	dw	?
	dw	?	;unuid
	dw	?	;itskpri
wupcnt	dw	?
suscnt	dw	?
pk_rtsk	ends

pk_rsem	struc
	dw	?	;exinf1
	dw	?	;exinf2
	dw	?	;wtsk
semcnt	dw	?
	dw	?	;unuid
pk_rsem	ends

pk_rflg	struc
	dw	?	;exinf1
	dw	?	;exinf2
	dw	?	;wtsk
flgptn	dw	?
	dw	?	;unuid
pk_rflg	ends

pk_rmbx	struc
	dw	?	;exinf1
	dw	?	;exinf2
	dw	?	;wtsk
msgcnt	dw	?	;着信メッセージ数
	dw	?	;unuid
o_pk_msg	dw	?
s_pk_msg	dw	?
mbxfre	dw	?	;メールボックス空き容量
pk_rmbx	ends



	;ＡＳＵＲＡ－Ｉ常駐チェックマクロ

chk_ai	macro	error
	xor	AX,AX
	mov	DS,AX
	mov	AX,DS:[18ah]	;segment for int62h
	cmp	AX,DS:[18eh]	;segment for int63h
	jnz	&error
	
	mov	DS,AX
	cmp	word ptr DS:[0ah],'A$'
	jnz	&error
	cmp	word ptr DS:[0ch],'US'
	jnz	&error
	cmp	word ptr DS:[0eh],'AR'
	jnz	&error
	cmp	word ptr DS:[10h],'I_'
	jnz	&error
	
	endm



	;システムコールマクロ
	;
	;???_???　の形式は、システムコール番号をセットするだけ
	;???_???_i　の形式は、パラメータのレジスタセットも含む

cre_tsk	macro
	mov	AX,0ffefh
	int	62h
	endm

cre_tsk_i	macro	tskid, pk_ctsk
	mov	DX,&tskid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_ctsk
	mov	CS:[SI+8],AX
	cre_tsk
	endm

del_tsk	macro
	mov	AX,0ffeeh
	int	62h
	endm

del_tsk_i	macro	tskid
	mov	DX,&tskid
	del_tsk
	endm

sta_tsk	macro
	mov	AX,0ffe9h
	int	62h
	endm

sta_tsk_i	macro	tskid, stacd
	mov	DX,&tskid
	mov	BX,&stacd
	sta_tsk
	endm

ext_tsk	macro
	mov	AX,0ffebh
	int62h
	endm

exd_tsk	macro
	mov	AX,0ffeah
	int	62h
	endm

ter_tsk	macro
	mov	AX,0ffe7h
	int	62h
	endm

ter_tsk_i	macro	tskid
	mov	DX,&tskid
	ter_tsk
	endm

dis_dsp	macro
	mov	AX,0ffe2h
	int	62h
	endm

ena_dsp	macro
	mov	AX,0ffe3h
	int	62h
	endm

chg_pri	macro
	mov	AX,0ffe5h
	int	62h
	endm

chg_pri_i	macro	tskid, tskpri
	mov	DX,&tskid
	mov	BX,&tskpri
	chg_pri
	endm

rot_rdq	macro
	mov	AX,0ffe4h
	int	62h
	endm

rot_rdq_i	macro	tskpri
	mov	BX,&tskpri
	rot_rdq
	endm

rel_wai	macro
	mov	AX,0ffe1h
	int	62h
	endm

rel_wai_i	macro	tskid
	mov	DX,&tskid
	rel_wai
	endm

get_tid	macro
	mov	AX,0ffe8h
	int	62h
	endm

ref_tsk	macro
	mov	AX,0ffech
	int	62h
	endm

ref_tsk_i	macro	tskid, pk_rtsk
	mov	DX,&tskid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_rtsk
	ref_tsk
	endm

sus_tsk	macro
	mov	AX,0ffdfh
	int	62h
	endm

sus_tsk_i	macro	tskid
	mov	DX,&tskid
	sus_tsk
	endm

rsm_tsk	macro
	mov	AX,0ffddh
	int	62h
	endm

rsm_tsk_i	macro	tskid
	mov	DX,&tskid
	rsm_tsk
	endm

frsm_tsk	macro
	mov	AX,0ffdch
	int	62h
	endm

frsm_tsk_i	macro	tskid
	mov	DX,&tskid
	frsm_tsk
	endm

slp_tsk	macro
	mov	AX,0ffdah
	int	62h
	endm

tslp_tsk	macro
	mov	AX,0ffdbh
	int	62h
	endm

wup_tsk	macro
	mov	AX,0ffd9h
	int	62h
	endm

wup_tsk_i	macro	tskid
	mov	DX,&tskid
	wup_tsk
	endm

can_wup	macro
	mov	AX,0ffd8h
	int	62h
	endm

can_wup_i	macro	tskid
	mov	DX,&tskid
	can_wup
	endm

cre_sem	macro
	mov	AX,0ffcfh
	int	62h
	endm

cre_sem_i	macro	semid, pk_csem
	mov	DX,&semid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_csem
	cre_sem
	endm

del_sem	macro
	mov	AX,0ffceh
	int	62h
	endm

del_sem_i	macro	semid
	mov	DX,&semid
	del_sem
	endm

sig_sem	macro
	mov	AX,0ffc9h
	int	62h
	endm

sig_sem_i	macro	semid
	mov	DX,&semid
	sig_sem
	endm

wai_sem	macro
	mov	AX,0ffcbh
	int	62h
	endm

wai_sem_i	macro	semid
	mov	DX,&semid
	wai_sem
	endm

preq_sem	macro
	mov	AX,0ff95h
	int	62h
	endm

preq_sem_i	macro	semid
	mov	DX,&semid
	preq_sem
	endm

twai_sem	macro
	mov	AX,0ff55h
	int	62h
	endm

ref_sem	macro
	mov	AX,0ffcch
	int	62h
	endm

ref_sem_i	macro	semid, pk_rsem
	mov	DX,&semid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_rsem
	ref_sem
	endm

cre_flg	macro
	mov	AX,0ffd7h
	int	62h
	endm

cre_flg_i	macro	flgid, pk_cflg
	mov	DX,&flgid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_cflg
	cre_flg
	endm

del_flg	macro
	mov	AX,0ffd6h
	int	62h
	endm

del_flg_i	macro	flgid
	mov	DX,&flgid
	del_flg
	endm

set_flg	macro
	mov	AX,0ffd0h
	int	62h
	endm

set_flg_i	macro	flgid, setptn
	mov	DX,&flgid
	mov	DI,&setptn
	set_flg
	endm

clr_flg	macro
	mov	AX,0ffd1h
	int	62h
	endm

clr_flg_i	macro	flgid, clrptn
	mov	DX,&flgid
	mov	DI,&clrptn
	clr_flg
	endm

wai_flg	macro
	mov	AX,0ffd2h
	int	62h
	endm

wai_flg_i	macro	flgid, waiptn, wfmode
	mov	DX,&flgid
	mov	DI,&waiptn
	mov	BX,&wfmode
	wai_flg
	endm

pol_flg	macro
	mov	AX,0ff96h
	int	62h
	endm

pol_flg_i	macro	flgid, waiptn, wfmode
	mov	DX,&flgid
	mov	DI,&waiptn
	mov	BX,&wfmode
	pol_flg
	endm

twai_flg	macro
	mov	AX,0ff56h
	int	62h
	endm

ref_flg	macro
	mov	AX,0ffd4h
	int	62h
	endm

ref_flg_i	macro	flgid, pk_rflg
	mov	DX,&flgid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_rflg
	ref_flg
	endm

cre_mbx	macro
	mov	AX,0ffc7h
	int	62h
	endm

cre_mbx_i	macro	mbxid, pk_cmbx
	mov	DX,&mbxid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_cmbx
	cre_mbx
	endm

del_mbx	macro
	mov	AX,0ffc6h
	int	62h
	endm

del_mbx_i	macro	mbxid
	mov	DX,&mbxid
	del_mbx
	endm

snd_msg	macro
	mov	AX,0ffc1h
	int	62h
	endm

snd_msg_i	macro	mbxid, pk_msg
	mov	DX,&mbxid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_msg
	snd_msg
	endm

rcv_msg	macro
	mov	AX,0ffc3h
	int	62h
	endm

rcv_msg_i	macro	mbxid
	mov	DX,&mbxid
	rcv_msg
	endm

prcv_msg	macro
	mov	AX,0ff94h
	int	62h
	endm

prcv_msg_i	macro	mbxid
	mov	DX,&mbxid
	prcv_msg
	endm

trcv_msg	macro
	mov	AX,0ff54h
	int	62h
	endm

ref_mbx	macro
	mov	AX,0ffc4h
	int	62h
	endm

ref_mbx_i	macro	mbxid, pk_rmbx
	mov	DX,&mbxid
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_rmbx
	ref_mbx
	endm

def_int	macro
	mov	AX,0ffbfh
	int	62h
	endm

def_int_i	macro	dintno, pk_dint
	mov	BX,&dintno
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_dint
	mov	CS:[SI+4],AX
	def_int
	endm

get_ver	macro
	mov	AX,0fff0h
	int	62h
	endm

get_ver_i	macro	pk_ver
	mov	AX,CS
	mov	ES,AX
	mov	SI,&pk_ver
	get_ver
	endm

ret_int	macro
	int	63h
	endm

loc_cpu	macro
	cli
	endm

unl_cpu	macro
	sti
	ena_dsp
	endm

	
	
	
	
	