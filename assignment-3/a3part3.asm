; a3part3.asm
; CSC 230: Summer 2019
;
; Student name: Tarush Roy
; Student ID: V00883469
; Date of completed work: 7/19/2019
;
; *******************************
; Code provided for Assignment #3
;
; Author: Mike Zastre (2019-Jul-04)
; 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#3. As with A#2, there are 
; "DO NOT TOUCH" sections. You are *not* to modify the lines
; within these sections. The only exceptions are for specific
; changes announced on conneX or in written permission from the course
; instructor. *** Unapproved changes could result in incorrect code
; execution during assignment evaluation, along with an assignment grade
; of zero. ****
;
; I have added for this assignment an additional kind of section
; called "TOUCH CAREFULLY". The intention here is that one or two
; constants can be changed in such a section -- this will be needed
; as you try to test your code on different messages.
;


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
;
; In this "DO NOT TOUCH" section are:
;
; (1) assembler directives setting up the interrupt-vector table
;
; (2) "includes" for the LCD display
;
; (3) some definitions of constants we can use later in the
;     program
;
; (4) code for initial setup of the Analog Digital Converter (in the
;     same manner in which it was set up for Lab #4)
;     
; (5) code for setting up our three timers (timer1, timer3, timer4)
;
; After all this initial code, your own solution's code may start.
;

.cseg
.org 0
	jmp reset

; location in vector table for TIMER1 COMPA
;
.org 0x22
	jmp timer1

; location in vector table for TIMER4 COMPA
;
.org 0x54
	jmp timer4

.include "m2560def.inc"
.include "lcd_function_defs.inc"
.include "lcd_function_code.asm"

.cseg

; These two constants can help given what is required by the
; assignment.
;
#define MAX_PATTERN_LENGTH 10
#define BAR_LENGTH 6

; All of these delays are in seconds
;
#define DELAY1 0.5
#define DELAY3 0.1
#define DELAY4 0.01


; The following lines are executed at assembly time -- their
; whole purpose is to compute the counter values that will later
; be stored into the appropriate Output Compare registers during
; timer setup.
;

#define CLOCK 16.0e6 
.equ PRESCALE_DIV=1024  ; implies CS[2:0] is 0b101
.equ TOP1=int(0.5+(CLOCK/PRESCALE_DIV*DELAY1))

.if TOP1>65535
.error "TOP1 is out of range"
.endif

.equ TOP3=int(0.5+(CLOCK/PRESCALE_DIV*DELAY3))
.if TOP3>65535
.error "TOP3 is out of range"
.endif

.equ TOP4=int(0.5+(CLOCK/PRESCALE_DIV*DELAY4))
.if TOP4>65535
.error "TOP4 is out of range"
.endif


reset:
	; initialize the ADC converter (which is neeeded
	; to read buttons on shield). Note that we'll
	; use the interrupt handler for timer4 to
	; read the buttons (i.e., every 10 ms)
	;
	ldi temp, (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0)
	sts ADCSRA, temp
	ldi temp, (1 << REFS0)
	sts ADMUX, r16


	; timer1 is for the heartbeat -- i.e., part (1)
	;
    ldi r16, high(TOP1)
    sts OCR1AH, r16
    ldi r16, low(TOP1)
    sts OCR1AL, r16
    ldi r16, 0
    sts TCCR1A, r16
    ldi r16, (1 << WGM12) | (1 << CS12) | (1 << CS10)
    sts TCCR1B, temp
	ldi r16, (1 << OCIE1A)
	sts TIMSK1, r16

	; timer3 is for the LCD display updates -- needed for all parts
	;
    ldi r16, high(TOP3)
    sts OCR3AH, r16
    ldi r16, low(TOP3)
    sts OCR3AL, r16
    ldi r16, 0
    sts TCCR3A, r16
    ldi r16, (1 << WGM32) | (1 << CS32) | (1 << CS30)
    sts TCCR3B, temp

	; timer4 is for reading buttons at 10ms intervals -- i.e., part (2)
    ; and part (3)
	;
    ldi r16, high(TOP4)
    sts OCR4AH, r16
    ldi r16, low(TOP4)
    sts OCR4AL, r16
    ldi r16, 0
    sts TCCR4A, r16
    ldi r16, (1 << WGM42) | (1 << CS42) | (1 << CS40)
    sts TCCR4B, temp
	ldi r16, (1 << OCIE4A)
	sts TIMSK4, r16

    ; flip the switch -- i.e., enable the interrupts
    sei

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================


; *********************************************
; **** BEGINNING OF "STUDENT CODE" SECTION **** 
; *********************************************

start:
	; Initializing stack
	ldi r16, low(RAMEND)
	out spl, r16
	ldi r16, high(RAMEND)
	out sph, r16

	; Initializing pulse, button_count and button_previous to zero
	ldi r16, 0
	sts PULSE, r16
	sts BUTTON_PREVIOUS, r16
	sts low(BUTTON_COUNT), r16
	sts high(BUTTON_COUNT), r16

	; Initializing lcd display
	rcall lcd_init

	; This part writes 5 zeros to the bottom right of the display
write_zeros_p2:
	ldi r16, 1
	ldi r17, 15
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, '0'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 1
	ldi r17, 14
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, '0'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 1
	ldi r17, 13
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, '0'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 1
	ldi r17, 12
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, '0'
	push r16
	rcall lcd_putchar
	pop r16
	ldi r16, 1
	ldi r17, 11
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, '0'
	push r16
	rcall lcd_putchar
	pop r16

; Polling loop to check if timer3 has reached its count
ploop:
	in r16, TIFR3
	sbrs r16, OCF3A
	rjmp ploop

	; timer3 has reached its count
	ldi r16, 1<<OCF3A
	out TIFR3, r16

; Reads value of pulse to determine whether it should
; display nothing or a heart
part1:
	lds r16, PULSE
	cpi r16, 1
	brne blank

; Code to display heart
heart:
	ldi r16, 0
	ldi r17, 14
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r16, '<'
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 0
	ldi r17, 15
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r16, '>'
	push r16
	rcall lcd_putchar
	pop r16

	rjmp part2

; Code to display nothing
blank:
	ldi r16, 0
	ldi r17, 14
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r16, ' '
	push r16
	rcall lcd_putchar
	pop r16

	ldi r16, 0
	ldi r17, 15
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16

	ldi r16, ' '
	push r16
	rcall lcd_putchar
	pop r16

; updating lcd display for button count
part2:
	lds r16, BUTTON_CURRENT
	cpi r16, 0
	breq part3

	; call to to_decimal_text with button_count 
	; and display_text as parameters
	lds r17, high(BUTTON_COUNT)
	lds r16, low(BUTTON_COUNT)
	push r17
	push r16
	lds r17, high(DISPLAY_TEXT)
	lds r16, low(DISPLAY_TEXT)
	push r17
	push r16
	rcall to_decimal_text ; function written by Zastre

	; initializing Z to start of display_text
	lds ZH, high(DISPLAY_TEXT)
	lds ZL, low(DISPLAY_TEXT)

	ldi r16, 1
	ldi r17, 11
	ldi r18, 5
print_display_text:
	push r16
	push r17
	rcall lcd_gotoxy ; init pos 1,11
	pop r17
	pop r16
	ld r19, Z+ ; load char value to r19 and move to next char
	push r19
	rcall lcd_putchar ; print char in r19
	pop r19
	dec r18 ; dec loop control
	inc r17 ; inc pos
	cpi r18, 0
	brne print_display_text

part3:
	lds r16, BUTTON_CURRENT
	lds r17, BUTTON_PREVIOUS
	
	cpi r16, 1
	brne no_btn

	rjmp active_btn

no_btn:
	rjmp blank_btn

active_btn:
	ldi r16, 1 ; initialize
	ldi r17, 0 ; position
	ldi r18, BAR_LENGTH
active_btn_loop:
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, '*'
	push r16
	rcall lcd_putchar
	pop r16
	dec r18 ; loop control
	inc r17 ; inc position
	cpi r18, 0
	brne active_btn_loop

	rjmp btn_end

blank_btn:
	ldi r16, 1
	ldi r17, 0
	ldi r18, BAR_LENGTH
blank_btn_loop:
	push r16
	push r17
	rcall lcd_gotoxy
	pop r17
	pop r16
	ldi r16, ' '
	push r16
	rcall lcd_putchar
	pop r16
	dec r18
	inc r17
	cpi r18, 0
	brne blank_btn_loop

btn_end:
	rjmp ploop

stop:
    rjmp stop


; timer1 interrupt handler 
; flips the pulse bit (1 to 0 or 0 to 1) every time it runs i.e. every 50ms
; *PULSE is not actually a bit it's just set up to seem like one
timer1:
	push r16
	push r17
	push r18
	in r16, SREG
	push r16

	ldi r16, 0
	lds r17, PULSE
	cp r17, r16
	brne setp0
setp1:
	ldi r18, 1
	sts PULSE, r18
	rjmp end
setp0:
	ldi r18, 0
	sts PULSE, r18

end:pop r16
	out SREG, r16
	pop r18
	pop r17
	pop r16
	reti

; Note there is no "timer3" interrupt handler as we must use this
; timer3 in a polling style within our main program.

; timer 4 interrupt handler
; reads ADCL and ADCH and stores it in BUTTON_CURRENT
; compares BUTTON_CURRENT and BUTTON_PREVIOUS
; if they are the same, button count is incremented by one
timer4:
	push r16
	in r16, SREG
	push r16
	push r17
	push XH
	push XL

	lds r16, 0x7A
	ori r16, 0x40
	sts 0x7A, r16
wait:
	lds r16, 0x7A
	andi r16, 0x40
	brne wait

	; loading 10-bit value of ADC_BTN
	lds XL, 0x78 ; ADCL
	lds XH, 0x79 ; ADCH

	; loading value of button press threshold
	ldi r16, low(1000)
	ldi r17, high(1000)

	cp XL, r16
	cpc XH, r17
	brsh blank1

	ldi r16, 1
	sts BUTTON_CURRENT, r16
	rjmp check

blank1:
	ldi r16, 0
	sts BUTTON_CURRENT, r16

check:
	lds r16, BUTTON_CURRENT
	lds r17, BUTTON_PREVIOUS
	
	cpi r16, 1
	brne t_btn_c_0 ; if btn_current is 1, go down else go to t_btn_c_0

	cpi r17, 0
	brne t_btn_pc_1

	; here, btn_current is one and btn_prev is 0
	ldi r16, 1
	sts BUTTON_CURRENT, r16

btn_count_add_one:
	lds XL, low(BUTTON_COUNT)
	lds XH, high(BUTTON_COUNT)
	ldi r16, low(1)
	ldi r17, high(1)
	add XL, r16 ; |add one to button_count
	adc XH, r17 ; |  add with carry
	sts low(BUTTON_COUNT), XL  ;|
	sts high(BUTTON_COUNT), XH ;|-store btn_count back to data mem
	rjmp t4end

t_btn_c_0:
	ldi r16, 0
	sts BUTTON_CURRENT, r16
	cpi r17, 1
	brne t4end ; btn_current and btn_prev are zero

	; here, btn_current is zero, btn_prev is one
	ldi r16, 0
	sts BUTTON_CURRENT, r16
	rjmp t4end

; both btn_current and btn_prev are 1
t_btn_pc_1:
	ldi r16, 1
	sts BUTTON_CURRENT, r16

t4end:
	lds r16, BUTTON_CURRENT
	sts BUTTON_PREVIOUS, r16

	pop XL
	pop XH
	pop r17
	pop r16
	out SREG, r16
	pop r16
    reti

; to_decimal_text function written by Michael Zastre
; taken from conneX, CSC230, Lecture slides, other files, hex_to_decimal.asm.pdf
;
; Due to warning "Registers r18, r19 and r16 already defined by the .DEF directive
; even though no .def statements were written. Replaced all .defs with their proper registers
to_decimal_text:
;.def countL=r18
;.def countH=r19
.def factorL=r20
.def factorH=r21
.def multiple=r22
.def pos=r23
.def zero=r0
;.def ascii_zero=r16
	push r19
	push r18
	push factorH
	push factorL
	push multiple
	push pos
	push zero
	push r16
	push YH
	push YL
	push ZH
	push ZL
	in YH, SPH
	in YL, SPL
	; fetch parameters from stack frame
	;
	.set PARAM_OFFSET = 16
	ldd r19, Y+PARAM_OFFSET+3
	ldd r18, Y+PARAM_OFFSET+2
	; this is only designed for positive
	; signed integers; we force a negative
	; integer to be positive.
	;
	andi r19, 0b01111111
	clr zero
	clr pos
	ldi r16, '0'
	; The idea here is to build the text representation
	; digit by digit, starting from the left-most.
	; Since we need only concern ourselves with final
	; text strings having five characters (i.e., our
	; text of the decimal will never be more than
	; five characters in length), we begin we determining
	; how many times 10000 fits into countH:countL, and
	; use that to determine what character (from ’0’ to
	; ’9’) should appear in the left-most position
	; of the string.
	;
	; Then we do the same thing for 1000, then
	; for 100, then for 10, and finally for 1.
	;
	; Note that for *all* of these cases countH:countL is
	; modified. We never write these values back onto
	; that stack. This means the caller of the function
	; can assume call-by-value semantics for the argument
	; passed into the function.
	;
to_decimal_next:
	clr multiple
to_decimal_10000:
	cpi pos, 0
	brne to_decimal_1000
	ldi factorL, low(10000)
	ldi factorH, high(10000)
	rjmp to_decimal_loop
to_decimal_1000:
	cpi pos, 1
	brne to_decimal_100
	ldi factorL, low(1000)
	ldi factorH, high(1000)
	rjmp to_decimal_loop
to_decimal_100:
	cpi pos, 2
	brne to_decimal_10
	ldi factorL, low(100)
	ldi factorH, high(100)
	rjmp to_decimal_loop
to_decimal_10:
	cpi pos, 3
	brne to_decimal_1
	ldi factorL, low(10)
	ldi factorH, high(10)
	rjmp to_decimal_loop
to_decimal_1:
	mov multiple, r18
	rjmp to_decimal_write
to_decimal_loop:
	inc multiple
	sub r18, factorL
	sbc r19, factorH
	brpl to_decimal_loop
	dec multiple
	add r18, factorL
	adc r19, factorH
to_decimal_write:
	ldd ZH, Y+PARAM_OFFSET+1
	ldd ZL, Y+PARAM_OFFSET+0
	add ZL, pos
	adc ZH, zero
	add multiple, r16
	st Z, multiple
	inc pos
	cpi pos, 5
	breq to_decimal_exit
	rjmp to_decimal_next
to_decimal_exit:
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop r16
	pop zero
	pop pos
	pop multiple
	pop factorL
	pop factorH
	pop r18
	pop r19
;.undef countL
;.undef countH
.undef factorL
.undef factorH
.undef multiple
.undef pos
.undef zero
;.undef ascii_zero
ret

; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION ********** 
; ***************************************************


; ################################################
; #### BEGINNING OF "TOUCH CAREFULLY" SECTION ####
; ################################################

; The purpose of these locations in data memory are
; explained in the assignment description.
;

.dseg

PULSE: .byte 1
COUNTER: .byte 2
DISPLAY_TEXT: .byte 16
BUTTON_CURRENT: .byte 1
BUTTON_PREVIOUS: .byte 1
BUTTON_COUNT: .byte 2
BUTTON_LENGTH: .byte 1
DOTDASH_PATTERN: .byte MAX_PATTERN_LENGTH

; ##########################################
; #### END OF "TOUCH CAREFULLY" SECTION ####
; ##########################################