#include <p18f4321.inc>
    
    CONFIG  OSC=HS     ; Set Oscillator
    CONFIG  PBADEN=DIG ; Set PORTB to digital
    CONFIG  WDT=OFF    ; Turn Watchdog Timer off

    ORG 0x0000
    GOTO    MAIN
    ORG 0x0008
    GOTO    HIGH_RSI
    RETFIE FAST
    ORG 0x0018
    RETFIE  FAST
    ORG 0x0020	;7segments values
    DB 0x7D, 0x30	; 0..1	, 20..21
    DB 0x6E, 0x7A	; 2..3  , 22..23
    DB 0x33, 0x5B	; 4..5	, 24..25
    DB 0x5F, 0x70	; 6..7	, 26..27
    DB 0x7F, 0x7B	; 8..9	, 28..29
    DB 0x7A, 0x1F	; A..B	, 2A..2B
    DB 0x4D, 0x3E	; C..D	, 2C..2D
    DB 0x4F, 0x47	; E..F	, 2E..2F
    
    ORG 0x0030	    ; The time at 1 to increase to the Servo PWM for each correct note, in 10uS increments
    DB 0xC8, 0x64	; 1, 2 (total notes)
    DB 0x42, 0x32	; 3, 4 (total notes)
    DB 0x28, 0x21	; 5, 6 (total notes)
    DB 0x1C, 0x19	; 7, 8 (total notes)
    DB 0x16, 0x14	; 9, 10 (total notes)
    DB 0x12, 0x10	; 11, 12 (total notes)
    DB 0x0F, 0x0E	; 13, 14 (total notes)
    DB 0x0D, 0x0C	; 15, 16 (total notes)
    
    
;    ORG 0x0040	   ; Table that stores values of distances (0-70 cm every 10 cm)
;    DB 0x17, 0x2D
;    DB 0x44, 0x5B
;    DB 0x72, 0x88
;    DB 0xFA, 0xFF
    
    
    ORG 0x0040	   ; Table that stores values of distances (0-70 cm every 10 cm)
    DB 0x02, 0x04
    DB 0x06, 0x08
    DB 0x0A, 0x0C
    DB 0x2F, 0xFF
    

    
;    ORG 0x0050	    ; The 1/2 period units for each note (1tic = 400uS)
;    DB 0x0A, 0x08
;    DB 0x06, 0x05
;    DB 0x05, 0x04
;    DB 0x03, 0x02
    
    ORG 0x0050	    ; The 1/2 period units for each note (1tic = 400uS)
    DB 0x17, 0x13
    DB 0x0F, 0x0C
    DB 0x09, 0x06
    DB 0x03, 0x01
    

    
    ;VARS:
    WaitingCounter1 EQU 0x10 ; Variable used to count time in instruction loops
    WaitingCounter2 EQU 0x11
    WaitingCounter3 EQU 0x12
    WaitingCounter5 EQU 0x2C
 
    NoteCounter	    EQU 0x13; Variable to store the number of notes introduced
    Counter	    EQU 0x14; Iterator for overall game
    Conta	    EQU 0x15; Iterator to read the correct 7seg value
    CurrentNote	    EQU 0x16
    CurrentDuration EQU 0x17
 
    Bit0Mask	    EQU 0x18
    Bit1Mask	    EQU 0x19
	    
    CurrentDistance EQU 0x1A
    LatestUssTime   EQU 0x1B
    FetchDistanceFlag EQU 0x1C
    MaxDistance	    EQU 0x1D
	    
    WregAux	    EQU 0x1E
    
    SpeakerTicsTotal	EQU 0x20
    SpeakerTicsCurrent	EQU 0x1F
    ServoSum		EQU 0x21
    SpeakerFlag		EQU 0x24
    ServoFlag		EQU 0x24

    RoundTime		EQU 0x25
    NoteTime		EQU 0x26
    NoteTimeFlag	EQU 0x27
	
    Timer20ms		EQU 0x28
    Servo		EQU 0x29
		
    Timer100ms		EQU 0x2A
    CounterEcho		EQU 0x2B
		
    TicsEco		EQU 0x2C
    EcoFlag		EQU 0x2D
		
    ;END VARS

    ;CONSTANTS
    FirstNote	    EQU 0x80
    First7seg	    EQU 0x20
    FirstDistance   EQU 0x40
    FirstNoteTics   EQU 0x50
    FirstServoTime  EQU 0x2F
	    
    ConfigT0CON	    EQU b'10001001'
    ConfigT1CON	    EQU b'00110001'
    ConfigT2CON	    EQU b'00000001'
    ;END CONSTANTS

    
HIGH_RSI
    btfsc INTCON, RBIF, 0
    GOTO ECHO_RSI	    ;The RSI for the Echo (for USS)
    ;bcf INTCON, RBIF, 0
    
    btfsc PIR1, TMR1IF
    BCF	PIR1, TMR1IF, 0
    
    btfsc PIR1, TMR2IF
    bcf	    PIR1, TMR2IF, 0
    
    btfsc INTCON, TMR0IF
    GOTO TMR0_RSI
    
    RETFIE FAST
    
ECHO_RSI

    btfsc PORTB, 4, 0
    GOTO ECHO_HIGH_RSI
    
    
    btfss PORTB, 4, 0
    GOTO ECHO_LOW_RSI
    
    RETFIE FAST
    
ECHO_HIGH_RSI
    
    incf    EcoFlag, 1, 0
    
    ; 1) Reset TMR0L
    ;clrf CounterEcho, 0
    
    ;ESPERA_20uS
	;movlw .12		    ;1
	;movwf WaitingCounter5, 0    ;1
	
	
	;WAITING5			    ;3 + 1
	    ;NOP			; Temporary for testing (sub for NOP loop)
	    ;decfsz WaitingCounter5, 1, 0   
	    ;GOTO WAITING5
	
    ;btfss PORTB, 4, 0
    ;GOTO ESPERA_20uS
    
    ;CALL FETCH_DISTANCE
    
    bcf INTCON, RBIF, 0
    RETFIE FAST
    
ECHO_LOW_RSI    
    ; 1) Read TMR0L
;    movff TMR0L, LatestUssTime
;    bsf FetchDistanceFlag, 0, 0
    
    ; 2) Check what distance that time corresponds to
    CALL FETCH_DISTANCE    
    
    clrf EcoFlag, 0
    clrf TicsEco, 0
    
    ;TicsEco
    
    bcf INTCON, RBIF, 0
    RETFIE FAST
    
    
TMR0_RSI
    
    movlw   .1
    cpfslt   EcoFlag, 0
    incf    TicsEco, 1, 0
    
    bcf INTCON, TMR0IF, 0
    CALL LOAD_TMR0
    
    incf SpeakerTicsCurrent, 1, 0
    incf Timer20ms, 1, 0
    incf Timer100ms, 1, 0
    
    tstfsz SpeakerFlag, 0
    CALL SPEAKER_ROUTINE
    
    movlw .250
    CPFSLT Timer100ms, 0
    CALL RSI100ms

    MOVLW .50
    CPFSEQ Timer20ms, 0
    RETFIE FAST
    
    CLRF Timer20ms, 0
    CALL SERVO_ROUTINE
    
    RETFIE FAST
    
LOAD_TMR0
    movlw HIGH(.64536)
    movwf   TMR0H, 0
    movlw LOW(.64536)
    MOVWF   TMR0L, 0
    RETURN
    
RSI100ms
    incf RoundTime, 1, 0
    clrf Timer100ms, 0
    
    btfsc NoteTimeFlag, 0
    incf NoteTime, 1, 0
    
    bsf LATB, 2, 0
    call WAIT_USS_TRIGGER
    bcf LATB, 2, 0
    
    ;GOTO SEND_TRIGGER
    
    return
    
    ;return
    
;TMR1_RSI
    ;CALL LOAD_TMR1
    ;bcf PIR1, TMR1IF, 0
    
    ;incf RoundTime, 1, 0
    
    
;    btfsc NoteTimeFlag, 0
;    incf NoteTime, 1, 0

    ;CALL SEND_TRIGGER
    
    ;RETFIE FAST
    
LOAD_TMR1
    clrf TMR1H, 0
    ;bsf TMR1H, 7, 0
    clrf TMR1L, 0
    
    RETURN
    
TMR2_RSI
    incf SpeakerTicsCurrent, 1, 0
    incf Timer20ms, 1, 0
    
    tstfsz SpeakerFlag, 0
    CALL SPEAKER_ROUTINE
    
    CALL LOAD_TMR2
    bcf PIR1, TMR2IF, 0
    
    MOVLW .50
    CPFSEQ Timer20ms, 0
    RETFIE FAST
    
    CLRF Timer20ms, 0
    CALL SERVO_ROUTINE
    
    RETFIE FAST
    
LOAD_TMR2
    NOP
    NOP	; doesnt load the value without this for some reason ¿?
    
    movlw .11
    movwf TMR2, 0
    
    RETURN
    
SPEAKER_ROUTINE
    
    movf SpeakerTicsCurrent, 0 
    cpfsgt SpeakerTicsTotal, 0
    btg LATC, 2, 0
    
    cpfsgt SpeakerTicsTotal, 0
    clrf SpeakerTicsCurrent, 0
    
    RETURN
    
    

SERVO_ROUTINE
    NOP
    
    movf Servo, 0, 0	; Put value in the waiting counter (to not lose it)
    movwf WaitingCounter2, 0
    
    bsf LATC, 1, 0
    LOOP_SERVO
	call WAIT_10uS
	decfsz WaitingCounter2, 1, 0
	GOTO LOOP_SERVO
    
    BCF	LATC, 1, 0
    RETURN 
    
SERVO_INCREASE
    movf ServoSum, 0
    addwf Servo, 1, 0
    
    RETURN
    
FETCH_SERVOSUM
    movlw FirstServoTime
    addwf NoteCounter, 0, 0
    
    clrf TBLPTRU, 0
    clrf TBLPTRH, 0
    movwf TBLPTRL, 0
    TBLRD*
    movff TABLAT, ServoSum
    
    RETURN
    
    
    
;WAITING FUNCTIONS: OSC=HS ? F = 10MHz  ? Tinstr = 400ns
WAIT_1MS
    movlw .208		    ;1
    movwf WaitingCounter1, 0	    ;1
    
    WAITING			    ;3 + 9
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP			; Temporary for testing (sub for NOP loop)
	decfsz WaitingCounter1, 1, 0   
	GOTO WAITING
	
    return
    

   
    
WAIT_250MS
    movlw .250
    movwf WaitingCounter2, 0
    
    WAITING2
	CALL WAIT_1MS
	decfsz WaitingCounter2, 1, 0
	GOTO WAITING2
    return
    
WAIT_10uS
    movlw .3			    ; 1
    movwf WaitingCounter3, 0	    ; 2
    
    WAITING4			    ;3 + 2
	NOP
	NOP
	decfsz WaitingCounter3, 1, 0   
	GOTO WAITING4
    
    NOP
	
    RETURN
    
WAIT_USS_TRIGGER
    movlw .10		    ;1
    movwf WaitingCounter3, 0	    ;1
    
    WAITING3			    ;3 + 1
	NOP			
	decfsz WaitingCounter3, 1, 0   
	GOTO WAITING3
	
    return
    
;SEND_TRIGGER
;    bsf LATB, 2, 0
;    
;    call WAIT_USS_TRIGGER
;    bcf LATB, 2, 0
;    return

    
    
    
    
;Function to store the key received through PORTA
STORE_DATA
    clrf FSR0H, 0		; Bank 0 of RAM
    
    movlw FirstNote		; Address where I store first note 
    addwf NoteCounter, 0, 0	; Add +1 to the @ for every note I have already stored
    incf NoteCounter, 1, 0	; Increase notes counter
    
    movwf FSR0L, 0		; Select address (0x00 + NoteCounter) in bank 1
    ;call WAIT_1MS
    movff PORTA, INDF0		; Note has been stored (2MSB are not useful)
    
    bsf LATB, 0, 0		; Make ACK high	(wait 2 ms so phase 1 can detect it)
    call WAIT_1MS
    call WAIT_1MS
    call WAIT_1MS
    call WAIT_1MS
    bcf LATB, 0, 0		; Make ACK low again 
        
    RETURN
    
    
    
FINISHED
    bcf LATA, 4, 0
    bcf LATA, 5, 0
    bcf LATC, 6, 0  ; Length 0 OFF
    bcf LATC, 7, 0  ; Length 1 OFF
    movlw 0x02
    movwf LATD, 0
    
    GOTO FINISHED
    
INIT_GAME
    
    CALL FETCH_SERVOSUM
    bsf T2CON, TMR2ON, 0
    
    GOTO GAME_LOGIC
    
GAME_LOGIC
    bcf INTCON, RBIE, 0 ; Disable USS interruption
    ;bcf T1CON, TMR1ON, 0
    clrf SpeakerFlag, 0
    clrf ServoFlag, 0
    

    
    movf NoteCounter, 0, 0
    cpfslt Counter, 0	; if Counter >= NoteCounter, I have done the game for all notes
    GOTO FINISHED	; Program finished, go to infinite loop
    
    ;READ NEXT STORED NOTE
    clrf FSR0H, 0	; Bank 1 of RAM
    
    movlw FirstNote
    addwf Counter, 0, 0	; Address = add. of 1st note + counter
    movwf FSR0L

    movff INDF0, CurrentNote    ; Move content into CurrentNote (XX + 2b duration + 4b with value of note)
    bcf CurrentNote, 7, 0
    bcf CurrentNote, 6, 0
    movff CurrentNote, CurrentDuration
    
    ;Sanitize CurrentNote
    bcf CurrentNote, 5, 0
    bcf CurrentNote, 4, 0
    ;Sanitize CurrentDuration (Remove note bits and shift to bits 1..0)
    bcf CurrentDuration, 3, 0
    bcf CurrentDuration, 2, 0
    bcf CurrentDuration, 1, 0
    bcf CurrentDuration, 0, 0

    swapf CurrentDuration, 1, 0
    ; I have value of note in CurrentNote, duration in CurrentDuration, and the address of the note in WREG
    ; FINISHED READING NOTE
    
    CALL UPDATE_7SEG
    CALL UPDATE_LENGTH
    
    bsf INTCON, RBIE, 0 ; Enable USS interruption
    
    
    ;bsf T1CON, TMR1ON, 0
    
    setf SpeakerFlag, 0
    setf ServoFlag, 0
    
    clrf RoundTime, 0
    setf NoteTimeFlag, 0
    
    
    GOTO PLAY_NOTE ;Play round for this note
   
    GOTO GAME_LOGIC
    
    
    
FETCH_DISTANCE
    clrf FetchDistanceFlag, 0
    
    clrf Conta, 0
    clrf TBLPTRU, 0
    clrf TBLPTRH, 0
    movlw FirstDistance
    movwf TBLPTRL, 0	;Set table @ to first distances value
    
    movf TicsEco, 0, 0
    
    BUCLE_FETCH_DISTANCE
	TBLRD*+
	cpfslt TABLAT, 0
	GOTO FOUND_DISTANCE
	
	incf Conta, 1, 0
	GOTO BUCLE_FETCH_DISTANCE
    		
    FOUND_DISTANCE
	movff Conta, CurrentDistance
	CALL UPDATE_SPEAKER
	
;	movlw First7seg			;Code to show the detected range in 7seg
;	addwf CurrentDistance, 0, 0
;	movwf TBLPTRL
;	TBLRD*
;	movff TABLAT, LATD
	
	return
	
UPDATE_SPEAKER
    movlw FirstNoteTics
    movwf TBLPTRL, 0	;Set table @ to first distances value
    movlw 0x00
     ;movlw 0x03
     ;movwf SpeakerTicsTotal, 0
     ;return
    
    BUCLE_SPEAKER
	TBLRD*+
	cpfseq CurrentDistance, 0
	GOTO SPK_NOTFOUND
	movff TABLAT, SpeakerTicsTotal
	return
	
    SPK_NOTFOUND
	addlw .1
	GOTO BUCLE_SPEAKER
	
	


	
; Loop function that's executed while the game is going on for a note
PLAY_NOTE

    movlw 0x1E
    cpfslt RoundTime, 0
    GOTO NOTE_NOT_DETECTED
    
    movf CurrentNote, 0
    clrf NoteTime, 0
    cpfseq CurrentDistance, 0
    GOTO PLAY_NOTE
    
    GOTO NOTE_DETECTED
    
    
NOTE_NOT_DETECTED
    bcf LATC, 4, 0
    bsf LATC, 5, 0
    incf Counter, 1, 0
    GOTO GAME_LOGIC
    
NOTE_DETECTED
    
    movlw 0x06
    cpfslt NoteTime, 0
    GOTO CONTINUE_NOTE
    
    movf CurrentNote, 0
    cpfseq CurrentDistance, 0
    GOTO PLAY_NOTE
    GOTO NOTE_DETECTED
    
CONTINUE_NOTE
    bcf LATC, 4, 0
    bcf LATC, 5, 0
    GOTO NOTE_WAIT_TIME
    
NOTE_WAIT_TIME

    ;movf CurrentDuration, 0
    ;mullw 0x05
    movlw 0x05
    mulwf CurrentDuration, 0
    movf PRODL, 0
    cpfslt NoteTime, 0
    GOTO CORRECT_NOTE
    
    movf CurrentNote, 0
    cpfseq CurrentDistance, 0
    GOTO NOTE_NOT_DETECTED
    
    GOTO NOTE_WAIT_TIME
    
CORRECT_NOTE
    bsf LATC, 4, 0
    incf Counter, 1, 0
    CALL SERVO_INCREASE
    
    GOTO GAME_LOGIC

    
    
   
;Function to update the 7seg display to the value of CurrentNote
UPDATE_7SEG
    clrf Conta, 0
    clrf TBLPTRU, 0
    clrf TBLPTRH, 0
    movlw First7seg
    movwf TBLPTRL, 0	;Set table @ to first 7seg value
    
    movf CurrentNote, 0, 0
    
    
    BUCLE7SEG
	TBLRD*
	cpfseq Conta, 0
	GOTO FOUND7SEG
	movff TABLAT, LATD
	RETURN

    FOUND7SEG
	incf Conta, 1, 0
	TBLRD*+
	GOTO BUCLE7SEG

	
;Function to update the Length LEDs to the value of CurrentDuration
UPDATE_LENGTH
	bcf LATC, 6, 0
	bcf LATC, 7, 0
	
	btfsc CurrentDuration, 0, 0
	bsf LATC, 6, 0
	
	btfsc CurrentDuration, 1, 0
	bsf LATC, 7, 0
	
    RETURN
    

;Function to set up IO ports
CONFIG_PORTS
    movlw 0x0F
    movwf ADCON1, 0

    ;Inputs
    setf TRISA, 0   ;Set RA as input (RA0..3 = Note[0..3]. RA4..5 = Duration0..1, 6..7 unused 
    bsf TRISC, 3, 0 ;RC3 as input = NewNote
    bsf TRISC, 0, 0 ;RC0 as input = StartGame
    bsf TRISB, 4, 0 ; RB4 as input = Echo
    
    ;Outputs:
    bcf TRISB, 0, 0 ; Ack signal (to phase 1)
    bcf TRISB, 2, 0 ; Trigger (for HSS)
    bcf TRISC, 1, 0 ; GameScore
    bcf TRISC, 2, 0 ; Speaker
    bcf TRISC, 4, 0 ; LedG (AnswerCorrect)
    bcf TRISC, 5, 0 ; LedR (AnswerIncorrect)
    bcf TRISC, 6, 0 ; Length0
    bcf TRISC, 7, 0 ; Length1
    clrf TRISD, 0   ; 7seg display of current node

    RETURN
    
;Function to set up interruptions
CONFIG_INTERRUPTS
    bcf RCON, IPEN, 0
    bsf INTCON, GIE, 0
    bsf INTCON, PEIE, 0
    
    ;PORTB Change interruption
    bsf INTCON, RBIE, 0	
    bcf INTCON, RBIF, 0
    
    ;TMR1 interruption
    ;bcf PIR1, TMR1IF, 0
    ;bsf PIE1, TMR1IE, 0
    
    ;TMR2 interruption
    ;bcf PIR1, TMR2IF, 0
    ;bsf PIE1, TMR2IE, 0
     
    ;TMR0 interruption
    bsf INTCON, TMR0IE, 0
    bcf INTCON, TMR0IF, 0
    
    RETURN
  
;Function to initialise variables
INIT_VARS
    clrf NoteCounter, 0
    clrf Counter, 0
    
    clrf EcoFlag, 0
    clrf TicsEco, 0
    
    clrf LATD, 0
    
    bcf LATC, 4, 0  ; Green OFF
    bcf LATC, 5, 0  ; Red OFF
    clrf LATD, 0    ; 7seg OFF
    bcf LATC, 6, 0  ; Length 0 OFF
    bcf LATC, 7, 0  ; Length 1 OFF
    
    movlw 0x01
    movwf Bit0Mask
    movlw 0x02
    movwf Bit1Mask
    
    movlw .7
    movwf MaxDistance
    
    
    movlw 0x03
    movwf SpeakerTicsTotal, 0
    
    
    clrf SpeakerFlag, 0
    clrf ServoFlag, 0
    
    clrf Timer20ms, 0
    
    movlw .50
    movwf Servo, 0
    
    RETURN
    
CONFIG_TMR0
    movlw ConfigT0CON
    movwf T0CON, 0
    
    movlw HIGH(.64536)
    movwf   TMR0H, 0
    movlw LOW(.64536)
    MOVWF   TMR0L, 0
    
    RETURN
    
CONFIG_TMR1
    movlw ConfigT1CON
    movwf T1CON, 0
    bcf T1CON, TMR1ON, 0
    
    RETURN
    
CONFIG_TMR2
    movlw ConfigT2CON
    movwf T2CON, 0
    bsf T2CON, TMR2ON, 0
    clrf SpeakerFlag, 0
    
    RETURN
    
MAIN
    CALL CONFIG_PORTS
    CALL CONFIG_INTERRUPTS
    CALL INIT_VARS
    CALL CONFIG_TMR0
    CALL CONFIG_TMR1
    CALL CONFIG_TMR2
    
    LOOP

	btfss PORTC, 3, 0
	CALL STORE_DATA
	
	btfsc PORTC, 0, 0
	GOTO INIT_GAME
	
	GOTO LOOP
END