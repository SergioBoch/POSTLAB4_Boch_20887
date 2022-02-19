; Archivo: POSTLABORATORIO4.s
; Dispositivo: PIC16F887
; Autor: Sergio Boch 20887
; Compilador: pic-as (v2.30), MPLABX v5.40
;
; Programa: CONTADOR CON TIMER0
; Hardware: 2 displays
;
; Creado: 14 feb, 2022
; Última modificación: 19 feb, 2022

PROCESSOR 16F887
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

;-------------------------------------------------------------------------------
UP EQU 0	
DOWN EQU 7
REINICIO MACRO	    ; Reinicio del timer 0. Funciona paralelo al programa
    BANKSEL PORTC   
    MOVLW   232	    ; Cargando valor N al timer0. Valor calculado con la formula. 
    MOVWF   TMR0    
    BCF	    T0IF    ; Limpiando la bandera del timer 0.
    ENDM
 
PSECT udata_bank0
 Bandera:	    DS	2   ; 2 bits
 Bandera2:     DS  2   ; 2 bits
PSECT udata_shr
 WTEMP:	    DS	1   ; 1 byte
 STSTEMP:   DS	1   ; 1 bit

PSECT resVect, class=code, abs, delta=2
;------------------------- Vector de reseteo ---------------------------
ORG 00h
  resVect:		   
    PAGESEL main
    GOTO main  
  PSECT code, delta=2, abs
;--------------------------Rutinas de interrumpción --------------------
ORG 04h

PUSH:			
    movwf WTEMP		; Cargar al registro temporal
    swapf STATUS, W	; Intercabia los valores del status y los guarda en el registro W
    movwf STSTEMP	

isr:			; Rutina principal de reseteo
    BTFSC T0IF		; Verifica la bandera del timer 0
    call General_Int	
    
POP:			
    SWAPF STSTEMP, W	; Intercambia los valores y los guarda en el registro W
    MOVWF STATUS	
    SWAPF WTEMP, F	; Intercambia los valores y los guarda en el registro F
    SWAPF WTEMP, W	
    RETFIE
    
General_Int:		; Rutina de interrupción general
    REINICIO		; Llamar al macro para reiniciar timer 0
    INCF Bandera	; Incrementa la variable	
    MOVF Bandera, w	; Verificando que cuente
    sublw 10		
    btfss STATUS, 2	; Verificar que se cumpla la intención
    RETURN		
    CLRF Bandera
    BTFSC PORTA, 4
    CLRF PORTA
    incf PORTA		; Incremento un valor en el puerto A
    MOVF PORTA, W	; Comienza la verificación del primer display 
    Call TABLA		; Llamo a la tabla
    MOVWF PORTD		
    MOVLW 10	    
    SUBWF PORTA, W	; Hace una resta para verficiar que cuente hasta 10
    BTFSC ZERO		; Verificar que esta en 0
    Call Display2	; Se llama a la rutina del display 2
    RETURN
    
Display2:
    CLRF PORTA
    INCF Bandera2	    ; Incrementa un valor en F de la bandera2
    MOVF Bandera2, W	    ; Mueve el valor de D de la bandera2 y lo guarda en el registro W
    Call TABLA		    ; Llama la función tabla
    MOVWF PORTC		    ; Mueve el valor de F al puerto C
    MOVLW 6	    
    SUBWF Bandera2, W	    ; Hace la operación de resta en la bandera2 y guarda en W
    BTFSC ZERO		    ; Al llegar a 60s se reincia
    call MAXIMO		    
    RETURN
    
MAXIMO:		    ; Rutina de reinicio de 2 displays
    CLRF PORTC	    ; Limpia  el puerto C
    CLRF Bandera2   ; Limpia el Contador2	
    RETURN
    
PSECT code, delta=2, abs
 ORG 100h
;--------------------------MICRO CONTROLADOR------------------------------------
PSECT code, delta=2, abs
ORG 0100h
 
TABLA:			    ; Tabla para encender ciertos segmentos y visualizar números en el display
    CLRF PCLATH
    BSF PCLATH, 0
    ADDWF PCL, 1
    RETLW 00111111B ;0
    RETLW 00000110B ;1
    RETLW 01011011B ;2
    RETLW 01001111B ;3
    RETLW 01100110B ;4
    RETLW 01101101B ;5
    RETLW 01111101B ;6
    RETLW 00000111B ;7
    RETLW 01111111B ;8
    RETLW 01101111B ;9
    RETLW 00111111B ;0
 return
;-----------------------------------main----------------------------------------
main:
    call CONFIGURACION
    call RELOJ
    call TIMER0_SETUP
    call INTER2
    
    banksel PORTC

loop:
    goto loop
;-------------------------------------------------------------------------------
 CONFIGURACION:
    bsf	STATUS, 5
    bsf	STATUS, 6
    CLRF ANSEL
    CLRF ANSELH
    bsf	STATUS, 5
    bCf	STATUS, 6
    CLRF TRISC
    CLRF TRISD
    CLRF TRISA
    bCf	STATUS, 5
    bCf	STATUS, 6
    CLRF PORTD
    CLRF PORTA
    CLRF PORTC
    return
    
RELOJ:			; Configuración del oscilador interno 
    banksel OSCCON	; Configurado a 225kHz
    BCF IRCF2
    BSF IRCF1
    BCF IRCF0
    BSF SCS
    return
    
TIMER0_SETUP:		; Configuración del timer0
    banksel TRISC
    BCF T0CS
    BCF PSA
    BSF PS2
    BSF PS1
    BSF PS0
    REINICIO 
    return
    
INTER2:
    BSF GIE
    BSF T0IE
    BCF T0IF
    RETURN
    
END


