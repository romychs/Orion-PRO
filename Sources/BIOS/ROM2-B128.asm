; ==============================================
;               " O r i o n - P R O "      
; ==============================================
;                 "Монитор-128/PRO"
;
;      Клавиатура "86РК", "МС7007"
;
;      V2.00   27.05.97
;      V2.10   28.11.99
;  (доработан вектор 0F833H)
; ----------------------------------------------
;   Дизассемблировано и адаптировно для SjasmpPlus.
;   Romych-ем  в  апреле 2021
; ==============================================

; ==============================================
;   2000H   Вход в режим "O-128"
;   2003H   Подпрограмма инициализации режима "O-128"
; ==============================================

        DEVICE NOSLOT64K

        INCLUDE "ports.inc"                 ; Порты Ориона


ADROM2  EQU 2000H                           ; Начальный адрес ROM2
;
; --- ORDOS ---
ORROM   EQU 2A20H                           ; 29E0H начальный адрес ORDOS в ROM2
ORSIZE  EQU 800H                            ; размер ORDOS
; ----------------------------------------------
 
        ORG ADROM2                          ; 2000H
        ;
        ; 2000H - Холодный старт компьютера в режиме Орион-128
        JP COLDST
        JP INI128
        ;
        DB ' BIOS-128/PRO V2.10 '
        DB '(C) 1990-99 ORIONSOFT '

; ----------------------------------------------
; 2003H - инициализация режима "O-128" из режима "PRO"
; ----------------------------------------------
INI128  CALL INIT1
        JP INIT2

; ----------------------------------------------
; Подпрограмма загрузки M-2
; ----------------------------------------------
INIT1   
        IN A,(PORT_0A_MEM_CFG)
        AND 0x7F
        OUT (PORT_0A_MEM_CFG),A
        LD HL,BEGIN                         ; Начальный адрес MON в ROM_2
        LD DE,START                         ; Начальный адрес MON в 0F800H
        LD BC,MNEND-BEGIN                   ; Размер монитора MON в ROM_2
        LDIR                                ; Перемещение монитора в ОЗУ
        ;IN A,PORT_0A_MEM_CFG
        OR 0x80                             ; включить режим "ORION-128"
        OUT PORT_0A_MEM_CFG,A
        IM 0
        RET

; ----------------------------------------------
; Холодный старт O-128
; ----------------------------------------------
COLDST  LD SP,STACK
        CALL INIT1
        JP START                            ; 0F800H

; ----------------------------------------------
; Подпрограмма установки ROM-диска
; (работает в ROM2)
; C=0FFH - установить текущиц ROM-диск и C = его номер
; C=0..3 - установить новый  ROM-диск
; ----------------------------------------------
SROMD2  PUSH IX
        IN A,PORT_05_RAM1P
        PUSH AF
        ; установка системного сегмента ОЗУ в окне RAM1
        LD A,(0x002F)
        CP '3'                              ; проверить модификацию ROM1 ; 33h
        LD A,0x1F
        JR NZ,SRD1
        LD A,0x03
SRD1    OUT PORT_05_RAM1P,A
        LD IX,0x7FFB                        ; ячейки с данными о текущем ROM-диске
        LD A,C
        INC A                               ; "Z"-читать
        JR NZ,SRD3
        LD A,(IX+0)
        CP 0xA5
        JR NZ,SRD2                          ; информация недостоверна
        LD A,(IX+1)
        LD C,A
        CP 3+1
        JR C,SRD4                           ; достоверна
SRD2    LD C,0
        ; установка нового ROM-диска
SRD3    LD (IX+0),0xA5                      ; признак достоверности
        LD (IX+1),C
        ; определение маски ROM-диска
SRD4    LD B,C                              ; C-номер ROM-диска 0..3
        INC B
        LD A,0x80
SRD5    RLCA
        DJNZ SRD5
        OUT (PORT_2C_ROMD_PAGE),A
        POP AF
        OUT (PORT_05_RAM1P),A
        POP IX
        RET
;
BEGIN   
; ==============================================
        PHASE 0xF800
;
START   JP ST1
KBX     JP KB                              ; F803  Вход подпрограммы обработки клавиатуры 
        JP PUSTO                           ;-F806
TVX     JP TVST                            ;-F809  -//- вывод символа C на TV
        JP PUSTO                           ;-F80C
        JP TV                              ;-F80F  -//- вывод символа A на TV
        JP STTS                            ; F812  -//- проверка статуса клавиатуры
        JP ASC                             ; F815  -//- байт=>TV(2ASCII)
        JP MSG                             ; F818  -//- вывод символьного сообщения
        JP INKEY                           ; F81B  -//- ввод кода нажатой клавиши
        JP RCUR                            ; F81E положение курсора
        JP TVBT                            ; F821 печать
        JP MOVBL                           ; F824 перенести блок
        JP CLS                             ; F827 запись константы в  страницу
        JP CSM                             ; F82A считать контрольную сумму
        JP RPAC                            ; F82D распаковка знакогенератора
        JP XPAGE                           ; F830 чтение/запись рабочей страницы
        JP RESET0                          ; F833 инициализация рабочих ячеек
        JP RRAM                            ; F836 чтение байта с доп. страниц
        JP WRAM                            ; F839 запись байта в доп. страницу
        JP WCUR                            ; F83C установка курсора
        JP BP                              ; F83F вход в звуковой синтез

; ----------------------------------------------
; подпрограмма инициализации портов и ячеек холодного старта
; ----------------------------------------------
INIT2   IN A,PORT_0A_MEM_CFG
        AND 0xE0
        OUT PORT_0A_MEM_CFG,A               ; включение WIN+ROM(1,2)
        CALL ROM20                          ; сегмент 0 ROM2 / A=0
        OUT REG_F9_RAM_PG,A                 ; PAGE=0
        OUT REG_FA_SCRN_CFG,A               ; экран=0
        LD A,0x1F
        OUT REG_FC_COLOR,A
        LD A,0x0E
        OUT PORT_F8_VMODE,A                 ; псевдоцвет
        CALL RESET                          ; Инициализация рабочих ячеек
        JP RPAC                             ; Распаковка ЗГ
        ;
        ; Включить доступ к 0 сегменту ROM2
ROM2X   OR 8
        OUT PORT_0A_MEM_CFG,A
ROM20   XOR A
        OUT PORT_09_ROM2_SEG,A
        RET

; ----------------------------------------------
; Холодный старт
; ----------------------------------------------
ST1     LD SP,STACK
        CALL INIT2
;
UR      LD SP,STACK                         ; "теплый старт"
        ;-------------------------
        ; программирование порта KBRD
        IN A,PORT_00_DIPSW
        AND 4                               ; какая KBRD?
        LD A,0x8A                           ; для РК86
        JR NZ,UR0
        LD A,0x90                           ; для МС7007
UR0     OUT PORT_1B_CTL,A

; ----------------------------------------------
; Загрузка ORDOS
; ----------------------------------------------
ST9     LD A,0x90
        OUT (PORT_2B_CTL),A                   ; PDU
        LD A,1
        OUT PORT_2C_ROMD_PAGE,A             ; Включить банк 1 ROM-диска
;
        IN A,(PORT_00_DIPSW)
        AND 0x40                            ; ORDOS внеш./внутр.?
        JP Z,ST900                          ; D6=0 - внутр.

; ----------------------------------------------
; Старый загрузчик ORDOS с внешнего ROM-диска
; ----------------------------------------------
        XOR A
        OUT PORT_29_ROMD_ADRL,A               ; установить нулевой адрес
        OUT PORT_2A_ROMD_ADRH,A
        NOP
        IN A,PORT_28_ROMD_DATA
        CP 0xff
        JP Z,ST_ERR                        ; ROM-disk не подключен
        AND A
        JP Z,ST_ERR                        ; ROM-disk не подключен
;
        LD HL,0
        CALL STI                            ; читать первый байт
        DEC HL
        CP 0xC3                            ; NEW TYPE ROM-DISK?
        JR NZ,ST90                         ; да!
;
        LD DE,0B800H
        LD BC,800H
        CALL ST80
        JP ST901                            ; JP 0BFFDH
;
; ----------------------------------------------
; Новый загрузчик из ROM-диска
; ----------------------------------------------
; если первый байт ROM-диска не "C3", то загрузка в новом формате
;
; первые адреса 0-1FH ROM_диска - служебная информация
;
; 0001 0203 0405 06 07....0F
;  \/   \/   \/  II_ кол. ROM-банков (0=1,..3=4)
;   |    |    |  |__ 0 - каждый банк автоном.
;   |    |    |     >0 - один общий ROM-диск
;   |    |    |
;   |    |     - адр.посад.фл. в ОЗУ+START
;   |     - размер загруж. блока
;    - адр.размещ.фл. в ROM
;
; Внимание!! байты 07-0F - резерв, содержимое ROM-диска начинается с 10H!
;
ST90    CALL STI
        LD E,A
        CALL STI
        LD D,A
        CALL STI
        LD C,A
        CALL STI
        LD B,A
        PUSH DE
        CALL STI
        LD E,A
        CALL STI
        LD D,A
        POP HL
        PUSH DE

        ; SP=DE= Адрес начала (RET)
        ; HL= Адрес в ROM
        ; DE= Адрес в ОЗУ
        ; BC= Размер
        LD A,B
        AND C
        INC A
        JR Z,ST_ER2                         ; диск не загрузочный
;
ST80    LD A,B
        OR C
        RET Z
        CALL STI
        LD (DE),A
        INC DE
        DEC BC
        JR ST80
;
ST_ER2  LD HL,TBER2
        JR ERR
TBER1   DB 1FH,' net wne{nego ROM-diska!',7,7,7,0
TBER2   DB 1FH,' w ROM-diske net sistemy!',7,7,7,0
;
ST_ERR  LD SP,STACK
        LD HL,TBER1
ERR     CALL MSG
        CALL KBRD
        JP ST9
;
STI     LD A,L
        OUT PORT_29_ROMD_ADRL,A             ; PDB
        LD A,H
        OUT PORT_2A_ROMD_ADRH,A             ; PDC
        NOP
        IN A,PORT_28_ROMD_DATA              ; PDA
        INC HL
PUSTO   RET
;
; ----------------------------------------------
; Загрузка внутренней ORDOS
; ----------------------------------------------
ST900   IN A,PORT_0A_MEM_CFG
        PUSH AF                         ; Сохранение содержимого диспетчера
        CALL ROM2X                      ; Включение ROM2
        LD HL,ORROM                     ; 29E0 начало адреса ORDOS в ROM2
        LD DE,0xB800                    ; B800 начало размещение ORDOS
        LD BC,ORSIZE                    ; 800 размер ORDOS
            ; LD A,(HL)
            ; CP 0xFF
            ; JR Z,ST_ER2               ; в ROM-2 нет системы
        LDIR
        POP AF
        OUT PORT_0A_MEM_CFG,A           ; Восстановление диспетчера
ST901   DEC C                           ; C=0FFH
        CALL SROMD                      ; Установить текущий ROM-диск
        JP 0xBFFD                       ; Запуск ORDOS

; ----------------------------------------------
;
RPAC    PUSH BC
        PUSH DE
        PUSH HL
        IN A,PORT_0A_MEM_CFG
        PUSH AF
        CALL ROM2X                      ; Открыть ROM2
;
        LD DE,NAZG
        LD HL,(ZNAKG)

B0      LD C,0x07
        XOR A
        LD (HL),A
        INC HL

B1      LD A,(DE)
        RLCA
        RLCA
        RLCA
        AND 0x07
        LD B,A

B2      LD A,(DE)
        AND 1FH
        LD (HL),A
        INC HL
        DEC C
        LD A,B
        AND A
        JR Z,B3
        DEC B
        JR B2

B3      INC DE
;
        LD A,D
        CP ZGEND >> 8                       ; 0x2A
        JR NZ,B4
        LD A,E
        CP ZGEND & 0xFF                     ; 0x06
        JR NZ,B4
;
        POP AF
        OUT PORT_0A_MEM_CFG,A
        JP STR2
;
B4      LD A,C
        AND A
        JR NZ,B1
        JR B0

VIRUS   
        DEPHASE
; ----------------------------------------------
; Блок исходного состояния ячеек MON-4. 
; Переносится при холодном старте в ОЗУ - F3C0-F3F3H
; ----------------------------------------------

        PHASE 0xF3C0
;
BEGVIR  
STACK   
;
FLRES   DB 0                                ; FLRES
ADRES   DW UR                               ; ADRES
BP      JP BEEP                             ; F3C3-..C5
KB      JP KBRD                             ; F3C6-..C8
TVBT    JP PRINT                            ; F3C9-..CB
TVST    JP TV2                              ; F3CC-..CE
;    
EKRAN   DB 0xC0                             ; F3CF EKRAN
EKRED   DB 0x30                             ; F3D0 EKRED
ZNAKG   DW 0xF000                           ; F3D1 ZG 20-7F
INVERS  DB 0                                ; F3D3 INVER
SZ      DB 0                                ; F3D4 SWIN
PAGE    DB 0                                ; F3D5 RAM PAGE
TVAD    DW 0                                ; F3D6 TVAD
;    
        DW 0                                ; F3D8 - не используется
        DW 0                                ; F3DA - не используется
        DW 0                                ; F3DC - не используется
;    
AR2     DB 0                                ; F3DE ESC
SVSTK   DW 0                                ; F3DF
TIMES2  DW TV2                              ; F3E1 - не используется
JOB1    DB 0                                ; F3E3 рабочая ячейка №1
JOB2    DB 0                                ; F3E4 рабочая ячейка №2
;
FFIX    DB 0                                ; F3E5 FL= RUS/LAT
SIMV    DB 0                                ; F3E6 FOR KBRD
CBEEP   DB 0x55                             ; F3E7 константа BEEP
TBRUS   DW TABR                             ; F3E8
TBLAT   DW TABL                             ; F3EA
;
STTSV   DW STTS_                            ; F3EC STTS
TVAV    DW TV_A                             ; F3EE TV_A
IKEYV   DW I_KEY                            ; F3F0 INKEY
        DW 0                                ;F3F2..F3 ?

; ----------------------------------------------
; Служебные ячейки KBRD+INKEY
; ----------------------------------------------
TSU     EQU 0xF3FD
TSH     EQU 0xF3FE
TBT     EQU 0xF3FF
;
EVIR    EQU $

        DEPHASE

        PHASE   VIRUS+(EVIR-BEGVIR)
ENDVIR  
        ;
        ; Перенос исходного состояния ячеек в ОЗУ
RESET   LD HL,VIRUS
        LD DE,BEGVIR
        LD BC,EVIR-BEGVIR
        LDIR
        RET
        ;
RESET0  AND A
        JR NZ,RESET1
        IN A,PORT_0A_MEM_CFG
        PUSH AF
        CALL ROM2X                          ; ROM2 / сегмент 0
        CALL RESET
        POP AF
        OUT PORT_0A_MEM_CFG,A

; ----------------------------------------------
; VECTOR_RESET
; 0 0 0 0  0 0 0 0
; I  \  /     \  /
; I    I        I_ тип ПК		00 - o-128.2
; I    I                        01 - O-128+CARD2
; I    I                        03 - O-128PLUS
; I    I                        04 - ORION-POWER
; I    I___ реальная скорость	00 - 2.5 МГц
; I                             01 - 3.5 МГц
; I_ / 0 - MONIT                02 - 5.0 МГц
;    \ 1 - vki                  03 - 6.5 МГц
;                               04 - 8.5 МГц
;                               05 - 10.0 МГц
;                               07 - 20.0 МГц
        LD A,54H
        RET
;
RESET1  INC A   ;A=FF?
        RET NZ

; ----------------------------------------------
; Установка текущего ROM-диска (C=FF)
; или нового (C=0,1,2,3)
; ----------------------------------------------
SROMD   IN A,(PORT_09_ROM2_SEG)
        PUSH AF
        XOR A
        OUT (PORT_09_ROM2_SEG),A
        IN A,(PORT_0A_MEM_CFG)
        PUSH AF
        OR 0x1A                         ; ROM1+ROM2+RAM1
        OUT (PORT_0A_MEM_CFG),A
        CALL SROMD2                     ; вызов из ROM2
        POP AF
        OUT (PORT_0A_MEM_CFG),A
        POP AF
        OUT (PORT_09_ROM2_SEG),A
        LD A,C                          ; текущий ROM-диск
        RET
;
ASC     PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL AS1
        POP AF
AS1     AND 0x0F
        CP 0x0A
        JP M,AS2
        ADD 0x07
AS2     ADD 0x30
TV20    PUSH BC
        LD C,A
        CALL TVX
        POP BC
AS3     RET
;
MSG     LD A,(HL)
        AND A
        RET Z
        CALL TV20
        INC HL
        JR MSG

; ----------------------------------------------
; Подпрограмма подсчета контрольной суммы
; ----------------------------------------------
CSM     EX DE,HL
        PUSH HL
        LD A,L
        LD HL,0
        JR CSM2
CSM1    EX DE,HL
        LD B,(HL)
        LD C,B
        INC HL
        EX DE,HL
        ADD HL,BC
CSM2    CP E
        JR NZ,CSM1
        POP BC
        PUSH BC
        LD A,B
        CP D
        LD A,C
        JR NZ,CSM1
        LD A,(DE)
        ADD L
        LD C,A
        LD B,H
        POP HL
        RET
;
DPCMP   LD A,H
        CP D
        RET NZ
        LD A,L
        CP E
        RET
;
WCUR    LD A,L
        RLCA
        RLCA
        LD L,A
        LD (TVAD),HL
RCUR    LD HL,(TVAD)
        LD A,L
        RRCA
        RRCA
        LD L,A
        RET
;
WRAM    OUT REG_F9_RAM_PG,A
        LD (HL),C
        JR RRM
RRAM    OUT REG_F9_RAM_PG,A
        LD C,(HL)
RRM     XOR A
        OUT REG_F9_RAM_PG,A
        RET

; ----------------------------------------------
; Чтение/запись рабочей страницы
; Вход:  A = 0 - читать
;        A != 0 - записать
;        C = номер страницы (0-7)
; Выход: чтение - A = номер страницы
;        запись - A = предыдущее состояние
; ----------------------------------------------
XPAGE   AND A
        JR Z,XPG1
        PUSH HL
        LD A,C
        OUT REG_F9_RAM_PG,A
        LD HL,PAGE
        LD A,(HL)
        LD (HL),C
        POP HL
        RET
XPG1    LD A,(PAGE)
        RET

; ----------------------------------------------
; Подпрограмма записи констаны в X-PAGE
; HL = начальный адрес
; DE = размер
; C = записываемый байт
; A - куда (PAGE) записывать байт
; ----------------------------------------------
CLS     AND 0x0F
        OUT (REG_F9_RAM_PG),A
        LD (HL),C
        LD B,D
        LD C,E
        LD D,H
        LD E,L
        INC DE
        DEC BC
        LD A,C
        OR B
        JR Z,CLS1
        LDIR
CLS1    LD A,(PAGE)
        OUT (REG_F9_RAM_PG),A
        RET

; ----------------------------------------------
; Подпрограмма переноса блока PAGE/PAGE
; HL=начальный адрес
; DE=начальный адрес - куда
; BC=количество
; A=0000____ - откуда читать
;   ____0000 - куда записать
; ----------------------------------------------
MOVBL   PUSH AF
        AND 0x0F
        LD (JOB2),A                         ; куда
        POP AF
        ;
        RRCA
        RRCA
        RRCA
        RRCA
        AND 0x0F
        LD (JOB1),A                         ; откуда
        LD (SVSTK),SP
        LD SP,HL                            ; SP = адрес откуда
        EX DE,HL                            ; HL = адрес куда
        ;
TR0     LD A,(JOB1)
        OUT REG_F9_RAM_PG,A
        POP DE
        LD A,(JOB2)
        OUT REG_F9_RAM_PG,A
        LD (HL),E
        INC HL
        DEC BC
        LD A,B
        OR C
        JR Z,TR1
        LD (HL),D
        INC HL
        DEC BC
        LD A,B
        OR C
        JR NZ,TR0
TR1     LD A,(PAGE)
        OUT REG_F9_RAM_PG,A
        LD SP,(SVSTK)                       ; восстановим стек
        RET

; ----------------------------------------------
; Печать
; Вход:
; 1. A != 0 - чтение статуса PRINT
; 2. A = 0 - печать символа
;    C = символ для печати
; Выход:
;   A = 0 - символ принят
;   A=/=0 - принтер не готов
;     D0=1 - PAGEEND
;     D1=1 - неисправность (ERROR)
;     D2=1 - занят (BUSY)
; ----------------------------------------------
PRINT   AND A
        JR Z,WPRT1  ; A=0 - печать

; ----------------------------------------------
;  Статус принтера
;  Выход:
;  A = 0 - принтер готов
;  A != 0 - принтер не готов
;    D0=1 - конец страницы PAGEEND
;    D1=1 - неисправность (ERROR)
;    D2=1 - занят (BUSY)
STATU   PUSH BC
        LD B,5
        NOP
        IN A,PORT_02_PRNT_CTL               ; PORT CTRL/PRINT
        RLCA
        RLCA
        RLCA
        XOR B
        AND 7
        POP BC
        RET

; ----------------------------------------------
; Подпрограмма печати символа
; Вход:
;  C=символ для печати
; ----------------------------------------------
WPRT1   PUSH BC
        PUSH DE
        PUSH HL
WPRT2   CALL STATU
        JP NZ,STR2
        LD A,C
        CPL
        OUT PORT_01_PRNT_DAT,A              ; PORT DATA-PRINT
        LD A,1                              ; STROBE \_ 0
        OUT PORT_02_PRNT_CTL,A              ; PORT CTRL/PRINT
        XOR A                               ; STROBE _/ 1
        NOP
        NOP
        OUT PORT_02_PRNT_CTL,A              ; PORT CTRL/PRINT
WPRT5   CALL STATU
        JP STR2

; ----------------------------------------------
; Проверка статуса клавиатуры
; ----------------------------------------------
STTS    PUSH HL
        LD HL,(STTSV)
        EX (SP),HL
        RET
;
STTS_   IN A,PORT_00_DIPSW
        AND 4
        JR Z,LF9A3
        XOR A
        OUT PORT_18_KBD,A
        IN A,PORT_19_KBD
        XOR 0xFF
        RET Z
        LD A,0xFF
        RET

LF9A3   XOR A
        OUT PORT_1A_KBD,A
        OUT PORT_19_KBD,A
        IN A,PORT_18_KBD
        INC A
        RET Z
        LD A,0xFF
        OUT PORT_1A_KBD,A
        LD A,0xFC
        OUT PORT_19_KBD,A
        IN A,PORT_18_KBD
        AND 0xEB
        CP 0xEB
        JR NZ,LF9D0
        LD A,3
        OUT PORT_19_KBD,A
        IN A,PORT_18_KBD
        INC A
        JR NZ,LF9D0
        OUT PORT_1A_KBD,A
        IN A,PORT_18_KBD
        INC A
        RET Z
LF9D0   LD A,0xFF
        RET

; ----------------------------------------------
; Подпрограмма обработки клавиатуры
; ----------------------------------------------
KBRD    PUSH BC
        PUSH DE
        PUSH HL
        CALL INKEY
        CP 0xFF
        JR NZ,KBR1
        LD (SIMV),A
KBR1    LD D,0
KBR2    INC DE
        DEC E
        INC E
        CALL Z,MASC
        CALL INKEY
        INC A
        JR Z,KBR2
        PUSH AF
        LD A,D
        RRCA
        CALL NC,MASC
        POP AF
        DEC A
        JP P,KBR5
        LD DE,0x5530
        LD HL,FFIX
        LD A,(HL)
        CPL
        LD (HL),A
        AND A
        LD A,D
        JR Z,KBR3
        LD A,E
KBR3    LD (CBEEP),A
KBR4    CALL INKEY
        INC A
        JR NZ,KBR4
        CALL MASC
        JR KBR1
KBR5    LD E,A
        LD D,20
        LD HL,SIMV
        CP (HL)
        JR Z,KBR7
KBR6    DEC D
        JR Z,KBR7
        CALL INKEY
        CP E
        JR Z,KBR6
KBR7    CALL BEEP
        LD (HL),E
        CALL MASC
        LD A,E
        JP STR2

; ----------------------------------------------
;  Ввод кода нажатой клавиши
; ----------------------------------------------
INKEY   PUSH HL
        LD HL,(IKEYV)
        EX (SP),HL
        RET
;
I_KEY   PUSH BC
        PUSH DE
        PUSH HL
        IN A,PORT_00_DIPSW
        AND 4
        JP  Z,INKEY7
        ;
        ; INKEY RK-86
        LD HL,STR2
        PUSH HL
        LD B,0
        LD D,9
        LD C,0FEH
INKR1   LD A,C
        OUT PORT_18_KBD,A
        RLCA
        LD C,A
        IN A,PORT_19_KBD
        CP 0xFF
        JR Z,LINKR2
        LD E,A
        ;
        LD HL,0x0900
LFA5E   DEC HL
        LD A,H
        OR L
        JR NZ,LFA5E
        ;
        IN A,PORT_19_KBD
        CP E
        JR Z,INKR4
LINKR2  LD A,B
        ADD 8
        LD B,A
        DEC D
        JR NZ,INKR1
        IN A,PORT_1A_KBD
        AND 0x80
        LD A,0xFE
        RET Z
        INC A
        RET
INKR3   INC B
INKR4   RRA
        JR C,INKR3
        LD A,B
        AND 0x3F
        CP 0x10
        JP C,INKR12
        CP 0x3F
        LD B,A
        LD A,0x20
        RET Z
        IN A,PORT_1A_KBD
        LD C,A
        AND 0x40
        JR NZ,INKR5
        LD A,B
        AND 0x1F
        RET
INKR5   LD A,(FFIX)
        AND A
        JR NZ,INKR10
        LD A,C
        AND 0x20
        LD A,B
        JR Z,INKR6
        CP 0x1C
        JP M,INKR8
        CP 0x20
        JP M,INKR9
        JR INKR8
INKR6   CP 0x1C
        JR C,INKR9
        CP 0x20
        JR C,INKR8
INKR7   ADD A,0x20
INKR8   ADD A,0x10
INKR9   ADD A,0x10
        POP HL
        JP STR2
INKR10  LD A,C
        AND 0x20
        LD A,B
        JR Z,INKR11
        CP 0x1C
        JP M,INKR8
        CP 0x20
        JP M,INKR9
        JR INKR7
INKR11  CP 0x1C
        JP M,INKR9
        JR INKR8
INKR12  LD HL,TBRK86
        LD C,A
        LD B,0
        ADD HL,BC
        LD A,(HL)
        RET

TBRK86  DB 0x0C,0x1F,0x1B,0,1,2,3,4
        DB 9,0x0A,0x0D,0x7F,8,0x19,0x18,0x1A
        ;
        ; INKEY MS7007
INKEY7  LD HL,0xFFFF
        LD (TSU),HL
        LD (TSH),HL
        DEC HL
        LD C,0
INKM1   LD A,L
        OUT PORT_19_KBD,A
        LD A,H
        OUT PORT_1A_KBD,A
        IN A,PORT_18_KBD
        CP 0xFF
        JR Z,INKM4
        LD B,A
        PUSH HL
        ;
        LD HL,0x0900
LFB1C   DEC HL
        LD A,H
        OR L
        JR NZ,LFB1C
        ;
        POP HL
        IN A,PORT_18_KBD
        CP B
        JR NZ,INKM4
        LD B,C
        JR INKM3
INKM2   INC C
INKM3   RRA
        JR C,INKM2
        LD A,C
        LD C,B
        LD DE,TSU
        CP 0x0A
        JR Z,INKM30
        CP 4
        INC DE
        JR Z,INKM30
        CP 0x14
        JR Z,INKM7
        INC DE
        DB 0x06                             ; LD B,0xAF
INKM30  XOR A
        LD (DE),A
INKM4   LD A,C
        ADD 8
        LD C,A
        SCF
        LD A,L
        RLA
        LD L,A
        LD A,H
        RLA
        LD H,A
        CP 0xF7
        JP NZ,INKM1
        LD A,(TBT)
        CP 0xFF
        JP Z,STR2
        LD HL,(TBRUS)
        EX DE,HL
        LD HL,(TBLAT)
        LD A,(FFIX)
        AND A
        JR Z,INKM5
        EX DE,HL
INKM5   LD B,0
        LD A,(TBT)                          ; scan-код клавиши
        LD C,A
        LD A,(TSH)                          ; нажат SHIFT ?
        AND A
        JR NZ,INKM6                         ; SHIFT не нажат
        ;
        EX DE,HL
        ;
        ADD HL,BC
        LD A,C                              ; scan-код
        ;
        ; проверка scan-кодов спецклавиш
        PUSH HL
        LD HL,SPECTB
        LD C,SPECTE-SPECTB
        CPIR
        POP HL
        LD A,(HL)
        JR NZ,INKM61                        ; не спецсимвол
        ;
        ; перекодировка спецсимволов при нажатом SHFIT
        XOR 0x10
        JR INKM61
            ;
INKM6   ADD HL,BC
        LD A,(HL)                           ; код символа
INKM61  LD C,A
        ;
        LD A,(TSU)                          ; CTRL ?
        AND A
        LD A,C
        JP NZ,STR2
        AND 0x1F
        JP STR2
INKM7   LD A,0FEH
        JP STR2
;
; таблица скан-кодов спецклавиш
SPECTB  DB 19H,21H,29H,30H,39H,41H,48H,50H,57H,4FH
        DB 47H,46H,10H,37H,54H,45H
SPECTE  ;
        ;
        ;
TABR    DB 39H,38H,0,0,0,34H,35H,36H
        DB 1BH,9,0,0EH,0FH,2BH,2DH,0DH
        DB 2BH,6AH,66H,71H,0,30H,2EH,2CH
        DB 0,21H,63H,79H,7EH,31H,32H,33H
        DB 1,22H,75H,77H,73H,37H,0CH,1FH
        DB 2,23H,6BH,61H,6DH,7FH,1EH,0AH
        DB 24H,65H,70H,69H,20H,18H,0DH,3FH
        DB 3,25H,6EH,72H,74H,1AH,19H,5FH
        DB 4,26H,67H,6FH,78H,3EH,2AH,3DH
        DB 27H,7BH,6CH,62H,8,7CH,68H,20H
        DB 28H,7DH,64H,60H,3CH,76H,7AH,29H
TABL    DB 39H,38H,0,0,0,34H,35H,36H
        DB 1BH,9,0,0EH,0FH,2BH,2DH,0DH
        DB 2BH,4AH,46H,51H,0,30H,2EH,2CH
        DB 0,21H,43H,59H,5EH,31H,32H,33H
        DB 1,22H,55H,57H,53H,37H,0CH,1FH
        DB 2,23H,4BH,41H,4DH,7FH,1EH,0AH
        DB 24H,45H,50H,49H,20H,18H,0DH,3FH
        DB 3,25H,4EH,52H,54H,1AH,19H,5FH
        DB 4,26H,47H,4FH,58H,3EH,2AH,3DH
        DB 27H,5BH,4CH,42H,8,5CH,48H,20H
        DB 28H,5DH,44H,40H,3CH,56H,5AH,29H
        ;

; ----------------------------------------------
; 
; ----------------------------------------------
TV      PUSH HL
        LD HL,(TVAV)
        EX (SP),HL
        RET
;
TV_A    PUSH BC
        LD C,A
        DB 6
TV2     PUSH BC
TBC     PUSH DE
        PUSH HL
        PUSH AF
        LD A,C
        CP 0x1B
        LD A,0xF0
        JP Z,UPR1
        LD A,(AR2)
        AND A
        JP NZ,UST
ARINT   LD A,C
        CP 0x7F
        JR NZ,VT14
        LD A,(INVERS)
        CPL
        LD (INVERS),A
        JP TVQ
VT14    LD H,20H
        SUB H
        JR C,OP1
        LD L,A
        ADD HL,HL
        ADD HL,HL
        ADD HL,HL
        EX DE,HL
        LD HL,(ZNAKG)
        ADD HL,DE
        EX DE,HL
        CALL MASC1
        EX DE,HL
        LD A,0x16
V22     PUSH AF
        PUSH HL
        LD A,(INVERS)
        XOR (HL)
        AND 0x3F
        LD L,A
        LD A,(JOB2)
        DEC A
        LD H,0
V21     ADD HL,HL
        ADD HL,HL
        INC A
        JR NZ,V21
        EX DE,HL
        LD A,B
        XOR (HL)
        AND (HL)
        OR D
        LD (HL),A
        INC H
        LD A,C
        XOR (HL)
        AND (HL)
        OR E
        LD (HL),A
        DEC H
        INC L
        EX DE,HL
        POP HL
        INC HL
        POP AF
        SUB 0x03
        JP P,V22
        LD HL,ZERO
        CP 0xF8
        JR NZ,V22
OP1     LD HL,(TVAD)
        CALL OPER
        ADD HL,BC
        LD A,H
        CP 0x19
        JR C,V3
        JR NZ,V4
        INC D
        LD H,D
        JR Z,V3
;             "rulon"
        PUSH HL
        LD (SVSTK),SP
        LD A,(EKRED)
        LD B,A
        LD A,(EKRAN)
        LD H,A
        LD A,(SZ)
        LD L,A
        CALL MULT10
        LD C,A
RL0     LD A,C
        ADD 0x0A
        LD L,A
        LD SP,HL    
        LD L,C
        LD A,0xF0
RL1     POP DE
        LD (HL),E
        INC L
        LD (HL),D
        INC L
        POP DE
        LD (HL),E
        INC L
        LD (HL),D
        INC L
        CP L
        JR NC,RL1
        LD A,(INVERS)
RL2     INC SP
        LD (HL),A
        INC L
        JR NZ,RL2
        INC H
        DEC B
        JR NZ,RL0
        LD SP,(SVSTK)
        POP HL
V4      LD H,18H
V3      LD (TVAD),HL
TVQ     POP AF
STR2    POP HL
        POP DE
        POP BC
        RET
;
OPER    DB 0x01
ZERO    DB 0x00
        DB 0x01
        LD D,C
        INC A
        CALL Z,GTV
        JR Z,V5
        CP 0xEB
        RET Z
        DEC D
        ADD 0x05
        RET Z
        INC D
        LD B,0xFF
        INC A
        RET Z
        LD C,0xFC
        CP 0xEF
        RET Z
        LD BC,0
        CP 0xF0
        JR NZ,VDOP
        LD A,L
        AND 0xE0
        ADD 0x20
        LD L,A
        RET
;
VDOP    LD C,04H
        INC A
        RET Z
        CP 0xEF
        JR NZ,V6
        POP AF                              ; баланс стека
        CALL BEEP
        JR TVQ
V6      ADD 0x0B
        JR Z,V7
        INC A
        RET NZ
V5      LD H,D
V7      LD L,D
        LD B,D
        LD C,D
        RET
;
MASC1   LD HL,(TVAD)
        LD A,L
        RRCA
        LD L,A
        RRCA
        ADD A,L
        LD B,A
        LD L,H
        LD A,(EKRAN)
        LD H,A
        LD A,B
        DEC H
M18     INC H
        SUB 0x04
        JR NC,M18
        LD (JOB2),A
        PUSH HL
        LD HL,0xFC
M19     ADD HL,HL
        ADD HL,HL
        INC A
        JR NZ,M19
        LD B,H
        LD C,L
        POP HL
MULT10  LD A,L
        RLCA
        RLCA
        RLCA
        ADD A,L
        ADD A,L
        LD L,A
        RET
;
MASC    CALL MASC1
        ADD A,0x09
        LD L,A
        LD A,B
        XOR (HL)
        LD (HL),A
        INC H
        LD A,C
        XOR (HL)
        LD (HL),A
        DEC H
        RET
;
UST1    LD A,C
        CP 0x59
        JR NZ,UST2
        LD A,02H
        OR B
UPR1    LD (AR2),A
        JP TVQ
;
UST     LD B,A
        AND 0x03
        JR Z,UST1
        DEC A
        JR Z,MEST
        DEC A
        JR Z,STROK
UST2    XOR A
        LD (AR2),A
        LD A,C
        CP 0x4A
        JR Z,SNC
        CP 0x4B
        JR Z,SPC
        LD HL,ARINT
        PUSH HL
        LD C,0x18
        CP 0x43
        RET Z
        INC C
        CP 0x41
        RET Z
        INC C
        CP 0x42
        RET Z
        LD C,0x08
        CP 0x44
        RET Z
        LD C,0x0C
        CP 0x48
        RET Z
        LD C,0x1F
        CP 0x45
        RET Z
        CP C
        RET Z
        POP HL
        JP TVQ
;
MEST    LD A,C
        SUB 0x20
        RLCA
        RLCA
        AND 0xFC
        LD (TVAD),A
        XOR A
        JR UPR1
;
STROK   LD A,C
        SUB 0x20
        LD (TVAD+1),A
        LD A,0xF1
        JR UPR1
;
GTV     PUSH BC
        PUSH DE
        PUSH HL ;D
        PUSH AF
        LD A,(SZ)
        JR SNSZ
;
SNC     LD A,(TVAD+1)                       ; стер.ниж.курс
        INC A
SNSZ    CP 0x19
        JP NC,TVQ
        LD L,A
        CALL MULT10
        LD C,A
        LD A,(EKRAN)
        LD H,A
        LD A,(EKRED)
        LD B,A
        DEC H
SNC2    INC H
        LD L,C
        LD A,(INVERS)
SNC3    LD (HL),A
        INC L
        JR NZ,SNC3
        DJNZ SNC2
        JP TVQ
;
SPC     LD HL,(TVAD)                        ; стер.прав.курс.
        PUSH HL
        LD B,L
        LD C,20H
SPC1    CALL TV2
        LD A,04H
        ADD B
        LD B,A
        JP NZ,SPC1
        POP HL
        JP V3

; ----------------------------------------------
; Звук
; ----------------------------------------------
BEEP    PUSH BC
        PUSH AF
        IN A,PORT_0A_MEM_CFG
        PUSH AF
        OR 0x20                             ; 2.5МГц
        OUT PORT_0A_MEM_CFG,A
        LD C,0x20
BP1     LD A,(CBEEP)
        OUT PORT_FF_SPEAKER,A
BP2     DEC A
        JR NZ,BP2
        DEC C
        JR NZ,BP1
        POP AF
        OUT PORT_0A_MEM_CFG,A
        POP AF
        POP BC
        RET
;
RAMEND  
        DEPHASE
;
        ASSERT RAMEND>0xF800 AND RAMEND<0xFFF8,  Переполнение памяти F800H

;
; Выровнять гекцимальный параграф ОЗУ - XXX0

MNEND   EQU $
        DS -(MNEND & 0x0F)+0x10

; ----------------------------------------------
; Упакованный знакогенератор TV
; ----------------------------------------------
NAZG    DB 0C0H,84H,0,4,4AH,60H,2AH,1FH
        DB 0AH,1FH,2AH,11H,0EH,51H,0EH,11H
        DB 18H,19H,2,4,8,13H,3,4
        DB 2AH,0CH,15H,12H,0DH,26H,2,4
        DB 40H,2,4,48H,4,2,8,4
        DB 42H,4,8,0,4,15H,0EH,15H
        DB 4,0,0,24H,1FH,24H,0,40H
        DB 2CH,4,8,40H,1FH,40H,80H,2CH
        DB 0,1,2,4,8,10H,0,0EH
        DB 11H,13H,15H,19H,11H,0EH,4,0CH
        DB 64H,0EH,0EH,11H,1,6,8,10H
        DB 1FH,1FH,1,2,6,1,11H,0EH
        DB 2,6,0AH,12H,1FH,22H,1FH,10H
        DB 1EH,21H,11H,0EH,7,8,10H,1EH
        DB 31H,0EH,1FH,1,2,4,48H,0EH
        DB 31H,0EH,31H,0EH,0EH,31H,0FH,1
        DB 2,1CH,0,2CH,20H,2CH,2CH,0
        DB 2CH,4,8,2,4,8,10H,8
        DB 4,2,20H,1FH,0,1FH,20H,8
        DB 4,2,1,2,4,8,0EH,11H
        DB 1,2,4,0,4,0EH,11H,13H
        DB 15H,17H,10H,0EH,4,0AH,31H,1FH
        DB 31H,1EH,31H,1EH,31H,1EH,0EH,11H
        DB 50H,11H,0EH,1EH,89H,1EH,1FH,30H
        DB 1EH,30H,1FH,1FH,30H,1EH,50H,0EH
        DB 11H,30H,13H,11H,0FH,51H,1FH,51H
        DB 0EH,84H,0EH,61H,31H,0EH,11H,12H
        DB 14H,18H,14H,12H,11H,90H,11H,1FH
        DB 11H,1BH,35H,51H,31H,19H,15H,13H
        DB 31H,0EH,91H,0EH,1EH,31H,1EH,50H
        DB 0EH,51H,15H,12H,0DH,1EH,31H,1EH
        DB 14H,12H,11H,0EH,11H,10H,0EH,1
        DB 11H,0EH,1FH,0A4H,0B1H,0EH,51H,2AH
        DB 24H,51H,55H,0AH,31H,0AH,4,0AH
        DB 31H,31H,0AH,64H,1FH,1,2,0EH
        DB 8,10H,1FH,0EH,88H,0EH,0,10H
        DB 8,4,2,1,0,0EH,82H,0EH
        DB 0EH,11H,80H,0A0H,1FH,12H,35H,1DH
        DB 35H,12H,4,0AH,31H,1FH,31H,1FH
        DB 30H,1EH,31H,1EH,92H,1FH,1,6
        DB 6AH,1FH,11H,1FH,30H,1EH,30H,1FH
        DB 4,1FH,35H,1FH,24H,1FH,11H,90H
        DB 31H,0AH,4,0AH,31H,31H,13H,15H
        DB 19H,31H,15H,11H,13H,15H,19H,31H
        DB 11H,12H,14H,18H,14H,12H,11H,7
        DB 89H,19H,11H,1BH,35H,51H,51H,1FH
        DB 51H,0EH,91H,0EH,1FH,0B1H,0FH,31H
        DB 0FH,5,9,11H,1EH,31H,1EH,50H
        DB 0EH,11H,50H,11H,0EH,1FH,0A4H,51H
        DB 0AH,4,8,10H,11H,35H,0EH,35H
        DB 11H,1EH,31H,1EH,31H,1EH,50H,1EH
        DB 31H,1EH,51H,19H,35H,19H,0EH,11H
        DB 1,6,1,11H,0EH,11H,95H,1FH
        DB 0EH,11H,1,7,1,11H,0EH,95H
        DB 1FH,1,51H,1FH,41H,52H
ZGEND   EQU $
;
        ASSERT ZGEND < ORROM, Наползание на ORDOS в ROM2

;
        DS ORROM-ZGEND,0xFF
;
        END     
