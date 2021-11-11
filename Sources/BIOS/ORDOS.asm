; ==============================================
;
;   О п е р а ц и о н н а я 
;        с и с те е м а
;        " O R D O S "
;
;       Для "Orion-PRO"
;
;   == O R I O N S O F T ==
;
;     V4.00   22.04.1997
;     V4.10   28.11.1999
;  (используется монитор V2.10)
; ==============================================

        DEVICE NOSLOT64K

        INCLUDE "ports.inc"                 ; Порты Ориона



VERS    EQU 41H
PCSEG   EQU 3                               ; Сегмент ROM2 с PC V2.00
PCADR   EQU 2C00H                           ; Адрес размещения PC
ORDROM  EQU 2A20H                           ; 29E0H ; Начало ORDOS в сегменте 0 ROM2

; ----------------------------------------------
; Адреса процедур монитора
; ----------------------------------------------
KBRD	EQU 0F803H                          ; Ввод символа с клавиатуры
TV2		EQU 0F809H                          ; Вывод символа на экран
STTS	EQU 0F812H                          ; Опрос состояния клавиатуры
ASC		EQU 0F815H                          ; Вывод байта в шестнадцатеричной форме
MSG		EQU 0F818H                          ; Вывод сообщения на экран
INKEY	EQU 0F81BH                          ; Опрос кода нажатой клавиши
RBDS	EQU 0F836H                          ; Чтение байта из страницы ОЗУ
WBDS	EQU 0F839H                          ; Запись байта в страницу ОЗУ
RESET	EQU 0F833H                          ; A=FF: WR(C=0..3)/RD(C=FF) CURRENT ROM-диск

; ----------------------------------------------
STACK	EQU 0F3C0H
MAXD	EQU 0EFFFH                          ; MAX адрес дисков "B-H"
        ;
        ORG 0B800H
        ;
; ----------------------------------------------
; ССР - командный процессор
; ----------------------------------------------
CCP		JP STCP
        ;
ORD		DB 1FH,1AH,1AH
ORD1	DB ' (C) 1990-1999  ORIONSOFT',0x0D,0x0A
        DB ' ORDOS-PRO  V4.10  281199',7
        DB 0x0D,0x0A,' A>',0
        ;
STCP	CALL RESROM                         ; Установить текущий ROM-диск
        CALL STTS
        AND A
        JR NZ,CCP4
        ;
        CALL RND
        LD (CCP4+1),A                       ; TB2
        LD HL,TBEXT                         ; "EXT"
        LD  A,'B'
CCP0	CALL PSCD                           ; Поиск файла
CCP1	LD HL, CCP2
        PUSH HL
        RET Z                               ; Если нет, переход -> (CCP1+1)
        POP HL
        JP PUSK0                            ; Запуск файла
;
FLEXT		
CCP2	LD  A,0
        AND A
        JR NZ,CCP4
; ----------------------------------------------
; Запусе PC$ из ROM-диска
; ----------------------------------------------
        LD A,1
        OUT (PORT_2C_ROMD_PAGE),A                         ; Всегда с 1-го ROM-диска
        LD HL,CCP5
        LD (CCP1+1),HL
        LD HL,TBNC
        LD A,'A'
        JR CCP0
; ----------------------------------------------
; Загрузка нового PC V2.00
; ----------------------------------------------
CCP5	LD A,PCSEG
        OUT (PORT_09_ROM2_SEG),A
        IN A,(PORT_0A_MEM_CFG)
        SET 3,A                             ; Включить окно ROM2 с сегментом PCSEG
        OUT (PORT_0A_MEM_CFG),A
        JP  PCADR

;
; LD HL,PCADR
; LD A,(HL)
; CP 0C3H   ;estx nowyj PC ?
; JP Z,PCHL ;da
; XOR A
; OUT (09H),A
;

; ----------------------------------------------
; Загрузка старого PC V1.00
; ----------------------------------------------

; LD HL, 31E0H  ; адрес в ROM2
; LD DE,0AD00H  ; адрес посадки PC
; LXI B,0DFFH   ; размер PC (по MAX!)
; PUSH D
; JP LROM2
;

CCP4	CALL WNDA                           ; Изначально установить диск "A"
CCP3	LD HL, ORD                          ; Вывод титула
        PUSH HL
        CALL MSG
        POP HL
        LD  (HL),0
        CALL TP3                            ; Ждать отпускания клавиш
        LD A,0x19
        CALL TV
;
CC2		LD SP,STACK                        ; "теплый вход" CCP
        CALL HDLN
        CALL SPC
        CALL RND                            ; вывести новер диска не TV
        CALL TV
        LD  A,'>'
        CALL TV
        LD HL,ORD+1                         ; BUFIN ;установка адреса буффера ввода
        CALL SDM
CD		LD B,0x0                            ; установка счетчика символов
CD1		CALL KBRD
        CP 0x3                              ; CTRL/C "теплый запуск" ОС
        JP Z,WBOOT
        CP  0x8                             ; <= ?
        JR NZ,CD2
CD4		LD  A,B
        AND A
        JR Z,CD1
CD5		PUSH HL
        LD HL,TABNZ
        CALL MSG
        POP HL
        DEC HL
        DEC B
        JR CD1
CD2		CP 7FH
        JR Z,CD4
        CP  0x0D
        JR Z,CD7
        CP  1FH
        JR C,CD1
        CALL TV
        LD (HL),A
        INC HL
        INC B
        LD  A,B
        CP  1FH                             ; Вход буфер = 32 символа
        JR NZ,CD1
        JR CD5
;
CD7		LD (HL),A
        CALL HDLN
        LD HL,ORD+1                         ; BUFIN
        LD A,(HL)
        CP  0x0D                            ; Вывод оглавления
        JR Z,CD6
        LD  B,A
        INC HL
        LD A,(HL)
        CP  0x3A                            ; Диск?
        LD  A,B
        JR NZ,CD6
        CALL SETR1                          ; Установить номер ROM-диска, если '0..3'
        CP  'A'
        JR C,ERR
        CP  'H'+1
        JR NC,ERR
        CALL WND
        INC HL
        LD A,(HL)
        CP  0x0D
        JP Z,CC2
        INC HL
CD6		LD (NABUF+1),HL
        LD HL,ERS                           ; Адрес возврата
        PUSH HL
        CP  0x0D                            ; Вывод оглавления
        JP Z,DIR
        CP  'D'                             ; Вывод оглавления
        JP Z,DIR
        CP  'R'                             ; Переименование файла
        JP Z,RN
        CP  'S'                             ; запись файла в кв. диск
        JP Z,SAVE
        CP  'E'                             ; Уничтожить файл
        JP Z,ERAS
        CP  'T'                             ; Просмотр файла
        JP Z,TYPE
        CP  'F'                             ; Форматирование дискa
        JP Z,FORMAT
        POP HL
        CP  'L'                             ; Чтение файла
        JP Z,PUSK0
        CP  0x20                            ; Чтение файла
        JP Z,PUSK0
ERR		LD  A,'?'
        CALL TV
        JP  CC2

; ----------------------------------------------
; Адрес возврата
; ----------------------------------------------
ERS		AND A
        JP Z,CC2
        LD HL,ERMSG
        PUSH HL
        LD HL,TABER1
        DEC A
        RET Z
        LD HL,TABER2
        DEC A
        RET Z
        LD HL,TABER3
        DEC A
        RET Z
        LD HL,TABER4
        DEC A
        RET Z
        JR ERR
;
ERMSG	CALL MSG
        LD HL,(NABUF+1)
EG1		LD A,(HL)
        CP  0x20
        JP Z,CC2
        CP  0x0D
        JP Z,CC2
        CALL TV
        INC HL
        JR EG1
;
TABNZ	DB 08H,0x20,8H,0

; ----------------------------------------------
; Сохранение файлв
; ----------------------------------------------
SAVE	LD HL,(NABUF+1)                     ; Поиск последнего пробела в буфере
CRT		LD A,(HL)
        INC HL
        CP  0x20
        JR NZ,CRT2
        LD (CRT3+1),HL
CRT2	CP 0x0D
        JR NZ,CRT
CRT3	LD HL,0                             ; Читать начальный адрес
        EX DE,HL
        CALL CVRT2
        LD (NADR+1),HL
        JR C,ERR
        CALL CVRT2
        LD (KADR+1),HL
        JR NC,ERR
        EX DE,HL
        LD HL,(NADR+1)
        LD A,H
        CP D
        JP C, WRT
        LD A,L
        CP E
        JR NC,ERR
        JP WRT
;
CVRT2	LD HL,0
        LD  B,L
        LD  C,L

HEX		LD A,(DE)
        INC DE
        CP 0x0D
        JR Z,RTN
        CP 0x2C
        RET Z
        SUB 0x30
        JP M,ERR
        CP 0x0A
        JP M,HX
        CP  0x11
        JP M,ERR
        CP 0x17
        JP P,ERR
        SUB 0x07
HX		LD C,A
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        JP C,ERR
        ADD HL,BC
        JR HEX
RTN		SCF
        RET

; ----------------------------------------------
; Директива "T". Вывод файла на экран
; ----------------------------------------------
TYPE	CALL PSC 
        LD  A,01H                           ; Ошибка, нет файла
        RET Z
        CALL ATFLD
TP1		CALL RDISK
        CP  0x0D
        CALL Z,HDLN
        AND 0x7F
        CP  0x7F
        JR Z,TP2
        CP  0x20
        JR C,TP2
        CALL TV
TP2		CALL INKEY
        CP  0x3
        JR Z,TP3
        INC A
        JR NZ,TP2
        INC HL
        CALL DPCMP
        JR NZ,TP1
TP3		CALL STTS
        OR A
        JR NZ,TP3
        RET                                 ; A=0!
;
SPC		LD  A,0x20

TV		LD  C,A
        JP  TV2
;
HDLN	LD  A,0x0D
        CALL TV
        LD  A,0x0A
        JR TV
;
ADR		LD  A,H
        CALL ASC
        LD  A,L
        JP  ASC

; ----------------------------------------------
; Директива "D"
; ----------------------------------------------
DIR		LD HL,(NAMAS+1)
DR0		CALL SPC
        LD  B,2
DIR0	CALL PPS
        AND A
        RET Z
        LD HL,(UAST)
        LD  D,0x8
DIR1	CALL RDISK
        CALL TV
        INC HL
        DEC D
        JR NZ,DIR1
        CALL SPC
        CALL RDDE
        EX DE,HL
        CALL ADR                            ; старт.адрес
        EX DE,HL
        CALL SPC
        INC HL
        CALL RDDE
        EX DE,HL
        CALL ADR                            ; Длина файла (HEX)
        CALL PPS4
        LD  D,4
DIR2	CALL SPC
        DEC D
        JR NZ,DIR2
        DJNZ DIR0
        CALL HDLN
        JR DR0
        ;
; ----------------------------------------------
; Директива "F". Формат
; ----------------------------------------------
FORMAT	CALL YES
        RET NZ
        LD HL,RND+1                         ; NDSK
        LD A,(HL)
        CP  'A'
        JR NZ,FR
        LD  (HL),'B'
FR		LD HL,0
        JP WEND
;
YES		LD HL,TABF                          ; Да?
        CALL MSG                            ; Вывести сообщение
        CALL KBRD
        CP  0x0D
        LD  A,0
        RET
;
ERAS	CALL YES
        RET NZ
        JP  DEL
;
TABF	DB ' da?[wk]',0
TABER1	DB ' net fajla:',0
TABER2	DB ' powtornyj fajl:',0
TABER3	DB ' malo diska dlq:',0
TABER4	DB ' tolxko ~tenie:',0
TBEXT	DB 'EXT '
TBNC	DB 'PC  '
BUFFLC	DB 'SETUP.TX '
;
QQ		EQU $
;
        DISPLAY "Code size: ",/H,QQ

        ASSERT QQ<=0xBB00, Переполнение CCP

        IF QQ<0xBB00
            DS 0xBB00-QQ,0xFF
        ENDIF
;
; адрес ST1 - 0BB00H !!!
;
ST1		JP CCP                              ; старт в CCP
UAST	DS 0x2                              ; н.а. оглавление текущего файла
AST		DS 0x2                              ; адрес запуска файла
DLINA	DS 02H                              ; количество байт в  w файлe
        ;
        ; Установить текущий ROM-диск (C=FF) или номер C=0..3
RESROM	LD A,0xFF
SETROM	LD C,A
        LD A,0xFF
        JP RESET
        ;
        ; Установить текущий ROM-диск номер A='0..3'
SETR1	CALL CPROM
        RET C
        SUB '0'
        CALL SETROM
        LD A,'A'
        RET
        ;
        ; Установить временный ROM-диск номер A='0..3'
SETR2	CALL CPROM
        RET C
        SUB '0'-1
        LD B,A
        LD A,0x80
SR2		RLCA
        DJNZ SR2
        OUT (PORT_2C_ROMD_PAGE),A
        LD A,'A'
        RET
        ;
CPROM	CP '0'
        RET C
        CP '3'+1
        CCF
        RET
        ;
WNDA	LD  A,'A'
WND		CP 'A'
        JR C,WND3
        CP 'I'
        JR C,WND2
WND3	LD  A,'A'
WND2	LD (RND+1),A
        SUB 41H
        LD (RDISK+1),A
        LD (WRISK+1),A
        PUSH HL
        LD HL,0H                            ; NAD_B-G
        JR NZ,WND1
        ;
        CALL RROM                           ; Читать первый байт ROM-диска
        INC A
        JR Z,WND1                           ; НЕт ПЗУ
        DEC A
        JR Z,WND1
        CP  0C3H                            ; Какой формат?
        LD HL,800H                          ; Старый ROM-диск
        JR Z,WND1
        LD HL,10H                           ; Новый ROM-диск
WND1	LD (NAMAS+1),HL
        POP HL
RND		LD  A,'A'                           ; NDSK
        RET

; ----------------------------------------------
; Чтение байта из текущего ROM-диска
; Вход:
;  HL - адрес, откуда
; Выход:
;  A - считаный байт
; ----------------------------------------------
RDISK	LD  A,0                             ; SMC, Вместо 0, подставляется значение
        AND A
        JP NZ,RISK
RROM	LD  A,L
        OUT PORT_29_ROMD_ADRL,A
        LD  A,H
        OUT PORT_2A_ROMD_ADRH,A
        NOP
        IN A,PORT_28_ROMD_DATA
        RET
RISK	PUSH BC
        CALL RBDS
        LD A,C
        POP BC
        RET

; ----------------------------------------------
; запись оглавления файла
; ----------------------------------------------
WOGL	CALL PSC
        LD  A,0x02                          ; ош.повт.файл
        RET NZ
        CALL UBUF
        CP  0x0D
        JP Z,ST1
        LD HL,(UAST)
        CALL NAMI
        EX DE,HL
        LD HL,(NADR+1)
        EX DE,HL
;
WRDE	LD  A,E
        CALL WDISK
        INC HL
        LD  A,D
;
WDISK	PUSH BC
        LD  C,A
WRISK	LD  A,1
        AND A
        JP Z,WISK
        CALL WBDS
WISK	POP BC
        RET
;
SDM		LD (NABUF+1),HL
LDM		
NABUF	LD HL, 0
        RET
;
ATF		
KADR	LD DE,0
NADR	LD HL, 0
        RET
;
WATF	LD (NADR+1),HL
        EX DE,HL
        LD (KADR+1),HL
        RET
;
ATFM	LD HL,(UAST)
        LD  B,H
        LD  C,L
        LD HL,(DLINA)
        EX DE,HL
        LD HL,(AST)
        RET
;
;WMAX		LD (RMAX+1),HL
;RMAX		LD HL, 0EFFFH
;RET

; ----------------------------------------------
; Установить MAX адрес дискa
; ----------------------------------------------
WMAX	PUSH AF
        PUSH BC
        PUSH HL
        CALL TABADR
        POP BC
        LD (HL),C
        INC HL
        LD (HL),B
        POP BC
        POP AF

; ----------------------------------------------
; Получить максимальный адрес диска
; ----------------------------------------------
RMAX	PUSH AF
        PUSH BC
        CALL TABADR
        LD A,(HL)
        INC HL
        LD H,(HL)
        LD L,A
        POP BC
        POP AF
        RET

; ----------------------------------------------
; Вычислить адрес в таблице размеров дискoв
; ----------------------------------------------
TABADR	LD A,(RDISK+1)
        ADD A,A
        LD C,A
        LD B,0
        LD HL,MAXTAB
        ADD HL,BC
        RET
        ;
MAXTAB	DW 0xFFFF                           ; MAX rразмер диска A (Не используется)
        DW MAXD                             ; B
        DW MAXD                             ; C
        DW MAXD                             ; D
        DW MAXD                             ; E
        DW MAXD                             ; F
        DW MAXD                             ; G
        DW MAXD                             ; H
        ;
ADISK	LD HL, PSC                          ; 0
        CALL SDM
;RET
;

; ----------------------------------------------
; Директива поиска файла
; ----------------------------------------------
PSC		CALL UBUF
NAMAS	LD HL, 0x800
        CP  0x0D
        LD  A,0
        RET Z
PS		XOR A
        LD (TR21+1),A
        CALL PPS                            ; Конец?
        RET Z
PS1		LD  D,0x08
        LD HL,(NABUF+1)
        LD  B,H
        LD  C,L
        LD HL,(UAST)
PS6		LD A,(BC)
        LD  E,A
        CP  0x0D
        JR Z,PS4
        CP  0x20
        JR Z,PS4
        CP  '$'
        JR Z,PS4
        CALL RDISK
        CP  '$'
        JR NZ,PS8
        LD (TR21+1),A
PS8		CP E
        JR NZ,PS7
PS2		INC BC
        INC HL
        DEC D
        JR NZ,PS6
        JR PS3
PS4		CALL RDISK
        CP  0x20
        JR Z,PS3
        CP  '$'
        JR Z,PS31
PS7		CALL PPS4
        JR PS
PS31    LD (TR21+1),A
PS3		LD HL,(UAST)
        PUSH HL
        LD DE,0x08
        ADD HL,DE
        CALL RDDE
        EX DE,HL
        LD (AST),HL
        EX DE,HL
        INC HL
        CALL RDDE
        INC HL
        INC HL
        INC HL
        INC HL
        INC HL
        LD (NADR+1),HL
        EX DE,HL
        LD (DLINA),HL
        ADD HL,DE
        LD (KADR+1),HL
        POP HL                              ; В HL - адрес оглавления файла
        LD  A,0xFF
        AND A
        RET
;
PPS		LD (UAST),HL
        CALL RDISK
        OR A
        RET Z                               ; Если в ПЗУ нет ROM-диска
        CP  0xFF
        RET NZ
PPS1	XOR A
        RET
;
PPS4	LD HL,(UAST)
        PUSH HL
        LD DE,0x0A
        ADD HL,DE
        CALL RDDE
        POP HL
        ADD HL,DE
        LD DE,0x10
        ADD HL,DE
        LD  A,0
        RLA
        AND A
        RET Z
        INC SP
        INC SP
        XOR A
        RET
;
RDDE	CALL RDISK
        LD  E,A
        INC HL
        CALL RDISK
        LD  D,A
        RET
;
UBUF	LD HL,(NABUF+1)
UBF4	LD A,(HL)
        CP  0x20
        JR NZ,UBF5
        INC HL
        JR UBF4
UBF5	LD (NABUF+1),HL
        LD  B,H
        LD  C,L
        RET
;
ADP		PUSH BC
        PUSH DE
        PUSH HL
        CALL PSC
        POP BC
        LD  A,0x01                          ; Ошибка, нет файла
        JR Z,ADP1
        LD DE,8
        LD HL,(UAST)
        ADD HL,DE
        CALL RDISK
        LD  E,A
        LD  A,C
        CALL WDISK
        INC HL
        CALL RDISK
        LD  D,A
        LD  A,B
        CALL WDISK
        EX DE,HL
ADP1	POP DE
        POP BC
        RET
;
NAMI	LD D,0x08
NMI		LD A,(BC)
        CP  0x20
        JR Z,NM2
        CP  0x0D
        JR Z,NM2
        CALL WDISK
        INC HL
        INC BC
        DEC D
        JR NZ,NMI
        RET
NM2		LD A,0x20
        CALL WDISK
        INC HL
        DEC D
        JR NZ,NM2
        RET
;
DPCMP	LD  A,H
        CP  D
        RET NZ
        LD  A,L
        CP  E
        RET
;
OFLL	PUSH HL
        PUSH DE
        PUSH BC
OFL		JP OFL1
;
OFL1	LD (NADR+1),HL
        LD (TS+1),A
        CALL WOGL
        AND A
        JP NZ,OF3                           ; Выход если повт. файл
        INC HL
        INC HL
        LD B,5
OFL5	INC HL
        CALL WDISK                          ; установить  "R/W"
        DEC B
        JP NZ,OFL5
        LD (TA+1),HL                        ; Текущий адрес
        EX DE,HL

        ;LD HL, MAXD ;k.adr "C","D"
        ;LDA RDISK+1
        ;CP 1
        ;JNZ OFL4

        CALL RMAX                           ; к.адрес дискa "С"
OFL4	CALL DPCMP
        JP C, OF2
        LD HL,0x00
        LD (TZ+1),HL                        ; Количество байт
        LD HL,OFL2
        LD (OFL+1),HL
TS		LD  A,0
;
OFL2	LD (TS+1),A

        ;LD HL, MAXD ;k.adr "C","D"
        ;LDA RDISK+1
        ;CP 1
        ;JNZ OFL3

        CALL RMAX                           ; к.адрес дискa "С"
OFL3	LD  A,L
        AND 0xF0
        LD  L,A
        DEC HL
        EX DE,HL
        LD HL,(TA+1)
OF1		CALL DPCMP
        JP Z,OF2                            ; Мало дискa
        LD A,(TS+1)
        CALL WDISK
TZ		LD HL,0                             ; Текущий размер фл.
        INC HL
        LD (TZ+1),HL
TA		LD HL,0                             ; Тек. адрес
        INC HL
OF5		LD (TA+1),HL
        XOR A
        JP  OF3
;
OF2		LD HL, OFL1
        LD (OFL+1),HL
        LD HL,(UAST)
        CALL WEND
        LD  A,03H  ;malo дискa
        AND A
OF3		POP BC
        POP DE
        POP HL
        RET

; ----------------------------------------------
; Записать файл
; ----------------------------------------------
WRT		LD HL,(KADR+1)
        EX DE,HL
        LD HL,(NADR+1)
WRT1	LD A,(HL)
        CALL OFLL
        RET NZ
        CALL DPCMP
        JP Z,CFL
        INC HL
        JP  WRT1

; ----------------------------------------------
; Закрыть файл
; ----------------------------------------------
CFL		LD HL, OFL1
        LD (OFL+1),HL
        LD DE,0x0A
        LD HL,(UAST)
        PUSH HL
        ADD HL,DE
        EX DE,HL
        LD HL,(TZ+1)                        ; размер файла
        DEC HL                              ; компенсировать последний не записанный байт
CFL1	INC HL
        LD  A,L
        AND 0FH
        JR NZ,CFL1
        EX DE,HL
        CALL WRDE
        POP HL
        ADD HL,DE
        LD DE,10H
        ADD HL,DE
        CALL WEND
        RET

; ----------------------------------------------
; Переименование файла
; ----------------------------------------------
RN		CALL PSC
        LD  A,0x02                          ; Ошибка, повторный файл
        RET NZ
;
        LD HL,(NABUF+1)
        PUSH HL
SPB1	LD A,(HL)
        CP  0x20
        LD (NABUF+1),HL
        INC HL
        JR NZ,SPB1
        ;
        CALL PSC
        LD  A,0x01                          ; Ошибка, нет файла
        POP HL
        RET Z
        LD  B,H
        LD  C,L
        LD HL,(UAST)
        CALL NAMI
        XOR A
        RET

; ----------------------------------------------
; Уничтожить файл
; ----------------------------------------------
DEL		CALL PSC
        LD  A,01H                           ; Ошибка, нет файла
        RET Z
        LD HL,(UAST)
        LD (NADR+1),HL
        LD DE,0CH
        ADD HL,DE
        CALL RDISK                          ; Чит. ячейку "R/O"
        AND 0x80
        LD  A,0x04                          ; Ошибка, "R/O"
        RET NZ
        LD HL,(NAMAS+1)
DL1		CALL PPS                            ; Конкц (END) ?
        AND A
        JR Z,DL2
        CALL PPS4                           ; Переход на следующий файл
        JR DL1
DL2		LD HL,(UAST)
        PUSH HL
        LD HL,(NADR+1)
        LD  B,H
        LD  C,L
        LD HL,(KADR+1)
        POP DE
DL3		CALL DPCMP
        JR Z,DL4
        CALL RDISK
        PUSH HL
        LD  H,B
        LD  L,C
        CALL WDISK
        POP HL
        INC HL
        INC BC
        JR DL3
DL4		LD  H,B
        LD  L,C
;
WEND	LD  A,0xFF
        CALL WDISK
        XOR A
        RET                                 ; A=0

; ----------------------------------------------
; Вывод DIR в буфер
; ----------------------------------------------
DRM		LD  B,H    
        LD  C,L
        XOR A
        LD (TB12+1),A
        LD HL,(NAMAS+1)
DR1		CALL PPS
        AND A
        LD A,(TB12+1)
        RET Z
        ;
        LD HL,(UAST)
        PUSH HL
        LD DE,0x0C
        ADD HL,DE
        CALL RDISK
        POP HL
        RRCA                                ; Проверка флага SYS
        JR C,DR4
        ;
        LD  D,0x10
DR2		CALL RDISK
        LD (BC),A
        INC HL
        INC BC
        DEC D
        JR NZ,DR2
TB12	LD  A,0                             ; Считывание файлoв в DIR
        INC A
        LD (TB12+1),A
DR4		CALL PPS4
        JR DR1

; ----------------------------------------------
PSCD1	LD HL,BUFFLC                        ; "SETUP.TX"
PSCD	CALL WND
        CALL SDM
        JP  PSC

; ----------------------------------------------
; "Холодный загрузчик"
; ----------------------------------------------
BOOT		
        LD SP,STACK 
        CALL STTS
        AND A
        JP NZ,ST1
;
        LD  A,'B'
        CALL PSCD1
        JR NZ,BOOT0
        LD A,1
        OUT (PORT_2C_ROMD_PAGE),A                         ; Поиск SETUP всегда на 1-м ROM-дискe
        LD  A,'A'
        CALL PSCD1
        JR Z,BOOT3
BOOT0	LD HL,WBOOT
        LD (START+1),HL
        LD HL,BOOT1
        JP  PUSK0                           ; Загрузка "SETUP.TX"
;
BOOT1	EX DE,HL
        LD (BT2+1),HL
BT0		LD SP,STACK
BT2		LD HL, 0
BT20	LD A,(HL)
        LD  C,A
        CP  '.'                             ; Конец SETUP.TX?
        JR Z,BOOT3
        CP  '%'                             ; Конец SETUP+BREAK_PC?
        JR Z,BOOT30
        CP  '#'                             ; BREAK AFORMAT?
        JR NZ,BT21
        INC HL
        LD A,(HL)
        CP  0x0D
        JR NZ,BT22
        LD (FLFORM+1),A
        INC HL
        JR BT20
;
BT21	CALL SDM
        INC HL
        LD A,(HL)
BT22	CP 0x3A                             ; ":" - Это диск?
        JR NZ,BT1
        INC HL
BT3		CALL SDM
        LD  A,C
        CALL SETR2                          ; установить номер ROM-диска, если '0..3'
        CALL WND
BT1		LD A,(HL)
        INC HL
        CP  0x0D
        JR NZ,BT1
BT4		LD (BT2+1),HL
        LD HL,BT0
        LD (START+1),HL
        JP  PUSK0                           ; Загрузка файла по "S.TX"
        ;
BOOT30	LD (FLEXT+1),A
BOOT3	LD HL, WBOOT
        LD (START+1),HL
        CALL WNDA
FLFORM	LD  A,0
        AND A
        JP NZ,BOOT4

; ----------------------------------------------
; AUTO_FORMAT
; ----------------------------------------------
AFOR0	LD HL, 0
        LD  B,8
AFOR1	LD  A,1
        CALL RBDS
        LD  A,C
        CP  0x20
        JR C,AFOR2
        CP  0x7F
        JR NC,AFOR2
        INC HL
        DEC B
        JR NZ,AFOR1
        JR AFOR3
AFOR2	LD HL, 0
        LD A,(AFOR1+1)
        LD  C,0xFF
        CALL WBDS
AFOR3	LD A,(AFOR1+1)
        INC A
        CP  8                               ; DISK I ?
        LD (AFOR1+1),A
        JR NZ,AFOR0
;
BOOT4	;JP ST1       ;***** только для ОЗУ

; ----------------------------------------------
; "Теплый загрузчик"
; ----------------------------------------------
WBOOT	LD SP,STACK
        CALL RND
        PUSH AF
        LD  A,0x90
        OUT PORT_2B_CTL,A                   ; Настройка ВВ55 ROM-диска
        ;
        LD HL,ORDROM                        ; ORDOS из ROM2
        LD DE,CCP
        LD BC,UAST-CCP                      ; размер CCP
        CALL LROM2
        POP AF
        CALL WND
        JP  ST1
;
LROM2	IN A,PORT_0A_MEM_CFG
        OR ROM2_WND_ON
        OUT PORT_0A_MEM_CFG,A               ; Включить окно ROM-BIOS2
        LDIR                                ; Скопировать данные
        AND ROM2_WND_OFF                            
        OUT PORT_0A_MEM_CFG,A               ; Выключить окно
        RET
        
;TBADSK		DB '?% '

; ----------------------------------------------
; Чтение файла из диска в ОЗУ
; ----------------------------------------------
RD		CALL PSC
        LD  A,0x1                           ; Ошибка, нет файла
        RET Z
RD0		LD HL,(AST)
        LD (TR2+1),HL
        LD  B,H
        LD  C,L
        CALL ATF
RD1		CALL RDISK
        LD (BC),A
        INC HL
        INC BC
        CALL DPCMP
        JR NZ,RD1
TR2		LD HL,0
TR21	LD A,0
        AND A
        RET Z
QQQ		LD A,0x80
        RET
;
PUSK0	LD (TR3+1),HL
PUSK	CALL RD                             ; HL=адрес стартa
        EX DE,HL
TR3		LD HL,START                         ; Адрес возврата а ORDOS
        PUSH HL
        CP 0x80
        RET NZ
        EX DE,HL
PCHL	JP (HL)
;
QQB		EQU $
VCT		EQU 0C000H-25*3                     ; Начало векторов ORDOS

; ----------------------------------------------
        
        ASSERT QQB<VCT, Переполнение ORDOS
        
        IF QQB<VCT
            DS VCT-QQB,0xFF
        ENDIF

; ----------------------------------------------
REZERV	RET
        DW 0
ADSK	JP ADISK                            ; Адрес "STOP" в диске
VER		LD A,VERS                           ; Версия "ORDOS"
        RET                                 ;
ADRP	JP ADP                              ; Изменение адресa посадки
RMX		JP RMAX                             ; Чтение макс. размера дискa
WMX		JP WMAX                             ; Запись макс. размера дискa
ATFLM	JP ATFM                             ; Чтение атриб. файла
WTFLD	JP WATF                             ; Запись адрес блока ОЗУ
ATFLD	JP ATF                              ; Чтение адрес размещения файла
SDMA	JP SDM                              ; Установить адрес буфера ввода
LDMA	JP LDM                              ; Чтение адрес буфера ввода
WDN		JP WND                              ; Установить текущ. к/дискa
RDN		JP RND                              ; Чтение N текущ.  к/дискa
READ	JP RDISK                            ; Чтение байта из к/дискa
WRITE	JP WDISK                            ; Запись байта из к/дискa
STOP	JP WEND                             ; Запись стоп-слова в диск
PSCF	JP PSC                              ; Поиск файла
DIRM	JP DRM                              ; Вывод каталога в буфер
REN		JP RN                               ; ПП переименования файла
ERA		JP DEL                              ; ПП уничтожения файла
OFILL	JP OFLL                             ; Открыть файл
CFILL	JP CFL                              ; Закрыть файл
WFILE	JP WRT                              ; ПП записи файла на к/диск
RFILE	JP RD                               ; ПП чтения  файла из к/диска
START	JP BOOT

; ----------------------------------------------
END
; ----------------------------------------------