
; =============================================
; Модуль обслуживания клавиатуры в ROM1
; =============================================

; ---------------------------------------------
;Статус клавиатуры
; ---------------------------------------------
STTS        IN A,(0x0)
            AND 0x4
            JR Z,STTS1
            XOR A
            OUT (PORT_18_KBD),A
            IN A,(PORT_19_KBD)
            XOR 0xff
            RET Z
            LD A,0xff
            RET
STTS1
            XOR A
            OUT (PORT_1A_KBD),A
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            INC A
            RET Z
            LD A,0xff
            OUT (PORT_1A_KBD),A
            LD A,0xfc
            OUT (PORT_19_KBD),A
            NOP
            IN A,(PORT_18_KBD)
            AND 0xe3
            CP 0xe3
            JR NZ,LAB_ram_1051
            LD A,0x3
            OUT (PORT_19_KBD),A
            NOP
            IN A,(PORT_18_KBD)
            INC A
            JR NZ,LAB_ram_1051
            OUT (PORT_1A_KBD),A
            NOP
            IN A,(PORT_18_KBD)
            INC A
            RET Z
LAB_ram_1051

            LD A,0xff
            RET

; ---------------------------------------------
; Процедура опроса клавиатуры с миганием курсором
; Вход:
;  C  - режим курсора, старший бит - признак того, что курсор отображается
;  DE - счетчик задержки мигания
; Выход:
;  A, "CY" - результат INKEY
; ---------------------------------------------
CURINK
            CALL INKEY
            BIT 0x5,C
            RET Z
            BIT 0x4,C
            RET Z
            DEC DE
            INC E
            DEC E
            RET NZ
            INC D
            DEC D
            RET NZ
            LD DE,(CURTM)
            BIT 0x7,C
            JR Z,CURON
CUROFF
            RES 0x7,C
            PUSH BC
            PUSH DE
            PUSH HL
            PUSH AF
            LD A,0x6                                ; Получить позицию курсора
            CALL TVOUT
            LD A,0x3                                ; Погасить графический курсор в заданн...
CO1
            CALL TVOUT
            POP AF
            POP HL
            POP DE
            POP BC
            RET
CURON
            SET 0x7,C
            PUSH BC
            PUSH DE
            PUSH HL
            PUSH AF
            LD A,0x6
            CALL TVOUT
            LD A,0x2
            JR CO1

; ---------------------------------------------
; Определение кодировки клавиатуры
;  "CY","NZ" - ALT, koi-8
;  "NC","Z"  - koi-7 n2
;  "NC","NZ" - koi-7 n1,0
; ---------------------------------------------
IS_KOI7
            LD A,(KBMODE)
            AND 0x3
            CP 0x2
            RET

; ---------------------------------------------
; Определение старого режима клавиатуры
;  "NZ" - rk-86 или старый режим ms7007
;  "Z"  - новый режим ms7007
; ---------------------------------------------
IS_OLD
            IN A,(0x0)
            AND 0x4
            RET NZ
            LD A,(KBMODE)
            BIT 0x7,A
            RET

; ---------------------------------------------
; Ввод символа с клавиатуры
; Выход:
;  A - Код нажатой клавиши
;  Для формироввания звука "rus/lat" используется процедура
;  "SOUND" монитора. она может быть заменена на другую.
;  На ее вход подпрограмма "KBRD" подает признак RUS/LAT в регистре A (A=0 - lat, A<>0 - rus).
;  В стандартной процедуре SOUND этот признак не используется, параметры звука задаются в регистрах BC, DE.
; Особенности: обеспечивается обработка буфера KBRD.
; ---------------------------------------------
KBRD        PUSH BC
            PUSH DE
            PUSH HL

            DB 3EH       ;LD A,...
KBRD1       POP AF
            CALL RDBUF
            LD A,C
            JR NC,KBRD3
            CALL KBD
            PUSH AF
            CALL GETKBM
            CP 0x3
            JR NC,KBRD2
            LD B,(HL)
            LD A,D
            AND 0x3
            CP 0x3
            JR Z,KBRD2
            LD E,A
            ADD A,A
            ADD A,E
            LD E,A
            LD D,0x0
            LD HL,FUNTAB
            ADD HL,DE
            LD A,C
            CP 0x4
            JR Z,KBRD01
            CP 0x0A                             ; упр?
            JR NZ,KBRD02
KBRD01      LD A,B
KBRD02      CALL FUNKEY
            JR NC,KBRD1
KBRD2       POP AF
KBRD3       POP HL
            POP DE
            POP BC
            RET

; ---------------------------------------------
; Обработка функциональных клавиш
;  Вход:
;   HL - адрес таблицы ФК
;   A  - код сканирования
;  Выход:
;   "CY" - нет в таблице, иначе строка  -> в буфер KBRD
; ---------------------------------------------
FUNKEY
            LD C,PORT_0A_MEM_CFG
            IN B,(C)
            PUSH BC
            SET SHIFT,B
            OUT (C),B
            SRL C
            IN B,(C)
            PUSH BC
            LD E,(HL)
            INC HL
            LD D,(HL)
            INC HL
            OUTI
            EX DE,HL
            RES 0x7,H
            SET 0x6,H
            PUSH HL
            CALL SRCKEY
            POP HL
            CALL NC,STRADR                                  ; HL- адрес строки
            CALL NC,BUFSTR
            POP BC
            OUT (C),B
            POP BC
            OUT (C),B
            RET

; ---------------------------------------------
; Поиск функциональной клавиши в таблице
;  Вход:
;   A - код сканирования
;   HL - адрес начала таблицы
;  Выход:
;   B = 0,
;   "CY" - не найден, иначе A - порядковый номер в таблице
; ---------------------------------------------
SRCKEY
            LD B,0x0
            LD C,(HL)
            SCF
            INC C
            DEC C
            RET Z
            INC HL
            PUSH BC
            CPIR
            LD A,C
            POP BC
            SCF
            RET NZ
            SUB C
            CPL
            OR A
            RET
; ---------------------------------------------
; Определение адреса строки в таблице
; Вход:
;  A - порядковый номер клавиши
;  HL - адрес начала таблицы
;  B = 0
; Выход:
;  HL - адрес начала строки
;  "NC"- всегда
; ---------------------------------------------
STRADR
            LD C,(HL)
            INC HL
            ADD HL,BC
            INC A
SA1
            DEC A
            OR A
            RET Z
            LD C,(HL)
            INC HL
            ADD HL,BC
            JR SA1

; ---------------------------------------------
; Запись строки в буфер клавиатуры
; Вход:
;   HL - адрес начала строки
; Выход:
; "CY" - строка пуста, иначе строка заносится в буфер
; ---------------------------------------------
BUFSTR
            LD B,(HL)
            SCF
            INC B
            DEC B
            RET Z
BS1
            INC HL
            LD C,(HL)
            CALL WRBUF
            JR C,BS2
            DJNZ BS1
BS2
            OR A
            RET

; ---------------------------------------------
; Процедура KBRD без поддержки буфера
; ---------------------------------------------
KBD
            LD A,NCURMR
            CALL TVOUT
            RES 0x7,C
            BIT ENACUR,C
            CALL NZ,CURON
            LD DE,(CURTM)
            JR KBD3
KBD0        POP AF
            LD HL,(KBAUTO)
            JR KBD21
KBD1        POP AF
KBD2        LD HL,1
KBD21       LD (STAUTO),HL
KBD3        CALL CURINK
            LD B,A
            JR NC,KBD32
            PUSH BC
            CALL KBD8
            POP BC
            JR KBD2
KBD32       CALL KBD20
            JR NC,KBD2
            LD HL,(STAUTO)
            PUSH HL
KBD4        XOR A
KBD5        DEC A
            JR NZ,KBD5
            CALL CURINK
            JR C,KBD1
            CP B
            JR NZ,KBD0
            DEC HL
            LD A,H
            OR L
            JR NZ,KBD4
            POP HL
            DEC HL
            LD A,H
            OR L
            LD HL,(KBAUTO)
            JR Z,KBD6
            LD HL,0x2
KBD6        LD (STAUTO),HL
            BIT 0x7,C
            CALL NZ,CUROFF
            LD A,B
            LD (KBSYM),A
            LD DE,(KBMODE)
            PUSH AF
            CALL KBSND                          ; Звук клавиатуры
            POP AF
            RET

; ---------------------------------------------
; Обработка спецклавиш
; Вход:
;  B - выходное значение INKEY
; ---------------------------------------------
KBD8
            LD HL,KBFLAG
            LD C,(HL)
            CALL IS_OLD
            LD A,B
            JR Z,KBD18
            CP 0xfe
            JR NZ,KBD11
KBD9        CALL IS_KOI7
            JR Z,KBD13
            JR NC,KBD19
            BIT GRFALF,(HL)
            JR NZ,KBD10
KBD13       LD A,(HL)
            XOR ruslat
            LD (HL),A
KBD10F      PUSH BC
            PUSH DE
            PUSH HL
            LD A,C
            LD DE,(KBMODE)
            CALL KBSIG
            POP HL
            POP DE
            POP BC
KBD10       CALL INKEY
            JR NC,KBD10
            INC A
            JR NZ,KBD10
            LD A,(HL)
            AND 0x1f
            JR NZ,KBD10
            RET
KBD11       CP 0xf
            JR NZ,KBD14
KBD12       RES GRFALF,(HL)
            JR KBD10F
KBD14       CP 0xe
            JR NZ,KBD16
KBD15       CALL IS_KOI7
            JR NC,KBD10
            SET GRFALF,(HL)
            JR KBD10F
KBD16       BIT SHIFT,(HL)
            RET Z
            BIT CTRL,(HL)
            RET Z
KBD17
            CALL IS_KOI7
            JR Z,KBD13
KBD19
            LD A,(HL)
            XOR bolmal
            LD (HL),A
            JR KBD10F
KBD18
            BIT FIX,(HL)
            RET Z
            BIT SHIFT,(HL)
            JR NZ,KBD17
            BIT ALF,(HL)
            JR NZ,KBD9
            BIT GRF,(HL)
            RET Z
            CALL IS_KOI7
            JR NC,KBD10
            LD A,(HL)
            XOR grfalf
            LD (HL),A
            JR KBD10F

; ---------------------------------------------
; Обработка ^O,^N rk86 и ms7007(OLD MODE)
; Вход:
;  (B) - код на выходе INKEY
;  "CY" - ^O,^N не нажаты
; ---------------------------------------------
KBD20
            CALL IS_OLD
            SCF
            RET Z
            CALL IS_KOI7
            CCF
            RET C
            LD HL,OLDGRF
            LD A,(HL)
            DEC HL
            CP (HL)
            JR NZ,KBD22
            CP B
            SCF
            RET NZ
            LD HL,KBFLAG
            BIT GRFALF,(HL)
            JR Z,KBD15
            JR KBD12
KBD22
            LD A,(HL)
            CP B
            INC HL
            LD A,(HL)
            LD HL,KBFLAG
            JR Z,KBD12
            CP B
            JR Z,KBD15
            SCF
            RET

; =============================================
; INKEY 
; =============================================

; ---------------------------------------------
; INKEY с обработкой спецклавиш
;  "NC", A - код клавиши
;  "CY",  A - не нажата или спецклавиша
; ---------------------------------------------
INKEY2      IN A,(PORT_00_DIPSW)
            AND 4                               ; Тип клавиатуры
            JR Z,INK23
                ; Полный опрос матрицы РК86
            XOR A
            OUT (PORT_18_KBD),A
            IN A,(PORT_19_KBD)
            OR A
            JR NZ,INK24
            IN A,(PORT_1A_KBD)
            OR 0x1f
            INC A
            JR NZ,INK24
INK22
            OR 0xff
            SCF
            RET
                ; Полный опрос матрицы МС7007
INK23
            XOR A
            OUT (PORT_19_KBD),A
            OUT (PORT_1A_KBD),A
            IN A,(PORT_18_KBD)
            INC A
            JR Z,INK22
INK24
            CALL INKEY
            PUSH HL
            PUSH BC
            PUSH DE
            LD B,A
            JR NC,INK26
            CALL KBD8
INK25
            OR 0xff
            SCF
            JP INK8
INK26
            CALL KBD20
            JR NC,INK25
            LD A,B
            OR A
            JP INK8

; ---------------------------------------------
; Опрос нажатой клавиши (старый вариант, базовая)
; Выход:
;  если "NC": клавиша нажата A - код клавиши (кроме CTRL,SHIFT,FIX,ALF,GRF)
;  если "CY":
;    A = 0FFH - клавиша не нажата
;    A = 0FEH - нажата одна клавиша "ФИКС" (РУС/LAT)
;    A = 0EH  - нажата одна клавиша "ГРАФ" на МС7007
;    A = 0FH  - нажата одна клавиша "АЛФ"  на МС7007
; ---------------------------------------------
INKEY
            PUSH HL
            PUSH BC
            PUSH DE
            CALL NUMINK
            AND A
            JR Z,INK3
            CP 0x4
            JR NC,INK3
            LD HL,KBFLAG
            LD D,A
            LD E,0x0
            LD A,(HL)
            AND 0x1f
            JR Z,INK10
            LD B,0x5
INK1
            RRCA
            JR NC,INK2
            INC E
INK2
            DJNZ INK1
            LD A,D
            CP E
            JR NZ,INK9
            DEC A
            JR NZ,INK3
            BIT FIX,(HL)
            JR NZ,INK4
            BIT GRF,(HL)
            JR NZ,INK5
            BIT ALF,(HL)
            JR NZ,INK6
;
INK3        LD A,0xFF
            DB 0x21
INK4        LD A,0xFE
            DB 0x21
INK5        LD A,0x0E                           ; граф
            DB 0x21
INK6        LD A,0x0F                           ; АЛФ
;
INK7        SCF
;
INK8        POP DE
            POP BC
            POP HL
            RET

INK9        LD A,C
            CP 0xd
            JR NC,INK92
            LD A,D
            CP 0x2
            JR NZ,INK3
            LD A,C
            CP 0xa
            JR NC,INK91
            CP 0x4
            JR NZ,INK92
INK91       PUSH HL
            LD HL,(BAZA)
            INC HL
            LD C,(HL)
            POP HL
INK92       BIT FIX,(HL)
            JR NZ,INK3
INK10       LD D,C
            LD A,C
            LD HL,CURTAB
            LD BC,0x0004
            CPIR            ;=
            JR NZ,INK11
            LD A,0x3
            SUB C
            LD C,A
            LD HL,CURCOD
            ADD HL,BC
            LD A,(KBFLAG)
            AND 0x3
            ADD A,A
            ADD A,A
            LD C,A
            LD A,E
            CP 0x2
            JR C,INK101
            LD C,0x0
INK101      ADD HL,BC
            LD A,(HL)
            JR INK8
INK11       LD C,D
            LD HL,KBTAB
            LD DE,KBTAB+88
            CALL IS_KOI7
            LD A,(KBFLAG)
            JR C,INK12
            EX DE,HL
            JR NZ,INK16
            BIT ALF,A
            JR Z,INK01
            XOR ruslat
INK01       BIT RUSLAT,A                                ; CHECK RUSLAT+1?
            JR NZ,INK17
            EX DE,HL
            JR INK17
INK12       BIT CTRL,A
            JR NZ,INK17
            LD HL,KBTAB+88*4
            LD DE,-(88*2)
            BIT GRF,A
            JR Z,INK13
            XOR grfalf
INK13
            BIT GRFALF,A
            JR NZ,INK15
            ADD HL,DE
            BIT ALF,A
            JR Z,INK14
            XOR ruslat
INK14
            BIT RUSLAT,A
            JR NZ,INK15
            ADD HL,DE
INK15
            EX DE,HL
            LD HL,88
            ADD HL,DE
INK16
            BIT CPSLCK,A
            JR Z,INK17
            EX DE,HL
INK17
            BIT SHIFT,A
            JR Z,INK18
            EX DE,HL
            ADD HL,BC
            IN A,(PORT_00_DIPSW)
            AND KBD_TYPE
            JR NZ,INK19
INK171
            LD A,C
            PUSH HL
            LD HL,SPECTB
            LD C,SPECTE-SPECTB          ; BC - длина таблицы
            CPIR
            POP HL
            JR NZ,INK19
            LD A,(HL)
            XOR 0x10
            JR INC20
INK18
            ADD HL,BC
            IN A,(CTRL)
            AND KBD_TYPE
            JR NZ,INK171
INK19
            LD A,(HL)
INC20
            LD C,A
            CALL IS_KOI7
            DEC A
            JR NZ,INK21
            LD HL,ALTK8
            LD A,C
            SUB 0x80
            JR C,INK21
            LD C,A
            ADD HL,BC
            LD C,(HL)

; ---------------------------------------------
; Обработка клавиши CTRL
; ---------------------------------------------
INK21       LD HL,INK8
            PUSH HL
            LD A,(KBFLAG)
            OR A
            BIT CTRL,A                      ; Нажата CTRL?
            LD A,C
            RET Z                           ; Не нажата
            CP ruslat
            CCF
            RET NC                          ; Не буква
            CP 0x7F
            RET NC                          ; Не буква
            AND 0x1F
            RET

;-- Таблица номеров клавиш курсора --
CURTAB      DB 4Ch,35h,3Eh,3Dh                           ; LEFT, RIGHT, UP, DOWN

;-- Таблица перекодирования номеров клавиш по SHIFT
SPECTB
            DB 19h,21h,29h,30h,39h,41h,48h,50h
            DB 57h,4Fh,47h,46h,10h,37h,54h,45h
SPECTE                                                         ; конец таблицы


; Таблица перевода сканкодов МС7007 в коды клавиш
; используется 4 таблицы по 88 байт каждая:
;  1). для больших латинских букв;
;  2). для маленьких латинских букв;
;      (или русские в верхнем КОИ-7);
;  3). для больших русских букв ALT-кодировки;
;  4). для маленьких русских букв;
;  5). для набора 1 псевдографики ALT-кодировки;
;  6). для набора 2 псевдографики ALT-кодировки;
; Примечание: коды клавиш курсора не учитываются
;

KBTAB
                ; Большие латинские
            DB 39H,38H,00H,00H,00H,34H,35H,36H   ;0-7
            DB 1BH,09H,00H,0EH,0FH,2BH,2DH,0DH   ;8-F
            DB 2BH,4AH,46H,51H,00H,30H,2EH,2CH   ;10-17
            DB 00H,21H,43H,59H,5EH,31H,32H,33H   ;18-1F
            DB 01H,22H,55H,57H,53H,37H,0CH,1FH   ;20-27
            DB 02H,23H,4BH,41H,4DH,7FH,1EH,0AH   ;28-2F
            DB 24H,45H,50H,49H,20H,18H,0DH,3FH   ;30-37
            DB 03H,25H,4EH,52H,54H,1AH,19H,5FH   ;38-3F
            DB 04H,26H,47H,4FH,58H,3EH,2AH,3DH   ;40-47
            DB 27H,5BH,4CH,42H,08H,5CH,48H,20H   ;48-4F
            DB 28H,5DH,44H,40H,3CH,56H,5AH,29H   ;50-57
                ;
                ; Малые латинские (или русские для КОИ-7 n2)
            DB 39H,38H,00H,00H,00H,34H,35H,36H   ;0-7
            DB 1BH,09H,00H,0EH,0FH,2BH,2DH,0DH   ;8-F
            DB 2BH,6AH,66H,71H,00H,30H,2EH,2CH   ;10-17
            DB 00H,21H,63H,79H,7EH,31H,32H,33H   ;18-1F
            DB 01H,22H,75H,77H,73H,37H,0CH,1FH   ;20-27
            DB 02H,23H,6BH,61H,6DH,7FH,1EH,0AH   ;28-2F
            DB 24H,65H,70H,69H,20H,18H,0DH,3FH   ;30-37
            DB 03H,25H,6EH,72H,74H,1AH,19H,5FH   ;38-3F
            DB 04H,26H,67H,6FH,78H,3EH,2AH,3DH   ;40-47
            DB 27H,7BH,6CH,62H,08H,7CH,68H,20H   ;48-4F
            DB 28H,7DH,64H,60H,3CH,76H,7AH,29H   ;50-57
                ;
                ; Русские большие
            DB 39H,38H,00H,00H,00H,34H,35H,36H   ;0-7
            DB 1BH,09H,00H,0EH,0FH,2BH,2DH,0DH   ;8-F
            DB 2BH,89H,94H,9FH,00H,30H,2EH,2CH   ;10-17
            DB 00H,21H,96H,9BH,97H,31H,32H,33H   ;18-1F
            DB 01H,22H,93H,82H,91H,37H,0CH,1FH   ;20-27
            DB 02H,23H,8AH,80H,8CH,7FH,1EH,0AH   ;28-2F
            DB 24H,85H,8FH,88H,20H,18H,0DH,3FH   ;30-37
            DB 03H,25H,8DH,90H,92H,1AH,19H,9AH   ;38-3F
            DB 04H,26H,83H,8EH,9CH,3EH,2AH,3DH   ;40-47
            DB 27H,98H,8BH,81H,08H,9DH,95H,20H   ;48-4F
            DB 28H,99H,84H,9EH,3CH,86H,87H,29H   ;50-57
                ;
                ; Русские малые
            DB 39H,38H,00H,00H,00H,34H,35H,36H      ;0-7
            DB 1BH,09H,00H,0EH,0FH,2BH,2DH,0DH      ;8-F
            DB 2BH,0A9H,0E4H,0EFH,00H,30H,2EH,2CH   ;10-17
            DB 00H,21H,0E6H,0EBH,0E7H,31H,32H,33H   ;18-1F
            DB 01H,22H,0E3H,0A2H,0E1H,37H,0CH,1FH   ;20-27
            DB 02H,23H,0AAH,0A0H,0ACH,7FH,1EH,0AH   ;28-2F
            DB 24H,0A5H,0AFH,0A8H,20H,18H,0DH,3FH   ;30-37
            DB 03H,25H,0ADH,0E0H,0E2H,1AH,19H,0EAH  ;38-3F
            DB 04H,26H,0A3H,0AEH,0ECH,3EH,2AH,3DH   ;40-47
            DB 27H,0E8H,0ABH,0A1H,08H,0EDH,0E5H,20H ;48-4F
            DB 28H,0E9H,0A4H,0EEH,3CH,0A6H,0A7H,29H ;50-57
                ;
                ; Псевдографика 1
            DB 39H,38H,00H,00H,00H,34H,35H,36H      ;0-7
            DB 1BH,09H,00H,0EH,0FH,2BH,2DH,0DH      ;8-F
            DB 2BH,0C9H,0CCH,0C8H,00H,30H,2EH,2CH   ;10-17
            DB 00H,21H,0CBH,0CEH,0CAH,31H,32H,33H   ;18-1F
            DB 01H,22H,0BBH,0B9H,0BCH,37H,0CH,1FH   ;20-27
            DB 02H,23H,0D6H,0C7H,0D3H,7FH,1EH,0AH   ;28-2F
            DB 24H,0D2H,0D7H,0D0H,20H,18H,0DH,3FH   ;30-37
            DB 03H,25H,0B7H,0B6H,0BDH,1AH,19H,0F0H  ;38-3F
            DB 04H,26H,0B0H,0DDH,0B2H,3EH,2AH,3DH   ;40-47
            DB 27H,0DFH,0FEH,0DCH,08H,0BAH,0CDH,20H ;48-4F
            DB 28H,0B1H,0DEH,0DBH,3CH,0FDH,0FBH,29H ;50-57
                ;
                ; Псевдографика 2
            DB 39H,38H,00H,00H,00H,34H,35H,36H      ;0-7
            DB 1BH,09H,00H,0EH,0FH,2BH,2DH,0DH      ;8-F
            DB 2BH,0DAH,0C3H,0C0H,00H,30H,2EH,2CH   ;10-17
            DB 00H,21H,0C2H,0C5H,0C1H,31H,32H,33H   ;18-1F
            DB 01H,22H,0BFH,0B4H,0D9H,37H,0CH,1FH   ;20-27
            DB 02H,23H,0D5H,0C6H,0D4H,7FH,1EH,0AH   ;28-2F
            DB 24H,0D1H,0D8H,0CFH,20H,18H,0DH,3FH   ;30-37
            DB 03H,25H,0B8H,0B5H,0BEH,1AH,19H,0F1H  ;38-3F
            DB 04H,26H,0F5H,0F7H,0F2H,3EH,2AH,3DH   ;40-47
            DB 27H,0F8H,0FFH,0F9H,08H,0B3H,0C4H,20H ;48-4F
            DB 28H,0F4H,0F6H,0F3H,3CH,0FCH,0FAH,29H ;50-57

                ;
                ;
                ; Таблица перекодировки ALT -> КОИ-8
ALTK8       DB 0E1H,0E2H,0F7H,0E7H,0E4H,0E5H,0F6H,0FAH ;А-З
            DB 0E9H,0EAH,0EBH,0ECH,0EDH,0EEH,0EFH,0F0H ;И-П
            DB 0F2H,0F3H,0F4H,0F5H,0E6H,0E8H,0E3H,0FEH ;Р-Ч
            DB 0FBH,0FDH,0FFH,0F9H,0F8H,0FCH,0E0H,0F1H ;Ш-Я
            DB 0C1H,0C2H,0D7H,0C7H,0C4H,0C5H,0D6H,0DAH ;а-з
            DB 0C9H,0CAH,0CBH,0CCH,0CDH,0CEH,0CFH,0D0H ;и-п
            DB 0B0H,0B1H,0B2H,0B3H,0B4H,0B5H,0B6H,0B7H ;графика
            DB 0B8H,0B9H,0BAH,0BBH,0BCH,0BDH,0BEH,0BFH
            DB 80H,81H,82H,83H,84H,85H,86H,87H
            DB 88H,89H,8AH,8BH,8CH,8DH,8EH,8FH
            DB 90H,91H,92H,93H,94H,95H,96H,97H
            DB 98H,99H,9AH,9BH,9CH,9DH,9EH,9FH
            DB 0D2H,0D3H,0D4H,0D5H,0C6H,0C8H,0C3H,0DEH ;р-ч
            DB 0DBH,0DDH,0DFH,0D9H,0D8H,0DCH,0C0H,0D1H ;ш-я
            DB 0A0H,0A1H,0A2H,0A3H,0A4H,0A5H,0A6H,0A7H ;спецсимволы
            DB 0A8H,0A9H,0AAH,0ABH,0ACH,0ADH,0AEH,0AFH

; ---------------------------------------------
; Опрос номеров нажатых клавиш
; Выход:
;   A - число нажатых клавиш
;   HL- адрес буфера с кодами клавиш
;   C - номер последней (по таблице) нажатой клавиши
;   если С=0FFh, то ни одна клавиша не нажата
; Особенности: данная пп формирует флаги клавиатуры CTRL, SHIFT, FIX в байте "KBFLAG"
;  при нажатии соответствующей клавиши (для МС7007 - еще и флаги ALF, GRF).
; ---------------------------------------------
NUMINK      LD HL,KBFLAG
            LD A,0xe0
            AND (HL)
            LD (HL),A
            XOR A
            LD HL,(BAZA)
            LD (HL),A
            INC HL
            EX DE,HL
            LD HL,POS1
            IN A,(0x0)
            AND KBD_TYPE
            JR NZ,NUM11
            LD C,0x0
NUM1
            LD A,L
            OUT (PORT_19_KBD),A
            LD A,H
            OUT (PORT_1A_KBD),A
            IN A,(PORT_18_KBD)
            CP 0xff
            JR Z,NUM7
            LD B,A
            LD A,(IKEYTM)
NUM2
            DEC A
            JR NZ,NUM2
            IN A,(PORT_18_KBD)
            CP B
            JR NZ,NUM7
            LD B,0x9
            DEC C
NUM3
            INC C
            DEC B
            JR Z,NUM8
            RRCA
            JR C,NUM3
            EX DE,HL
            LD (HL),C
            INC HL
            OR 0x80
            LD (HL),A
            EX DE,HL
            PUSH HL
            PUSH AF
            LD HL,KBFLAG
            LD A,C
            CP 0x4
            JR NZ,NUM4
            SET SHIFT,(HL)
NUM4        CP 0xa
            JR NZ,NUM5
            SET CTRL,(HL)
NUM5        CP 0x14
            JR NZ,NUM51
            SET FIX,(HL)
NUM51       CP 0xb
            JR NZ,NUM52
            SET GRF,(HL)
NUM52       CP 0xc
            JR NZ,NUM6
            SET ALF,(HL)
NUM6        LD HL,(BAZA)
            INC (HL)
            POP AF
            POP HL
            JR NUM3
NUM7        LD A,C
            ADD A,0x8
            LD C,A
NUM8                                                    ; db 0CBh
            SLL L                                       ; DEC (HL)
            RL H
            LD A,H
            CP 0xf7                                     ; Конец опроса?
            JR NZ,NUM1
NUM9        LD HL,(BAZA)
            EX DE,HL
            LD A,(DE)
            AND A
            LD C,0xff
            JR Z,NUM10
            DEC HL
            LD C,(HL)
NUM10       EX DE,HL
            INC HL
            RET

NUM11       LD HL,0x97f
            LD C,0x0
            IN A,(PORT_1A_KBD)
            OR 0x1f
            CP 0xff
            JR Z,NUM19
            JR NUM14
NUM12
            LD A,L
            OUT (PORT_18_KBD),A
            IN A,(PORT_19_KBD)
            CP 0xff
            JR Z,NUM19
            LD B,A
            LD A,(IKEYTM)
NUM13
            DEC A
            JR NZ,NUM13
            IN A,(PORT_19_KBD)
            CP B
            JR NZ,NUM19
NUM14
            LD B,0x9
            DEC C
NUM15
            INC C
            DEC B
            JR Z,NUM20
            RRCA
            JR C,NUM15
            EX DE,HL
            PUSH AF
            PUSH BC
            PUSH HL
            LD HL,KBFLAG
            LD A,C
            CP 0x5
            JR NZ,NUM16
            SET SHIFT,(HL)
NUM16
            CP 0x6
            JR NZ,NUM17
            SET CTRL,(HL)
NUM17
            CP 0x7
            JR NZ,NUM18        ;РУС/LAT?
            SET FIX,(HL)
NUM18
            LD HL,(BAZA)
            INC (HL)
            LD HL,TBNUM-5
            LD B,0x0
            ADD HL,BC
            LD A,(HL)
            POP HL
            LD (HL),A
            POP BC
            POP AF
            INC HL
            OR 0x80
            LD (HL),A
            EX DE,HL
            JR NUM15
NUM19
            LD A,C
            ADD A,0x8
            LD C,A
NUM20
            RLC L
            DEC H
            JR NZ,NUM12
            JR NUM9

; ---------------------------------------------
; Таблица перевода скан-кодов РК86 в скан-коды МС7007
; Начало таблицы = TBNUM-05H
; ---------------------------------------------
TBNUM       DB 4,0AH,14H                                    ; ss, us, rus/LAT
            DB 26H,27H,8,18H,20H,28H,38H,40H                ; 0-7
            DB 9,2FH,36H,2DH,4CH,3EH,35H,3DH                ; 8-F
            DB 4FH,19H,21H,29H,30H,39H,41H,48H              ; 10-17
            DB 50H,57H,46H,10H,54H,47H,45H,37H              ; 18-1F
            DB 53H,2BH,4BH,1AH,52H,31H,12H,42H              ; 20-27
            DB 4EH,33H,11H,2AH,4AH,2CH,3AH,43H              ; 28-2F
            DB 32H,13H,3BH,24H,3CH,22H,55H,23H              ; 30-37
            DB 44H,1BH,56H,49H,4DH,51H,1CH,34H              ; 38-3F
;
