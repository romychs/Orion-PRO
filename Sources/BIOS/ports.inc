;==============================
; Порты Ориона-128 и Ориона-ПРО
;==============================

PORT_00_DIPSW           EQU 0x00
PORT_01_PRNT_DAT        EQU 0x01
PORT_02_PRNT_CTL        EQU 0x02
PORT_03_CTL             EQU 0x03

PORT_04_RAM0P           EQU 0x04
PORT_05_RAM1P           EQU 0x05
PORT_06_RAM2P           EQU 0x06
PORT_07_CTL             EQU 0x07

PORT_08_RAM_PG          EQU 0x08
PORT_09_ROM2_SEG        EQU 0x09
PORT_0A_MEM_CFG         EQU 0x0A
PORT_0B_CTL             EQU 0x0B

PORT_10_VG_CMD          EQU 0x10
PORT_11_VG_TRK          EQU 0x11
PORT_12_VG_SECT         EQU 0x12
PORT_13_VG_DATA         EQU 0x13
PORT_14_VG_CTL          EQU 0x14


; Порты клавиатуры
PORT_18_KBD             EQU 0x18        ; F400 - port KBRD
PORT_19_KBD             EQU 0x19
PORT_1A_KBD             EQU 0x1A
PORT_1B_CTL             EQU 0x1B

; Мультикарта
PORT_1D_MCARD_CTL       EQU 0x1d
PORT_1E_MOUSE           EQU 0x1e

; ROM-диск
PORT_28_ROMD_DATA       EQU 0x28        ; данные ROM-диска
PORT_29_ROMD_ADRL       EQU 0x29        ; мл. адрес в ROM-диске
PORT_2A_ROMD_ADRH       EQU 0x2A        ; ст. адрес в ROM-диске
PORT_2B_CTL             EQU 0x2B        ; управление ВВ55 ROM-диска
PORT_2C_ROMD_PAGE       EQU 0x2C

PORT_3B_VI53_CTL        EQU 0x3b        ; ВИ53 на плате портов COM

; порты IDE
PORT_56_HDD_CTL         EQU 0x56
PORT_57_HDD_HB          EQU 0x57
PORT_58_HDD_LB          EQU 0x58
PORT_59_HDD_ERR         EQU 0x59
PORT_5F_HDD_STAT_CMD    EQU 0x5F

; порты палитры
PORT_E0_PAL_R           EQU 0xE0
PORT_E1_PAL_G           EQU 0xE1
PORT_E2_PAL_B           EQU 0xE2

PORT_F8_VMODE           EQU 0xF8
REG_F9_RAM_PG           EQU 0xF9
REG_FA_SCRN_CFG         EQU 0xFA
PORT_FB_TMR_INT         EQU 0xFB        ; порт вкл прерывания и разблок. ROM
REG_FC_COLOR            EQU 0xFC
PORT_FF_SPEAKER         EQU 0xFF

; Порты через память для Ориона-128
PORT_128_F400           EQU 0xF400  ; Клавиатура
PORT_128_F500           EQU 0xF500  ; Порт пользователя 1
PORT_128_F600           EQU 0xF600  ; Порт пользователя 2
PORT_128_F700           EQU 0xF700  ; Порт платы расширения
PORT_128_F800           EQU 0xF800  ; WR Цветные режимы
PORT_128_F900           EQU 0xF900  ; WR Управление памятью
PORT_128_FA00           EQU 0xFA00  ; WR Переключение экранов
PORT_128_FB00           EQU 0xFB00  ; WR Переключение типа экрана граф/симв (не импользуется)


;
; Биты конфигурации порта 00 (DIP Switch)
;
SW_O128_MODE        EQU 7
SW_INT_ROM_DISK     EQU 6
SW_MENU             EQU 5
SW_CHR_DISP         EQU 4
SW_CMP_PG1          EQU 3
SW_KBD_RK86         EQU 2
SW_HDD              EQU 1
SW_FDD              EQU 0 

;
; Биты порта 0A
;
RAM0_WND            EQU 0                    ;  Окно 0  если 1 - Открыто (0000-3FFFF)
RAM1_WND            EQU 1                    ;  Окно 1  если 1 - Открыто (4000-7FFFF)
RAM2_WND            EQU 2                    ;  Окно 2  если 1 - Открыто (8000-BFFFF)
ROM2_WND            EQU 3                    ;  Если 1 - Включено окно ROM2
ROM2_WND_ON         EQU 0x08
ROM2_WND_OFF        EQU 0xF7
ROM1_WND            EQU 4                    ;  Если 1 - Включено окно ROM1

;                       ПОРТЫ "ОРИОН-ПРО"
;                        =================
;    00H - DIP-переключатели (чтение);
;    01H - данные принтера, инверсные (запись);
;    02H - управляющие сигналы принтера (чтение, запись);
;    03H - регистр управления для портов 00H..02H;
;    04H - регистр сегментов для окна ОЗУ RAM-0 (чтение, запись);
;    05H - регистр сегментов для окна ОЗУ RAM-1 (чтение, запись);
;    06H - регистр сегментов для окна ОЗУ RAM-2 (чтение, запись);
;    07H - регистр управления для портов 04H..05H;
;    08H - регистр страниц ОЗУ для режима "Pro" (чтение, запись);
;    09H - регистр сегментов ПЗУ ROM-2 (чтение, запись);
;    0AH - диспетчер памяти (чтение, запись);
;    0BH - регистр управления для портов 08H..0AH;
;    10H - регистр состояния/команд ВГ93 (чтение, запись)
;          в режиме "128" доступен через адрес 0F710H;
;    11H - регистр дорожки ВГ93 (чтение, запись),
;          в режиме "128" доступен через адрес 0F711H;
;    12H - регистр сектора ВГ93 (чтение, запись),
;          в режиме "128" доступен через адрес 0F712H;
;    13H - регистр данных ВГ93 (чтение, запись),
;          в режиме "128" доступен через адрес 0F713H;
;    14H - порт управления НГМД (запись),
;          в режиме "128" доступен через адрес 0F714H;
;    18H..1BH - порты клавиатуры,
;          в режиме  "128"  в  зависимости  от положения перемычки
;          доступны через адреса 0F4XXH / 0F5XXH / 0F6XXH;
;    1CH - свободный порт Мультикарты (чтение, запись);
;    1DH - регистр управления портами 1CH,1EH,1FH;
;    1EH - порт параллельной мыши на Мультикарте (чтение);
;    1FH - порт джойстика на Мультикарте (чтение);
;    20H..23H - универсальный порт на Мультикарте,  в  зависимости
;          от положения  перемычки  может  быть  доступен в режиме
;          "128" по адресам 0F6XXH;

;    30H - регистр данных ВВ51 "COM1" (DD7)
;    31H - регистр управления ВВ51 "COM1" (DD7)
;    34H - регистр данных ВВ51 "COM2" (DD8)
;    35H - регистр управления ВВ51 "COM2" (DD8)
;    38H - счетчик 1 ВИ53 (DD6)
;    39H - счетчик 2 ВИ53 (DD6)
;    3AH - счетчик 3 ВИ53 (DD6)
;    3BH - регистр управления ВИ53 (DD6)

;    3EH - запись данных музыкального процессора (DD9)
;    3FH - чтение данных музыкального процессора (DD9)
;    3FH - запись номера регистра музыкального процессора (DD9)
;    50H - регистр данных RTC, CMOS ВИ1 (чтение, запись);
;    51H - регистр адреса RTC, CMOS ВИ1 (запись);
;    56H - регистр состояния/управления IDE (чтение, запись);
;    57H - старший байт регистра данных IDE (чтение, запись);
;    58H - младший байт регистра данных IDE (чтение, запись);
;    59H - регистр ошибок/свойств IDE;
;    5AH - счетчик секторов IDE
;    5BH - регистр сектора IDE
;    5CH - младший байт номера цилиндра IDE;
;    5DH - старший байт номера цилиндра IDE;
;    5EH - регистр головки и устройства IDE;
;    5FH - регистр состояния (чтение) и команд (запись) IDE;
;    A0H,A1H,A2H - регистры адреса Квазидиска 1Мб/128К (запись);
;    A3H - регистр данных Квазидиска 1Мб (чтение, запись);
;    A4H - регистр данных Квазидиска 128К (чтение, запись);
;    E0H - порт управления палитрой R на Мультикарте (запись);
;    E1H - порт управления палитрой G на Мультикарте (запись);
;    E2H - порт управления палитрой B на Мультикарте (запись);
;    F8H - порт управления цветовым режимом экрана (запись),
;          в режиме "128" доступен" через ячейку 0F800H;
;    F9H - порт выбора страницы ОЗУ для режима "128" (запись),
;          в режиме "128" доступен" через ячейку 0F900H;
;    FAH - порт выбора номера экрана и ширины (запись),
;          в режиме "128" доступен" через ячейку 0FA00H;
;    FBH - регистр разрешения прерываний IRQ0 - 50Гц (запись);
;    FCH - регистр псевдоцвета (запись);
;    FDH - резерв для портов "ZX";
;    FEH - порт ЦАП /звук (запись);
;    FFH - динамик (запись).
