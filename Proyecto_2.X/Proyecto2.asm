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
COMA		EQU	.44
CON_ASCII	EQU	.48
CONFG_TMR0	EQU	.129
CONT_TMR0	EQU	.6
NUEVA_LINEA	EQU	.10
;*********************************Variables**************************************
PR_VAR		UDATA
;---------------------------------------Delays--------------------------------------------
CONT1		    RES 1		    ;Variable para delays
CONT2		    RES 1		    ;para delays
;---------------------------------Para los ejes, enviar------------------------------------
VAR_CDU	    RES 1		    ;contiene el valor conjunto de unidades, decenas y centenas
VAR_U		    RES 1		    ;contiene las unidades
VAR_D		    RES 1		    ;contiene las decenas
VAR_C		    RES 1		    ;contiene las centenas		    
VAR_X		    RES 1		    ;contiene el valor leido en el canal AN8
VARX_U	    RES 1		    ;contiene las unidades del eje x
VARX_D	    RES 1		    ;contiene las decenas del eje x
VARX_C	    RES 1		    ;contiene las centenas del eje x
VAR_Y		    RES 1		    ;contiene el valor leido en el canal AN9
VARY_U	    RES 1		    ;contiene las unidades del eje y
VARY_D	    RES 1		    ;contiene las decenas del eje y
VARY_C		    RES 1		    ;contiene las centenas del eje y
;-------------------------------Para mostrar los datos-----------------------------------
DISY_L		    RES 1		    ;contiene el valor del display mas bajo, del eje y
DISY_M	    RES 1		    ;contiene el valor del display el medio, del eje y
DISY_H	    RES 1		    ;contiene el valor del display mas alto, del eje y
DISX_L		    RES 1		    ;contiene el valor del display mas bajo, del eje x
DISX_M	    RES 1		    ;contiene el valor del display el medio,  del eje x
DISX_H	    RES 1		    ;contiene el valor del display mas alto, del eje x
EJE_XY		    RES 1		    ;variable para selecionar el eje actual.
FLAGS		    RES 1		    ;para el multiplexeo  
;---------------------------------Interrupcion--------------------------------------------		    
TEMP_STATUS	    RES 1		    ;para interrupcion
TEMP_W	    RES 1		    ;para	    ||


RES_VECT  CODE    0x0000            ; processor reset vector
    GOTO    START                   ; go to beginning of program
    
;************************************Interrupcion********************************
ISR_VECT   CODE    0X0004
SAVE:					;Sirve para guardar el valor actual de:
    MOVWF	TEMP_W		;"W"
    SWAPF	STATUS, W
    MOVWF	TEMP_STATUS		;& STATUS
ISR:
    BTFSS	INTCON, T0IF		;Interrupcion del TRM0
    GOTO		MUX
    BTFSS	PIR1, ADIF		;Interrupcion del ADC
    GOTO		ADC_C
    BTFSS	PIR1, RCIF		;Interrupcion de la recepcion
    GOTO		RECEPCION
MUX:
    MOVLW	CONT_TMR0
    MOVWF	TMR0
    CALL		DISPLAY
    INCF		FLAGS, F
    GOTO		LOAD
ADC_C:		;Configurar este apartado para cambiar de canal: ADCON, 2 =1 -> AN9 & ADCON, 2 =1 -> AN8    
    BTFSC	ADCON0, 2
    GOTO		DATA_Y
    BCF		PIR1, ADIF
    MOVFW	ADRESH
    MOVWF	VAR_X
    BSF		ADCON0, 2 
   GOTO		INICIO_CON
DATA_Y:
    BCF		PIR1, ADIF
    MOVFW	ADRESH
    MOVWF	VAR_Y
    BCF		ADCON0, 2 
    GOTO		INICIO_CON
RECEPCION:
    MOVFW	RCREG			;Se mueve el valor recibido
    MOVWF	VAR_CDU		;a la variable de los displays
    GOTO		LOAD
INICIO_CON:
    NOP
    NOP
    NOP
    NOP
    NOP
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
    ADDWF	PCL , F
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
 
DISPLAY				
    CLRF		PORTA			    ;valores de las variables.
    MOVF		FLAGS,W		    ;Dependiendo del actual valor de banderas
    ADDWF	PCL,F			    ;se selecciona el diplays que va a mostrar su valor:
    GOTO		DISPLAY_0		    ;Para los displays del eje x
    GOTO		DISPLAY_1		    ;	    ||
    GOTO		DISPLAY_2		    ;	    ||
    GOTO		DISPLAY_3		    ;Para los displays del eje y
    GOTO		DISPLAY_4		    ;	    ||
    GOTO		DISPLAY_5		    ;	    ||
    CLRF		FLAGS
DISPLAY_0:					;Unidades de 'x'.
   MOVF		DISX_L, W		
   CALL		TABLA			
   MOVWF	PORTD	
   BSF		PORTA,  0
   RETURN
DISPLAY_1:					;Decenas de 'x'.
   MOVF		DISX_M, W		
   CALL		TABLA			
   MOVWF	PORTD
   BSF		PORTA,  1
   RETURN
DISPLAY_2:					;Centenas de 'x'.
   MOVF		DISX_H, W
   CALL		TABLA
   MOVWF	PORTD
   BSF		PORTA,  2
   RETURN
DISPLAY_3:					;Unidades de 'y'
    MOVF		DISY_L, W
    CALL		TABLA			
   MOVWF	PORTD			
   BSF		PORTA,  3		
   RETURN
DISPLAY_4:					;Decenas de 'y'.
    MOVF		DISY_M, W		
   CALL		TABLA			
   MOVWF	PORTD			
   BSF		PORTA,  4	
   RETURN
DISPLAY_5:					;Centenas de 'y'.
    MOVF		DISY_H, W
    CALL		TABLA
   MOVWF	PORTD			
   BSF		PORTA,  5		
    RETURN  
    
MAIN_PROG	CODE                      ; let linker place main program
 
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
   MOVLW	CONFG_TMR0
   MOVWF	OPTION_REG 
    BSF		INTCON, GIE		;Se habilitaron la interrupciones globales,
    BSF		INTCON, PEIE		;perifericas,
    BSF		INTCON, T0IE 		;del TRM0.
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
    CLRF		FLAGS    
    CLRF		CONT1		    
    CLRF		CONT2		    
    CLRF		VAR_CDU	   
    CLRF		VAR_U		   
    CLRF		VAR_D		    
    CLRF		VAR_C		    
    CLRF		VAR_X		    
    CLRF		VARX_U	    
    CLRF		VARX_D	    
    CLRF		VARX_C	  
    CLRF		VAR_Y		   
    CLRF		VARY_U	   
    CLRF		VARY_D	   
    CLRF		VARY_C		  
    CLRF		DISY_L		   
    CLRF		DISY_M	    
    CLRF		DISY_H	    
    CLRF		DISX_L		   
    CLRF		DISX_M	  
    CLRF		DISX_H	  
    CLRF		EJE_XY		   	    
LOOP:
;-------------------------------------Eje x-----------------------------------------------
    MOVF		VAR_X, W
    MOVWF	VAR_CDU		;Se mueve el valor del ADC a la variable general
    CALL		CONV_NO		;Se llama a la funcion para pasar el valor de unidades, decenas y centenas
    
    MOVF		VAR_C, W
    MOVWF	VARX_C		;Valor de las centanas que se van a enviar
    
    MOVF		VAR_D, W
    MOVWF	VARX_D		;Valor de las decenas que se van a enviar
    
    MOVF		VAR_U, W
    MOVWF	VARX_U		;Valor de las unidades que se van a enviar 
;-------------------------------------Eje y-----------------------------------------------
    MOVF		VAR_Y, W
    MOVWF	VAR_CDU		;Se mueve el valor del ADC a la variable general
    CALL		CONV_NO		;Se llama a la funcion para pasar el valor de unidades, decenas y centenas
  
    MOVF		VAR_C, W
    MOVWF	VARY_C			;Valor de las centanas que se van a enviar 
    
    MOVF		VAR_D, W
    MOVWF	VARY_D		;Valor de las decenas que se van a enviar
    
    MOVF		VAR_U, W
    MOVWF	VARY_U		;Valor de las unidades que se van a enviar
SEND:
    CALL		ENVIO_DATOS
    
    GOTO		LOOP 
    ;Configurar los datos recibidos en valor de los display, limitado por coma.
;-----------------------------------------Subrutinas-------------------------------------  
CONV_NO
    CLRF		VAR_U			;se obtienen los valores de las centenas, 
   CLRF		VAR_D			;decenas y unidades independientemente
   CLRF		VAR_C			;del eje con el que se trabaje.
CENTENAS:
   MOVLW	.100			;Se le resta un valor, en este caso .100,
   SUBWF	VAR_CDU, W		;luego se verifica si la variable es menor al 
   BTFSS		STATUS, C		;valor sustraido, si es menor se procede a la
   GOTO		DECENAS		;siguiente posición caso contrario se repite el
   INCF		VAR_C			;procedimiento antes descrito hasta que la va- 
   MOVWF	VAR_CDU		;riable tenga un valor menor al sustraido. 
   GOTO		CENTENAS
DECENAS:
   MOVLW	.10			;El procedimiento descrito en Centenas, apli-
   SUBWF	VAR_CDU, W		;ca para decenas. 
   BTFSS		STATUS, C
   GOTO		UNIDADES
   INCF		VAR_D
   MOVWF	VAR_CDU
   GOTO		DECENAS
UNIDADES:
   MOVLW	.1			;El procedimiento descrito en Centenas, apli-
   SUBWF	VAR_CDU, W		;ca para unidades. 
   BTFSS		STATUS, C
   RETURN
   INCF		VAR_U
   MOVWF	VAR_CDU
   GOTO		UNIDADES
   
ENVIO_DATOS
   BTFSS		PIR1,  TXIF		    ;Se revisa si esta ocupado
   RETURN				    ;si lo esta regresa al loop.
   MOVF		EJE_XY, W		    ;Sirve para saber
   ADDWF	PCL,F			    ;que dato se debe de enviar:
   GOTO		DATO_1			    ;Centenas de x
   GOTO		DATO_2		    ;Decenas de x
   GOTO		DATO_3		    ;unidades de x
   GOTO		SEPARADOR		    
   GOTO		DATO_4		    ;mismo orden de x, solo que 
   GOTO		DATO_5		    ;esta ves para y
   GOTO		DATO_6
   GOTO		FIN_LINEA
DATO_1:				    ;se mueve el valor actual y se le suma una 
    MOVF		VARX_C, W		    ;literal de .48 para ajustarlo a su caracter ASCII
    GOTO		AJUSTE		    ;este procedimiento se repite en todos los "DATO_N".
DATO_2:
    MOVF		VARX_D, W
    GOTO		AJUSTE
DATO_3:
    MOVF		VARX_U, W
    GOTO		AJUSTE
SEPARADOR:
    MOVLW	COMA			    ;Caracter especifico para separar las 
    GOTO		ENVIO			    ;coordenadas.
DATO_4:
    MOVF		VARY_C, W
    GOTO		AJUSTE
DATO_5:
    MOVF		VARY_D, W
    GOTO		AJUSTE
DATO_6:
    MOVF		VARY_U, W
    GOTO		AJUSTE
FIN_LINEA:
    MOVLW	NUEVA_LINEA		 ;Sirve para saber que las coordenadas
    GOTO		ENVIO			 ;se han enviado completamente.
AJUSTE:
    ADDLW	CON_ASCII		;equivale a 48 base 10.
ENVIO:
    MOVWF	RCREG
    INCF		EJE_XY, F
    RETURN
    END