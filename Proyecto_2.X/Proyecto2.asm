;********************************************************************************
 ;Daniel Mundo 
;19508
;UVG
; Proyecto 2: Etch a Sketch
;********************************************************************************
; Assembly source line config statements

#include "p16f887.inc"

; CONFIG1
; __config 0xE0D4
 __CONFIG _CONFIG1, _FOSC_INTRC_NOCLKOUT & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
; CONFIG2
; __config 0xFFFF
 __CONFIG _CONFIG2, _BOR4V_BOR40V & _WRT_OFF
 
 
 PR_VAR	    UDATA
CONT1		    RES 1		    ;Variable para delays
CONT2		    RES 1		    ;para delays
DISPX_L	    RES 1		    ;contiene los bits 0 - 99, eje x
DISX_H	    RES 1		    ;contiene los valores de  0 - 9, eje x
DISY_L		    RES 1		    ;contiene los bits 0 - 99, eje y
DISY_H	    RES 1		    ;contiene los valores de  0 - 9, eje y
NIBB_L		    RES 1		    ;utilizada para los nibbles menos significativos
NIBB_H		    RES 1		    ;utilizada para el nibble mas significativo
LED		    RES 1		    ;variable para mostrar el valor de los leds
TEMP_STATUS	    RES 1		    ;para interrupcion
TEMP_W	    RES 1		    ;para	    ||
FLAGS		    RES 1		    ;para el multiplexeo  

RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;************************************Interrupcion********************************
ISR_VECT   CODE    0X0004
SAVE:					;Sirve para guardar el valor actual de:
    MOVWF	TEMP_W		;"W"
    SWAPF	STATUS, W
    MOVWF	TEMP_STATUS		;& STATUS
ISR:
    BTFSS	PIR1, ADIF
    GOTO	LOAD
    BCF		PIR1, ADIF
    MOVFW	ADRESH
    MOVWF	DISPLAY_V
    BSF		ADCON0, GO
LOAD:					;Se recupera el valor de:
    SWAPF	TEMP_STATUS, W
    MOVWF	STATUS		;STATUS
    SWAPF	TEMP_W, F
    SWAPF	TEMP_W, W		;& de "W"
    BSF		INTCON, GIE		;se habilitan la interrupciones globales
    RETFIE
;-------------------------------------Tabla----------------------------------------------
TABLA
    ADDWF PCL , F
		;    PCDEGFAB
    RETLW	B'01110111'   ; 0 EN EL DISPLAY
    RETLW	B'01000001' ; 1
    RETLW	B'00111011' ; 2
    RETLW	B'01101011' ; 3
    RETLW	B'01001101' ; 4
    RETLW	B'01101110' ; 5
    RETLW	B'01111110' ; 6
    RETLW	B'01000011' ; 7
    RETLW	B'01111111' ; 8
    RETLW	B'01101111' ; 9
 RETURN

MAIN_PROG CODE                      ; let linker place main program
 
START
    BSF		 STATUS, 6
    BSF		STATUS, 5		;--------------------Banco 3----------------
    CLRF		ANSEL
    CLRF		ANSELH
    BSF		ANSELH,  ANS8		;Se habilita el analogico en B1
    BSF		ANSELH, ANS10		;Se habilita el analogico en B2
    BCF		STATUS, 6		;-------------------Banco 1------------------
    MOVLW	B'00000110'
    MOVWF	TRISB			;Solo B1 & B2 como entrada.
    CLRF		TRISA			;Seleccion de displays.
    CLRF		TRISD			;Displays. 
    ;------------------------Configuracion de ADC-----------------------------------------
    BCF		ADCON1, ADFM		;Justificado a la izquierda.
    BCF		ADCON1, VCFG1		;Ref: VSS.
    BCF		ADCON1, VCFG0		;Ref: VDD.
    ;-------------------Configuracion de Interrupcion--------------------------------------
    BSF		INTCON, GIE		;Se habilitaron la interrupciones globales,
    BSF		INTCON, PEIE		;perifericas,
    BSF		PIE1, ADIE		;y la interrupciones por el A/D.
    BCF		STATUS, 5		;-------------------Banco 0------------------
    CLRF		PORTA			;Se limpian los puertos.
    CLRF		PORTB
    CLRF		PORTD
    CLRF		DISPLAY_V		;Se limpian las variables.
    CLRF		NIBB_H
    CLRF		NIBB_L    
    CLRF		BANDERAS
    MOVLW	B'01110011'		;Fosc/8, ANS12 & conversion activada.
    MOVWF	ADCON0
    BCF		PIR1, ADIF		;Se apaga la bandera del A/D.
    CALL		DELAY_4US
    BSF		ADCON0, GO
LOOP: 
    CALL		SEPARAR_NIBBLES
    CALL		DISPLAY
    GOTO LOOP

    GOTO $                          ; loop forever

    END