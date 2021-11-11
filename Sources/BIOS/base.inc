; Физический сегмент для непереключаемого ОЗУ
;RAMSEG:EQU 03H                             ;для плат V2.10
RAMSEG          EQU 1FH                         ; для плат V3.10

;----------------------------------
VERS            EQU 210H                        ; номер версии монитора двоично десятичный
                         
VERS1           EQU '2'                         ; первая
VERS2           EQU '1'                         ; вторая
VERS3           EQU '0'                         ; третья цифра


;======================= Внимание ====================
; Констаны связи с драйвером TV-PRO из ROM2
;------------------------------------------------------

R2SEG           EQU 1                           ; Номер сегмента ROM2 с драйвером TV-PRO
;
; номер функции в векторе управления экраном
SETWND          EQU 16                          ; Установить окно
GETWND          EQU 17                          ; Получить окно
SETSCR          EQU 4                           ; Установить номер экрана
GETSCR          EQU 5                           ; Получить номер экрана
;
; номер функции в векторе вывода символа/курсора TV-PRO
NTVC            EQU 0                           ; Номер фуекции вывода символа TVC-PRO
NCURON          EQU 2                           ; Номер функции отображения курсора
NCUROF          EQU 3                           ; Номер функции ga{eniq kursora
NWCUR           EQU 5                           ; Номер функции ustanowki pozicii kursora
NRCUR           EQU 6                           ; Номер функции ~teniq pozicii kursora
NSYMMS          EQU 7                           ; Номер функции ustanowki revima wyw.simw.
NSYMMR          EQU 8                           ; Номер функции polu~eniq revima wyw.simw.
NCURMS          EQU 14                          ; Номер функции ustanowki revima kursora
NCURMR          EQU 15                          ; Номер функции polu~eniq revima kursora
NCURSS          EQU 16                          ; Номер функции ustanowki razmerow kursora
NCURSR          EQU 17                          ; Номер функции polu~eniq razmerow kursora
NCURPS          EQU 18                          ; Номер функции ustanowki {ablona kursora
NCURPR          EQU 19                          ; Номер функции polu~eniq {ablona kursora
NCURBS          EQU 20                          ; Номер функции ustanowki adresa bufera dlq kursora
NCURBR          EQU 21                          ; Номер функции polu~eniq adresa bufera dlq kursora
NCURLN          EQU 22                          ; Номер функции polu~eniq neobh.dliny bufera
;   
; Номера битов в управляющем байте кусора
ENACUR          EQU 5                           ; Признак разрешения вывода курсора
BLINK           EQU 4                           ; Признак мигания курсора

; --------------------------------------------
; Размещение в памяти основных структур данных
; --------------------------------------------
STACK           EQU 0xF7C0                      ; Системный стек
SPTUNL          EQU 0xFFFD                      ; Стек туннеля ROM1 <> ROM2
CELLS           EQU 0xFF50                      ; Начало рабочих ячеек
RAMTOP          EQU 0xFFD0                      ; Резерв ячеек для стека туннеля
;
COLDST          EQU 0xFFFF                      ; Ячейка с флагом холодного старта
POS1            EQU 0xFFFE                      ; Указатель главного меню
POS2            EQU 0xFFFD                      ; Указатель меню тестов

SCR_C000        EQU 0xC000

;-------------------
; Флаги клавиатуры
;-------------------

; Распределение флагов по битам:
; по нажатию соотв. клавиши
CTRL            EQU 0                           
SHIFT           EQU 1
FIX             EQU 2
ALF             EQU 3
GRF             EQU 4
; триггерные
CPSLCK          EQU 5       
RUSLAT          EQU 6
GRFALF          EQU 7
; триггерные для инверсии
bolmal          EQU 0x20    
ruslat          EQU 0x40
grfalf          EQU 0x80
;
KBD_TYPE        EQU 0x4

MON_128_F800    EQU 0xF800


CPM_ROM2        EQU 0x2000          ; Начало ROM 2 - CP/M
BUFF            EQU 0xB000          ; Буфер для чтения/записи сектора диска
