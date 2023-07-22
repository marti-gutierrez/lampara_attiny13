;
; lampara_nocturna.asm
;
; Created: 7/21/2023 12:00:20 PM
; Author : marti
; Description: Programa para bajar la intensidad luminosa por medio de PWM(PB0/OC0A), de
; 2 botones para incrementar(PB1/INT0) y decrementar(PB2/PCINT2)

.include "tn13def.inc"

#define PIN_UP    PB1
#define PIN_DOWN  PB2
#define PIN_PWM   PB0

.def reg_step = r17
.def reg_dirb = r18
.def reg_mask = r19
.equ STEP = 17

.cseg
.org 0x0000 rjmp reset
.org 0x0001 rjmp int0_up
.org 0x0002 rjmp pcint0_down

reset:
	ldi   r16,low(RAMEND)
	out   SPL,r16
	ldi   reg_step,STEP
	ldi   reg_mask,1<<PIN_DOWN
	; configure GPIO
	ldi   r16,0<<PIN_DOWN|0<<PIN_UP|1<<PIN_PWM
	out   DDRB,r16
	ldi   r16,0x00
	out   PORTB,r16
	; configure pwm for OC0B input
	ldi   r16,1<<COM0A1|0<<COM0A0|1<<WGM01|1<<WGM00  ; Compare mode: Clear OC0A | Fast PWM
	out   TCCR0A,r16
	ldi   r16,0<<WGM02|0<<CS02|1<<CS01|0<<CS00       ; 4MHz/(8*256) = 1.95KHz
	out   TCCR0B,r16
	ldi   r16,0                                      ; init Duty cicle = 0%
	out   OCR0A,r16
	; configure interruptions
	ldi   r16,0<<SE|0<<SM1|0<<SM0|1<<ISC01|1<<ISC00 ; sleep: idle | the rising-edge INT0
	out   MCUCR,r16
	ldi   r16,1<<PCIE|1<<INT0   ; enable INT0 and PCINT0
	out   GIMSK,r16
	ldi   r16,1<<PCINT2         ; mask for PB2 pin-change
	out   PCMSK,r16
	sei
	in    r16,MCUCR
	ori   r16,1<<SE
	out   MCUCR,r16
wait:
	sleep
	rjmp  wait

;pin change interrupt
int0_up:
	in    r16,OCR0A
	cpi   r16,255
	breq  wait
	add   r16,reg_step
	out   OCR0A,r16
	reti

pcint0_down:
	in    reg_dirb,PINB
	in    r16,OCR0A
	and   reg_dirb,reg_mask
	cp    reg_dirb,reg_mask
	brne  wait
	cpi   r16,0
	breq  wait
	sub   r16,reg_step
	out   OCR0A,r16
	reti


