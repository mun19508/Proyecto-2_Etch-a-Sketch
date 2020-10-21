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
;-----------------------------------Constantes------------------------------------------- 
VALOR_CERO	EQU	.0
DISPLAYS_X	EQU	.1	
;-------------------------------------Variables------------------------------------------	
PR_VAR		UDATA
CONT1		    RES 1		    ;Variable para delays
CONT2		    RES 1		    ;para delays
DISPLAY_V	    RES 1
DISP_L		    RES 1		    ;contiene los bits 0 - 99, eje x
DISX_H	    RES 1		    ;contiene los valores de  0 - 9, eje x
DISY_L		    RES 1		    ;contiene los bits 0 - 99, eje y
DISY_H	    RES 1		    ;contiene los valores de  0 - 9, eje y
NIBB_L		    RES 1		    ;utilizada para los nibbles menos significativos
NIBB_H		    RES 1		    ;utilizada para el nibble mas significativo
LED		    RES 1		    ;variable para selecionar el eje actual.
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
    GOTO		ADC_C
    BTFSS	PIR1, RCIF		
    GOTO		RECEPCION
ADC_C:
    ;Configurar este apartado para cambiar de canal: ADCON, 2 =1 -> AN9 & ADCON, 2 =1 -> AN8
    BCF		PIR1, ADIF
    MOVFW	ADRESH
    MOVWF	DISPLAY_V
    BSF		ADCON0, GO
   GOTO		LOAD
RECEPCION:
    
    GOTO		LOAD
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
     ;-----------------Configuracion de Recepcion/transmision-----------------------------
    MOVWF	SPBRG			;Baud Rate 9615.
    BSF		TXSTA, 2		;Modo de alta velocidad. 
    BCF		TXSTA, 4		;Modo Asincronico. 
    BSF		TXSTA,  5		;Bit de transmicion activo. 
    BCF		TXSTA,  6		;Transmicion de 8 bits. 
    ;-------------------Configuracion de Interrupcion--------------------------------------
    BSF		INTCON, GIE		;Se habilitaron la interrupciones globales,
    BSF		INTCON, PEIE		;perifericas,
    BSF		PIE1, ADIE		;y la interrupciones por el A/D.
    MOVLW	B'01100001'		;Fosc/8, ANS8 & conversion activada.
    MOVWF	ADCON0
    BCF		STATUS, 5		;-------------------Banco 0------------------
  ;-----------------Configuracion de Recepcion/transmision-------------------------------
    BSF		RCSTA, SPEN		;Habilitar puerto serial. 
    BSF		RCSTA, CREN		;Habilitar recepcion continua. 	
    BCF		RCSTA, RX9		;Recepcion de 8 bits. 	
   ;----------------------------Se limpian los puertos-------------------------------------
    CLRF		PORTA			
    CLRF		PORTB
    CLRF		PORTD
    ;----------------------------Se limpian las variables------------------------------------
    CLRF		DISPLAY_V		
    CLRF		NIBB_H
    CLRF		NIBB_L    
    CLRF		FLAGS    
EJE_X:
    CLRF		LED
    ;BCF		PIR1, ADIF		;Se apaga la bandera del A/D.
    CALL		DELAY_4US
    BSF		ADCON0, GO
    BTFSC	ADCON0, GO
    GOTO		$-1
    MOVFW	ADRESH
    MOVWF	DISPLAY_V
    CALL		SEPARAR_NIBBLES
    CALL		DISPLAY
EJE_Y: 
    BSF		LED, VALOR_CERO
    MOVLW	B'01101001'		;Fosc/8, ANS10 & conversion activada.
    MOVWF	ADCON0
    BCF		PIR1, ADIF		;Se apaga la bandera del A/D.
    CALL		DELAY_4US
    BSF		ADCON0, GO
   BTFSC		ADCON0, GO
    GOTO		$-1
    MOVFW	ADRESH
    MOVWF	DISPLAY_V
    CALL		SEPARAR_NIBBLES
    CALL		DISPLAY
FIN:    
    CALL		TOGGLES  
    GOTO		EJE_X
    ;configurar una especie de menu donde se use algun bit para mantener la seleccion del eje 
    ; los nibbles son los que tienen que ser especificos. restringir el aumento y la disminucion 
    ;del tercer display.
;-----------------------------------------Subrutinas--------------------------------------    
SEPARAR_NIBBLES
    MOVF		DISPLAY_V, W		
    ANDLW	B'00001111'		
    MOVWF	 NIBB_L		
    SWAPF	DISPLAY_V, W		
    ANDLW	B'00001111'		
    MOVWF	NIBB_H		
    RETURN
    
DISPLAY				
   CLRF		PORTA			    ;valores de las variables.
    MOVF		FLAGS,W		    ;Dependiendo del actual valor de banderas
    ADDWF	PCL,F			    ;se selecciona el diplays que va a mostrar su valor:
   GOTO		DISPLAY_0		    ;Para los displays del eje x
    GOTO		DISPLAY_1		    ;	    ||
    GOTO		DISPLAY_2		    ;	    ||
    ;GOTO		DISPLAY_3		    ;Para los displays del eje y
 ;  GOTO		DISPLAY_4		    ;	    ||
    ;GOTO		DISPLAY_5		    ;	    ||
DISPLAY_0:
   MOVF		NIBB_H, W		
   CALL		TABLA			
   MOVWF	PORTD	
   BTFSC		LED, VALOR_CERO
   GOTO		$+3
   BSF		PORTA,  0
   GOTO		END_DIS
   BSF		PORTA,  3	
   GOTO		END_DIS
DISPLAY_1:   
   MOVF		NIBB_L, W		
   CALL		TABLA			
   MOVWF	PORTD
  BTFSC		LED, VALOR_CERO
   GOTO		$+3
   BSF		PORTA,  1
   GOTO		END_DIS
   BSF		PORTA,  4	
   GOTO		END_DIS
DISPLAY_2:
   MOVF		NIBB_H, W		
   CALL		TABLA
   MOVWF	PORTD
   BTFSC    	LED, VALOR_CERO 
   GOTO		$+3
   BSF		PORTA,  2
   GOTO		END_DIS
   BSF		PORTA,  5	
   GOTO		END_DIS
;DISPLAY_3:   
 ;  MOVF		NIBB_L, W		
  ; CALL		TABLA			
  ; MOVWF	PORTD			
   ;BSF		PORTA,  3		
   ;GOTO		END_DIS
;DISPLAY_4:
  ; MOVF		NIBB_H, W		
 ;  CALL		TABLA			
  ; MOVWF	PORTD			
  ; BSF		PORTA,  4	
  ; GOTO		END_DIS
;DISPLAY_5:   
  ; MOVF		NIBB_L, W		
   ;CALL		TABLA
 ;  MOVLW	VALOR_CERO
 ;  MOVWF	PORTD			
;   BSF		PORTA,  5		
   ;GOTO		END_DIS
END_DIS:
  RETURN  
  
TOGGLES:				;Se incrementa el valor de banderas cada
    INCF		FLAGS,F		;vez que que se llama a la funcion.
    MOVLW	.3			;Debido a que hay 6 displays, se resetea
    SUBWF	FLAGS,W		;la variable cada vez que esta tiene un valor
    BTFSC	STATUS, Z		;de 6.
    CLRF		FLAGS
    RETURN
 
DELAY_4US				;DELAY DE  4us (supuestamente)
    MOVLW   .25
    MOVWF   CONT1
    DECFSZ  CONT1, F	
    GOTO    $-1 
   RETURN    
 
    END