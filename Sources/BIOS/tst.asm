; =======================================
;    Модуль тестирования компьютера 
;    TST02.AS  21.05.96
;    TST03.AS  05.06.96
;    TST.AS    01.06.97
;      V2.10 17.04.00
; =======================================

TSTST       EQU TSTR2>=0x8000               ; Признак отладки

            ; Ожидание нажатия клавиш
WAIT_KEY    CALL STTS
            JR NZ,WAIT_KEY

WT1         CALL INKEY
            JR C,WT1
            PUSH AF
            CALL BEEP

WT2         CALL STTS
            JR NZ,WT2
            POP AF
            CP 0x3
            SCF
            RET Z
            CP 0x1b
            SCF
            RET Z
            OR A
            RET

; ---------------------------------------------
; Вывод большой рамки
; ---------------------------------------------
BIGFRM
            LD C,0x1f
            CALL TVSYM
            LD BC,0x0
            LD E,C
            LD D,C
            CALL UGOL
            LD A,0xd
            LD C,0xff
            LD DE,0x17f
            CALL TVGRF
            LD C,0x2
            LD DE,0x3
            PUSH DE
            CALL UGOL
            LD A,0xd
            LD BC,0xfd
            LD DE,0x17c
            CALL TVGRF
            POP DE
            LD BC,27
            CALL UGOL
            LD DE,380
LINEX
            LD A,7
            LD L,R2SEG
            JP TVGRF
UGOL
            LD A,0x5
            JP TVGRF

; ---------------------------------------------
; Очистка средней части экрана
; ---------------------------------------------
WINCLR
            LD BC,0xb432
            LD DE,0x14
            LD HL,0x154
            CALL SETWIN ;undefined SETWIN()
            LD A,0x12
            CALL TVSCR
FULSCR
            LD BC,0x0
            LD E,C
            LD D,C
            LD HL,0x180

SETWIN
            LD A,0x10
            JP TVSCR
INVON       DB -1BH,-'6',0
INVOF       DB -1BH,-'7',0
CUROH       DB -1BH,-'<',0
CUROF       DB -1BH,-';',0

;Вывод пункта меню
PUNKT
            PUSH BC
            PUSH HL
            LD L,(IX+R2SEG)
            LD H,(IX+0x2)
            LD E,(IX+0x3)
            LD D,(IX+0x4)
            INC C
PNKT1
            DEC C
            JR Z,PNKT3
            EX DE,HL
PNKT2
            LD B,(HL)
            INC HL
            INC B
            DJNZ PNKT2
            EX DE,HL
            INC H
            JR PNKT1
PNKT3
            PUSH AF
            CALL SCUR
            POP AF
            OR A
            LD HL,INVON
            CALL NZ,MSGXX
            EX DE,HL
            CALL MSGXX
            LD HL,INVOF
            CALL MSGXX
            POP HL
            POP BC
            RET
MENU
            LD B,(IX+0x0)
            LD C,0x0
MNU1        XOR A
            CALL PUNKT
            INC C
            DJNZ MNU1
            ;
MNU2        LD C,(HL)
            LD A,0xff
            CALL PUNKT
            PUSH HL
            LD HL,CUROF
            CALL MSGXX
            CALL KBRD
            PUSH AF
            LD HL,CUROH
            CALL MSGXX
            XOR A
            CALL PUNKT
            POP AF
            POP HL
            CP 0x1B
            SCF
            RET Z
            ;
            CP 0x3
            SCF
            RET Z
            ;
            CP 0xd
            JR NZ,MNU3
            LD A,(HL)
            ADD A,A
            LD E,A
            LD D,0x0
            LD L,(IX+0x5)
            LD H,(IX+0x6)
            ADD HL,DE
            LD A,(HL)
            INC HL
            LD H,(HL)
            LD L,A
            CALL PCHL
            OR A
            RET

PCHL        JP (HL)
            ;
MNU3        LD DE,MNU2
            PUSH DE
            ;
            CP 0x19
            JR NZ,MNU4
            ;
            DEC (HL)
            RET P
            LD A,(IX+0)
            DEC A
            LD (HL),A
            RET
            ;
MNU4        CP 0x1A
            RET NZ
            INC (HL)
            LD A,(IX+0)
            CP (HL)
            RET NZ
            LD (HL),0x00
            RET

TEST        CALL BIGFRM
            LD HL,TIT2
            CALL MSGXX
            LD BC,99
            LD DE,126
            CALL UGOL
            LD A,0xd
            LD BC,0xa9
            LD DE,0x107
            CALL TVGRF
            LD IX,MENU2
            LD HL,POS2
            CALL MENU
            JR NC,TEST
            RET

CONF        CALL WINCLR
            LD C,0x4f
            LD B,0x6e
            LD DE,0x72
            LD HL,0x9e
            CALL SETWIN
DRWFRAM     LD BC,0x0
            LD E,C
            LD D,C
            CALL UGOL
            LD A,0xd
            LD BC,0x6d
            LD DE,0x9d
            PUSH DE
            CALL TVGRF
            LD BC,0x14
            LD E,B
            LD D,B
            CALL UGOL
            POP DE
            CALL LINEX
            LD BC,0x6854
            LD DE,0x85
            LD HL,0x80
            CALL SETWIN
            LD HL,CFGMSG
            CALL MSGXX
            CALL OUTCFG
            CALL WAIT_KEY
            JP FULSCR
OUTCFG      IN A,(PORT_00_DIPSW)
            LD C,0xff
            CALL OUTDIP
            BIT 0x0,A
            LD B,0x0
            JR Z,CNF1
            INC B
CNF1        CALL OUTPOS
            CALL OUTDIP
            BIT 0x1,A
            LD B,0x0
            JR Z,CNF2
            INC B
CNF2        CALL OUTPOS
            CALL OUTDIP
            BIT 0x2,A
            LD B,0x3
            JR Z,CNF3
            DEC B
CNF3        CALL OUTPOS
            CALL OUTDIP
            BIT 0x3,A
            PUSH BC
            LD C,0x32
            JR Z,CNF4
            DEC C
CNF4        PUSH AF
            CALL SPC
            POP AF
            CALL TVSYM
            POP BC
            CALL OUTDIP
            BIT 0x4,A
            LD B,0x0
            JR Z,CNF5
            INC B
CNF5        CALL OUTPOS
            CALL OUTDIP
            BIT 0x5,A
            LD B,0x0
            JR Z,CNF6
            INC B
CNF6        CALL OUTPOS
            CALL OUTDIP
            BIT 0x6,A
            LD B,0x4
            JR Z,CNF7
            INC B
CNF7        CALL OUTPOS
            CALL OUTDIP
            BIT 0x7,A
            LD B,0x7
            JR Z,OUTPOS
            DEC B
OUTPOS      PUSH AF
            CALL SPC
            POP AF
            PUSH BC
            PUSH AF
            LD HL,SELMSG
            LD A,B
            ADD A,A
            ADD A,A
            ADD A,B
            LD B,0x5
            JR RSL0
OUTDIP      PUSH AF
            CALL HDLN
            POP AF
            INC C
            PUSH BC
            PUSH AF
            LD B,0xe
            LD HL,DIPMSG
            LD A,C
            LD E,A
            ADD A,A
            ADD A,A
            ADD A,A
            ADD A,A
RSL0        LD E,A
            LD D,0x0
            ADD HL,DE
RSL1        LD A,(HL)
            NEG
            LD C,A
            CALL TVSYM
            INC HL
            DJNZ RSL1
            POP AF
            POP BC
            RET

CFGMSG      DB -' ',-' ',-' ',-'C',-'O',-'N'
            DB -'F',-'I',-'G',-'U',-'R',-'A',-'T',-'I',-'O'
            DB -'N',-0DH,-0AH,0
            ;
SELMSG      DB -'Y',-'e',-'s',-' ',-' '
            DB -'N',-'o',-' ',-' ',-' '
            DB -'P',-'K',-'-',-'8',-'6'
            DB -'M',-'7',-'0',-'0',-'7'
            DB -'R',-'O',-'M',-'-',-'2'
            DB -'R',-'O',-'M',-'-',-'D'
            DB -'O',-'R',-'D',-'O',-'S'
            DB -'C',-'P',-'M',-'8',-'0'
            ;
DIPMSG      DB -'1',-' ',-'F',-'l',-'o',-'p',-'p',-'y',-' '
            DB -'d',-'r',-'i',-'v',-'e',-' ',-'-'           ;14
            DB -'2',-' ',-'H',-'a',-'r',-'d',-' ',-'d',-'r'
            DB -'i',-'v',-'e',-' ',-' ',-' ',-'-'
            DB -'3',-' ',-'K',-'e',-'y',-'b',-'o',-'a',-'r'
            DB -'d',-' ',-' ',-' ',-' ',-' ',-'-'
            DB -'4',-' ',-'P',-'a',-'g',-'e',-' ',-'C',-'P',-'/'
            DB -'M',-'-',-'8',-'0',-' ',-'-'
            DB -'5',-' ',-'E',-'x',-'t',-'.',-'d',-'i',-'s'
            DB -'p',-'l',-'a',-'y',-' ',-' ',-'-'
            DB -'6',-' ',-'S',-'t',-'a',-'r',-'t',-'-',-'M'
            DB -'e',-'n',-'u',-' ',-' ',-' ',-'-'
            DB -'7',-' ',-'L',-'o',-'a',-'d',-' ',-'O',-'R'
            DB -'D',-'O',-'S',-' ',-' ',-' ',-'-'
            DB -'8',-' ',-'S',-'y',-'s',-'t',-'e',-'m',-' '
            DB -' ',-' ',-' ',-' ',-' ',-' ',-'-'

; ---------------------------------------------
; Тест ОЗУ
; ---------------------------------------------
TSTRAM      CALL WINCLR
            LD BC,0x37
            LD DE,0x46
            PUSH DE
            CALL UGOL
            LD BC,0xd7
            LD DE,0x13e
            LD A,0xd
            CALL TVGRF
            LD BC,0x4b
            CALL UGOL
            POP DE
            CALL LINEX
            LD BC,0xc3
            CALL UGOL
LAB_ram_09c4

            LD DE,0x13e
            CALL LINEX
            LD HL,RAMMSG
            CALL MSGXX
                ; отображение на экране DD-номеров ИМС
            LD BC,0x1000
            LD DE,IMSCOD
RAMT1
            LD H,8
            LD A,C
            CP 8
            JR C,RAMT2
            LD H,14
            SUB 8
RAMT2
            ADD A,A
            ADD A,A
            ADD A,0x11
            LD L,A
            CALL SCUR
            LD A,'D'
            CALL TVA
            LD A,(DE)
            CALL HEX_OUT
            INC DE
            INC C
            DJNZ RAMT1
            LD IX,IMSADR
RAMT3
            LD L,(IX+0x0)
            LD H,(IX+0x1)
            INC IX
            INC IX
            LD A,L
            OR H
            JR Z,RAMT7
            LD DE,GODIMS
            LD C,0x20
RAMT4
            LD A,(DE)
            OR A
            JR Z,RAMT3
            LD B,A
            INC DE
            LD A,(DE)
RAMT5
            LD (HL),A
            INC L
            DEC C
            JR NZ,RAMT6
            LD C,0x20
            INC H
            LD A,L
            SUB C
            LD L,A
            LD A,(DE)
RAMT6
            DJNZ RAMT5
            INC DE
            JR RAMT4
RAMT7
            LD HL,SCLADR
            LD C,17
RAZM1
            LD B,0x8
RAZM2
            LD (HL),0x0
            LD A,B
            CP 0x4
            JR NZ,RAZM3
            LD (HL),0xAA
RAZM3
            INC L
            DJNZ RAZM2
            LD L,0xC9
            INC H
            DEC C
            JR NZ,RAZM1

            ; Начало теста ОЗУ
            IN A,(PORT_0A_MEM_CFG)
            SET RAM1_WND,A                  ; Окно открыть
            OUT (PORT_0A_MEM_CFG),A
            db 0FDh
            LD H,0                          ; HY = константа заполнения
RAMT8
            db 0FDh
            LD L,0                          ; LY = номер сегмента
RAMT9
            db 0FDh
            LD A,L                          ; A=LY
            CP 0x20
            JR NC,RAMT11
            OUT (PORT_05_RAM1P),A
            CP 0x3
            JR Z,RAMT10
            CP 0x1f
            JR Z,RAMT10
   			;
			IF TSTST
				CP 12
				JR C,RAMT10
			ENDIF
			;
            LD HL,0x4000
            LD DE,0x4001
            db 0FDh
            LD A,H                          ; A=HY
            LD (HL),A
            ;
            IF TSTST
                IN A,(PORT_05_RAM1P)
                CP 13; 20
                JR NZ,XXX
                LD A,(HL)
                OR 12H
                LD (HL),A
XXX
            ENDIF
            LD BC,0x3fff
            LDIR

            ; Отображение факта заполнения сегмента
RAMT10
            LD HL,SCLADR
SCAL1
            LD A,(HL)
            AND 0x1
            JR Z,SCAL2
            INC H
            JR SCAL1
SCAL2       LD A,IYL                        ; db 0FDh, LD A,L
            AND 0x7
            INC A
            LD B,A
            LD A,0x1
SCAL3       RRCA
            DJNZ SCAL3
            LD C,A
            LD B,0x8
SCAL4       LD A,(HL)
            OR C
            LD (HL),A
            INC L
            DJNZ SCAL4
            IN A,(0x0)
            AND 0x4
            JR Z,KSTAT2
            XOR A
            OUT (PORT_18_KBD),A
            IN A,(PORT_19_KBD)
            XOR 0xff
            JR Z,KSTAT3
KSTAT1      CALL BEEP
            CALL WAIT_KEY
            JR NC,KSTAT3
            RET
KSTAT2      XOR A
            OUT (PORT_1A_KBD),A
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            INC A
            JR NZ,KSTAT1
KSTAT3      INC IYL                         ; db 0FDh, INC L
            JR RAMT9
RAMT11      LD IYL,0                        ; db 0FDh, LD L,0
            
            ; Проверка очередного сегмента
RAMT12      LD A,IYL                        ; db 0FDh, LD A,L
            CP 0x20
            JP NC,RAMT22
            OUT (PORT_05_RAM1P),A
            CP 0x3
            JP Z,RAMT21
            CP 0x1f
            JP Z,RAMT21
			;
			IF TSTST
				CP 12   
				JP C,RAMT21
			ENDIF
			;
            LD HL,0x4000
            LD B,H
            LD C,L
            LD E,IYH                        ; db 0FDh, LD E,H
RAMT13      LD A,(HL)
            XOR E
            JP Z,RAMT20
            EXX
            LD C,A
            LD E,0x0
            LD B,0x8
            IN A,(PORT_05_RAM1P)
            BIT 0x2,A
            JR Z,RAMT14
            LD E,0x10
RAMT14      RRC C
            JR NC,RAMT19
            LD HL,IMSADR
            LD D,0x0
            ADD HL,DE
            LD A,(HL)
            INC HL
            LD H,(HL)
            LD L,A
            INC L
            LD A,(HL)
            DEC L
            AND 0x7f
            JR NZ,RAMT19
            LD IYL,E                        ; db 0FDh, LD L,E
            LD IXL,C                        ; db 0DDh, LD L,C
            LD IXH,B                        ; db 0DDh, LD H,B
            LD DE,BADIMS
            LD C,0x20
RAMT15      LD A,(DE)
            OR A
            JR Z,RAMT18
            LD B,A
            INC DE
            LD A,(DE)
RAMT16      LD (HL),A
            INC L
            DEC C
            JR NZ,RAMT17
            LD C,0x20
            INC H
            LD A,L
            SUB C
            LD L,A
            LD A,(DE)
RAMT17      DJNZ RAMT16
            INC DE
            JR RAMT15
RAMT18      LD E,IYL                        ; db 0FDh, LD E,L
            LD C,IXL                        ; db 0DDh, LD C,L
            LD B,IXH                        ; db 0DDh, LD B,H
            IN A,(PORT_05_RAM1P)
            LD IYL,A                        ; db 0FDh, LD L,A
RAMT19      INC E
            INC E
            DEC B
            JP NZ,RAMT14
            EXX
RAMT20      INC HL
            DEC BC
            LD A,B
            OR C
            JP NZ,RAMT13
RAMT21      LD HL,SCLADR
SCAL5       LD A,(HL)
            AND 0x1
            JR Z,SCAL6
            INC H
            JR SCAL5
SCAL6       LD A,IYL                        ; db 0FDh, LD A,L
            AND 0x7
            INC A
            LD B,A
            LD A,0x1
SCAL7       RRCA
            DJNZ SCAL7
            LD C,A
            LD B,0x8
SCAL8       LD A,(HL)
            OR C
            LD (HL),A
            INC L
            DJNZ SCAL8
            IN A,(0x0)
            AND 0x4
            JR Z,KSTAT4
            XOR A
            OUT (PORT_18_KBD),A
            IN A,(PORT_19_KBD)
            XOR 0xff
            JR Z,KSTAT5
KSTAT6      CALL BEEP
            CALL WAIT_KEY
            JR NC,KSTAT5
            RET
KSTAT4      XOR A
            OUT (PORT_1A_KBD),A
            OUT (PORT_19_KBD),A
            IN A,(PORT_18_KBD)
            INC A
            JR NZ,KSTAT6
KSTAT5      INC IYL                         ; db 0FDh, INC L
            JP RAMT12
RAMT22      LD A,IYH                        ; db 0FDh, LD A,H
            CPL
            LD IYH,A                        ; db 0FDh, LD H,A
            OR A
            JP NZ,RAMT8
            LD HL,SCLADR+16*256
            LD B,0x8
            LD A,0xFC
RAMT23
            LD (HL),A
            INC L
            DJNZ RAMT23
            LD HL,0xF000
RAMT24
            DEC HL
            LD A,H
            OR L
            JR NZ,RAMT24
            XOR A
            OUT (PORT_05_RAM1P),A
            IN A,(PORT_0A_MEM_CFG)
            RES 0x1,A
            OUT (PORT_0A_MEM_CFG),A
            JP RAMT7                        ; продолжить тестирование

;
; Таблица кодов ИМС (DD..) в экранном порядке
IMSCOD      DB 70H,60H,61H,59H,73H,65H,62H,64H
            DB 52H,71H,54H,57H,63H,74H,72H,53H
;
ANI         EQU 0xCD5E                          ; Адрес начала изображений ИМС на экране
SCLADR      EQU ANI + 0x036B                    ; Адрес шкалы на экране


; Таблица адресов ИМС на экране по номеру разряда
IMSADR      DW ANI + 0x063C, ANI + 0x0600, ANI + 0x033C, ANI + 0x0300  ; Банк 1
            DW ANI + 0x093C, ANI + 0x0900, ANI + 0x0000, ANI + 0x003C
            DW ANI + 0x153C, ANI + 0x1500, ANI + 0x0F00, ANI + 0x0F3C  ; Банк 2
            DW ANI + 0x0C3C, ANI + 0x0C00, ANI + 0x1200, ANI + 0x123C
            DW 0
;
; Изображение хорошей ИМС
GODIMS      DB 1,0FFH,26,80H,1,83H,3,84H,2,0FFH
            DB 26,01H,1,0C1H,3,21H,1,0FFH,0
;
; Изображение неисправной ИМС
BADIMS      DB 27,0FFH,1,0FCH,2,0FBH,1,0F8H
            DB 28,0FFH,1,3FH,2,0DFH,1,1FH,1,0FFH,0
;
RAMMSG      DB -1BH,-'Y',-26H,-3CH
            DB -'R',-'A',-'M',-' ',-'T',-'E',-'S',-'T',0

; ---------------------------------------------
; Тест ROM
; ---------------------------------------------
TSTROM
            CALL WINCLR
                ; рисуем окно
            LD BC,0x73
            LD DE,0x74
            PUSH DE
            CALL UGOL
            LD A,0xd
            LD BC,0xa2
            LD DE,0x0111
            CALL TVGRF
            LD BC,0x87
            CALL UGOL
            POP DE
            CALL LINEX
TROM1
            LD HL,ROMMSG
            CALL MSGXX
            CALL CSROM2
            PUSH HL                         ; Контрольная сумма ROM2
            CALL HEX_OUT                     ; Объем ROM2 TODO: это дб вызов HEX
            CALL CSROM1                     ; BC = Контрольная сумма
            POP DE
            LD HL,0x0E21                    
            PUSH HL
            CALL SCUR
            LD A,B
            CALL HEX_OUT
            LD A,C
            CALL HEX_OUT
            POP HL
            INC H
            CALL SCUR
            LD A,D
            CALL HEX_OUT
            LD A,E
            CALL HEX_OUT
            LD BC,0x1000
TROM2
            CALL KB_STTS                    ; Получение статуса клавиатуры
            JR Z,TROM3
            CALL BEEP
            JP WAIT_KEY
TROM3
            DEC BC
            LD A,B
            OR C
            JR NZ,TROM2
            JR TROM1

ROMMSG      DB -1BH,-'Y',-2CH,-3DH,-'R',-'O',-'M',-' '
            DB -'T',-'E',-'S',-'T'
            DB -1BH,-'Y',-2EH,-37H,-'R',-'O',-'M',-'1',-' '
            DB -'C',-'S',-':',-' ',-' ',-' ',-' ',-' ',-' '
            DB -' ',-'(',-' ',-'8',-'K',-')'
            DB -1BH,-'Y',-2FH,-37H,-'R',-'O',-'M',-'2',-' '
            DB -'C',-'S',-':',-' ',-' ',-' ',-' ',-' ',-' '
            DB -' ',-'(',-' ',-' ',-'K',-')',-8,-8,-8,-8,0

; ---------------------------------------------
; TV-Тест
; ---------------------------------------------
TVTEST
            LD A,0x2
            OUT (PORT_F8_VMODE),A
            LD DE,COLTAB
            LD HL,SCR_C000
TVT1        LD B,3
TVT2        LD (HL),0xff
            LD A,(DE)
            LD C,A
            LD A,1
            CALL WRAM            ; Запись байта в расширенную страницу
            INC L
            JR NZ,TVT2
            INC H
            LD A,H
            CP 0xF0
            JR Z,TVT3
            DJNZ TVT2
            INC DE
            JR TVT1
            ; Монохромная палитра
TVT3        LD BC,0x1000
TVT4        LD A,C
            RLCA
            RLCA
            RLCA
            RLCA
            OR C
            OUT (PORT_E0_PAL_R),A
            OUT (PORT_E1_PAL_G),A
            OUT (PORT_E2_PAL_B),A
            INC C
            DJNZ TVT4
            LD A,6
            OUT (PORT_F8_VMODE),A
            CALL WAIT_KEY
            JR C,TVT5
            ; цветная палитра
            CALL INITPAL
            CALL WAIT_KEY
            ;
TVT5        LD A,0x0F
            OUT (PORT_F8_VMODE),A
            RET

COLTAB      DB 0,8,1,9,4,12,5,13,2,10,3,11,6,14,7,15

; ---------------------------------------------
; Контрольная сумма ROM
; ---------------------------------------------
CSROM1
            LD HL,0x0
            LD DE,0x1fff
CSM
            EX DE,HL
            PUSH HL
            LD A,L
            LD HL,0x0
            JR CSM2
CSM1
            EX DE,HL
            LD B,(HL)
            LD C,B
            INC HL
            EX DE,HL
            ADD HL,BC
CSM2
            CP E
            JR NZ,CSM1
            POP BC
            PUSH BC
            LD A,B
            CP D
            LD A,C
            JR NZ,CSM1
            LD A,(DE)
            ADD A,L
            LD C,A
            LD B,H
            POP HL
            RET

; ---------------------------------------------
; Контрольная сумма ROM2
; ---------------------------------------------
CSROM2
            LD HL,0x2008
            LD C,0x4
            CALL TSTR2
            LD B,0x8
            LD A,0x64
            JR NZ,CSR21
            LD B,0x4
            LD A,0x32
CSR21
            PUSH AF
            LD DE,0x4000
            XOR A
            LD (DE),A
            LD C,A
            LD L,A
            LD H,A
            IN A,(PORT_0A_MEM_CFG)
            PUSH AF
            SET 0x3,A
            OUT (PORT_0A_MEM_CFG),A
CSR22
            LD A,B
            DEC A
            JR NZ,CSR23
            DEC DE
CSR23
            LD A,C
            OUT (PORT_09_ROM2_SEG),A
            PUSH BC
            PUSH DE
            PUSH HL
            LD HL,0x2000
            CALL CSM
            POP HL
            ADD HL,BC
            POP DE
            POP BC
            INC C
            DJNZ CSR22
            POP AF
            OUT (PORT_0A_MEM_CFG),A
            POP AF
            RET
MENU1
            DB 4h                                   ; Число режимов меню
            DB 1Bh                                  ; X пунктов меню
            DB 0Bh                                  ; Y первого пнкта
            DW MMSG1                                ; Адрес сообщения с названием пунктов
            DW MADR1                                ; Таблица адресов обработки
;
; Названия пунктов главного меню
MMSG1       DB -' ',-' ',-'M',-'o',-'n',-'i',-'t',-'o',-'r',-' ',-' ',0
            DB -' ',-'O',-'r',-'i',-'o',-'n',-'-',-'P',-'R',-'O',-' ',0
            DB -' ',-'O',-'r',-'i',-'o',-'n',-'-',-'1',-'2',-'8',-' ',0
            DB -' ',-' ',-'T',-' ',-'E',-' ',-'S',-' ',-'T',-' ',-' ',0
;
; адреса обработчиков пунктов главного меню
MADR1       DW MON_UR,MNT3,MON128,TEST

;
;Описание меню тестов
MENU2       DB 5                                    ; Число режимов меню
            DB 25                                   ; X пунктов меню
            DB 11                                   ; Y первого пунка
            DW MMSG2                                ; адрес сообщения с названиями пунктов
            DW MADR2                                ; таблица адресов обработки
;
MMSG2       DB -' ',-'C',-'o',-'n',-'f',-'i',-'g',-'u',-'r',-'a',-'t',-'i',-'o',-'n',-' ',0
            DB -' ',-'R',-'A',-'M',-' ',-'-',-' ',-'T',-' ',-'e',-' ',-'s',-' ',-'t',-' ',0
            DB -' ',-'R',-'O',-'M',-' ',-'-',-' ',-'T',-' ',-'e',-' ',-'s',-' ',-'t',-' ',0
            DB -' ',-'T',-'V',-' ',-' ',-'-',-' ',-'T',-' ',-'e',-' ',-'s',-' ',-'t',-' ',0
            DB -' ',-' ',-' ',-'M',-'a',-'i',-'n',-' ',-'M',-'e',-'n',-'u',-' ',-' ',-' ',0
;
; Адреса обработчиков пунктов меню тестов
MADR2       DW CONF,TSTRAM,TSTROM,TVTEST,MAIN

;
TIT1        DB -1BH,-59H,-21H,-22H
            DB -'(',-'C',-')',-' ',-'1',-'9',-'9',-'3',-'-',-'2'
            DB -'0',-'0',-'0',-' ',-'O',-'r',-'i',-'o',-'n'
            DB -'s',-'o',-'f',-'t',-' ',-'C',-'o',-'.',-','
            DB -'L',-'t',-'d',-1BH,-59H,-21H,-4FH
            DB -'O',-'r',-'i',-'o',-'n',-'-',-'P',-'r',-'o'
            DB -' ',-'V',-'3',-'.',-'1',-'0',0
;
TIT2        DB -1BH,-59H,-21H,-35H,-'*',-' ',-'T'
            DB -'E',-'S',-'T',-' ',-'O',-'R',-'I',-'O',-'N',-'-'
            DB -'P',-'R',-'O',-' ',-'*',0
;

