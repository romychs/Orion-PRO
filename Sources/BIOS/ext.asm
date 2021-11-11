;=========================================
;
;        " ORION-PRO "
;      Расширенные функции
;      V0.06   12.02.95
;      V2.10   18.04.00
;=========================================

; ==============================================
; Блок внешней загрузки CM/M для режима Орион-128
; ==============================================
EXTB
            DISP 0xF3A0

EXTLD       CALL 0x2003                                     ; Иициализация режима Orion-128
            POP AF
            LD C,A                                          ; рабочая страница
            LD A,0x1
            CALL 0xF830                                     ; Установка страницы (XPAGE)
            RST CLD_START
            ENT
EXTE        ;

MMMPB       ;
            DISP  0xF800
; ----------------------------------------------
; Знаком "*" помечены вектора, перенастраиваемые при
; инициализации драйвера TV-PRO
; ----------------------------------------------
MEXTX
            JP ST1
            JP KBRDX                                        ; 03 переход на пп обработки клавиатуры
            JP KBDCTL                                       ; 06 управление клавиатурой
TVSYM       JP TVC                                          ; 09 * вывод символа на TV
TVSCR       JP PUSTO                                        ; 0С * управление экранами
TVOUT       JP PUSTO                                        ; 0F * вывод символа/курсора
KB_STTS     JP STTSX                                        ; 12 проверка статуса клавиатуры
HEX_OUT     JP HEX                                          ; 15 байт=>TV(2ASCII)
            JP MSGX                                         ; 18 вывод символьного сообщения
            JP INKEYX                                       ; 1B ввод кода нажатой клавиши
GCUR        JP RCUR                                         ; 1E положение курсора
            JP PRINT                                        ; 21 вывод на печать
            JP NMKEYX                                       ; 24 ввод номера нажатой клавиши
INFST       JP INFAST                                       ; 27 быстрый INKEY
TVGRF       JP PUSTO                                        ; 2A * вывод графики
TVSERV      JP PUSTO                                        ; 2D * вектор дополнительных функций TV
            JP FILLP                                        ; 30 запись константы в PAGE
            JP MOVBL                                        ; 33 перенос блока PAGE/PAGE
RRAM        JP RRAMX                                        ; 36 чтение байта доп. страницы
WRAM        JP WRAMX                                        ; 39 запись байта доп. сраницы
SCUR        JP WCUR                                         ; 3С установка курсора
SOUND       JP SND                                          ; 3F вход в звуковой синтез
            JP RDWIN                                        ; 42 восстановление состояния диспетчера ОЗУ
            JP WRWIN                                        ; 45 сохранение состояния диспетчера ОЗУ
            JP JPWIN                                        ; 48 установка варианта диспетчера и переход
            JP OPCLW                                        ; 4B открыть/закрыть окно ОЗУ, ПЗУ
MOUSE       JP MOUS                                         ; 4E опрос порта мыши
MOUCTR      JP MOUCTL                                       ; 51 управление мышью
            JP RDSEC                                        ; 54 чтение сектора диска
            JP WRSEC                                        ; 57 запись сектора диска
            JP SYS_X                                        ; 5A управление системой
            JP VERSION                                      ; 5D версия ROM1/ROM2
KBSND       JP BEEP                                         ; 60 звук клавиатуры
KBSIG       JP PUSTO                                        ; 63 сигнал переключения флагов клавиа...

ST1
            LD SP,STACK
            IN A,(PORT_0A_MEM_CFG)
            OR 0x18                                         ; Вкл ROM1 и ROM2
            OUT (PORT_0A_MEM_CFG),A
            LD HL,STTYT                                     ; ORION-POWER SYSTEM
            CALL MSGXX
            LD BC,0x40c4

LNTT
            CALL TVSYM
            DJNZ LNTT
            LD HL,XTYT                                      ; LOADING DISK-SYSTEM...
            CALL MSGXX
            IN A,(PORT_0A_MEM_CFG)
            AND 0xe0                                        ; Выкл ROM1 и ROM2
            OUT (PORT_0A_MEM_CFG),A

; ----------------------------------------------
; Загрузка системы с дисков
; ----------------------------------------------
            IN A,(PORT_00_DIPSW)
            RRCA
            JP C,NOFDD
            LD A,0x10
            OUT (PORT_14_VG_CTL),A
            LD A,0xd0                                       ; Принудительное прерывание
            CALL WRCOM
            LD A,0x4b                                       ; Шаг вперед (для 3,5")
            CALL WRCOM
            LD A,0x8                                        ; TRK-00
            CALL WRCOM
            LD B,0xa

; ----------------------------------------------
; Проверка наличия дискеты  (для 5.25") - ускоряет!
; Если дискета не вставлена в дисковод 5.25", то сигнал INDEX = 1.
; Если дискета вставлена но дверца не закрыта, INDEX = 0.
; При вращении дискеты, длительность сигнала INDEX = 1 около 5мс.
; Для дисководов 3.5", при отсутствии дискеты, всегда INDEX = 0.
; ----------------------------------------------
IS_IDX
            PUSH BC
            LD BC,0x1          ;1мс
            LD DE,0x0          ;0Гц
            CALL SOUND
            POP BC
            IN A,(PORT_10_VG_CMD)
            BIT 0x1,A
            JR Z,NOIDX
            DJNZ IS_IDX
            JP NOFDD

; Проверка готовности дисковода
NOIDX
            LD DE,0x0
RDY
            IN A,(PORT_10_VG_CMD)
            RLCA
            JP NC,ST2
            LD A,0xa
RDYCYC
            DEC A
            JR NZ,RDYCYC
            DEC DE
            LD A,D
            OR E
            JR NZ,RDY
            JP NOFDD
NOSYS
            LD HL,TBER4
            JR ERR2
ERROR
            LD HL,TBERR
ERR2
            PUSH HL
            LD HL,TBER0
            CALL MSGXX
            POP HL
            CALL MSGXX
            LD HL,TBQT
            CALL MSGXX
            CALL KBRDX
            CP 0x3
            JR Z,ERR21
            CP 0x1b
            JP NZ,ST1
ERR21
            IN A,(PORT_0A_MEM_CFG)
            OR 0x10
            OUT (PORT_0A_MEM_CFG),A
            JP SYSMON

; Загрузка с дискеты
ST2
            LD HL,FLTYT
            CALL MSGXX                                       ; Вывод: Загрузка с НГМД
            LD A,0x1
            OUT (PORT_12_VG_SECT),A
            LD HL,BUFF
            CALL RDSEC
            JR NZ,ERROR
ANBUF
            LD A,(HL)
            CP 0xc3
            JR NZ,NOSYS                                     ; Не системный диск
            LD HL,BUFF
            LD DE,0x0
            LD BC,0x100
            LD A,(BUFF+0x2F)
            INC A
            JP Z,BUFF
            CP 0x5
            JP NC,NOSYS
            DEC A
            JR NZ,ST6
            LD B,0x4
ST6
            PUSH AF
            CALL MOVBL
            POP AF
            OUT (PORT_08_RAM_PG),A
            CP 0x2
            JP NC,CLD_START

; Инициализация режима О128
            LD SP,0xf3c0
            PUSH AF                                         ; Сохранить страницу
            IN A,(PORT_0A_MEM_CFG)
            OR 0x18
            OUT (PORT_0A_MEM_CFG),A                         ; Включить ROM1,2
            XOR A
            OUT (PORT_09_ROM2_SEG),A
DEAD
            LD A,(0x2003)
            CP 0xc3
            JR NZ,DEAD
            LD HL,EXTB
            LD DE,EXTLD
            LD BC,EXTE-EXTB
            LDIR
            JP EXTLD

; ----------------------------------------------
; Старт системы с HDD
; ----------------------------------------------
NOFDD
            IN A,(PORT_00_DIPSW)
            BIT 0x1,A
            JR Z,LDHDD

                ;Нет дисков, загрузка из ПЗУ
            CALL W93OFF
            IN A,(PORT_0A_MEM_CFG)
            OR 0x18                                                     ; Вкл ROM1,ROM2
            OUT (PORT_0A_MEM_CFG),A
            LD HL,0x2008                                                ; Адрес ROM2
            LD C,0x4                                                    ; Сегмент ROM2 с CP/M
            CALL TSTR2                                                  ; Есть сегмент с CM/M?
            JR Z,NODSK
            LD HL,(CPM_ROM2)
            LD A,L
            CP H
            JP NZ,CPM_ROM2
NODSK
            JP SYSMON
LDHDD
            CALL W93OFF
            LD HL,HDTYT
            CALL MSGXX
            LD A,0x2
            OUT (PORT_56_HDD_CTL),A
            LD DE,0x6ff                                                 ; Ожидание готовности
NRLOOP      DEC DE
            LD A,D
            OR E
            JP Z,ERROR                                                  ; Not ready
            LD B,0xff
HDD_DLY
            EX (SP),HL
            EX (SP),HL
            EX (SP),HL
            EX (SP),HL
            EX (SP),HL
            DJNZ HDD_DLY
            IN A,(PORT_5F_HDD_STAT_CMD)
            OR A
            JP M,NRLOOP
            IN A,(PORT_59_HDD_ERR)
            AND 0x7f                                                    ; Игнорируем ошибки SLAVE
            CP 0x1
            JP NZ,ERROR

; Читать MBR
            LD HL,BUFF
            LD A,0x21
            OUT (PORT_5F_HDD_STAT_CMD),A
BUS01
            IN A,(PORT_5F_HDD_STAT_CMD)
            BIT 0x7,A
            JR NZ,BUS01
            BIT 0x3,A
            JR Z,STR                                                    ; Данные не готовы
            LD B,0x0
CONRD
            IN A,(PORT_58_HDD_LB)                                       ; Читать мл. байт
            LD (HL),A
            INC HL
            IN A,(PORT_57_HDD_HB)                                       ; Читать ст. байт
            LD (HL),A
            INC HL
            DJNZ CONRD

STR         IN A,(PORT_5F_HDD_STAT_CMD)
            AND 0x21
            JP NZ,ERROR
            LD HL,BUFF
            JP ANBUF                                                    ; Анализ флаговой ячейки ОЗУ

; ----------------------------------------------
; Утилиты
; ----------------------------------------------
WR93
            OUT (PORT_10_VG_CMD),A
            LD A,0x2f
W93
            DEC A
            JR NZ,W93
            RET

; Погасить НГМД
W93OFF      IN A,(PORT_00_DIPSW)
            RRCA
            RET C
            XOR A

; Запись кода команды  (A)  в ВГ93
WRCOM       CALL WR93

WRC         IN A,(PORT_10_VG_CMD)
            RRCA
            JR C,WRC
            RET

RDS
            LD A,0x80
            CALL WR93
RDS1
            IN A,(PORT_10_VG_CMD)
            RRA
            RET NC
            RRA
            JR NC,RDS1
            IN A,(PORT_13_VG_DATA)
            LD (HL),A
            INC HL
            JR RDS1
RDSEC
            PUSH HL
            CALL RDS
RDS2
            EX DE,HL
            POP HL
            IN A,(PORT_10_VG_CMD)
            AND 0xdd
            RET
WRSEC
            LD A,0xa0
            CALL WR93
            PUSH HL
            LD (WRS5+1),SP
            LD SP,HL
            LD C,PORT_13_VG_DATA
WRS1
            POP HL
WRS2
            IN A,(PORT_10_VG_CMD)
            XOR 0x1
            JR Z,WRS2
            OUT (C),L
            RRA
            JR C,WRS4
            RRA
            JR NC,WRS2
WRS3
            IN A,(PORT_10_VG_CMD)
            XOR 0x1
            JR Z,WRS3
            OUT (C),H                                   ; PORT_13_VG_DATA
            JR WRS1
WRS4
            LD HL,-2
            ADD HL,SP
WRS5
            LD SP,0x0
            JR RDS2

; ----------------------------------------------
; Вывод сообщения HL
; ----------------------------------------------
MSGX
            LD A,(HL)
            AND A
            RET Z
            CALL TVA
            INC HL
            JR MSGX

; ----------------------------------------------
; Установка позиции курсора
; ----------------------------------------------
WCUR
            PUSH AF
            LD A,NWCUR
            CALL TVOUT
            POP AF
PUSTO
            RET

; ----------------------------------------------
;Получение позиции курсора
; ----------------------------------------------
RCUR
            PUSH AF
            PUSH BC
            PUSH DE
            LD A,NRCUR
            CALL TVOUT
            POP DE
            POP BC
            POP AF
            RET

; ----------------------------------------------
; Вывод символа C
; ----------------------------------------------
TVC
            PUSH AF
            XOR A
            CALL TVOUT
            POP AF
            RET

; ----------------------------------------------
; Запись байта в страницу
;  Вход:
;  A - номер страницы (0-7)
;  C - записывемый байт
; ----------------------------------------------
WRAMX
            PUSH AF
            IN A,(PORT_08_RAM_PG)
            LD (RRM1+1),A
            POP AF
            OUT (PORT_08_RAM_PG),A
            LD (HL),C
            JR RRM1

; ----------------------------------------------
; Чтение байта со страницы
; Вход:
;  A - номер страницы (0-7)
;  C - записывемый байт
; ----------------------------------------------
RRAMX
            PUSH AF
            IN A,(PORT_08_RAM_PG)
            LD (RRM1+1),A
            POP AF
            OUT (PORT_08_RAM_PG),A
            LD C,(HL)
RRM1
            LD A,0x0
            OUT (PORT_08_RAM_PG),A
            RET

; ----------------------------------------------
; Сохранение портов диспетчера в ОЗУ
; HL - адрес сохранения (6-байт)
;  порт 4 - WIN0
;  порт 5 - WIN1
;  порт 6 - WIN2
;  порт 8 - PAGE
;  порт 9 - WIN_ROM2
;  порт A - диспетчер
; ----------------------------------------------
RDWIN
            PUSH HL
            PUSH BC
            LD BC,0x304
RDW01
            IN A,(C)                                    ; PORT_04_RAM0P
            LD (HL),A
            INC HL
            INC C
            DJNZ RDW01
            INC C
            LD B,0x3
RDW02
            IN A,(C)                                        ; PORT_06_RAM2P
            LD (HL),A
            INC HL
            INC C
            DJNZ RDW02
            POP BC
            POP HL
            RET

; ----------------------------------------------
; Восстановление портов диспетчера
;  HL- адрес буфера с сохраненными портами
; ----------------------------------------------
WRWIN
            PUSH HL
            PUSH BC
            LD BC,0x304
WWN01
            LD A,(HL)
            OUT (C),A                                       ; PORT_04_RAM0P
            INC HL
            INC C
            DJNZ WWN01
            INC C
            LD B,0x3
WWN02
            LD A,(HL)
            OUT (C),A                                       ; PORT_06_RAM2P
            INC HL
            INC C
            DJNZ WWN02
            POP BC
            POP HL
            RET

; ----------------------------------------------
; Установка окон и диспетчера из таблиц и передача управления
; Вход:
;  A=0ffh - уст адрес табл
;  HL - адрес таблицы
;  A=0-N - номер канала
;
; ADR WIN0    <- kanal_0
;     WIN1
;     WIN2
;     PAGE
;     WIN_ROM2
;     DISP
;     ADDR_START
;     WIN0    <- kanal_1
;     ....
;     ADDR_START
;     WIN0    <- kanal_N
; ----------------------------------------------
JPWIN
            INC A
            JR NZ,WRW1
            LD (ADWRW+1),HL
            RET
WRW1
            PUSH BC
            DEC A
            ADD A,A
            ADD A,A
            ADD A,A
            LD C,A
            LD B,0x0
ADWRW
            LD HL,0x0
            ADD HL,BC
            LD BC,0x304
WRW01
            LD A,(HL)
            INC HL
            OUT (C),A                                                   ; PORT_04_RAM0P
            INC C
            DJNZ WRW01
            INC C
            LD B,0x3
WRW02
            LD A,(HL)
            INC HL
            OUT (C),A                                                   ; PORT_06_RAM2P
            INC C
            DJNZ WRW02
            LD A,(HL)
            INC HL
            LD H,(HL)
            LD L,A
            POP BC
            JP HL

; ----------------------------------------------
; Открыть/закрыть окно
; Вход:
;  A = 0  - открыть окно
;  C = номер окна
;  B = номер сегмента
;  A != 0 - закрыть окно
;  C = номер окна
; ----------------------------------------------
OPCLW       PUSH HL
            LD (FLOC+1),A
            LD A,C
            AND 0x7
            LD L,A
            LD C,A
            LD A,0x1
            INC L
OPC1        DEC L
            JR Z,OPC2
            RLCA
            JR OPC1
OPC2        LD L,A
FLOC        LD A,0x0
            AND A
            JR NZ,OPC20
            LD A,L
            CPL
            LD L,A
            IN A,(PORT_0A_MEM_CFG)
            AND L
            JR OPC7
OPC20       LD A,B
            INC C
            DEC C
            JR NZ,OPC3
            OUT (PORT_04_RAM0P),A
            JR OPC6
OPC3        DEC C
            JR NZ,OPC4
            OUT (PORT_05_RAM1P),A
            JR OPC6
OPC4        DEC C
            JR NZ,OPC5
            OUT (PORT_06_RAM2P),A
            JR OPC6
OPC5        DEC C
            JR NZ,OPC6
            OUT (PORT_09_ROM2_SEG),A
OPC6        IN A,(PORT_0A_MEM_CFG)
            OR L
OPC7        OUT (PORT_0A_MEM_CFG),A
            POP HL
            RET

; ----------------------------------------------
; Управление системой
; ----------------------------------------------
SYS_X       PUSH IX
            db 0DDh
            LD L,A;LD LX,A
            LD A,0x15
            CALL TUNEL
            POP IX
            RET

STTSX       LD A,0xc
            JP TUNEL

INKEYX      LD A,0xf
            JP TUNEL

KBRDX       LD A,0x9
            JP TUNEL

; ----------------------------------------------
; Управление клавиатурой
; ----------------------------------------------
KBDCTL      PUSH IX
            db 0DDh
            LD L,A
            LD A,0x6
            CALL TUNEL
            POP IX
            RET

; ----------------------------------------------
; Управление мышью
; ----------------------------------------------
MOUCTL      OR A
            JR Z,MSWND
            CP 0xa
            JP NC,MOUC10

MOUS1       PUSH IX
            db 0DDh
            LD L,A
            LD A,0x18
            CALL TUNEL
            POP IX
            RET

MSWND       LD (MSY),BC
            LD (MSX),DE
            PUSH HL
            CALL GCUR
            PUSH HL
            LD A,GETWND
            CALL TVSCR
            PUSH BC
            PUSH DE
            PUSH HL
            LD A,GETSCR
            CALL TVSCR
            LD A,(MSMODE)
            RLCA
            LD A,SETSCR
            CALL C,TVSCR
            XOR A
            CALL MOUS1
            POP HL
            POP DE
            POP BC
            PUSH AF
            LD A,SETWND
            CALL TVSCR
            POP AF
            POP HL
            PUSH AF
            CALL SCUR
            POP AF
            POP HL
            LD BC,(MSY)
            LD DE,(MSX)
            RET
MOUC10      RET NZ

TSTOBL      XOR A
            CP B
            RET C
            LD A,(HL)
            OR A
            INC HL
            SCF
            RET Z
            PUSH IX
            PUSH HL
            POP IX
            PUSH AF
TSTO1       PUSH AF
            PUSH BC
            CALL TSTXY
            JR NC,TSTO3
            LD BC,0x6
            ADD IX,BC
            POP BC
            POP AF
            DEC A
            JR NZ,TSTO1
            POP AF
            SCF
TSTO2       PUSH IX
            POP HL
            POP IX
            RET

TSTO3       POP BC
            LD A,C
            POP BC
            LD C,A
            POP AF
            SUB B
            LD B,0x0
            JR TSTO2
TSTXY       LD L,(IX+0x0)
            LD H,(IX+0x1)
            PUSH HL
            SCF
            SBC HL,DE
            POP HL
            CCF
            RET C
            LD A,C
            LD C,(IX+0x3)
            LD B,(IX+0x4)
            DEC BC
            ADD HL,BC
            LD C,A
            OR A
            SBC HL,DE
            RET C
            LD A,(IX+0x2)
            SCF
            SBC A,C
            CCF
            RET C
            LD B,(IX+0x5)
            LD A,(IX+0x2)
            DEC B
            ADD A,B
            CP C
            RET

MOUS        PUSH BC
MO1         IN A,(PORT_1E_MOUSE)
            LD C,A
            IN A,(PORT_1E_MOUSE)
            CP C
            JR NZ,MO1
            POP BC
            RET

NMKEYX      LD A,0x12
TUNEL       LD (TSTECK+1),SP
            LD SP,SPTUNL
            LD (TUN0+1),A
            IN A,(PORT_0A_MEM_CFG)
            LD (TUN2+1),A
            OR 0x10
            OUT (PORT_0A_MEM_CFG),A
TUN0        CALL CLD_START
            PUSH AF
TUN2        LD A,0x0
            OUT (PORT_0A_MEM_CFG),A
            POP AF
TSTECK      LD SP,0x0
            RET

HEX         PUSH AF
            RRCA
            RRCA
            RRCA
            RRCA
            CALL HEX1
            POP AF
HEX1        AND 0xf
            CP 0xa
            JP M,HEX2
            ADD A,0x7
HEX2        ADD A,0x30
            ;

TVA         PUSH BC
            LD C,A
            CALL TVSYM
            POP BC
            RET

SND         IN A,(PORT_0A_MEM_CFG)
            LD (SND4+1),A
            SET 0x5,A
            OUT (PORT_0A_MEM_CFG),A
            PUSH BC
            PUSH DE
            PUSH HL
SND0
            LD HL,0x0
SND1
            LD A,B
            OR C
            JR Z,SND4
            DEC BC
            PUSH BC
            LD B,0x20
SND2
            LD A,H
            ADD HL,DE
            ADD HL,DE
            XOR H
            RLCA
            JR NC,SND3
            OUT (PORT_FF_SPEAKER),A
SND3
            NOP
            NOP
            LD A,0x0
            DJNZ SND2
            POP BC
            JR SND1
SND4
            LD A,0x40
            OUT (PORT_0A_MEM_CFG),A
            LD (SND0+1),HL
            POP HL
            POP DE
            POP BC
            RET
BEEP
            LD A,E
            AND 0x3
            CP 0x3
            LD A,D
            LD BC,0x14
            LD DE,0x400
            JR NZ,BP1
            XOR 0x20
            BIT 0x5,A
            JR BP2
BP1
            BIT 0x6,A
BP2
            JR Z,BP3
            LD DE,0x800
BP3
            JP SOUND

; ----------------------------------------------
;  Вывод закодированного сообщения
;  HL - адрес сообщения в ROM1
; ----------------------------------------------
MSGXX       IN A,(PORT_0A_MEM_CFG)          ; Сохранить конфигурацию памяти
            PUSH AF
            PUSH BC
            SET ROM1_WND,A                  ; Включить окно ROM1
            OUT (PORT_0A_MEM_CFG),A
            ; Вывод символов в цикле
MSGX1       LD A,(HL)
            AND A
            JR Z,MSGX2                      ; Конец строки?
            NEG                             ; Смена знака (декодирование)
            CALL TVA                        
            INC HL
            JR MSGX1

MSGX2       POP BC
            POP AF
            OUT (PORT_0A_MEM_CFG),A         ; Восстановить настройки памяти
            RET

; ----------------------------------------------
; Быстрый INKEY
; ----------------------------------------------
INFAST      PUSH HL
            LD L,0
            IN A,(PORT_00_DIPSW)
            AND 0x4                         ; 1 - РК86, 0 - МС7007
            JP NZ,IN86F
            LD A,0xFF
            OUT (PORT_1A_KBD),A
            LD A,0xFC
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            BIT 2,A                         ; УПР?
            JR NZ,IN77F1
            SET 0,L

IN77F1      AND 0x10                        ; SHIFT?
            JR NZ,IN77F2
            SET 0x1,L

IN77F2      LD A,0xFB
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            AND 0x10                        ; ФИКС?
            JR NZ,IN77F3
            SET 2,L

IN77F3      LD A,0xBF                       ; =>
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            AND 0x20
            OR 0xdf
            LD H,A
            LD A,0x7F                       ; Вверх/вниз
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            BIT 5,A
            JR NZ,IN77F6
            RES 6,H

IN77F6      BIT 6,A
            JR NZ,IN77F7
            RES 4,H
IN77F7
            LD A,0xFF
            OUT (PORT_19_KBD),A
            LD A,0xFD
            OUT (PORT_1A_KBD),A
            IN A,(PORT_18_KBD)
            AND 0x10
            JR NZ,IN77F5
            RES 3,H
IN77F5
            LD A,H
            CPL
            RLCA
IN77F8
            AND 0xf0
            OR L
            POP HL
            RET

; ----------------------------------------------
; INFAST - РК86
; ----------------------------------------------
IN86F       IN A,(PORT_1A_KBD)
            CPL
            RLA                             ; CY = ФИКС
            RL L
            RLA                             ; CY = УПР
            PUSH AF
            RLA                             ; CY = SHIFT
            RL L
            POP AF
            RL L
            LD A,0xFD
            OUT (PORT_18_KBD),A
            IN A,(PORT_19_KBD)
            CPL
            JR IN77F8

; ----------------------------------------------
; Получение версии
; Выход:
;  H - ROM1, L - TV ROM2
; ----------------------------------------------
VERSION     DB 21H                                                  ; LXI H,..
VERSTV      DB 0                                                    ; Версия TV-PRO
            DB VERS/10H                                             ; Версия ROM1
            RET

; ----------------------------------------------
; Печать
; Вход:
; 1. A !=0 - чтение статуса PRINT
; 2. A = 0 - печать символа
;    C = символ для печати
; Выход:
;   A = 0 - символ принят
;   A != 0 - принтер не готов
;     D0=1 - неисправность (ERROR)
;     D1=1 - занят (BYSY)
; ----------------------------------------------
PRINT
            AND A
            JR Z,WPRT1
STATU
            PUSH BC
            LD B,0x5
            NOP
            IN A,(PORT_02_PRNT_CTL)
            RLCA
            RLCA
            RLCA
            XOR B
            AND 0x7
            POP BC
            RET

; ----------------------------------------------
; Печать символа из регистра С
; ----------------------------------------------
WPRT1       PUSH BC
            PUSH DE
            PUSH HL
WPRT2
            CALL STATU
            JR NZ,WPEND
            LD A,C
            CPL
            OUT (PORT_01_PRNT_DAT),A
            LD A,1                          ; STROBE -\_
            OUT (PORT_02_PRNT_CTL),A
            NOP
            NOP
            XOR A
            OUT (PORT_02_PRNT_CTL),A        ; STRONE _/-
            CALL STATU
WPEND
            POP HL
            POP DE
            POP BC
            RET

; ----------------------------------------------
; Запись константы в память
; Вход:
;  A - Страница
;  C - Записываемый байт
;  HL - Адрес внутри страницы
;  DE - Количество байт
; ----------------------------------------------
FILLP       PUSH AF
            IN A,(PORT_08_RAM_PG)
            LD (FLP1+1),A                   ; Исходная страница
            POP AF
            ;
            AND 0x0F                        ; Сбросим лишние биты
            OUT (PORT_08_RAM_PG),A          ; и включи нужную страницу
            ;
            LD (HL),C
            LD B,D
            LD C,E
            LD D,H
            LD E,L
            INC DE
            DEC BC
            LD A,C
            OR B
            JR Z,FLP1
            LDIR
FLP1        LD A,0
            OUT (PORT_08_RAM_PG),A
            RET

; ----------------------------------------------
; Перенос блока со страницы на страницу
; HL - начальный адрес - откуда
; DE - начальный адрес - куда
; BC - количество
; A 0000----  - страница, откуда читать
;   ----0000  - страница, куда записывать
; ----------------------------------------------
MOVBL       PUSH AF
            AND 0x0F
            LD (MVB2+1),A                   ; Куда писать
            POP AF
            RRCA
            RRCA
            RRCA
            RRCA
            AND 0x0F
            LD (MVB1+1),A                   ; Откуда писать
            IN A,(PORT_08_RAM_PG)           
            LD (MVB3+1),A                   ; Текущая страница
            LD (MVSTK+1),SP                 ; Текущий стек
            LD SP,HL                        ; Откуда
            EX DE,HL                        ; Куда

MVB1        LD A,0                          ; вместо 0, подставляется номер страницы
            OUT (PORT_08_RAM_PG),A          ; Выбрать стр. откуда
            POP DE                          ; Два очередных байта
MVB2
            LD A,0                          ; вместо 0, подставляется номер страницы
            OUT (PORT_08_RAM_PG),A          ; Выбрать стр. куда
            LD (HL),E                       ; Запись 1-го байта
            INC HL
            DEC BC
            LD A,B
            OR C                            ; Все?
            JR Z,MVB3                       ; да
            LD (HL),D                       ; Запись 2-го байта
            INC HL
            DEC BC
            LD A,B
            OR C                            ; Все?
            JR NZ,MVB1                      ; нет
            ; Восстановление страницы памяти
MVB3        LD A,0                          
            OUT (PORT_08_RAM_PG),A
            ; Восстановление стека
MVSTK       LD SP,0                         
            RET

; ----------------------------------------------
; Заглушка для ISR
; ----------------------------------------------
DEFESR      EI
            RETI

DUMMY
            DB 0
ENDEXT      ;
            ENT
MMMPE       ;

            ASSERT  ENDEXT < CELLS, Коллизия EXT и CELLS
