; a2_morse.asm
; CSC 230: Summer 2019
;
; Student name: Tarush Roy
; Student ID: V00883469
; Date of completed work: 6/27/2019
;
; *******************************
; Code provided for Assignment #2
;
; Author: Mike Zastre (2019-Jun-12)
; 
; This skeleton of an assembly-language program is provided to help you
; begin with the programming tasks for A#2. As with A#1, there are 
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

.include "m2560def.inc"

.cseg
.equ S_DDRB=0x24
.equ S_PORTB=0x25
.equ S_DDRL=0x10A
.equ S_PORTL=0x10B

	
.org 0
	; Copy test encoding (of 'sos') into SRAM
	;
	ldi ZH, high(TESTBUFFER)
	ldi ZL, low(TESTBUFFER)
	ldi r16, 0x30
	st Z+, r16
	ldi r16, 0x37
	st Z+, r16
	ldi r16, 0x30
	st Z+, r16
	clr r16
	st Z, r16

	; initialize run-time stack
	ldi r17, high(0x21ff)
	ldi r16, low(0x21ff)
	out SPH, r17
	out SPL, r16

	; initialize LED ports to output
	ldi r17, 0xff
	sts S_DDRB, r17
	sts S_DDRL, r17

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================

; ***************************************************
; **** BEGINNING OF FIRST "STUDENT CODE" SECTION **** 
; ***************************************************

	; If you're not yet ready to execute the
	; encoding and flashing, then leave the
	; rjmp in below. Otherwise delete it or
	; comment it out.

	;rjmp stop

    ; The following seven lines are only for testing of your
    ; code in part B. When you are confident that your part B
    ; is working, you can then delete these seven lines. 
	;ldi r17, high(TESTBUFFER)
	;ldi r16, low(TESTBUFFER)
	;push r17
	;push r16
	;rcall flash_message
    ;pop r16
    ;pop r17

	
   
; ***************************************************
; **** END OF FIRST "STUDENT CODE" SECTION ********** 
; ***************************************************


; ################################################
; #### BEGINNING OF "TOUCH CAREFULLY" SECTION ####
; ################################################

; The only things you can change in this section is
; the message (i.e., MESSAGE01 or MESSAGE02 or MESSAGE03,
; etc., up to MESSAGE09).
;

	; encode a message
	;
	ldi r17, high(MESSAGE02 << 1)
	ldi r16, low(MESSAGE02 << 1)
	push r17
	push r16
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall encode_message
	pop r16
	pop r16
	pop r16
	pop r16

; ##########################################
; #### END OF "TOUCH CAREFULLY" SECTION ####
; ##########################################


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================
	; display the message three times
	;
	ldi r18, 3
main_loop:
	ldi r17, high(BUFFER01)
	ldi r16, low(BUFFER01)
	push r17
	push r16
	rcall flash_message
	dec r18
	tst r18
	brne main_loop


stop:
	rjmp stop
; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================


; ****************************************************
; **** BEGINNING OF SECOND "STUDENT CODE" SECTION **** 
; ****************************************************


flash_message:
.set PARAM_OFFSET = 10
	push r30
	push r31
	push r16
	push r17
	push YH
	push YL
	in YH, SPH
	in YL, SPL

	; Reading in address for start of dot-dash sequence
	ldd ZL, Y + PARAM_OFFSET
	ldd ZH, Y + PARAM_OFFSET + 1

; Calls morse_flash for each byte
loop2:
	ld r17, Z+
	cpi r17, 0
	breq loop2end
	mov r16, r17
	call morse_flash
	rjmp loop2

loop2end:
	pop YL
	pop YH
	pop r17
	pop r16
	pop r31
	pop r30
	ret



morse_flash:
	push r17
	push r18
	push r19
	push r20

	; Space character handling
	cpi r16, 0xff
	breq end

	mov r17, r16
	swap r16
	andi r16, 0b00001111 ;length
	andi r17, 0b00001111 ;sequence
	mov r20, r16
	ldi r18, 1

; Pushing onto stack, the sequence of dot-dash(es) from LSB to MSB
; so that it can call the leds_on and leds_off in the right order
; by popping off those values and handling the dots and dashes accordingly
loop1:
	cpi r16, 0
	breq part2
	mov r19, r17
	and r19, r18
	lsl r18
	push r19
loop1end:
	dec r16
	rjmp loop1
part2:
	pop r19
	cpi r19, 0
	brne dash
dot:push r16
	ldi r16, 2
	call leds_on
	pop r16
	call delay_short
	call leds_off
	call delay_long
	cpi r20, 1
	breq end
	dec r20
	rjmp part2
dash:
	push r16
	ldi r16, 4
	call leds_on
	pop r16
	call delay_long
	call leds_off
	call delay_long
	cpi r20, 1
	breq end
	dec r20
	rjmp part2

end:call delay_long
	call delay_long
	call delay_long

	pop r20
	pop r19
	pop r18
	pop r17
	ret


; Input: number of LEDs to be turned on
; what it does:
; initializes 2 registers to first and last values of LED
; if r16 is not 0, turn on 1 LED, then dec r16. <-- This loops until r16 is 0
leds_on:
	push r17
	push r18
	push r19
	push r20
	ldi r17, 0b10000000
	ldi r18, 0b00000010
	ldi r19, 0
leds_on_loop:
	cpi r16, 0
	breq leds_ret
	cpi r19, 4
	brsh diff
	sts PORTL, r17
	mov r20, r17
	lsr r17
	lsr r17
	or r17, r20
	rjmp cont
diff:
	out PORTB, r18
	mov r20, r18
	lsl r18
	lsl r18
	or r18, r20
cont:
	inc r19
	dec r16
	rjmp leds_on_loop
leds_ret:
	pop r20
	pop r19
	pop r18
	pop r17
	ret


; Turns off all LEDs
leds_off:
	push r17
	ldi r17, 0
	sts PORTL, r17
	out PORTB, r17
	pop r17
	ret


; Reads character, calls alphabet_encode, stores one-byte equivalent in buffer
encode_message:
	push r16
	push r17
	push r18
	push r19
	push r20
	push r21
	push YH
	push YL

	in YH, SPH
	in YL, SPL

	ldd XL, Y + 12 ;buffer address for storing
	ldd XH, Y + 13 
	ldd ZL, Y + 14	;address to read
	ldd ZH, Y + 15

enc_loop1:
	lpm r16, Z+
	cpi r16, 0
	breq enc_end
	push r16
	call alphabet_encode
	pop r16
	st X+, r0
	rjmp enc_loop1
enc_end:
	pop YL
	pop YH
	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	ret	



alphabet_encode:
	push r16
	push r17
	push r18
	push r19
	push r20
	push r21
	push r22
	push r23
	push r24
	push r25
	push r26
	push r27
	push YH
	push YL
	push ZH
	push ZL

	in YH, SPH
	in YL, SPL
	ldd r17, Y + 20 ;letter from stack
	ldi ZH, high(ITU_MORSE << 1)
	ldi ZL, low(ITU_MORSE << 1)
	ldi r18, '.'
	ldi r19, '-'
	ldi r20, 0
	ldi r21, 1
	ldi r22, low(8)
	ldi r23, high(8)
	ldi r24, low(1)
	ldi r25, high(1)
	ldi r26, 0

s1:	cpi r16, 0x20 ; Space character handling
	breq fe
	lpm r16, Z
	cp r16, r17 ;check if letter is equal to byte from morse table
	brne skip1

; loop s2 pushes dot-dash seq for character in reverse order
; so it can be popped off and stored at buffer address in right order
s2:	add ZL, r24 ;z=z+1
	adc ZH, r25 ;
	lpm r16, Z
	cpi r16, 0
	breq s25
	inc r26
	push r16
	rjmp s2

; runs dot code if dot, dash code if dash while popping off values from the stack
s25:mov r27, r26
s3:	cpi r27, 0
	breq exit1
	dec r27
	pop r16
	cp r16, r18
	brne ae_dash
ae_dot:
	lsl r21
	rjmp s3
ae_dash:
	or r20, r21
	lsl r21
	rjmp s3

skip1:
	add ZL, r22 ;z=z+8
	adc ZH, r23 ;
	rjmp s1

exit1:
	mov r0, r20
	swap r26	; Adds length to
	or r0, r26	; first nibble
	rjmp alp_end

; Space character handling
fe:
	ldi r20, 0xff
	mov r0, r20

alp_end:
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop r27
	pop r26
	pop r25
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	ret	 


; **********************************************
; **** END OF SECOND "STUDENT CODE" SECTION **** 
; **********************************************


; =============================================
; ==== BEGINNING OF "DO NOT TOUCH" SECTION ====
; =============================================

delay_long:
	rcall delay
	rcall delay
	rcall delay
	ret

delay_short:
	rcall delay
	ret

; When wanting about a 1/5th of second delay, all other
; code must call this function
;
delay:
	rcall delay_busywait
	ret


; This function is ONLY called from "delay", and
; never directly from other code.
;
delay_busywait:
	push r16
	push r17
	push r18

	ldi r16, 0x08
delay_busywait_loop1:
	dec r16
	breq delay_busywait_exit
	
	ldi r17, 0xff
delay_busywait_loop2:
	dec	r17
	breq delay_busywait_loop1

	ldi r18, 0xff
delay_busywait_loop3:
	dec r18
	breq delay_busywait_loop2
	rjmp delay_busywait_loop3

delay_busywait_exit:
	pop r18
	pop r17
	pop r16
	ret



.org 0x1000

ITU_MORSE: .db "a", ".-", 0, 0, 0, 0, 0
	.db "b", "-...", 0, 0, 0
	.db "c", "-.-.", 0, 0, 0
	.db "d", "-..", 0, 0, 0, 0
	.db "e", ".", 0, 0, 0, 0, 0, 0
	.db "f", "..-.", 0, 0, 0
	.db "g", "--.", 0, 0, 0, 0
	.db "h", "....", 0, 0, 0
	.db "i", "..", 0, 0, 0, 0, 0
	.db "j", ".---", 0, 0, 0
	.db "k", "-.-", 0, 0, 0, 0
	.db "l", ".-..", 0, 0, 0
	.db "m", "--", 0, 0, 0, 0, 0
	.db "n", "-.", 0, 0, 0, 0, 0
	.db "o", "---", 0, 0, 0, 0
	.db "p", ".--.", 0, 0, 0
	.db "q", "--.-", 0, 0, 0
	.db "r", ".-.", 0, 0, 0, 0
	.db "s", "...", 0, 0, 0, 0
	.db "t", "-", 0, 0, 0, 0, 0, 0
	.db "u", "..-", 0, 0, 0, 0
	.db "v", "...-", 0, 0, 0
	.db "w", ".--", 0, 0, 0, 0
	.db "x", "-..-", 0, 0, 0
	.db "y", "-.--", 0, 0, 0
	.db "z", "--..", 0, 0, 0
	.db 0, 0, 0, 0, 0, 0, 0, 0

MESSAGE01: .db "a a a", 0
MESSAGE02: .db "sos", 0
MESSAGE03: .db "a box", 0
MESSAGE04: .db "dairy queen", 0
MESSAGE05: .db "the shape of water", 0, 0
MESSAGE06: .db "john wick parabellum", 0, 0
MESSAGE07: .db "how to train your dragon", 0, 0
MESSAGE08: .db "oh canada our own and native land", 0
MESSAGE09: .db "is that your final answer", 0

; First message ever sent by Morse code (in 1844)
MESSAGE10: .db "what god hath wrought", 0


.dseg
.org 0x200
BUFFER01: .byte 128
BUFFER02: .byte 128
TESTBUFFER: .byte 4

; =======================================
; ==== END OF "DO NOT TOUCH" SECTION ====
; =======================================