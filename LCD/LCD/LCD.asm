/*
 * LCD.asm
 *
 *  Created: 9/30/2015 12:44:08 PM
 *   Author: ELIAS
 */ 

.include "m16def.inc"

.EQU DATA = PORTD
.EQU DATA_PIN = PIND
.EQU DATA_DDR = DDRD

.EQU CONTROL = PORTA
.EQU CONTROL_DDR = DDRA


//CONNECTIONS FOR CONTROL PORT
.EQU CS1 = 0
.EQU CS2 = 1
.EQU RS = 2 //DATA OR INSTRUCTION
.EQU RW = 3// READ OR WRITE
.EQU ENABLE = 4
.EQU RESET = 5

.EQU IMAGE = 0x800 // z pointer for bmp image

; DARK_POINT_AT X,Y 
.MACRO		DARK_POINT_AT
			LDI R17,@0
			LDI R16,@1
			call SET_XY
.ENDMACRO

; LIGHT_POINT_AT X,Y 
.MACRO		LIGHT_POINT_AT
			LDI R17,@0
			LDI R16,@1
			call CLEAR_XY
.ENDMACRO


; HORIZONTAL_LINE X,Y, FINAL_X
.MACRO        HORIZONTAL_LINE
			  LDI R17, @0
				LDI R16,@1
				other:
				push r16
				push r17
				CALL SET_XY // X= R17, Y=R16
				pop r17
				pop r16
				inc r17
				CPI R17 ,@2+1
				BRLO other
.ENDMACRO

; VERTICAL_LINE X,Y, FINAL_Y
.MACRO		   VERTICAL_LINE
				LDI R17, @0
				LDI R16, @1
				other:
				push r16
				push r17
				call SET_XY
				pop r17
				pop r16
				inc r16
				cpi r16 , @2+1
				brlo other
.ENDMACRO

.MACRO		RECTANGLE ; X,Y,LENGTH,HEIGHT
			HORIZONTAL_LINE @0,@1,@2
			HORIZONTAL_LINE @0,@3,@2
			VERTICAL_LINE @0,@1,@3
			VERTICAL_LINE @2,@1,@3
.ENDMACRO

.MACRO		DISPLAY_BMP ; (Z POINTER)
			ldi zh, high(@0<<1)
			ldi zl,low(@0<<1)
			ldi r16, 0
			other_disp_bmp:
			push r16
			SBI CONTROL,CS1
			SBI CONTROL,CS2
			call SET_X
			pop r16
			push r16
			call other_page_bmp
			pop r16
			inc r16
			cpi r16,8
			brlo other_disp_bmp
.ENDMACRO



LDI R16, high(RAMEND)
OUT SPH, R16
LDI R16, low(RAMEND)
OUT SPL, R16

LDI R16, 0XFF; DATA AND CONTROL AS OUTPUT
OUT CONTROL_DDR, R16
OUT DATA_DDR, R16


CALL delay10ms
call delay10ms


CALL LCD_ON
sbi control, cs1
cbi control, cs2
LDI R16,0
call SET_X
LDI R16,0
call SET_Y
LDI R16,4
call WRITE_D

HORIZONTAL_LINE 5,5,120
call delay1s
HORIZONTAL_LINE 5,60,120
call delay1s
VERTICAL_LINE 5,6,60
call delay1s
VERTICAL_LINE 120,6,60
call delay1s
RECTANGLE 10,10,100,50
call delay1s
RECTANGLE 20,20,90,40
call delay1s
RECTANGLE 30,30,80,30
call delay1s
RECTANGLE 40,40,70,20
call delay1s
call CLEAR_LCD
DISPLAY_BMP IMAGE
call delay1s
call LCD_OFF
call delay1s
call LCD_ON
call delay1s
call LCD_OFF
call delay1s
call LCD_ON
call delay1s
call LCD_OFF
call delay1s
call LCD_ON

LDI R16, 0
other_start:
push r16
call SET_DISPLAY_START_LINE
call delay10ms
call delay10ms
call delay10ms
call delay10ms
pop r16
inc r16
cpi r16, 63
brlo other_start




end: rjmp end

CLEAR_LCD:		
LDI R16,0
OTHER_CLEAR_LCD:
push r16
CALL CLEAR_PAGE
pop r16
INC R16
CPI R16,8
BRLO OTHER_CLEAR_LCD
ret



other_page_bmp:
ldi r16,0
call SET_Y ; Y at 0 for beginning of page
ldi r16,0
other_page_y_bmp_2:
call SELECT_CHIP
push r16
lpm r16,z+
call WRITE_D ;y auto increments
pop r16
inc r16
cpi r16,128
brlo other_page_y_bmp_2
ret





CLEAR_PAGE://page at r16, x:0-7
SBI CONTROL,CS1
SBI CONTROL,CS2
CALL SET_X
ldi r16,0
other_page_y:
call SELECT_CHIP
push r16
ldi r16,0
call WRITE_D 
pop r16
inc r16
cpi r16,128
brlo other_page_y
ret

SELECT_CHIP://SELECT CHIP BASED ON Y, Y AT R16
CPI R16,64
BRSH SELECT_CHIP_2
SELECT_CHIP_1:
SBI CONTROL,CS1
CBI CONTROL,CS2
ret
SELECT_CHIP_2:
SBI CONTROL,CS2
CBI CONTROL,CS1
ret



CLEAR_XY: ;LIGHT SPOT
CPI R17,64
BRSH LIGHT_Y_CS2
LIGHT_Y_CS1:
SBI CONTROL,CS1
CBI CONTROL,CS2
push r16
MOV R16,R17
push r17
CALL SET_Y
pop r17
pop r16
call X_CALC_LIGHT
ret

LIGHT_Y_CS2:
CBI CONTROL,CS1
SBI CONTROL,CS2
SUBI R17, 64
push r16
Mov r16,r17
push r17
CALL SET_Y
pop r17
pop r16
call X_CALC_LIGHT
ret


X_CALC_LIGHT:
push r17
CPI R16,8
BRLO DIRECT_X_light
LDI R17,0
OTHER_PAGE_NUMBER_LIGHT:
SUBI R16,8
INC R17 // page number
CPI R16,8 
BRSH OTHER_PAGE_NUMBER_LIGHT
push r16
MOV R16,R17
CALL SET_X
POP R16
call SHIFT_X
push r16
call READ_D
MOV R17,R16
pop r16
NEG R16
AND R16,R17
mov r1,r16
pop r17
MOV R16,R17
call SET_Y
mov r16,r1
CALL WRITE_D
ret
DIRECT_X_LIGHT:
push R16
LDI R16,0
call SET_X
pop r16
call SHIFT_X
push r16
call READ_D
MOV R17,R16
pop r16
neg r16
AND R16,R17
mov r1,r16
pop r17
mov r16,r17
call SET_Y
MOV R16,R1
call WRITE_D
ret




SET_XY:;R16 for X, R17 for Y, DARK SPOT
CPI R17,64
BRSH Y_CS2
Y_CS1:
SBI CONTROL,CS1
CBI CONTROL,CS2
push r16
MOV R16,R17
push r17
CALL SET_Y
pop r17
pop r16
call X_CALC
ret

Y_CS2:
CBI CONTROL,CS1
SBI CONTROL,CS2
SUBI R17, 64
push r16
Mov r16,r17
push r17
CALL SET_Y
pop r17
pop r16
call X_CALC
ret



X_CALC:
push r17
CPI R16,8
BRLO DIRECT_X
LDI R17,0
OTHER_PAGE_NUMBER:
SUBI R16,8
INC R17 // page number
CPI R16,8 
BRSH OTHER_PAGE_NUMBER
push r16
MOV R16,R17
CALL SET_X
POP R16
call SHIFT_X
push r16
call READ_D
MOV R17,R16
pop r16
OR R16,R17
mov r1,r16
pop r17
MOV R16,R17
call SET_Y
mov r16,r1
CALL WRITE_D
ret
DIRECT_X:
push R16
LDI R16,0
call SET_X
pop r16
call SHIFT_X
push r16
call READ_D
MOV R17,R16
pop r16
OR R16,R17
mov r1,r16
pop r17
mov r16,r17
call SET_Y
MOV R16,R1
call WRITE_D
ret



SHIFT_X:
SEC //SET CARRY FLAG
LDI R17,0
INC R16
other_shift:
ROL R17
DEC R16
BRNE other_shift
MOV R16,R17
ret


SET_X: ;X AT R16 (0-7)
ANDI R16, 0b00000111
ldi r17, 0b10111000
OR R16,R17
call WRITE_I
ret

SET_Y:; Y AT R16 (0-64)
ANDI R16,0b00111111
LDI R17, 0b01000000
OR R16,R17
call WRITE_I
ret

SET_DISPLAY_START_LINE:; START LINE AT R16
SBR R16,0xC0
call WRITE_I
ret



LCD_ON:
SBI CONTROL,CS1
SBI CONTROL,CS2
CBI CONTROL, RS
CBI CONTROL, RW
LDI R16, 0X3F
OUT DATA, R16
call TRIGGER_ENABLE
ret


LCD_OFF:
SBI CONTROL,CS1
SBI CONTROL,CS2
CBI CONTROL, RS
CBI CONTROL, RW
LDI R16, 0X3E
OUT DATA, R16
call TRIGGER_ENABLE
ret


TRIGGER_ENABLE:
call delay10us
SBI CONTROL, ENABLE
call delay10us
CBI CONTROL, ENABLE
;call delay10us
ret


WRITE_I:
CBI CONTROL,RS
CBI CONTROL,RW
OUT DATA, R16
call TRIGGER_ENABLE
ret

WRITE_D:
SBI CONTROL,RS
CBI CONTROL,RW
OUT DATA, R16
call TRIGGER_ENABLE
ret

READ_D:
ldi r16,0
out DATA_DDR,R16
SBI CONTROL,RS
SBI CONTROL,RW
call delay1us
SBI CONTROL, ENABLE
call delay1us
CBI CONTROL, ENABLE
call delay10us
call delay10us
SBI CONTROL,ENABLE
CALL delay1us
IN R16,DATA_PIN
CBI CONTROL,ENABLE
call delay1us
push r16
ldi r16,0xff
out DATA_DDR,R16;keep as output
pop r16
ret

delay10us:
push r20
ldi r20, 80
ciclo_delay10us:
DEC R20
BRNE ciclo_delay10us
pop r20
ret

delay5us:
push r20
ldi r20,10
ciclo_delay5us:
dec r20
brne ciclo_delay5us
pop r20
ret


delay1us:
push r20
ldi r20, 8
ciclo_delay1us:
DEC R20
BRNE ciclo_delay1us
pop r20
ret


delay10ms:
	push r20
	push r21
	LDI R20, 104
	ciclo1: LDI R21, 255
	ciclo:  dec r21
		BRNE ciclo
		DEC R20
		BRNE CICLO1
		pop r21
		pop r20
RET

delay100ms:
push r20
ldi r20,10
other_delay100ms:
call delay10ms
dec r20
brne other_delay100ms
pop r20
ret

delay1s:
push r20
ldi r20,100
other_delay1s:
	call delay10ms
	dec r20
	brne other_delay1s
pop r20
ret

delay10s:
push r20
ldi r20,10
other_delay10s:
	call delay1s
	dec r20
	brne other_delay10s
pop r20
ret

delay5s:
push r20
ldi r20,5
other_delay5s:
	call delay1s
	dec r20
	brne other_delay5s
pop r20
ret

.org IMAGE
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,254,254,254,6,6,6,6,6
.db 6,6,6,6,12,252,248,224,0,0,0,224,240,248,24,12
.db 6,6,6,6,6,6,4,12,120,248,224,0,0,0,0,0
.db 254,254,254,124,248,224,0,0,0,0,0,0,254,254,254,0
.db 0,0,0,128,240,248,24,12,6,6,6,6,6,6,4,28
.db 248,248,224,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,255,255,255,12,12,12,12,12
.db 12,12,12,14,14,7,3,0,0,0,0,63,255,249,128,0
.db 0,0,0,0,0,0,0,128,224,255,127,14,0,0,0,0
.db 255,255,255,0,0,1,7,30,60,240,192,128,255,255,255,0
.db 0,0,0,63,255,255,128,0,0,0,0,0,0,12,12,12
.db 252,252,252,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,15,15,15,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,3
.db 3,15,14,14,15,3,3,3,1,0,0,0,0,0,0,0
.db 15,15,15,0,0,0,0,0,0,0,1,3,15,15,15,0
.db 0,0,0,0,0,0,1,3,3,15,14,14,14,15,3,3
.db 1,15,15,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,192,64,64
.db 64,64,64,0,0,0,192,64,64,64,64,64,64,192,0,0
.db 0,192,64,64,64,64,64,64,192,0,0,0,192,64,64,64
.db 64,64,64,192,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,8,15,8,8,200
.db 56,0,0,192,56,7,0,0,0,0,192,56,7,0,192,56
.db 7,0,0,0,0,192,56,7,0,192,56,7,0,0,0,0
.db 192,56,7,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,1,3,2,2,2,2,2,2,1
.db 0,0,1,3,2,2,2,2,2,2,1,0,0,1,3,2
.db 2,2,2,2,2,1,0,0,1,3,2,2,2,2,2,2
.db 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
.db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0



























