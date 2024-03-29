;**********************
; Universidad del Valle de Guatemala 
; IE2023:: Programación de Microcontroladores
; Proyectointento.asm
; Autor: jose Velásquez
; Proyecto: RELOJ
; Hardware: ATMega328P
; Creado: 10/03/2024
;**********************

.INCLUDE "M328PDEF.INC"
.EQU T1VALUE = 0XE17B
.DEF STATE = R18		;R16 AND R17 VAR
.DEF COUNTER_T0 = R20
.DEF COUNTER = R19
.CSEG
.ORG 0X00
	JMP SETUP		;RESET VECTOR
.ORG 0X0006
	JMP ISR_PCINT0	;VECTOR: PC_INT0
.ORG 0X0020
	JMP ISR_TIMER0	;ISR: TIMER0 VECTOR


SETUP:
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R17, LOW(RAMEND)
	OUT SPL, R17

	;LIST OF VALUES FOR DISPLAY, NUMBERS
	SEG: .DB 0x3F,0x06,0x5B,0x4F,0x66,0x6D,0x7D,0x07,0x7F,0x6F

	;PINS CONFIG
	LDI R16, 0X00
	STS UCSR0B, R16		;RX AN TX AS NORMAL PINS
	
	LDI R16, 0XFF		;ENTIRE PORTD AS OUTPUT
	OUT DDRD, R16
	CBI PORTD, PD7

	LDI R16, 0X3F		;ENTIRE PORTC AS OUTPUT
	OUT DDRC, R16

	LDI R16, 0X0F		;PB0-PB3 AS INPUT W PULL-UP
	OUT PORTB, R16
	LDI R16, 0X30		;PB5 AND PB4 AS OUTPUT, PB0-PB3 AS INPUT
	OUT DDRB, R16

	;IT TAKES EVERY VALUE FROM THE LIST OF VALUES FOR DISPLAY
	LDI R21, 0
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R21
	LPM R21, Z
	
	;CLEAR PORTC AND PORTD BEFORE RUNNING THE ENTIRE PROGRAM
	CLR R16
	OUT PORTC, R16

	LDI R16, (1 << PCINT1) | (1 << PCINT0) | (1 << PCINT2) | (1 << PCINT3)
	STS PCMSK0, R16		;ISR PCINT FOR PB0 AND PB1

	LDI R16, (1 << PCIE0)
	STS PCICR, R16		;PIN CHANGE FOR PORTB
	
	CALL INIT_T0		;SET TIMER0

	SEI					;ENABLE GLOBAL INTERRUPTS

	CLR STATE
	CLR COUNTER_T0
	CLR COUNTER
	;IF I WANT TO SET A VALUE FOR THE RTC, SET DISPLAY BY DISPLAY
	LDI R16, 0
	STS 0X0121, R16		;DISPLAY1 SECONDS
	LDI R16, 5
	STS 0X0122, R16		;DISPLAY2 SECONDS
	LDI R16, 9
	STS 0X0123, R16		;DISPLAY1 MIN
	LDI R16, 5
	STS 0X0124, R16		;DISPLAY2 MIN
	LDI R16, 3
	STS 0X0125, R16		;DISPLAY1 HOURS
	LDI R16, 2
	STS 0X0126, R16		;DISPLAY2 HOURS
	CLR R16
	STS 0X0127, R16		;STATE DISPLAY

	;MANUAL SET FOR RTC
	STS 0X0131, R16		;STATE DISPLAY1 MIN
	STS 0X0132, R16		;STATE DISPLAY2 MIN
	STS 0X0133, R16		;STATE DISPLAY3 HOUR
	STS 0X0134, R16		;STATE DISPLAY4 HOUR

	;ALARMA
	STS 0X0141, R16		;STATE DISPLAY1 MIN
	STS 0X0142, R16		;STATE DISPLAY2 MIN
	STS 0X0143, R16		;STATE DISPLAY3 HOUR
	STS 0X0144, R16		;STATE DISPLAY4 HOUR

;LOOP IS USED JUST FOR KNOWING IN WICH STATE WE R
LOOP:
	CPI STATE, 0
    BREQ STATE0P
    CPI STATE, 1
    BREQ STATE1P
	CPI STATE, 2
	BREQ STATE2P
	CPI STATE, 3
	BREQ STATE3P
	CPI STATE, 4
	BREQ STATE4P
	CPI STATE, 5
	BREQ STATE5P
	CPI STATE, 6
	BREQ STATE6P
	CPI STATE, 7
	BREQ STATE7P
	CPI STATE, 8
	BREQ STATE8P
	CPI STATE, 9
	BREQ STATE9P
	CPI STATE, 10
	BREQ STATE10P
	CPI STATE, 11
	BREQ STATE10P

;PASSSING STATES
STATE0P:
	JMP STATE0
STATE1P:
	CLR R16
	STS 0X0132, R16		;STATE DISPLAY2 MIN
	STS 0X0133, R16		;STATE DISPLAY3 HOUR
	STS 0X0134, R16		;STATE DISPLAY4 HOUR
	JMP STATE1
STATE2P:
	CLR R16
	STS 0X0133, R16		;STATE DISPLAY3 HOUR
	STS 0X0134, R16		;STATE DISPLAY4 HOUR
	JMP STATE2
STATE3P:
	CLR R16
	STS 0X0134, R16		;STATE DISPLAY4 HOUR
	JMP STATE3
STATE4P:
	JMP STATE4
STATE5P:
	JMP STATE5
STATE6P:
	CLR R16
	STS 0X0142, R16		;STATE DISPLAY2 MIN
	STS 0X0143, R16		;STATE DISPLAY3 HOUR
	STS 0X0144, R16		;STATE DISPLAY4 HOUR
	JMP STATE6
STATE7P:
	CLR R16
	STS 0X0143, R16		;STATE DISPLAY3 HOUR
	STS 0X0144, R16		;STATE DISPLAY4 HOUR
	JMP STATE7
STATE8P:
	CLR R16
	STS 0X0144, R16		;STATE DISPLAY4 HOUR
	JMP STATE8
STATE9P:
	JMP STATE9
STATE10P:
	JMP STATE10
STATE11P:
	JMP STATE11


;******************************************************************************
;                                    STATE0	
;******************************************************************************
STATE0:					;SHOW CLOCK
	CLR R22

	;DISPLAY1 MINUTES
	CALL CLEAN
	LDS R22, 0X0123
	CALL DISPLAY
	LDI R16, 0X01		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 3
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 MINUTES
	CALL CLEAN
	LDS R22, 0X0124
	CALL DISPLAY
	LDI R16, 0X02		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 4
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY1 HOUR
	CALL CLEAN
	LDS R22, 0X0125
	CALL DISPLAY
	LDI R16, 0X04		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 5
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 HOUR
	CALL CLEAN
	LDS R22, 0X0126
	CALL DISPLAY
	CBI PORTB, PB5		;CLR PB5
	LDI R16, 0X08		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 6
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY
	
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 50
	BREQ D7
	CPI COUNTER_T0, 99
	BREQ D7
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS0
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	SBI PIND, PD7
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP
D7:
	SBI PIND, PD7
	SBI PORTB, PB4
	CBI PORTC, PC5
	RJMP LOOP
ZEROSP:
	JMP ZEROS
LOOPS0:
	RJMP LOOP


;******************************************************************************
;                                    STATE1	
;******************************************************************************

;HERE, JUST SET A VALUE FOR DISPLAY1 MIN
STATE1:
	CALL MUX_DISPLAYS
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS1
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0

	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP1			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS1:
	JMP LOOP
ZEROSP1:
	JMP ZEROS


;******************************************************************************
;                                    STATE2	
;******************************************************************************

;HERE, JUST SET A VALUE FOR DISPLAY2 MIN
STATE2:
	CALL MUX_DISPLAYS
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS2
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0

	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP2			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS2:
	JMP LOOP
ZEROSP2:
	JMP ZEROS



;******************************************************************************
;                                    STATE3	
;******************************************************************************
STATE3:
	CALL MUX_DISPLAYS
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS3
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP3			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS3:
	JMP LOOP
ZEROSP3:
	JMP ZEROS



;******************************************************************************
;                                    STATE4	
;******************************************************************************
STATE4:
	CALL MUX_DISPLAYS
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS4
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP4		;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS4:
	JMP LOOP
ZEROSP4:
	JMP ZEROS

;******************************************************************************
;                                    STATE5	
;******************************************************************************
STATE5:
	LDI STATE, 6		;ASSIGN NEXT STATE
	LDS R22, 0X0131
	LDS R16, 0X0132
	OR R22, R16
	LDS R16, 0X0133
	OR R22, R16
	LDS R16, 0X0134
	OR R22, R16
	CPI R22, 0
	BREQ LOOPS5
	
	LDS R22, 0X0133		;VALUE OF HOUR UNITS
	CPI R22, 4
	BRSH RESET_CH		;IT CHECKS IF VALUE OF 0X0133 IS EQUAL OR MORE THAN 4
	CALL ASSIGN_TIME

RESET_CH:
	LDS R22, 0X0134		;CHECK IF HOUR DOZ IS 2
	CPI R22, 2
	BREQ RST_T			; IF IT'S 2, IT GOES TO RST HOUR
	CALL ASSIGN_TIME
RST_T:
	CLR R22
	STS 0X0133, R22		;ASSIGN VALUE 0 FOR UNITS AN DOZ OF HOUR
	STS 0X0134, R22
	CALL ASSIGN_TIME
ASSIGN_TIME:
	LDS R22, 0X0131		;UPLOAD VALUE FOR MIN UNITS
	STS 0X0123, R22
	LDS R22, 0X0132		;UPLOAD VALUE FOR MIN DOZ
	STS 0X0124, R22
	LDS R22, 0X0133		;UPLOAD VALUE FOR HOUR UNITS
	STS 0X0125, R22
	LDS R22, 0X0134		;UPLOAD VALUE FOR HOUR DOZ
	STS 0X0126, R22
	CLR R22
	CALL MUX_DISPLAYS
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS5
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP5		;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP
LOOPS5:
	JMP LOOP
ZEROSP5:
	JMP ZEROS






;SATETE 6 *************************************************************



;HERE, JUST SET A VALUE FOR DISPLAY1 MIN
STATE6:
	CALL MUX_DISPLAYS_ARM
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS6
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0

	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP6			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS6:
	JMP LOOP
ZEROSP6:
	JMP ZEROS


;******************************************************************************
;                                    STATE7
;******************************************************************************

;HERE, JUST SET A VALUE FOR DISPLAY2 MIN
STATE7:
	CALL MUX_DISPLAYS_ARM
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS7
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0

	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP7			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS7:
	JMP LOOP
ZEROSP7:
	JMP ZEROS



;******************************************************************************
;                                    STATE8
;******************************************************************************
STATE8:
	CALL MUX_DISPLAYS_ARM
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS8
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP8			;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS8:
	JMP LOOP
ZEROSP8:
	JMP ZEROS



;******************************************************************************
;                                    STATE9
;******************************************************************************
STATE9:
	CALL MUX_DISPLAYS_ARM
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS9
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP9		;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP

LOOPS9:
	JMP LOOP
ZEROSP9:
	JMP ZEROS

;******************************************************************************
;                                    STATE10
;******************************************************************************
STATE10:
	LDI STATE, 11		;ASSIGN NEXT STATE
	LDS R22, 0X0141
	LDS R16, 0X0142
	OR R22, R16
	LDS R16, 0X0143
	OR R22, R16
	LDS R16, 0X0144
	OR R22, R16
	CPI R22, 0
	BREQ LOOPS10
	
	LDS R22, 0X0143		;VALUE OF HOUR UNITS
	CPI R22, 4
	BRSH RESET_CH10		;IT CHECKS IF VALUE OF 0X0133 IS EQUAL OR MORE THAN 4
	CALL ASSIGN_TIME10

RESET_CH10:
	LDS R22, 0X0144		;CHECK IF HOUR DOZ IS 2
	CPI R22, 2
	BREQ RST_T10			; IF IT'S 2, IT GOES TO RST HOUR
	CALL ASSIGN_TIME10
RST_T10:
	CLR R22
	STS 0X0143, R22		;ASSIGN VALUE 0 FOR UNITS AN DOZ OF HOUR
	STS 0X0144, R22
	CALL ASSIGN_TIME10
ASSIGN_TIME10:
	/*LDS R22, 0X0131		;UPLOAD VALUE FOR MIN UNITS
	STS 0X0123, R22
	LDS R22, 0X0132		;UPLOAD VALUE FOR MIN DOZ
	STS 0X0124, R22
	LDS R22, 0X0133		;UPLOAD VALUE FOR HOUR UNITS
	STS 0X0125, R22
	LDS R22, 0X0134		;UPLOAD VALUE FOR HOUR DOZ
	STS 0X0126, R22*/
	CLR R22
	CALL MUX_DISPLAYS
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS10
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP10		;IF IT'S BEEN 10 SECS GOES TO RESTART
	CLR R22
	JMP LOOP
LOOPS10:
	JMP LOOP
ZEROSP10:
	JMP ZEROS

; ESTATE 11***********************************************************************************************

STATE11:					;SHOW CLOCK
	CLR R22

	;DISPLAY1 MINUTES
	CALL CLEAN
	LDS R22, 0X0123
	CALL DISPLAY
	LDI R16, 0X01		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 3
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 MINUTES
	CALL CLEAN
	LDS R22, 0X0124
	CALL DISPLAY
	LDI R16, 0X02		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 4
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY1 HOUR
	CALL CLEAN
	LDS R22, 0X0125
	CALL DISPLAY
	LDI R16, 0X04		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 5
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 HOUR
	CALL CLEAN
	LDS R22, 0X0126
	CALL DISPLAY
	CBI PORTB, PB5		;CLR PB5
	LDI R16, 0X08		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 6
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY
	
	;IT WAITS ONE SEC
	CPI COUNTER_T0, 50
	BREQ D711
	CPI COUNTER_T0, 99
	BREQ D711
	CPI COUNTER_T0, 100			; 100 * 10ms = 1000ms
	BRNE LOOPS11
	CLR COUNTER_T0				;IT CLEARS COUNTER_T0
	SBI PIND, PD7
	;IT UPLOADS VALUE OF SECONDS
	CLR R22
	LDS R22, 0X0121		;LOAD TO R22 THE CONTENT FROM 0X0121, D1 SEC'S COUNTER
	INC R22				;COUNTER FOR SECONDS
	STS 0X0121, R22		;RELOAD COUNT TO 0X0121
	CPI R22, 10			;COMPARE CONTENT OF 0X0121 TO 10 (10 SECS)
	BREQ ZEROSP11			;IF IT'S BEEN 10 SECS GOES TO RESTART
	
	CLR R22
	CLR R16
	LDS R22, 0X0141
	LDS R16, 0X0123
	CPSE R22, R16
	JMP LOOP

	CLR R22
	CLR R16
	LDS R22, 0X0142
	LDS R16, 0X0124
	CPSE R22, R16
	JMP LOOP

	CLR R22
	CLR R16
	LDS R22, 0X0143
	LDS R16, 0X0125
	CPSE R22, R16
	JMP LOOP

	CLR R22
	CLR R16
	LDS R22, 0X0144
	LDS R16, 0X0126
	CPSE R22, R16
	JMP LOOP
	SBI PORTC, PC5

	JMP LOOP
D711:
	SBI PIND, PD7
	SBI PORTB, PB4
	SBI PORTC, PC5
	RJMP LOOP
ZEROSP11:
	JMP ZEROS
LOOPS11:
	RJMP LOOP


;******************************************************************************
;*************************        MUX FOR CLOCK          **********************
;******************************************************************************
ZEROS:
	LDI R22, 0			;LOAD CLR REG TO 0X0121, RESTART TO 0 SECS UNITS
	STS 0X0121, R22

	LDS R22, 0X0122		;LOAD FROM 0X0122 TO R22
	INC R22
	STS 0X0122, R22		;RELOAD NEW VALUE TO 0X0122
	CPI R22, 6			;COMPARE IF COUNT IS 60 SECS
	BREQ SIXS			;IF IT'S BEEN 1 MIN IT CLEARS SECS
	RJMP LOOP

SIXS:
	LDI R22, 0
	STS 0X0122, R22		;CLR SEC'S DOZENS

	LDS R22, 0X0123		;LOAD FROM 0X0123, MIN'S UNITS
	INC R22
	STS 0X0123, R22		;RELOAD VALUE FOR MIN'S UNITS
	CPI R22, 10			;10 MINUTES
	BREQ ZEROM
	RJMP LOOP

ZEROM:
	LDI R22, 0
	STS 0X0123, R22		;CLR MIN'S UNITS

	LDS R22, 0X0124		;LOAD FROM 0X0124, MIN'S DOZENS
	INC R22
	STS 0X0124, R22		;RELOAD VALUE FOR DOZENS OF MINUTES
	CPI R22, 6			;60 MINS
	BREQ SIXM
	RJMP LOOP

SIXM:
	LDI R22, 0
	STS 0X0124, R22		;CLR MIN'S DOZENS

	LDS R22, 0X0125		;LOAD HOUR'S UNITS
	INC R22
	STS 0X0125, R22		;RELOAD HOUR'S UNITS
	CPI R22, 10
	BREQ ZEROH
	CPI R22, 4
	BREQ ENDTIME
	RJMP LOOP

ZEROH:
	LDI R22, 0
	STS 0X0125, R22		;CLR HOUR'S UNITS

	LDS R22, 0X0126		;LOAD HOUR'S DOZ
	INC R22
	STS 0X0126, R22		;RELOAD HOUR'S DOZ
	RJMP LOOP

ENDTIME:
	LDS R22, 0X0126		;LOAD HOUR'S DOZ
	SBRS R22, 1			;IF BIT 1 IS NOT SET (HOUR'S DOZ IS 2) IT JUMPS
	RJMP LOOP			;EXCUTED IF BIT1 IS 0

	LDI R22, 0
	STS 0X0125, R22		;CLR HOUR'S UNITS

	LDI R22, 0
	STS 0X0126, R22		;CLR HOUR'S DOZ
	RJMP LOOP



MUX_DISPLAYS:
	CLR R22

	;DISPLAY1 MINUTES
	CALL CLEAN
	;VALUE FOR DISPLAY
	LDS R22, 0X0131			;LOAD VALUE FROM 0X0122
	CALL DISPLAY
	LDI R16, 0X01		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 1
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 MINUTES
	CALL CLEAN
	;VALUE FOR DISPLAY
	LDS R22, 0X0132		;CREATE A COPY FOR LOOKING UP INTO THE LIST
	CALL DISPLAY
	LDI R16, 0X02		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 4
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY1 HOUR
	CALL CLEAN
	;VALUE FOR DISPLAY
	LDS R22, 0X0133		;CREATE A COPY FOR LOOKING UP INTO THE LIST
	CALL DISPLAY
	LDI R16, 0X04		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 5
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 HOUR
	CALL CLEAN
	LDS R22, 0X0134		;LOAD VALUE FROM 0X0122
	CALL DISPLAY
	LDI R16, 0X08		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 6
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY7 STATE
	//CALL SHOW_STATE_SC

	SBI PIND, PD7
	RET


CLEAN:
	CLR R16
	OUT PORTC, R16		;CLEAR TRANSISTORS
	OUT PORTD, R16		;CLEAR DISPLAY
	CBI PORTB, PB5
	RET

DISPLAY:
	LDI ZH, HIGH(SEG << 1)
	LDI ZL, LOW(SEG << 1)
	ADD ZL, R22
	LPM R22, Z				;UPLOAD NEW VALUE FOR DISPLAY1 SECONDS
	RET

/*SHOW_STATE_SC:
	CLR R16
	CBI PORTB, PB5
	OUT PORTC, R16		;CLEAR TRANSISTORS
	OUT PORTD, R16		;CLEAR DISPLAY
	SBI PORTB, PB5		;ACTIVATE PB5
	LDI R16, 0X00		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 7
	LDI R22, 0x6D		;IT SHOWS A S FOR "SET" CLOCK
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY
	RET*/






MUX_DISPLAYS_ARM:
	CLR R22

	;DISPLAY1 MINUTES
	CALL CLEAN
	;VALUE FOR DISPLAY
	LDS R22, 0X0141			;LOAD VALUE FROM 0X0122
	CALL DISPLAY
	LDI R16, 0X01		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 1
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 MINUTES
	CALL CLEAN
	;VALUE FOR DISPLAY
	LDS R22, 0X0142		;CREATE A COPY FOR LOOKING UP INTO THE LIST
	CALL DISPLAY
	LDI R16, 0X02		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 4
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY1 HOUR
	CALL CLEAN
	;VALUE FOR DISPLAY
	LDS R22, 0X0143		;CREATE A COPY FOR LOOKING UP INTO THE LIST
	CALL DISPLAY
	LDI R16, 0X04		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 5
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY2 HOUR
	CALL CLEAN
	LDS R22, 0X0144		;LOAD VALUE FROM 0X0122
	CALL DISPLAY
	LDI R16, 0X08		;MUX
	OUT PORTC, R16		;ONLY TRANSISTOR 6
	OUT PORTD, R22		;SHOW VALUES FOR DISPLAY

	;DISPLAY7 STATE
	//CALL SHOW_STATE_SC

	CBI PIND, PD7
	CBI PORTB, PB4
	SBI PORTC, PC5
	RET


;******************************************************************************
;*************************        INTERRUPTIONS          **********************
;******************************************************************************

;PCINT, INTERRUPTION FOR PORTB
ISR_PCINT0:
	PUSH R16
	IN R16, SREG
	PUSH R16
	
	;LOOING UP CURRENT STATE
	CPI STATE, 0
	BREQ STATE0_ISR_P
	CPI STATE, 1
	BREQ STATE1_ISR_P
	CPI STATE, 2
	BREQ STATE2_ISR_P
	CPI STATE, 3
	BREQ STATE3_ISR_P
	CPI STATE, 4
	BREQ STATE4_ISR_P
	CPI STATE, 6
	BREQ STATE6_ISR_P
	CPI STATE, 7
	BREQ STATE7_ISR_P
	CPI STATE, 8
	BREQ STATE8_ISR_P
	CPI STATE, 9
	BREQ STATE9_ISR_P
	CPI STATE, 11
	BREQ STATE11_ISR_P


	

STATE0_ISR_P:
	RJMP STATE0_ISR
STATE1_ISR_P:
	RJMP STATE1_ISR
STATE2_ISR_P:
	RJMP STATE2_ISR
STATE3_ISR_P:
	RJMP STATE3_ISR
STATE4_ISR_P:
	RJMP STATE4_ISR
STATE6_ISR_P:
	RJMP STATE6_ISR
STATE7_ISR_P:
	RJMP STATE7_ISR
STATE8_ISR_P:
	RJMP STATE8_ISR
STATE9_ISR_P:
	RJMP STATE9_ISR
STATE11_ISR_P:
	RJMP STATE11_ISR




;******************************************************************************
;                              STATE INTERRUPTIONS
;******************************************************************************

STATE0_ISR:
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF BUTTON 0 (COUNTER) WAS ACTIVATED IT DOES NOTHING (PB1)
	NOP
	SBRS R16, 0		;IF BUTTON 1 (COUNTER) WAS ACTIVATED IT DOES NOTHING (PB0)
	NOP
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 1	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	NOP
	//LDI STATE, ####	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP



STATE1_ISR:
	STS 0X0131, COUNTER
	CPI COUNTER, 0	;FIRST, COMPARE IF ITS ZERO
	BREQ INF_LIM

	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 10
	BREQ SUP_LIM
	JMP END_ISR1

SUP_LIM:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR1
INF_LIM:
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 9 AS NEW VALUE
	LDI COUNTER, 9
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR1
END_ISR1:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUTNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 2	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 0	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP


STATE2_ISR:
	STS 0X0132, COUNTER
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	CPI COUNTER, 0	;FIRST, COMPARE IF COUNTER IS ZERO
	BREQ INF_LIM_S2

	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 6
	BREQ SUP_LIM_S2
	JMP END_ISR2

SUP_LIM_S2:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR2
INF_LIM_S2:
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 6 AS NEW VALUE
	LDI COUNTER, 5
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR2
END_ISR2:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 3	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 1	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP



STATE3_ISR:
	STS 0X0133, COUNTER
	CPI COUNTER, 0	;FIRST, COMPARE IF ITS ZERO
	BREQ INF_LIM3

	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 10
	BREQ SUP_LIM3
	JMP END_ISR3

SUP_LIM3:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR3
INF_LIM3:
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 9 AS NEW VALUE
	LDI COUNTER, 9
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR3
END_ISR3:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUTNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 4	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 2	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP



STATE4_ISR:
	STS 0X0134, COUNTER
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	CPI COUNTER, 0	;FIRST, COMPARE IF COUNTER IS ZERO
	BREQ INF_LIM_S4

	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 3
	BREQ SUP_LIM_S4
	JMP END_ISR4

SUP_LIM_S4:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR4
INF_LIM_S4:
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 6 AS NEW VALUE
	LDI COUNTER, 2
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR4
END_ISR4:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 5	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 3	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP

;*****************************************************************************************************

STATE6_ISR:
	STS 0X0141, COUNTER
	CPI COUNTER, 0	;FIRST, COMPARE IF ITS ZERO
	BREQ INF_LIM6

	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 10
	BREQ SUP_LIM6
	JMP END_ISR6

SUP_LIM6:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR6
INF_LIM6:
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 9 AS NEW VALUE
	LDI COUNTER, 9
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR6
END_ISR6:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUTNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 7	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 4	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP


STATE7_ISR:
	STS 0X0142, COUNTER
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	CPI COUNTER, 0	;FIRST, COMPARE IF COUNTER IS ZERO
	BREQ INF_LIM_7

	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 6
	BREQ SUP_LIM_7
	JMP END_ISR7

SUP_LIM_7:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR7
INF_LIM_7:
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 6 AS NEW VALUE
	LDI COUNTER, 5
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR7
END_ISR7:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 8	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 6	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP



STATE8_ISR:
	STS 0X0143, COUNTER
	CPI COUNTER, 0	;FIRST, COMPARE IF ITS ZERO
	BREQ INF_LIM8

	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 10
	BREQ SUP_LIM8
	JMP END_ISR8

SUP_LIM8:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR8
INF_LIM8:
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 9 AS NEW VALUE
	LDI COUNTER, 9
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR8
END_ISR8:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUTNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 9	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 7	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP



STATE9_ISR:
	STS 0X0144, COUNTER
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	CPI COUNTER, 0	;FIRST, COMPARE IF COUNTER IS ZERO
	BREQ INF_LIM_9

	SBRS R16, 1		;IF PB1 WAS ACTIVATED DEC COUNTER
	DEC COUNTER
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER

	CPI COUNTER, 3
	BREQ SUP_LIM_9
	JMP END_ISR9

SUP_LIM_9:
	LDI COUNTER, 0	;RESTART VALUE FOR DISPLAY
	JMP END_ISR9
INF_LIM_9:
	SBRS R16, 1		;IF PB1 WAS ACTIVATED SET 6 AS NEW VALUE
	LDI COUNTER, 2
	SBRS R16, 0		;IF PB0 WAS ACTIVADED INC COUNTER
	INC COUNTER
	JMP END_ISR9
END_ISR9:
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 10	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 8	;LOAD VALUE OF PREVIOUS STATE
	RJMP ISR_POP



STATE11_ISR:
	IN R16, PINB	;READ PORTB, ONLY INPUTS PB0-PB3
	SBRS R16, 1		;IF BUTTON 0 (COUNTER) WAS ACTIVATED IT DOES NOTHING (PB1)
	NOP
	SBRS R16, 0		;IF BUTTON 1 (COUNTER) WAS ACTIVATED IT DOES NOTHING (PB0)
	NOP
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED FIRST CLR COUNTER (CHANGE STATE)
	CLR COUNTER
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 0	;LOAD VALUE OF NEXT STATE
	SBRS R16, 2		;IF B2 (PB2) WAS ACTIVATED (CHANGE STATE)
	CBI PORTB, PB4	;LOAD VALUE OF NEXT STATE
	SBRS R16, 3		;IF B3 (PB3) WAS ACTIVATED (CHANGE STATE)
	LDI STATE, 9
	RJMP ISR_POP



ISR_POP:
	SBI PCIFR, PCIF0
	POP R16
	OUT SREG, R16
	POP R16
	RETI

;TIMER0 INTERRUPTION
 INIT_T0:
	LDI R16, (1 << CS02) | (1 << CS00)
	OUT TCCR0B, R16			;SET PRESCALER, 1024
	LDI R16, 99				;OVERFLOW VALUE, EVERY 10ms
	OUT TCNT0, R16			;LOAD START VALUE OF TIMER
	LDI R16, (1 << TOIE0)
	STS TIMSK0, R16			;INTERRUPTION ENABLE
	RET

ISR_TIMER0:
	LDI R16, 99				;VALUE OF TIMER OVERFLOW
	OUT TCNT0, R16			;LOAD THE OVERFLOW VALUE
	SBI TIFR0, TOV0			;TURN OFF FLAG
	INC COUNTER_T0			;INCREASE COUNTER OF 10ms
	RETI


