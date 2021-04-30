;***
 ; @Description: boot.asm
 ; @Version: 
 ; @Autor: Yunfei
 ; @Date: 2021-02-25 21:35:11
 ; @LastEditors: Yunfei
 ; @LastEditTime: 2021-04-03 16:57:11
 ;***


org 07c00h  ;   操作系统加载到07c00h开始读取

BaseOfStack     equ     07c00h

%include "load.inc"     ;   加入loader和kernel所需要的段地址信息

    jmp short LABEL_START
    nop     ;不知道为何必不可少（？）

%include "fat12hdr.inc" ;包含一些磁盘信息,加入以便于系统识别

LABEL_START:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, BaseOfStack

    ;清屏
    mov ax, 0600h       ;   AH = 6,  AL = 0h
    mov bx, 0700h      ;   黑底白字（BL = 07h）
    mov cx, 0           ;   左上角:(0,0)
    mov dx, 0184fh      ;   右下角:(80,50)
    int 10h

    mov dh, 0           ;   显示booting
    call DispStr

    ;软驱复位
    xor ah, ah
    xor dl, dl
    int 13h

;寻找 LOADER.BIN
    mov word [wSectorNo], SectorNoOfRootDirectory
LABEL_SEARCH_IN_ROOT_DIR_BEGIN:

    cmp word [wRootDirSizeForLoop], 0
    jz  LABEL_NO_LOADERBIN
    dec word [wRootDirSizeForLoop]
    ;判断根目录区是否读完，若读完表示未找到

    mov ax, BaseOfLoader
    mov es, ax
    mov bx, OffsetOfLoader
    ; es:bx = BaseOfLoader:OffsetOfLoader

    mov ax, [wSectorNo]
    mov cl, 1
    call    ReadSector

    mov si, LoaderFileName      ; ds:si --> "LOADER.BIN" (si是作指针)
    mov di, OffsetOfLoader      ; es:di --> BaseOfLoader:0100
    cld
    mov dx, 10h
LABEL_SEARCH_FOR_LOADERBIN:
    cmp dx, 0                                   ;if dx == 0
    jz LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR       ;goto LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR
    dec dx                                      ;dx--
    mov cx, 11


LABEL_CMP_FILENAME:
    cmp cx, 0
    jz LABEL_FILENAME_FOUND     ;11个字符相同，则表示找到

    dec cx
    lodsb                       ;ds:si -> al
    cmp al, byte [es:di]
    jz  LABEL_GO_ON
    jmp LABEL_DIFFERENT         ;有一个不一样则表明该 DirectoryEnry 不是
LABEL_GO_ON:
    inc di
    jmp LABEL_CMP_FILENAME

LABEL_DIFFERENT:
    and di, 0FFE0h              ;指向本条目录开头
    add di, 20h                 ;下一个根目录区条目
    mov si, LoaderFileName
    jmp LABEL_SEARCH_FOR_LOADERBIN

LABEL_GOTO_NEXT_SECTOR_IN_ROOT_DIR:
    add word [wSectorNo], 1
    jmp LABEL_SEARCH_IN_ROOT_DIR_BEGIN


LABEL_NO_LOADERBIN:
    mov dh, 2                   ;no loader
    call DispStr
    jmp $                       ;没有找到，死循环在这里

LABEL_FILENAME_FOUND:
    mov ax, RootDirSectors
    and di, 0FFE0h              ;di:当前条目开始
    add di, 01Ah                ;di:首个sector位置
    mov cx, word [es:di]
    push cx                     ;cx <- 在FAT中的序号
    add cx, ax
    add cx, DeltaSectorNo       ;这句完成时 cl 里面变成 LOADER.BIN 的起始扇区号
    mov ax, BaseOfLoader
    mov es, ax                  ;es <- BaseOfLoader
    mov bx, OffsetOfLoader      ;bx <- OffsetOfLoader
    mov ax, cx                  ;ax <- Sector 号

LABEL_GOON_LOADING_FILE:
    push ax
    push bx
    mov ah, 0Eh
    mov al, '.'
    mov bl, 0Fh
    int 10h
    pop bx
    pop ax
    ;读一个扇区就打一个点

    mov cl, 1
    call    ReadSector          ;此处将 loader.bin 的所在扇区读入对应内存
    pop ax                      ;取出 Sector 在 FAT 中的序号
    call    GetFATEntry
    cmp ax, 0FFFh
    jz  LABEL_FILE_LOADED
    ; 若找到为0FFFh，则表明加载完毕
    
    push ax                     ;保存 Sector 在 FAT 中的序号
    mov dx, RootDirSectors
    add ax, dx
    add ax, DeltaSectorNo
    add bx, [BPB_BytsPerSec]
    jmp LABEL_GOON_LOADING_FILE

LABEL_FILE_LOADED:

    mov dh, 1                   ;ready
    call    DispStr

    jmp BaseOfLoader:OffsetOfLoader ;跳转到内存中 LOADER.BIN 的开始处

;===========================================================================
;变量
wRootDirSizeForLoop dw RootDirSectors   ;占用的扇区数
wSectorNo       dw  0                   ;要读取的扇区号
bOdd            db  0                   ;奇偶
;===========================================================================

;===========================================================================
;字符串
LoaderFileName		db	"LOADER  BIN", 0	; LOADER.BIN 之文件名
; 为简化代码, 下面每个字符串的长度均为 MessageLength
MessageLength		equ	9
BootMessage:		db	"Booting  "; 9字节, 不够则用空格补齐. 序号 0
Message1		db	"Ready.   "; 9字节, 不够则用空格补齐. 序号 1
Message2		db	"No LOADER"; 9字节, 不够则用空格补齐. 序号 2
;===========================================================================

;***
 ; @description: DispStr 利用系统中断显示字符串
 ; @param {u8 (dh) 字符串序号}
 ; @return {null}
 ; @author: Yunfei
 ;***
DispStr:
    mov ax, MessageLength
    mul dh
    add ax, BootMessage
    mov bp, ax

    mov ax, ds
    mov es, ax
    ;es:bp 为串地址
    mov cx, MessageLength
    mov ax, 01301h      ;AH = 13,   AL = 01h
    mov bx, 0007h       ;BH(页号) = 0 BL = 07h(白底黑字)
    mov dl, 0
    int 10h
    ret

;***
 ; @description: ReadSector:从第 ax 个 Sector 开始，将 cl 个 Sector 读入 es:bx 中
 ; @param {u16 (ax),u8 (cl)}
 ; @return {512byte * cl (es:bx)} (仍是void，但是可以记录一下)
 ; @author: 
 ;***
ReadSector:
; -----------------------------------------------------------------------
	; 怎样由扇区号求扇区在磁盘中的位置 (扇区号 -> 柱面号, 起始扇区, 磁头号)
	; -----------------------------------------------------------------------
	; 设扇区号为 x
	;                           ┌ 柱面号 = y >> 1
	;       x           ┌ 商 y ┤
	; -------------- => ┤      └ 磁头号 = y & 1
	;  每磁道扇区数     │
	;                   └ 余 z => 起始扇区号 = z + 1

    push bp                 ;SS的一个相对基指针寄存器
    mov bp, sp
    sub esp, 2              ;留存2byte空间保存要读取的扇区数

    mov byte [bp-2], cl
    push bx

    mov bl, [BPB_SecPerTrk] ;除数：每磁道扇区数目
    div bl                  ;ax/bl = al...ah
    inc ah                  ;z++
    mov cl, ah              ;cl <-- 起始扇区号
    mov dh, al              ;dh <-- y
    shr al, 1
    mov ch,al               ;ch <-- 柱面号
    and dh, 1               ;dh <-- 磁头号

    pop bx

    mov dl, [BS_DrvNum]     ;驱动器号
.GoOnReading:
    mov ah, 2               ;读
    mov al, byte [bp-2]     ;读入 al 个扇区
    int 13h
    jc  .GoOnReading        ;读取错误，则CF置1,读取到正确为止

    add esp, 2
    pop bp

    ret

;;ReadSector 结束

;***
 ; @description: GetFATEntry
 ; @param {u16 No (ax)}
 ; @return {FAT_Location (ax)}
 ; @author:
 ;***
 GetFATEntry:
    push es
    push bx
    push ax
    mov ax, BaseOfLoader
    sub ax, 0100h
    mov es, ax
    ; 在BaseOfLoader后面留出4k用于存放FAT
    pop ax
    mov byte [bOdd], 0
    mov bx, 3
    mul bx
    mov bx, 2
    div bx
    cmp dx, 0
    ;ax(序号) * 1.5 dx为小数部分 /2后余数
    jz LABEL_EVEN
    mov byte [bOdd], 1
LABEL_EVEN:
    xor dx, dx
    mov bx, [BPB_BytsPerSec]
    div bx
    ;这里是寻找FAT项所在的扇区，所以去除以512...,ax <- 商，即所在扇区号，dx <- 偏移
    push dx
    mov bx, 0
    add ax, SectorNoOfFAT1
    mov cl, 2
    call ReadSector         ;读2个扇区
    pop dx
    add bx, dx
    mov ax, [es:bx]
    cmp byte [bOdd], 1
    jnz LABEL_EVEN_2
    shr ax, 4
LABEL_EVEN_2:
    and ax, 0FFFh

LABEL_GET_FAT_ENTRY_OK:
    pop bx
    pop es
    ret

;; GetFATEntry结束

times 510-($-$$)    db  0       ;填充空间
dw  0xaa55                      ;结束标志