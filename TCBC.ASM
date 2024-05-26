;
;      ASURA-I TCB CHECKER
;                rel 0.00.00
;Copyright(c) Mineyuki Kimoto 1994
;

	;正逆リンクの整合と重複をチェック
	;entry : BX = 0~0ffh
	;exit  : BX as next link
nxt_lnk	macro	lnk_fb, lnk_dbl
	mov	AL,[BX+100h]
	xchg	AL,BL
	cmp	AL,[BX+200h]
	jnz	&lnk_fb
	
	mov	AH,0ffh
	xchg	ES:[BX],AH
	or	AH,AH
	jnz	&lnk_dbl
	endm
	;BLレジスタがセマフォのキューエント
	;リであることを確認する
chk_sem	macro	err
	mov	AH,BL
	not	AH
	test	AH,83h
	jnz	&err
	endm

	;BLレジスタがフラグのキューエントリ
	;であることを確認する
chk_flg	macro	err
	mov	AH,BL
	xor	AH,82h
	test	AH,83h
	jnz	&err
	endm

	;BLレジスタがメールのキューエントリ
	;であることを確認する
chk_mbx	macro	err
	mov	AH,BL
	xor	AH,2
	test	AH,83h
	jnz	&err
	endm

	;正逆リンクの整合と重複をチェック
	;entry : BX = 100h~1ffh
	;exit  : BX as next link
nxt_mlq	macro	lnk_fb, lnk_dbl
	mov	AL,[BX+700h]
	xchg	AL,BL
	cmp	AL,[BX+701h]
	jnz	&lnk_fb
	
	mov	AH,0ffh
	xchg	ES:[BX],AH
	or	AH,AH
	jnz	&lnk_dbl
	endm


	;属性エラー検出用
sta_ate	equ	0ech	;not 16h
tsk_ate	equ	0feh	;not 1
flg_ate	equ	0f7h	;not 8
wflg_ate	equ	0fch	;not 3

code	segment
	assume CS:code, DS:code

	org 100h
start:
mov	DI,1
	mov	AX,CS
	add	AX,100h
	mov	ES,AX		;ES is for work-area
	
	xor	AX,AX
	mov	DS,AX
	mov	AX,DS:[018ah]	;get int_vec
	mov	DS,AX		;DS is for ASURA-I TCB
	
	xor	BX,BX	;start adr.
	mov	CX,100h	;100h words
	xor	AX,AX	;fill pattern
loop01:
	mov	ES:[BX],AX
	inc	BX
	inc	BX
	loop	loop01

	mov	DX,403h		;DH=4
				;DL=3


mov	DI,2
mov	SI,1
idl_t:
	mov	BX,100h
	cmp	word ptr [BX],3		;f-link & suscnt
	jnz	idl_t_e1
	mov	BH,3
	cmp	word ptr [BX],102h	;ready & wupcnt=0
	jnz	idl_t_e1
	mov	BL,2
	cmp	word ptr [BX],303h	;tskpri=0
	jz	idl_t01
idl_t_e1:
	jmp	err_msg
idl_t01:

mov	SI,2
all_t:
	mov	BX,4		;TCB top
	mov	CX,3fh		;repeat count
all_t01:
	mov	AL,[BX+300h]	;get tskstat
	or	AL,AL
	jz	all_t03		;tskstat=0 / no_exist
	
	test	AL,0e9h		;=not (2+4+10h)
	jnz	all_t_e1		;tskstat error (undefined bit)
	
	mov	AX,[BX+302h]	;get pri & ipri
	or	AL,AL
	jz	all_t_e2		;pri=0 (error)
	or	AH,AH
	jz	all_t_e2		;ipri=0 (error)
	xor	AX,303h		;check pri=0??? ???? ???? ??11 (2)
	test	AX,8383h
	jnz	all_t_e2		;pri / ipri error
	
	test	byte ptr [BX+0d00h],tsk_ate
	jnz	all_t_e3		;tskatr error(undefined bit)
all_t03:
	add	BL,DH
	loop	all_t01
	jmp	all_t04
all_t_e1:
	mov	BH,3
	jmp	err_msg
all_t_e2:
	add	BX,302h
	jmp	err_msg
all_t_e3:
	mov	BH,0dh
	jmp	err_msg
all_t04:


mov	DI,3
mov	SI,1
r_chk:
	mov	BX,3		;ready-que top
	mov	CL,2		;tskstat=ready
r_chk01:
	mov	CH,BL
	add	CH,DH
	and	CH,7fh		;CH = pri
r_chk02:
	nxt_lnk	r_chk_e1, r_chk_e2

	test	BL,DL
	jz	r_chk03		;link is task

	cmp	BL,CH		;link must be next pri
	jnz	r_chk_e3		; [error]
	cmp	BL,DL		;last link?
	jnz	r_chk01		;loop
	jmp	r_chk04		;end
r_chk03:
	mov	AX,[BX+300h]	;AL=tskstat, AH=wupcnt+1
	or	AH,AH		;if task is sleep
	jz	r_chk_e4		; [error]
	mov	AH,[BX+302h]	;AH=priority
	cmp	AX,CX
	jnz	r_chk_e5
	jmp	r_chk02		;loop
	
r_chk_e1:
	mov	BH,2		;backward link error
	jmp	err_msg
r_chk_e2:
	inc	BH		;link doubled
	mov	BL,AL		;before link
	jmp	err_msg
r_chk_e3:
	inc	BH		;not ready que
	mov	BL,AL		;AL is before link
	jmp	err_msg
r_chk_e4:
	add	BX,301h		;wupcnt+1 error
	jmp	err_msg
r_chk_e5:
	mov	BH,3		;tskstat or pri error
	jmp	err_msg
r_chk04:

mov	SI,2
	jmp	s_chk
s_chk_e1:
	mov	BH,2		;backward-link error
	jmp	err_msg
s_chk_e2:
	inc	BH		;link doubled
	mov	BL,AL
	jmp	err_msg

s_chk:
	mov	BX,83h		;semid = 0
s_chk01:
	nxt_lnk	s_chk_e1, s_chk_e2

	chk_sem	s_chk_e3

	cmp	BL,83h
	jnz	s_chk01
	
	mov	BL,87h		;semid = 1
s_chk02:
	mov	CL,BL		;一回目
	nxt_lnk	s_chk_e1, s_chk03

	test	BL,DL
	jz	s_chk06		;link is task
	
	cmp	BL,CL		;link must be sem_link
	jnz	s_chk_e3
	jmp	s_chk05
s_chk03:
				;非存在リンク
	chk_sem	s_chk_e3		;not SEM

	mov	BL,CL
	jmp	s_chk05
s_chk04:				;待ちタスクがある場合
	nxt_lnk	s_chk_e1, s_chk_e2

	test	BL,DL
	jz	s_chk06		;link is task
	
	cmp	BL,CL		;link must be sem_link
	jnz	s_chk_e3
	
	mov	AL,[BX+800h]	;check SEM-count
	or	AL,AL
	jnz	s_chk_e4
s_chk05:
	add	BL,DH		;DH=4
	jnc	s_chk02		;not overflow
	jmp	s_chk07
s_chk06:
				;待ちタスクの検査
	mov	AX,[BX+300h]	;check wupcnt
	or	AH,AH
	jz	s_chk_e5
	cmp	AL,DH		;DH=4 (wait)
	jz	s_chk04
	jmp	s_chk_e6
s_chk_e3:
	inc	BH		;link error(not SEM)
	mov	BL,AL
	jmp	err_msg
s_chk_e4:
	mov	BH,8		;SEM-count error
	jmp	err_msg
s_chk_e5:
	add	BX,301h		;task is sleep
	jmp	err_msg
s_chk_e6:
	mov	BH,3		;tskstat error
	jmp	err_msg
s_chk07:

mov	SI,3
	jmp	f_chk
f_chk_e1:
	mov	BH,2		;backward-link error
	jmp	err_msg
f_chk_e2:
	inc	BH		;link doubled
	mov	BL,AL
	jmp	err_msg

f_chk:
	mov	BX,82h		;flgid = 0
f_chk01:
	nxt_lnk	f_chk_e1, f_chk_e2

	chk_flg	f_chk_e3		;not flg-link

	cmp	BL,82h
	jnz	f_chk01
	
	mov	BL,86h		;flgid = 1
f_chk02:
	mov	CL,BL		;一回目
	nxt_lnk	f_chk_e1, f_chk03

	test	BL,DL		;DL = 3
	jz	f_chk06		;link is task
	
	cmp	BL,CL		;link must be flg_link
	jnz	f_chk_e3
	
	test	byte ptr [BX+800h],flg_ate
	jnz	f_chk_e4		;flgatr error
	jmp	f_chk05
f_chk03:
				;非存在リンク
	chk_flg	f_chk_e3		;not FLG

	mov	BL,CL
	jmp	f_chk05
f_chk04:				;待ちタスクがある場合
	nxt_lnk	f_chk_e1, f_chk_e2

	test	BL,DL
	jz	f_chk06		;link is task
	
	cmp	BL,CL		;link must be flg_link
	jnz	f_chk_e3
	test	byte ptr [BX+800h],flg_ate
	jnz	f_chk_e4		;flgatr error
f_chk05:
	add	BL,DH		;DH=4
	jnc	f_chk02		;not overflow
	jmp	f_chk07
f_chk06:
				;待ちタスクの検査
	mov	AX,[BX+300h]	;check wupcnt
	or	AH,AH
	jz	f_chk_e5
	cmp	AL,DH		;DH=4 (wait)
	jnz	f_chk_e6
	test	byte ptr [BX+201h],wflg_ate
	jnz	f_chk_e7		;wflg_atr error
	jmp	f_chk04
f_chk_e3:
	inc	BH		;link error(not FLG)
	mov	BL,AL
	jmp	err_msg
f_chk_e4:
	mov	BH,8
	jmp	err_msg
f_chk_e5:
	add	BX,301h		;task is sleep
	jmp	err_msg
f_chk_e6:
	mov	BH,3		;tskstat error
	jmp	err_msg
f_chk_e7:
	add	BX,201h
	jmp	err_msg
f_chk07:

mov	SI,4
	jmp	m_chk
m_chk_e1:
	mov	BH,2		;backward-link error
	jmp	err_msg
m_chk_e2:
	inc	BH		;link doubled
	mov	BL,AL
	jmp	err_msg

m_chk:
	mov	BX,2		;mbxid = 0
m_chk01:
	nxt_lnk	m_chk_e1, m_chk_e2

	chk_mbx	m_chk_e3		;not mbx-link

	cmp	BL,2
	jnz	m_chk01		;loop
	
	mov	BL,6		;mbxid = 1
m_chk02:
	mov	CL,BL		;一回目
	nxt_lnk	m_chk_e1, m_chk03

	test	BL,DL		;DL = 3
	jz	m_chk06		;link is task
	
	cmp	BL,CL		;link must be mbx_link
	jnz	m_chk_e3
	jmp	m_chk05
m_chk03:
			;非存在リンク
	chk_mbx	m_chk_e3		;not MBX

	mov	BL,CL
	jmp	m_chk05
m_chk04:				;待ちタスクがある場合
	nxt_lnk	m_chk_e1, m_chk_e2

	test	BL,DL		;DL=3
	jz	m_chk06		;link is task
	
	cmp	BL,CL		;link must be mbx_link
	jnz	m_chk_e3
	
	cmp	[BX+800h],BL	;バックリンクは後の
				;チェックでＯＫ
	jnz	m_chk_e7
m_chk05:
	add	BL,DH		;DH=4
	test	BL,80h
	jz	m_chk02		;not overflow
	jmp	m_chk07
m_chk06:
				;待ちタスクの検査
	mov	AX,[BX+300h]	;check wupcnt
	or	AH,AH
	jz	m_chk_e5
	cmp	AL,DH		;DH=4 (wait)
	jz	m_chk04
	jmp	m_chk_e6
m_chk_e3:
	inc	BH		;link error(not MBX)
	mov	BL,AL
	jmp	err_msg
m_chk_e5:
	add	BX,301h		;task is sleep
	jmp	err_msg
m_chk_e6:
	mov	BH,3		;tskstat error
	jmp	err_msg
m_chk_e7:
	mov	BH,8		;mail-que error
	jmp	err_msg
m_chk07:


mov	DI,4
mov	SI,1
nm_tsk:
	mov	BX,4		;tskid=1
nm_tsk01:
	test	ES:[BX],DL	;DL=3
	jnz	nm_tsk02		;marked
	
	cmp	[BX+100h],BL	;forward-link check
	jnz	nm_tsk_e1
	cmp	[BX+200h],BL	;backward-link check
	jnz	nm_tsk_e2
	
	mov	AX,[BX+300h]	;AH=wupcnt+1
				;AL=tskstat
	test	AL,0efh
	jz	nm_tsk02		;dormant or no-exist
	
	cmp	AX,4
	jnz	nm_tsk_e3	;no-wait or no-sleep
nm_tsk02:
	add	BL,DH		;DH=4
	jnc	nm_tsk01
	jmp	nm_tsk03
nm_tsk_e1:
	inc	BH		;forward-link error
	jmp	err_msg
nm_tsk_e2:
	mov	BH,2		;backward-link error
	jmp	err_msg
nm_tsk_e3:
	mov	BH,3		;tskstat error
	jmp	err_msg
nm_tsk03:

mov	SI,2
ml_chk:
	cmp	DS:[802h],202h	;check mbxid=0
	jnz	ml_chk_e1
	
	mov	BX,106h		;mbxid=1
ml_chk01:
	mov	CL,BL
ml_chk02:
	nxt_mlq	ml_chk_e2, ml_chk_e3

	test	BL,DL
	jz	ml_chk02		;link is mail
	
	cmp	BL,CL		;link must be self
	jnz	ml_chk_e4
	
	add	BL,DH		;next mbxid
	test	BL,80h		;mbxid > 01fh
	jz	ml_chk01
	jmp	ml_chk03

ml_chk_e1:
	mov	BX,802h
	jmp	err_msg
ml_chk_e2:
	add	BX,701h
	jmp	err_msg
ml_chk_e3:
	mov	BH,8
	jmp	err_msg
ml_chk_e4:
	mov	BH,8
	mov	BL,AL
	jmp	err_msg
ml_chk03:

mov	SI,3
ml_nul:
	mov	BX,100h
ml_nul01:
	mov	AL,ES:[BX]
	or	AL,AL
	jnz	ml_nul02
	
	mov	AX,[BX+700h]
	cmp	AL,BL
	jnz	ml_nul_e1
	cmp	AH,BL
	jnz	ml_nul_e2
ml_nul02:
	add	BL,DH
	jnc	ml_nul01
	jmp	ml_nul03

ml_nul_e1:
	mov	BH,8
	jmp	err_msg
ml_nul_e2:
	add	BX,801h
	jmp	err_msg
ml_nul03:


mov	DI,5
	mov	AX,0
	int	21h

err_msg:
	mov	AX,CS
	mov	DS,AX

	mov	CX,4
	mov	AX,BX		;AX is address
	mov	BX,offset msg_adr
err_msg01:
	xor	DL,DL
	rcl	AX,1
	rcl	DL,1
	rcl	AX,1
	rcl	DL,1
	rcl	AX,1
	rcl	DL,1
	rcl	AX,1
	rcl	DL,1
	add	DL,30h		;'0'
	cmp	DL,3ah		;'9'+1
	jc	err_msg02
	
	add	DL,7
err_msg02:
	mov	[BX],DL
	inc	BX
	loop	err_msg01

	mov	DX,offset msg
	mov	AH,9
	int	21h

	mov	AX,0
	int	21h

msg	db	'Error detected in '
msg_adr	db	'%%%%', 0dh, 0ah, '$'



	org	1000h
	db	512 dup (?)

code	ends
	end	start
