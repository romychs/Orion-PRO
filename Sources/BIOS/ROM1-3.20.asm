; ==============================================
;               " O r i o n - P R O "      
; ==============================================
;                     ROM1-BIOS          
;                             
;   0.36    03 июня     1994  
;   0.90    14 февраля  1996  
;   3.10    14 мая      1996  
;   1.00    05 июня     1996  
;   2.00    24 декабря  1997  
;   2.10    17 апреля   2000  
;   3.20    ???               
; ----------------------------------------------
;   Дизассемблировано и адаптировно для SjasmpPlus 
;   Romych-ем  в  апреле 2021
; ==============================================

            DEVICE NOSLOT64K

            include "ports.inc"                 ; Порты Ориона
            include "base.inc"                  ; Базовые константы

            ORG 0x0000

CLD_START   JP PSK1
PRO         JP INIT_PRO
CTLKBD      JP CTRLKB
KBPRO       JP KBRD
STPRO       JP STTS
INPRO       JP INKEY2
NUMKEY      JP NUMINK
SYSCTR      JP SYSCTL
MSCTR       JP MSCTL

            BLOCK 3,0x00                        ; filler

            IF RAMSEG = 1FH                     ; Cимволы номера сегмента
                db '1F'
            ELSE
                db '03'
            ENDIF

ROM_ID      DB 'ROM1-BIOS V',VERS1,'.',VERS2,VERS3,' (C) "ORIONSOFT" '

; ==============================================
; Описание рабочих ячеек
; ==============================================
;
; Ячейки с заранее заданными значениями
; При холодном старте, эти ячейки переносятся в ОЗУ
;
JOBORG      EQU CELLS           ; Адрес размещения ячеек в ОЗУ
BEGJOB      EQU $               ; Адрес размещения ячеек в ПЗУ
;
            DISP JOBORG

; ----------------------------------------------
; Постоянно используемые ячейки 
; ----------------------------------------------

; ----------------------------------------------
; Ячейки MOUSE
; ----------------------------------------------
MSMODE      DB 03H              ; 09H - режим отображения мыши
MSPADR      DW ARROW            ; адрес шаблона мыши
MSPSEG      DB RAMSEG           ; номер сегмента с шаблоном мыши
MSPH        DB 8                ; высота шаблона мыши
MSPL        DB 5                ; ширина шаблона мыши
MSPD        DB 0                ; смещение шаблона мыши
MSSTY       DB 2                ; шаг мыши по Y
MSSTX       DB 2                ; шаг мыши по X
MSBSEG      DB 1BH,1CH,1DH,1EH  ; Номера сегментов буфера для мыши
MSBADR      DB low(0x4000-0x50) ; Адрес начала буфера в сегментах

; Шаблон стрелки мыши
ARROW       DB 80H,0C0H,0E0H,0F0H,0F8H,0F0H,0B0H,30H

; ----------------------------------------------
; Ячейки драйвера клавиатуры
; ----------------------------------------------
KBMODE      DB 00H

;бит  7   - признак старого режима MC7007
;биты 0,1 - кодировка (00-ALT)
KBFLAG      DB 0                                    ; Флаг клавиатуры (CAPS LOCK = ON)
;

KBSYM       DB 0                                    ; Последний символ KBRD
BAZA        DW BFNUM                                ; Адрес буфера NUMINK
CURTM       DW 200H                                 ; Константа мигания курсора
IKEYTM      DB 40H                                  ; Константа антидребезга
KBAUTO      DW 150H                                 ; Константа автоповтора
STAUTO      DW 1                                    ; Счетчик автоповтора
OLDALF      DB 0FH                                  ; Включение АЛФ режима (^O)
OLDGRF      DB 0EH                                  ; Включение графики (^N)
;                   
CURCOD      DB 08H,18H                              ; Коды клавиш курсора
            DB 19H,1AH
CURCTR      DB 08H,18H                              ; Коды клавиш курсора + CTRL
            DB 19H,1AH
CURSFT      DB 08H,18H                              ; Коды клавиш курсора + SHIFT
            DB 19H,1AH
;                   
KBHEAD      DW KBDBUF                               ; Указабель головы буфера KBRD
KBTAIL      DW KBDBUF                               ; Указатель хвоста буфера KBRD
;
FUNTAB      DW DUMMY                                ; Адрес таблицы функциональных клавиш
FUNSEG      DB RAMSEG                               ; Номер сегмента ОЗУ (блок "EXT")
;
CTRTAB      DW DUMMY                                ;-"- при надатии УПР
CTRSEG      DB RAMSEG
;
SFTTAB      DW DUMMY                                ;-"- при нажатии SHIFT
SFTSEG      DB RAMSEG
;
            ENT

ENDJOB

; ----------------------------------------------
; Буфер для NUM_INKEY (10 байт) 
; ----------------------------------------------
NUMLEN      EQU 10                                  ; длина буфера NUMKEY
BFNUM       EQU SFTSEG+1                            ; начало буфера NUMKEY
BFNUME      EQU BFNUM+NUMLEN-1                      ; конец буфера NUMKEY

; ----------------------------------------------
; Буфер KBRD 
; ----------------------------------------------
BUFLEN      EQU 16                                  ; длина буфера KBRD
KBDBUF      EQU BFNUME+1                            ; начало буфера KBRD
KBDBFE      EQU KBDBUF+BUFLEN-1                     ; конец буфера KBRD

; ----------------------------------------------
; Временные ячейки монитора 
; (нужны только при вводе команды монитора)
; ----------------------------------------------
INBF        EQU KBDBFE+1                            ; буфер ввода команд
INBF1       EQU INBF+1
INBFE       EQU INBF+0x10                           ; адрес конца буфера команд + 1
OPER1       EQU INBFE                               ; 1-операнд
OPER2       EQU OPER1+2                             ; 2-операнд
PORTFA      EQU OPER2+2                             ; дубль порта 0xFA (Номер экрана и ширина)

; ----------------------------------------------
; Временные ячейки драйвера мыши
; ----------------------------------------------
MSX         EQU KBDBFE+1
MSY         EQU MSX+2
DMX         EQU MSY+2
NDMX        EQU DMX+2
DMY         EQU NDMX+2
NDMY        EQU DMY+2
MSJ1        EQU NDMY+2
MSJ2        EQU MSJ1+2
MSJ3        EQU MSJ2+2
MSJ4        EQU MSJ3+2
MSJ5        EQU MSJ4+2
MSJ6        EQU MSJ5+2
MSJ7        EQU MSJ6+2
MSJ8        EQU MSJ7+2
ENDMS       EQU MSJ8+2
;
;
TMPEND      EQU ENDMS                               ; конец временных ячеек
;
            ASSERT (TMPEND>100H) && (TMPEND<=RAMTOP), Переплнение памяти рабочих ячеек

; ----------------------------------------------
; Конец описания рабочих ячеек
; ----------------------------------------------


; ----------------------------------------------
;Таблица адресов подпрограмм обработки прерываний
; ----------------------------------------------
ISRTAB      DW DEFESR, DEFESR, DEFESR, DEFESR, DEFESR, DEFESR, DEFESR, DEFESR

; ----------------------------------------------
; Проверка наличия сегмента в ROM2
; Вход:
;  С - номер сегмента
;  HL - адрес
; Выход:
;  "Z" - сегмента нет, "NZ" - сегмент есть
;  (для сегмента № 2: HL >= 2040H)
; ----------------------------------------------
TSTR2
            LD B,C
TSTR21
            DEC B
            RET M
            IN A,(PORT_0A_MEM_CFG)
            SET 3,A
            OUT (PORT_0A_MEM_CFG),A
            LD A,B
            OUT (PORT_09_ROM2_SEG),A
            LD E,(HL)
            INC HL
            LD D,(HL)
            LD A,C
            OUT (PORT_09_ROM2_SEG),A
            LD A,(HL)
            DEC HL
            PUSH HL
            LD L,(HL)
            LD H,A
            EX DE,HL
            OR A
            SBC HL,DE
            POP HL
            RET Z
            LD A,D
            AND E
            INC A
            RET Z
            JR TSTR21

; ----------------------------------------------
; Процедура инициализации ПРО
; ----------------------------------------------
INIT0       DI
            LD A,0x50                                       ; 0101_0000  вкл окно ROM1 и откл переклю ОЗУ F000-FFFF
            OUT (PORT_0A_MEM_CFG),A

INIT1       IN A,(PORT_00_DIPSW)
            BIT SW_KBD_RK86,A
            LD A,0x8A                                       ; РК-86
            JR NZ,MNT1
            LD A,0x98                                       ; МС7007

MNT1        OUT (PORT_1B_CTL),A                             ; Инициализация ВВ55 клавиатуры
            CALL RES0                                       ; Инициализация рабочих ячеек
            LD HL,MMMPB                                     ; Инициализация модуля EXT (Перенос его в ОЗУ)
            LD DE,0xF800
            LD BC,MMMPE-MMMPB
            LDIR
            RET

; ----------------------------------------------
; Инициализация режима ПРО (0003H)
; На входе:
;  A=0 - с гашением видео, A=1 - без гашения
; На выходе:
;  "Z" - нет "TV-PRO"
;  A - номер версии "TV-PRO"
; ----------------------------------------------
INIT_PRO    PUSH AF
            CALL INIT0
            POP AF

; ----------------------------------------------
; Программная инициализация TV-PRO
; На входе:
;  A=0 - с гашением видео, A=1 - без гашения
; На выходе:
;  "Z" - net ROM2 s "TV-PRO"
;   A-nomer wersii "TV-PRO"
; ----------------------------------------------
INITV       LD E,A
            IN A,(PORT_0A_MEM_CFG)          ; Чтение и сохранение конфигурации памяти
            PUSH AF
            XOR A
            LD (VERSTV),A                   ; Обнуление версии
            LD HL,0x2008                    ; Адрес в ROM2
            LD C,R2SEG
            PUSH DE
            CALL TSTR2                      ; Проверка наличия сегмента TVPRO
            POP DE
            JR Z,TVNO                       ; Переход, если нет драйвера
            LD A,E
            CALL 0x2000                     ; Выполнение холодной инициализации
            ;
            LD (VERSTV),A                   ; Сохранить номер версии

            ; Подмена адресов векторов
            LD HL,TVSCR+1
            CALL DTOH                       ; Вектор управления экранами
            LD HL,TVOUT+1
            CALL DTOH                       ; Вектор вывода символа/курсора
            LD HL,TVGRF+1
            CALL DTOH                       ; Вектор графических функций
            LD HL,TVSERV+1
            CALL DTOH                       ; Вектор сервисных функций

TVNO        POP AF
            OUT (PORT_0A_MEM_CFG),A         ; Восстановление конфигурации памяти
            LD A,(VERSTV)
            OR A
            RET

; ----------------------------------------------
; Подпрограмма записи (DE),(DE+1) -> (HL),(HL+1)
; ----------------------------------------------
DTOH        LD A,(DE)
            LD (HL),A
            INC DE
            INC HL
            LD A,(DE)
            LD (HL),A
            INC DE
            RET

; ----------------------------------------------
;Настройка схемы управления палитрами
; ----------------------------------------------
INITPAL     LD HL,PALTAB                    
            LD BC,0x10e0                    ; e0-e2 - порты палитры
            OTIR
            LD BC,0x10e1
            OTIR
            LD BC,0x10e2
            OTIR
            RET

; ----------------------------------------------
;Палитра, по 16 байт на канал цвета
; ----------------------------------------------
PALTAB
            ; канал красного
            db 0h,14h,20h,30h,4Ch,5Fh,6Ch,7Fh
            db 80h,90h,0A0h,0B0h,0CCh,0DFh,0ECh,0FFh
            ; канал зеленого
            db 0h,14h,20h,30h,40h,50h,60h,70h
            db 8Ch,9Fh,0ACh,0BFh,0CCh,0DFh,0ECh,0FFh
            ; канал синего
            db 0h,14h,2Ch,3Fh,40h,50h,6Ch,7Fh
            db 80h,90h,0ACh,0BFh,0C0h,0D0h,0ECh,0FFh

; ----------------------------------------------
; Процедура холодного старта системы
; ----------------------------------------------
PSK1        LD HL,0xA000
            ; Задержка, можно заменить тестом CPU
PSK10       DEC HL
            LD A,H
            OR L
            JR NZ,PSK10

            ; Программирование портов ВВ55
            LD A,0x98
            OUT (PORT_03_CTL),A             ; DIP SW, PRINTER
            LD A,0x92
            OUT (PORT_1D_MCARD_CTL),A       ; Мультикарта, мышь
            LD A,0x16
            OUT (PORT_3B_VI53_CTL),A        ; Таймеры ВИ53
            LD A,0x56
            OUT (PORT_3B_VI53_CTL),A
            LD A,0x96
            OUT (PORT_3B_VI53_CTL),A
            LD A,0x80
            OUT (PORT_07_CTL),A             ; Банки RAM
            OUT (PORT_0B_CTL),A             ; Страницы RAM

            ; Подготовка диспетчера памяти
PSK11       LD A,0x50
                ;D7=0 - MEM-PORT - откл.
                ;D6=1 - F/ОЗУ RD/WR
                ;если D7=1, то D6=X
                ;D5=0 - F 5/10 MHz
                ;D4=1 - ROM1=вкл.
                ;D3=0 - ROM2=выкл.
                ;D0,1,2 = 0 - все окна закрыты
            OUT (PORT_0A_MEM_CFG),A
            CALL ENABLE_ROM1_OFF            ; Снять запрет на отключение ROM1
            OUT (PORT_08_RAM_PG),A
            OUT (REG_F9_RAM_PG),A
            OUT (REG_FA_SCRN_CFG),A
            LD (MSJ5),A
            LD A,0x1f
            OUT (REG_FC_COLOR),A
            LD A,0xf
            OUT (PORT_F8_VMODE),A
            LD HL,COLDST
            LD A,(HL)
            CP 0x5A                         ; Уже было включено питание?
            JR Z,MONIT                      ; да, в монитор
            LD (HL),0x5A                    ; нет, пометим, что уже было
            DEC HL
            LD (HL),0x0
            DEC HL
            LD (HL),0x0

; ----------------------------------------------
; Теплый старт ROM1
; ----------------------------------------------
MONIT
            LD SP,STACK
            CALL INIT1
            CALL INITPAL
            IN A,(0x0)
            BIT 0x5,A
            JP Z,SYSMON
            CALL NUMINK
            AND A
            JR Z,MNT2
            DEC A
            JP NZ,SYSMON
MNT2
            IN A,(0x0)
            BIT 0x7,A
            JR NZ,MON2

MNT3        LD A,1                          ; без гашения видео
            CALL INITV
            JP Z,HALT_                      ; нет TV-PRO
            JP MON_128_F800

; ----------------------------------------------
; Загрузка монитора из ROM2 в режиме O-128
; ----------------------------------------------
MON128
            LD BC,500
            LD DE,0x0
            CALL SOUND                      ; пауза 500мс
MON2        IN A,(PORT_0A_MEM_CFG)
            SET 3,A                         ; вкл ROM2
            OUT (PORT_0A_MEM_CFG),A
            XOR A
            OUT (PORT_09_ROM2_SEG),A
            LD HL,(0x2000)                  ; Начальная ячейка ROM2
            LD A,L
            CP H
            JP NZ,0x2000

; -------------
; Нет ROM-2
; -------------
HALT_
            CALL CLRSCR
            LD A,0xe0
            OUT (REG_FC_COLOR),A             ; Светлый экран
            LD A,0xf
            OUT (PORT_F8_VMODE),A            ; Певдоцветной
            CALL SNDP
            CALL SNDP
            CALL SNDP
            HALT

; ----------------------------------------------
; Очистка экрана
; ----------------------------------------------
CLRSCR
            LD BC,0x3000
            LD HL,SCR_C000
            LD DE,SCR_C000+1
            LD (HL),0
            LDIR
            RET

; ----------------------------------------------
; Звук с паузой
; ----------------------------------------------
SNDP
            LD BC,0xc8
            LD DE,0x400
            CALL SOUND
            LD DE,0x0
            JP SOUND

; ----------------------------------------------
; Внутренний системный монитор
; ----------------------------------------------
SYSMON
            LD SP,STACK
            XOR A
            CALL INITV
            JP Z,HALT_
            XOR A
            OUT (PORT_08_RAM_PG),A
            OUT (REG_FA_SCRN_CFG),A
            LD A,0x4f
            OUT (REG_FC_COLOR),A
            LD A,0xf
            OUT (PORT_F8_VMODE),A
            CALL RES0
MAIN
            LD SP,STACK
            CALL BIGFRM
            LD HL,TIT1
            CALL MSGXX
            LD A,0x5
            LD BC,0x63
            LD DE,0x92
            CALL TVGRF
            LD A,0xd
            LD BC,0x9f
            LD DE,0xf3
            CALL TVGRF
            LD IX,MENU1
            LD HL,POS1
            CALL MENU
            JP C,MONIT
            JR MAIN

;--------------
; Монитор
;--------------
MON_UR
            LD A,0x1f
            OUT (REG_FC_COLOR),A
            LD A,0xf
            OUT (PORT_F8_VMODE),A
            LD HL,TBTYT
            CALL MSGXX
            CALL LINE
            LD HL,TBCOM
            CALL MSGXX
            CALL LINE

UR          LD SP,STACK
            LD HL,TAB3
            CALL MSGXX
            LD HL,UR
            PUSH HL
            CALL CDIN
            CALL CVRT
            LD A,(MSX)
            OR A
            JP M,ERR
            CP BEGJOB
            JR C,UR1
            AND 0xdf

UR1         CP 'M'
            JP Z,MEMR
            CP 'D'
            JP Z,DUMP
            CP 'F'
            JP Z,FILL
            CP 'T'
            JP Z,TRANS
            CP 'C'
            JP Z,COMP
            CP 'I'
            JP Z,INPUT
            CP 'O'
            JP Z,OUTPUT
            CP 'V'
            JP Z,VIDEO
            CP 'W'
            JP Z,WIN
            CP 'X'
            JP Z,XWIN
            CP '2'
            JP Z,SPEED2
            CP '8'
            JP Z,SPEED5
            CP 'G'
            JP NZ,ERR
            JP HL

CDIN        LD DE,INBF
            LD B,0x0
CD1         CALL KBRD
            CP 0x3
            JP Z,MONIT
            CP 0x1b
            JP Z,MON_UR
            CP 0x7f
            JR Z,CD02
            CP 0x8
            JR NZ,CD2
CD02        INC B
            DEC B
            JR Z,CD1
CD5         DEC DE
            DEC B
            LD A,0x8
            CALL TVA
            CALL SPC
            LD A,0x8
            CALL TVA
            JR CD1
CD2         CP 0xd
            JR Z,CD6
            CP 0x20
            JR C,CD1
CD6         LD (DE),A
            INC B
            CP 0xd
            RET Z
            CALL TVA
            INC DE
            LD A,INBFE-INBF-1
            CP B
            JR NC,CD1
            JR CD5
CVRT        LD DE,INBF1
            LD HL,0x0
            LD (OPER2),HL
            CALL CVRT2
            LD (OPER1),HL
            RET C
            CALL CVRT2
            LD (OPER2),HL
            JR C,CVRT1
            CALL CVRT2
            LD B,H
            LD C,L
            LD HL,(OPER2)
CVRT1       EX DE,HL
            LD HL,(OPER1)
            RET
CVRT2       LD HL,0x0
            LD B,L
            LD C,L
CVR         ADD HL,BC
CVR1        LD A,(DE)
            INC DE
            CP 0x20
            JR Z,CVR1
            CP 0xd
            JR Z,CVR3
            CP 0x2c
            RET Z
            CP BEGJOB
            JR C,CVR4
            AND 0xdf
CVR4        SUB 0x30
            JP M,ERR
            CP 0xa
            JP M,CVR2
            CP 0x11
            JP M,ERR
            CP 0x17
            JP P,ERR
            SUB 0x7
CVR2        LD C,A
            ADD HL,HL
            ADD HL,HL
            ADD HL,HL
            ADD HL,HL
            JR NC,CVR
ERR         LD A,'?'
            CALL TVA
            JP UR
CVR3        SCF
            RET

AS          LD A,(HL)
ASC         PUSH AF
            RRCA
            RRCA
            RRCA
            RRCA
            CALL AS1
            POP AF
AS1         AND 0xf
            CP 0xa
            JP M,AS2
            ADD A,0x7
AS2         ADD A,0x30
            JP TVA
MCT         CALL HDLN
ADR         LD A,H
            CALL ASC
ADR1        LD A,L
ADR2        CALL ASC
SPC         LD A,0x20
            JP TVA
HDLN        LD A,0x0D
            CALL TVA
            LD A,0x0A
            JP TVA
DPCMP       LD A,H
            CP D
            RET NZ
            LD A,L
            CP E
            RET

LINE        LD BC,0x3EC4
            CALL SPC
LINE1       CALL TVSYM
            DJNZ LINE1
            RET

M1          INC HL
MEMR        CALL MCT
            CALL AS
            CALL SPC
            CALL CDIN
            LD DE,INBF
            LD A,(DE)
            CP 0x0D
            JR Z,M1
            PUSH HL
            CALL CVRT2
            EX DE,HL
            POP HL
            LD (HL),E
            JR M1
DUMP        LD HL,(OPER1)
            LD L,0x0
DP1         LD B,0xff
            CALL ABC
D3          CALL MCT
            CALL SPC
            PUSH HL
            LD B,0x2
D1          LD A,(OPER2)
            CALL DISK
            CALL ASC
            INC HL
            DJNZ D5
            CALL SPC
            LD B,0x2
D5          LD A,L
            AND 0xf
            JR NZ,D1
            POP HL
            CALL SPC
L1          LD A,(OPER2)
            CALL DISK
            CP 0x20
            JR C,L13
            CP 0xb0
            JR C,L12
            CP 0xe0
            JR C,L13
            CP 0xf2
            JR C,L12
L13         LD A,'.'
L12         CALL TVA
            INC HL
            LD A,L
            AND 0xf
            JR NZ,L1
            LD A,L
            AND A
            JR NZ,D3
            CALL HDLN
            CALL ABC0
L9          CALL KBRD
            CP 0x1b
            JP Z,MON_UR
            CP 0xc
            JR Z,DUMP
            CP 0x42
            JR Z,DUMP
            CP 0x62
            JR Z,DUMP
            CP 0x19
            JR Z,L7
            OR A
            JR NZ,L8
L7          DEC H
            DEC H
            JR DP1
L8          CP 0x1A
            JR Z,DP1
            CP 0x2
            JR Z,DP1
            JR L9
;
ABCC0       DB -1BH,-'6',-' ',-' ',-' ',-' ',-' ',-' ',-'E',-'S'
            DB -'C',-' ',-'-',-' ',-'Q',-'u',-'i',-'t',-' '
            DB -' ',-' ',-' ',-' ',-' ',-' ',-' ',-' ',-' '
            DB -' ',-' ',-' ',-' ',-' ',-' ',-' ',-' ',-' ',-' '
            DB -'(',-'B',-')',-'e',-'g',-'i',-'n',-' ',-' '
            DB -' ',-' ',-'P',-'g',-'-',-0F8H,-' ',-' ',-' '
            DB -' ',-'P',-'g',-'-',-0F9H,-' ',-' ',-' '
            DB -' ',-1BH,-'7',0
;
ABC0
            PUSH HL
            LD HL,ABCC0
            CALL MSGXX
            POP HL
            RET
;
ABCC        DB -1BH,-59H,-27H,-20H,-1BH,-'6',-20H,-'P',-'=',0
;
ABC         PUSH HL
            LD HL,ABCC
            CALL MSGXX
            POP HL
            LD A,(OPER2)
            LD C,A
            AND 0xf0
            LD A,C
            JR NZ,AB6
            OR 0x30
AB6
            CALL TVA
            CALL SPC
            CALL SPC
            CALL SPC
            LD C,0x0
AB4
            LD B,0x2
AB2
            LD A,C
            CALL AS1
            CALL SPC
            INC C
            DJNZ AB2
            CALL SPC
            LD A,C
            CP 0x10
            JR NZ,AB4
AB3
            LD A,C
            CP ' '
            JR Z,AB8
            CALL AS1
            INC C
            JR AB3
AB7
            CALL SPC
AB8
            PUSH HL
            LD HL,INVOF
            CALL MSGXX
            POP HL
            RET
DISK
            AND 0xf
            CALL RRAM
            LD A,C
            RET
INPUT
            CALL SPC
            LD C,L
            IN A,(C)
HEXBIN
            LD C,A
            CALL ASC
            LD A,ENDJOB-BEGJOB
            CALL TVA
            LD A,C
            LD B,0x8
BIN0
            LD C,A
            AND 0x80
            LD A,0x30
            JR Z,BIN1
            LD A,0x31
BIN1        CALL TVA
            LD A,B
            CP 0x5
            JR NZ,BIN2
            LD A,0x5f
            CALL TVA
BIN2        LD A,C
            RLCA
            DJNZ BIN0
            RET

OUTPUT      LD C,L
            OUT (C),E
            RET

WIN         LD A,L
            AND 0x3
            LD L,A
            LD C,A
            LD A,0x1
            INC L
WN1         DEC L
            JR Z,WN2
            RLCA
            JR WN1
WN2         LD L,A
            LD A,E
            CP 0xff
            JR NZ,WN20
            LD A,L
            CPL
            LD L,A
            IN A,(PORT_0A_MEM_CFG)
            AND L
            JR WN7
WN20        INC C
            DEC C
            JR NZ,WN3
            OUT (PORT_04_RAM0P),A
            JR WN6
WN3         DEC C
            JR NZ,WN4
            OUT (PORT_05_RAM1P),A
            JR WN6
WN4         DEC C
            JR NZ,WN5
            OUT (PORT_06_RAM2P),A
            JR WN6
WN5         OUT (PORT_09_ROM2_SEG),A
WN6         IN A,(PORT_0A_MEM_CFG)
            OR L
WN7         OUT (PORT_0A_MEM_CFG),A
            RET

XWIN        CALL HDLN
            LD E,0xff
            LD C,0x4
SG2         LD B,0x8
            LD A,E
SG1         ADD A,0x4
            PUSH AF
            CALL ADR2
            POP AF
            DJNZ SG1
            CALL HDLN
            DEC E
            DEC C
            JR NZ,SG2
            CALL HDLN
            LD A,0x30
            CALL TVA
            LD A,0x33
            CALL TVA
            CALL SPC
            IN A,(PORT_09_ROM2_SEG)
            CALL XW5
            LD L,0x2
            CALL ADR1
            IN A,(PORT_06_RAM2P)
            CALL XW5
            DEC L
            CALL ADR1
            IN A,(PORT_05_RAM1P)
            CALL XW5
            DEC L
            CALL ADR1
            IN A,(PORT_04_RAM0P)
            CALL XW5
            LD A,0x44
            CALL TVA
            LD A,0x50
            CALL TVA
            CALL SPC
            IN A,(PORT_0A_MEM_CFG)
XW5         CALL HEXBIN
            JP HDLN

FILL        LD (HL),C
            CALL DPCMP
            RET Z
            INC HL
            JR FILL

VIDEO       LD A,0x80
            LD HL,PORTFA
            XOR (HL)
            LD (HL),A
            OUT (REG_FA_SCRN_CFG),A
            RET

COMP        CALL DPCMP
            RET Z
            LD A,(BC)
            CP (HL)
            JR NZ,COMP2
COMP1       INC HL
            INC BC
            JR COMP
COMP2       CALL HDLN
            CALL ADR
            CALL SPC
            CALL AS
            CALL SPC
            LD A,(BC)
            CALL ASC
COMP3       CALL INKEY
            CP 0x1b
            RET Z
            INC A
            JR NZ,COMP3
            JR COMP1

TRANS       LD A,(HL)
            LD (BC),A
            LD A,H
            CP D
            JR NZ,TRS1
            LD A,L
            CP E
            RET Z
TRS1        INC HL
            INC BC
            JR TRANS

SPEED2      IN A,(PORT_0A_MEM_CFG)
            OR 0x20
            OUT (PORT_0A_MEM_CFG),A
            RET

SPEED5      IN A,(PORT_0A_MEM_CFG)
            AND 0xdf
            OUT (PORT_0A_MEM_CFG),A
            RET

; ---------------------------------------------
; Управление системой
;  A=0 - инициализация рабочих ячеек "ROM1-BIOS";
;  A=1 - инициализация портов диспетчера памяти (отключение всех окон);
;  A=2 - освобождение оверлейной области ОЗУ, используемой драйвером "TV-PRO";
;  A=З - проверка занятости оверлейной области ОЗУ, используемой драйвером "TV-PRO"
; ---------------------------------------------
SYSCTL      LD A,IXL                       ; db 0DDh LD A,L
            OR A
            JR NZ,SYS1

; Процедура переноса блока исходного состояния в ОЗУ
RES0        DI
            LD HL,BEGJOB
            LD DE,JOBORG
            LD BC,ENDJOB-BEGJOB
            LDIR
            LD HL,ISRTAB
            LD A,0xf7
            LD I,A
            LD D,A
            LD E,0x0
            LD BC,0x10
            LDIR
            IM 2
            RET

SYS1        DEC A
            JR NZ,SYS2

;Отключение всех окон
RES1        XOR A
            OUT (PORT_04_RAM0P),A
            OUT (PORT_05_RAM1P),A
            OUT (PORT_06_RAM2P),A
            OUT (PORT_09_ROM2_SEG),A
            IN A,(PORT_0A_MEM_CFG)
            AND 0xF0
            OUT (PORT_0A_MEM_CFG),A
            RET

SYS2        DEC A
            JR NZ,SYS3

; Освобождение оверлейной части драйвера TV-PRO
FREOVR
            LD IX,0x2003
            JR SUBR2

SYS3        DEC A
            RET NZ

; Проверка оверлейой области драйвера TV-PRO
TSTOVR      LD IX,0x2006

; Вызов подпрограммы из ROM2
; IX - Адрес в ROM2
SUBR2       PUSH IY
            IN A,(PORT_09_ROM2_SEG)
            LD IYL,A                        ; db 0FDh, LD L,A
            LD A,R2SEG
            OUT (PORT_09_ROM2_SEG),A
            IN A,(PORT_0A_MEM_CFG)
            SET ROM2_WND,A
            OUT (PORT_0A_MEM_CFG),A
            CALL PCIX
            PUSH AF
            LD A,IYL                        ; db 0FDh, LD A,L
            OUT (PORT_09_ROM2_SEG),A
            POP AF
            POP IY
            RET

PCIX        JP IX




; ---------------------------------------------
; Подключение модуля тестирования
; ---------------------------------------------
            include "tst.asm"               
            
;
;
TYTBS1      DB -1FH,-1BH,-59H,-21H,-22H
            DB -'(',-'C',-')',-' ',-'1',-'9',-'9',-'3',-'-',-'1'
            DB -'9',-'9',-'7',-' ',-'O',-'r',-'i',-'o',-'n'
            DB -'s',-'o',-'f',-'t',-' ',-'C',-'o',-'.'
            DB -1BH,-59H,-21H,-4FH
            DB -'O',-'r',-'i',-'o',-'n',-'-',-'P',-'r',-'o'
            DB -' ',-'V',-'3',-'.',-'1',-'0'
            DB -0DH,-0AH,0
;
TBTYT       DB -1FH,-0AH,-0AH
            DB -' ',-'S',-'y',-'s',-'t',-'e',-'m',-' ',-'M'
            DB -'O',-'N',-'I',-'T',-'O',-'R'
            DB -' ',-' ',-'V'
            DB -VERS1,-'.',-VERS2,-VERS3,-0DH,-0AH,0
;
TBCOM       DB -0DH,-0AH
            DB -' ',-'-',-' ',-'M',-' ',-'D',-' ',-'F'
            DB -' ',-'T',-' ',-'C',-' ',-'-',-' ',-'I',-' '
            DB -'O',-' ',-'V',-' ',-'W',-' ',-'X',-' ',-'2'
            DB -' ',-'8',-' ',-'-',-' ',-'G',-' ',-'-'
            DB -0DH,-0AH,0
;
TAB3        DB -0DH,-0AH,-0AH
            DB -'=',-'>',-7,0

; ---------------------------------------------
; Управление клавиатурой
; LX - Номер функции
; ---------------------------------------------
CTRLKB      LD A,IXL                        ; DB 0DDh, LD A,LX
            SUB 19
            JP NC,KBC19
            ADD A,19
            JR NZ,KBC1

; ---------------------------------------------
; Установка режима клавиатуры
; E - режим, D - байт флагов
; ---------------------------------------------
SETKBM      PUSH HL
            LD HL,(BAZA)
            XOR A
            LD (HL),A
            POP HL
            LD (KBMODE),DE
            RET
KBC1        DEC A
            JR NZ,KBC2

; Получение режима клавиатуры
;  A  keys_pressed
;  C  last_key
;  HL buff_numkey
;  E  режим
;  D  флаги
GETKBM      LD HL,(BAZA)
            LD A,(HL)                                 ; Число нажатых клавиш
            LD E,A
            OR A
            LD D,0x0
            PUSH HL
            ADD HL,DE
            LD C,0xff
            JR Z,GKBM1
            LD C,(HL)
GKBM1       POP HL
            INC HL
            LD DE,(KBMODE)
            RET

KBC2        DEC A
            JR NZ,KBC3

; Установка констант задержки
; HL - автоповтора, DE - мигания курсора
            LD (KBAUTO),HL
            LD (CURTM),DE
            RET

KBC3        DEC A
            JR NZ,KBC4

; Получение констант задержки
; HL - автоповтора, DE - мигания курсора
            LD HL,(KBAUTO)
            LD DE,(CURTM)
            RET

KBC4        DEC A
            JR NZ,KBC5

; Установить коды клавиш управления курсором
; C,B,E,D - коды клавиш
;
            LD (CURCOD),BC
            LD (CURCOD+2),DE
            RET

KBC5        DEC A
            JR NZ,KBC6

; Получить коды клавиш управления курсором
; C,B,E,D - коды клавиш
;
            LD BC,(CURCOD)
            LD DE,(CURCOD+2)
            RET

KBC6        DEC A
            JR NZ,KBC7

; Установить коды клавиш + CTRL
; C,B,E,D - коды клавиш
;
            LD (CURCTR),BC
            LD (CURCTR+2),DE
            RET

KBC7        DEC A
            JR NZ,KBC8

; Получить коды клавиш + CTRL
; C,B,E,D - коды клавиш
            LD BC,(CURCTR)
            LD DE,(CURCTR+2)
            RET

KBC8        DEC A
            JR NZ,KBC9

; Установить коды клавиш + SHIFT
; C,B,E,D - коды клавиш
            LD (CURSFT),BC
            LD (CURSFT+2),DE
            RET

KBC9        DEC A
            JR NZ,KBC10

; Получить коды клавиш + CTRL
; C,B,E,D - коды клавиш
            LD BC,(CURSFT)
            LD DE,(CURSFT+2)
            RET

KBC10       DEC A
            JR NZ,KBC11

; Установка адреса таблицы функциональных клавиш
; HL - адрес, C - номер сегмента ОЗУ
;
            LD (FUNTAB),HL
            LD A,C
            LD (FUNSEG),A
            RET
KBC11
            DEC A
            JR NZ,KBC12

; Получение адреса таблицы функциональных клавиш
; HL - адрес, C - номер сегмента ОЗУ
;
            LD HL,(FUNTAB)
            LD A,(FUNSEG)
            LD C,A
            RET
KBC12
            DEC A
            JR NZ,KBC13

; Установка адреса таблицы клавиш + упр --
; HL - адрес, C - номер сегмента ОЗУ
;
            LD (CTRTAB),HL
            LD A,C
            LD (CTRSEG),A
            RET
KBC13
            DEC A
            JR NZ,KBC14

; Получение адреса таблицы клавиш + упр --
; HL - адрес, C - номер сегмента ОЗУ
            LD HL,(CTRTAB)
            LD A,(CTRSEG)
            LD C,A
            RET
KBC14
            DEC A
            JR NZ,KBC15

; Установка адреса таблицы клавиш + SHIFT
; HL - адрес, C - номер сегмента ОЗУ
;
            LD (SFTTAB),HL
            LD A,C
            LD (SFTSEG),A
            RET
KBC15
            DEC A
            JR NZ,KBC16

; Получение адреса таблицы клавиш + SHIFT
; HL - адрес, C - номер сегмента ОЗУ
            LD HL,(SFTTAB)
            LD A,(SFTSEG)
            LD C,A
            RET
KBC16
            DEC A
            JR NZ,KBC17

; Занесение символа в буфер клавиатуры KBRD
; C - код символа
; "CY" - буфер заполнен
;
WRBUF
            PUSH DE
            PUSH HL
            LD HL,(KBTAIL)
            LD DE,KBDBFE
            LD (HL),C
            CALL CPHLDE
            INC HL
            JR C,WB1
            LD HL,KBDBUF
WB1
            LD DE,(KBHEAD)
            CALL CPHLDE
            SCF
            JR Z,WB3
            LD (KBTAIL),HL
WB2
            OR A
WB3
            POP HL
            POP DE
            RET

; ---------------------------------------------
; Процедура сравнения HL и DE
; ---------------------------------------------
CPHLDE
            PUSH HL
            OR A
            SBC HL,DE
            POP HL
            RET
KBC17
            DEC A
            JR NZ,CLRBUF

; Получение символа из буфера клавиатуры
; C - код символа
; "CY" - буфер пуст
RDBUF
            PUSH DE
            PUSH HL
            CALL TSB
            JR C,WB3
            LD C,(HL)
            LD DE,KBDBFE
            CALL CPHLDE
            INC HL
            JR C,RB1
            LD HL,KBDBUF
RB1
            LD (KBHEAD),HL
            JR WB2

; ---------------------------------------------
; Обнуление буфера клавиатуры
; ---------------------------------------------
CLRBUF
            PUSH HL
            LD HL,(KBTAIL)
            LD (KBHEAD),HL
            POP HL
            RET
KBC19
            JR NZ,KBC20

; ---------------------------------------------
; Проверка буфера клавиатуры
; ---------------------------------------------
TSTBUF
            PUSH DE
            PUSH HL
            CALL TSB
            POP HL
            POP DE
            RET
TSB
            LD HL,(KBHEAD)
            LD DE,(KBTAIL)
            CALL CPHLDE
            SCF
            RET Z
            OR A
            RET
KBC20
            DEC A
            JR NZ,KBC21

; ---------------------------------------------
; Установка кода АЛФ ГРАФ
;  L - для включения алфавитного режима
;  H - для включения псевдографического режима;
; ---------------------------------------------
            LD (OLDALF),HL
            RET
KBC21
            DEC A
            RET NZ
            LD HL,(OLDALF)
            RET

; ---------------------------------------------
; Подключение модуля клавиатуры
; ---------------------------------------------
            include "kbd.asm"

; ---------------------------------------------
; Подключение модуля мыши
; ---------------------------------------------
            include "mou.asm"


; =============================================
; Текстовые сообщения для режима "PRO"
; =============================================

FLTYT       DB -09H,-'f',-'r',-'o',-'m',-' ',-'f',-'l',-'o',-'p',-'p',-'y',-' '
            DB -'d',-'i',-'s',-'k',-0DH,-0AH,0
;
HDTYT       DB -09H,-' ',-'f',-'r',-'o',-'m',-' ',-'h',-'a',-'r',-'d',-' '
            DB -'d',-'i',-'s',-'k',-0DH,-0AH,0
;
TBER4       DB -'N',-'o',-'n',-'-',-'s',-'y',-'s',-'t',-'e',-'m',-' ',-'d',-'i',-'s',-'k',-'!',0
;
TBERR       DB -'D',-'i',-'s',-'k',-' ',-'b',-'o',-'o',-'t',-' ',-'f',-'a',-'i',-'l',-'u',-'r',-'e',-'!',0

TBER0       DB -0DH,-0AH,-0AH,-' ',-'E',-'R',-'R',-'O',-'R',-3AH,-' ',0
TBQT        DB -' ',-'[',-'A',-'P',-'2',-'-',-'Q',-'u',-'i',-'t',-']',0
;
STTYT       DB -1FH,-0DH,-0AH
            DB -' ',-'O',-'r',-'i',-'o',-'n',-'-',-'P',-'r',-'o'
            DB -' ',-'s',-'y',-'s',-'t',-'e',-'m',-09H,-09H,-09H
            DB -'(',-'C',-')',-' '
            DB -'1',-'9',-'9',-'3',-'-',-'2',-'0',-'0',-'0'
            DB -' ',-'O',-'r',-'i',-'o',-'n',-'s',-'o',-'f',-'t',-0DH,-0AH,0
;
XTYT        DB -0DH,-0AH
            DB -' ',-'L',-'o',-'a',-'d',-'i',-'n',-'g',-' '
            DB -'D',-'i',-'s',-'k',-' ',-'O',-'p',-'e',-'r'
            DB -'a',-'t',-'i',-'n',-'g',-' ',-'S',-'y',-'s'
            DB -'t',-'e',-'m',-0DH,-0AH,0

; ----------------------------------------------
; Подключение блока расширенных функций
; ----------------------------------------------
            include "ext.asm"
            
; ----------------------------------------------
; Filler
; ----------------------------------------------
            BLOCK 9,0xFF

ENABLE_ROM1_OFF
            LD A,0x80
            OUT (PORT_FB_TMR_INT),A
            XOR A
            RET

            BYTE 0xff   ; filler up to 8192

CODE_SIZE   EQU $

            ASSERT CODE_SIZE<2001H, Переполение ROM1 (EXT)
            DISPLAY "Code size is:",/A,CODE_SIZE
            END

