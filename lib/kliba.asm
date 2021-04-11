;***
 ; @Description: asm Function lib for C
 ; @Version: 
 ; @Autor: Yunfei
 ; @Date: 2021-02-28 19:52:19
 ; @LastEditors: Yunfei
 ; @LastEditTime: 2021-04-03 15:47:11
 ;***


%include "sconst.inc"

extern disp_pos

[section .text]

global disp_str
global disp_color_str
global	out_byte
global	in_byte

global  enable_irq
global  disable_irq

global	enable_int
global	disable_int

global  bochs_magic_break

;***
 ; @description: disp_str
 ; @param {char* (esp)}
 ; @return {null}
 ; @author: Yunfei
 ;***
disp_str:
    push    ebp         ;保存当前的ebp
    mov     ebp, esp    ;设置ebp等于当前的esp

    push    ebx         ;需要将ebx保存起来
    push    esi
    push    edi

    mov esi, [ebp + 8]  ;pszInfo  进来之前：-4，push ebp后是-8,所以ebp+8 就正好是指向当前字符串
    mov edi, [disp_pos] ;将地址存放的显示位置赋予给edi
    mov ah, 0Fh         ;改变颜色
.1
    lodsb               ;装入一个byte到al
    test    al,al
    jz  .2              ;若是无byte
    cmp al, 0Ah         ;是否是回车
    jnz .3              ;不是则跳转
    push eax
    mov eax, edi
    mov bl, 160
    div bl
    and eax, 0FFh
    inc eax
    mov bl,160
    mul bl 
    mov edi, eax
    pop eax
    jmp .1              ;以上作用：另起一行
.3
    mov [gs:edi],ax     ;ax 赋给视频段地址
    add edi,2           ;因为是ax，所以edi要+2
    jmp .1
.2
    mov [disp_pos], edi

    pop edi
    pop esi
    pop ebx
    pop ebp
    ret

;;DispStr结束
;***
 ; @description: disp_color_str
 ; @param {char* (esp),u8 color(ah)}
 ; @return {void}
 ; @author: Yunfei
 ;***
disp_color_str:
	push	ebp
	mov	ebp, esp

    push    ebx         ;需要将ebx保存起来
    push    esi
    push    edi

	mov	esi, [ebp + 8]	; pszInfo
	mov	edi, [disp_pos]
	mov	ah, [ebp + 12]	; color
.1:
	lodsb
	test	al, al
	jz	.2
	cmp	al, 0Ah	; 是回车吗?
	jnz	.3
	push	eax
	mov	eax, edi
	mov	bl, 160
	div	bl
	and	eax, 0FFh
	inc	eax
	mov	bl, 160
	mul	bl
	mov	edi, eax
	pop	eax
	jmp	.1
.3:
	mov	[gs:edi], ax
	add	edi, 2
	jmp	.1

.2:
	mov	[disp_pos], edi

	pop edi
    pop esi
    pop ebx
    pop ebp
	ret
;; disp_color_str 结束
;***
 ; @description: 输出byte
 ; @param {u8(al),port(p1)}
 ; @return {void}
 ; @author: Yunfei
 ;***
out_byte:
	mov	edx, [esp + 4]		; port
	mov	al, [esp + 4 + 4]	; value
	out	dx, al
	nop	; 一点延迟
	nop
	ret
;***
 ; @description: 输入byte
 ; @param {u8(al),port(p1)}
 ; @return {void}
 ; @author: Yunfei
 ;***
in_byte:
	mov	edx, [esp + 4]		; port
	xor	eax, eax
	in	al, dx
	nop	; 一点延迟
	nop
	ret
    
; ========================================================================
;                  void disable_irq(int irq);
; ========================================================================
; Disable an interrupt request line by setting an 8259 bit.
; Equivalent code:
;	if(irq < 8){
;		out_byte(INT_M_CTLMASK, in_byte(INT_M_CTLMASK) | (1 << irq));
;	}
;	else{
;		out_byte(INT_S_CTLMASK, in_byte(INT_S_CTLMASK) | (1 << irq));
;	}
disable_irq:
        mov     ecx, [esp + 4]          ; irq
        pushf
        cli
        mov     ah, 1
        rol     ah, cl                  ; ah = (1 << (irq % 8))
        cmp     cl, 8
        jae     disable_8               ; disable irq >= 8 at the slave 8259
disable_0:
        in      al, INT_M_CTLMASK
        test    al, ah
        jnz     dis_already             ; already disabled?
        or      al, ah
        out     INT_M_CTLMASK, al       ; set bit at master 8259
        popf
        mov     eax, 1                  ; disabled by this function
        ret
disable_8:
        in      al, INT_S_CTLMASK
        test    al, ah
        jnz     dis_already             ; already disabled?
        or      al, ah
        out     INT_S_CTLMASK, al       ; set bit at slave 8259
        popf
        mov     eax, 1                  ; disabled by this function
        ret
dis_already:
        popf
        xor     eax, eax                ; already disabled
        ret

; ========================================================================
;                  void enable_irq(int irq);
; ========================================================================
; Enable an interrupt request line by clearing an 8259 bit.
; Equivalent code:
;       if(irq < 8){
;               out_byte(INT_M_CTLMASK, in_byte(INT_M_CTLMASK) & ~(1 << irq));
;       }
;       else{
;               out_byte(INT_S_CTLMASK, in_byte(INT_S_CTLMASK) & ~(1 << irq));
;       }
;
enable_irq:
        mov     ecx, [esp + 4]          ; irq
        pushf
        cli
        mov     ah, ~1
        rol     ah, cl                  ; ah = ~(1 << (irq % 8))
        cmp     cl, 8
        jae     enable_8                ; enable irq >= 8 at the slave 8259
enable_0:
        in      al, INT_M_CTLMASK
        and     al, ah
        out     INT_M_CTLMASK, al       ; clear bit at master 8259
        popf
        ret
enable_8:
        in      al, INT_S_CTLMASK
        and     al, ah
        out     INT_S_CTLMASK, al       ; clear bit at slave 8259
        popf
        ret

        
; ========================================================================
;		   void disable_int();
; ========================================================================
disable_int:
	cli
	ret

; ========================================================================
;		   void enable_int();
; ========================================================================
enable_int:
	sti
	ret

bochs_magic_break:
        xchg bx,bx
        ret