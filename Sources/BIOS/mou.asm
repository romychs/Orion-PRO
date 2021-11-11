; =========================================
;
;  Модуль управления мышью для Orion-PRO
;
;  MOU01.AS  14.02.96
;  MOU02.AS  17.04.96
;  MOU.AS    25.04.97
;
; =========================================

MSCTL       LD A,IXL                        ; DB 0DDh, LD A,L
            OR A
            JP NZ,MSC1

; ---------------------------------------------
; Промежуточная функция перемещения курсора в окне
; Вход:
;   (MSX)    - координата X мыши
;   (MSY)    - координата Y мыши
;   (MSMODE) - режим отображения мыши
;   (MSPADR) - адрес шаблона мыши в сегменте
;   (MSPSEG) - сегмент шаблона мыши
;   (MSPH)   - высота шаблона мыши
;   (MSPL)   - ширина шаблона мыши
;   (MSPD)   - смещение шаблона мыши в пределах байта
;   (MSSTY)  - шаг мыши по Y
;   (MSSTX)  - шаг мыши по X
;   (MSBSEG) - 4 номера сегментов буфера сохранения
;   (MSBADR) - адрес буфера сохранения в сегментах
; Выход:
;  "CY" - указатель вне окна или переполнение буфера сохранения области экрана
;  иначе:
;   A - код нажатой кнопки:
;       80H - левая кнопка
;       40H - правая кнопка
;   (MSX)   - координата X мыши
;   (MSY)   - координата Y мыши
; Особенности: используются временные двухбайтовые ячейки (DMX),(DMY),(NDMX),(NDMY),(MSJ1)..(MSJ8)
;
INMS        CALL INM0                       ; Переустановить параметры курсора

            ; Вычисление шагов приращения координат
            LD HL,(MSSTY)
            PUSH HL
            LD H,0                          ; HL - шаг по Y
            LD (DMY),HL
            LD A,L
            DEC H
            NEG
            LD L,A
            LD (NDMY),HL
            POP HL
            LD L,H
            LD H,0                          ; HL - шаг по X
            LD (DMX),HL
            LD A,L
            DEC H
            NEG
            LD L,A
            LD (NDMX),HL
            
            ; Отображение указателя мыши
            LD BC,(MSY)
            LD DE,(MSX)
            LD A,NCURON
            CALL TVOUT
            JR NC,INM1
            LD A,NCUROF
            CALL TVOUT
            SCF
            JR INM7

            ; Ожидание отпускания кнопки мыши
INM1        CALL MOUSE
            BIT 4,A                         ; ЛКМ
            JR Z,INM1
            BIT 5,A                         ; ПКМ
            JR Z,INM1

            ; Ожидание отпускания клавиш клавиатуры
INM01       CALL STTS
            JR NZ,INM01

            ; Лвижение мыши до нажатия любой кнопки
INM2        CALL MSINK                      ; MOUSE + INKEY
            JR NC,INM2

            LD (MSY),BC
            LD (MSX),DE                     ; Сохранение текущих X,Y
            LD L,A
            LD A,NCUROF
            CALL TVOUT                      ; Погасить мышь
            LD A,L
            AND 0x30
            CP 0x30                         ; Нажаты кнопки?
            JR NZ,INM4                      ; Да
            LD A,L
            BIT 0x0,A
            CALL Z,MLEFT
            BIT 0x1,A
            CALL Z,MRIGHT
            BIT 0x2,A
            CALL Z,MDOWN
            BIT 0x3,A
            CALL Z,MUP
            LD A,NCURON
            CALL TVOUT                      ; Отобразить мышь
            JR NC,INM2                      ; Норма. В окне
            ; Выход за пределы окна
            LD BC,(MSY)
            LD DE,(MSX)                     ; Прежние координаты
            LD A,NCURON                     ; Отображение мыши на старом месте
            CALL TVOUT
            JR INM2

INM4        XOR A
            BIT 4,L
            JR NZ,INM5
            SET 7,A
INM5        BIT 5,L
            JR NZ,INM6
            SET 6,A
INM6        OR A

            ; Восстановление параметров курсора
INM7        PUSH AF
            LD BC,(MSJ6)
            LD DE,(MSJ7)
            LD HL,(MSJ8)
            LD A,NCURBS                     ; адрес буфера
            CALL TVOUT
            LD BC,(OPER2)
            LD HL,(MSJ5)
            LD A,NCURPS                     ; адрес шаблона
            CALL TVOUT
            LD BC,(MSJ1)
            LD DE,(MSJ2)
            LD HL,(OPER1)
            LD A,NCURSS                     ; размеры
            CALL TVOUT
            LD C,H
            LD A,NCURMS                     ; режим курсора
            CALL TVOUT
            POP AF
            RET

; ----------------------------------------------
; Мышь влево
; ----------------------------------------------
MLEFT       LD HL,(NDMX)
            ADD HL,DE
            EX DE,HL
            RET

; ----------------------------------------------
; Мышь вправо
; ----------------------------------------------
MRIGHT      LD HL,(DMX)
            ADD HL,DE
            EX DE,HL
            RET

; ----------------------------------------------
; Мышь вниз
; ----------------------------------------------
MDOWN       LD HL,(DMY)
            ADD HL,BC
            LD B,H
            LD C,L
            RET

; ----------------------------------------------
; Мышь вверх
; ----------------------------------------------
MUP         LD HL,(NDMY)
            ADD HL,BC
            LD B,H
            LD C,L
            RET

; ----------------------------------------------
; Процедура опроса мыши и клавиатуры
; Выход:
;  "CY" - нажата кнопка или перемещение мыши
;  A   - код мыши
; ----------------------------------------------
MSINK       CALL MOUSE                      ; Опрос мыши
            AND 0x3F
            CP 0x3F
            SCF
            RET NZ                          ; Мышь сработала
            LD HL,0x200                     ; Пауза
MSINK0      DEC HL
            LD A,H
            OR L
            JR NZ,MSINK0
            CALL INFST                      ; Опрос клавиш курсора
            AND 0xF0
            JR NZ,MSINK1
            
            ; Клавиши курсора не нажаты, значит ВК или АР2
            CALL INKEY
            LD L,0x1F
            CP 0x0D                         ; ВК?
            JR Z,MSINK5
            LD L,0x2F
            CP 0x1B                         ; AP2?
            JR Z,MSINK5
            XOR A
            RET

MSINK1      LD L,0x3F
            BIT 4,A                         ; Влево?
            JR Z,MSINK2
            RES 0,L

MSINK2      BIT 5,A                         ; Вверх?
            JR Z,MSINK3
            RES 3,L
MSINK3      BIT 6,A                         ; Вправо?
            JR Z,MSINK4
            RES 1,L
MSINK4      BIT 7,A                         ; Вниз?
            JR Z,MSINK5
            RES 2,L
MSINK5      LD A,L
            SCF
            RET

; ----------------------------------------------
; Переустановка параметров курсора
; ----------------------------------------------
INM0        LD A,NCURMR
            CALL TVOUT                      ; Режим курсора

            LD H,C
            LD A,NCURSR
            CALL TVOUT                      ; Размеры курсора

            LD (MSJ1),BC
            LD (MSJ2),DE
            LD (OPER1),HL
            LD A,NCURPR
            CALL TVOUT                      ; Адрес шаблона

            LD (OPER2),BC
            LD (MSJ5),HL
            LD A,NCURBR                     ; Адрес буфера сохр. инф. под курсором
            CALL TVOUT

            LD (MSJ6),BC
            LD (MSJ7),DE
            LD (MSJ8),HL

            ; Установка параметров стрелки мыши
            CALL GETMMD
            LD A,NCURMS
            CALL TVOUT                      ; Установка размера мыши
            
            CALL GETMSZ
            LD BC,0
            LD A,NCURSS
            CALL TVOUT                      ; Размер шаблона мыши

            CALL GETMPA
            LD A,NCURPS
            CALL TVOUT                      ; Адрес шаблона

            CALL GETMBA
            LD A,NCURBS
            JP TVOUT                        ; Буфер для сохранения

MSC1        DEC A
            JR NZ,MSC2

; ----------------------------------------------
; Установка режима вывода мыши
; ----------------------------------------------
SETMMD      LD A,C
            LD (MSMODE),A
            RET

MSC2        DEC A
            JR NZ,MSC3

; ----------------------------------------------
; Получение режима вывода мыши
; ----------------------------------------------
GETMMD      LD A,(MSMODE)
            LD C,A
            RET

MSC3        DEC A
            JR NZ,MSC4

; ----------------------------------------------
; Установка размеров указателя мыши
; ----------------------------------------------
SETMSZ      LD (MSPH),DE
            LD (MSSTY),BC
            LD A,L
            LD (MSPD),A
            RET

MSC4        DEC A
            JR NZ,MSC5

; ----------------------------------------------
; Получение размеров указателя мыши
; ----------------------------------------------
GETMSZ      LD DE,(MSPH)
            LD BC,(MSSTY)
            LD A,(MSPD)
            LD L,A
            RET

MSC5        DEC A
            JR NZ,MSC6

; ----------------------------------------------
; Установка адреса шаблона мыши
; ----------------------------------------------
SETMPA      LD (MSPADR),HL
            LD A,C
            LD (MSPSEG),A
            RET

MSC6        DEC A
            JR NZ,MSC7

; ----------------------------------------------
; Получение адреса шаблона мыши
; ----------------------------------------------
GETMPA      LD HL,(MSPADR)
            LD A,(MSPSEG)
            LD C,A
            RET

MSC7        DEC A
            JR NZ,MSC8

; ----------------------------------------------
; Установка адреса буфера сохранения для мыши
; ----------------------------------------------
SETMBA      LD (MSBADR),HL
            LD (MSBSEG),BC
            LD (MSBSEG+2),DE
            RET

MSC8        DEC A
            JR NZ,MSC9

; ----------------------------------------------
; Получение адреса буфера сохранения для мыши
; ----------------------------------------------
GETMBA      LD HL,(MSBADR)
            LD BC,(MSBSEG)
            LD DE,(MSBSEG+2)
            RET

MSC9        DEC A
            RET NZ

; ----------------------------------------------
; Определение длины буфера для сохранения
; ----------------------------------------------
GETMLN      PUSH BC
            PUSH HL
            CALL INM0
            LD A,NCURLN
            CALL TVOUT
            PUSH DE
            CALL INM7
            POP DE
            POP HL
            POP BC
            RET

; ===================
; Конец драйвера мыши
; ===================
