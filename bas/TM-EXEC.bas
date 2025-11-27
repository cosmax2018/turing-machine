
'TM Turing Machine fatta in QBasic (compilata con FreeBasic   'fbc -lang qb tm-exec.bas' )
'by CosMax2016, april-may 2016

'una TM deterministica e' una 7-upla M = (Q,S,T,d,q0,B,F)
'dove:
'	Q = insieme finito di stati
'	S = insieme finito di simboli di input
'	T = insieme finito di simboli del nastro (contiene S)
'	d = funzione di transizione Q x T -> Q x T x {H,R,L} ,ossia le quintuple
'  q0 = stato iniziale
'	B = simbolo di blank (appartiene a T)
'	F = insieme degli stati finali (contenuto in Q), ad esempio un solo stato come q8

'consente di eseguire delle quintuple caricate da file

'ex: > TM-EXEC -tape tape.t -quint add.tm -b "B" -q0 "0" -qf "8" -t "01XYB" -s "01" -q "0123456789" -m "CRL" -debug
'    > TM-EXEC -h  (to have an help!)

#include once "file.bi"
#include once "string.bi"

const as integer			FALSE					= 0
const as integer			TRUE					= -1
const as integer			NO_MOVE					= 1
const as integer			TO_RIGHT				= 2
const as integer			TO_LEFT					= 3
const as integer			CFG_STATE				= 1	'first char of the quintuple
const as integer			CFG_SYMBOL				= 2 'second    "  "  "  "
const as integer			NEW_SYMBOL				= 3 'third     "  "  "  "
const as integer			NEW_MOVE				= 4 'etc..
const as integer			NEW_STATE				= 5 'etc...
const as string				EMPTY					= ""
dim as integer				N_OF_SYMBOLS,N_OF_TAPE_SYMBOLS,N_OF_STATES,N_OF_MOVES
dim as string*1 			BLANK			: BLANK 			= "B"
dim as string				SYMBOLS			: SYMBOLS			= "01"				: N_OF_SYMBOLS		= Len(SYMBOLS)
dim as string				TAPE_SYMBOLS	: TAPE_SYMBOLS		= "01B"				: N_OF_TAPE_SYMBOLS = Len(TAPE_SYMBOLS)
dim as string				STATES			: STATES			= "0123456789ABCDEF": N_OF_STATES		= Len(STATES)
dim as string				MOVES			: MOVES				= "CRL"				: N_OF_MOVES		= Len(MOVES)
dim as string*1				MOVES_TO_RIGHT	: MOVES_TO_RIGHT	= "R"
dim as string*1 			MOVES_TO_LEFT	: MOVES_TO_LEFT		= "L"
dim as string*1 			MOVES_TO_NOWHERE: MOVES_TO_NOWHERE	= "C"
dim as string*1				Q0				: Q0				= "0"	'lo stato iniziale della TM (quello da cui la TM si avvia)
dim as string*1				QF				: QF				= "F"	'lo stato finale della TM (quello raggiunto il quale la TM si arresta)
dim as integer				MAX_TAPE_LENGTH	: MAX_TAPE_LENGTH	= 4096	'max tape length permissible (4K bytes)
dim as integer				TAPE_LENGTH		: TAPE_LENGTH		= 0		'the actual tape length
dim as integer				P,P0			: P0  				= 1		'actual head position and initial head position
dim as string				TAPE			: TAPE				= EMPTY	'il nastro
dim as integer				MAX_QUINTUPLES	: MAX_QUINTUPLES	= 20000	'massimo numero di quintuple gestibili
dim as integer				N_OF_QUINTUPLES	: N_OF_QUINTUPLES	= 0		'numero di quintuple effettivo
dim as string*5				QUINTUPLES(1 to MAX_QUINTUPLES)				'array of quintuples (q,s,s',m,q')
dim as integer				USED_QUINTUPLE(1 to MAX_QUINTUPLES)			'how many times the i-th quintuple was used?
dim as string*5				QUINTUPLE		: QUINTUPLE			= "START"
dim as string*1				Q				: Q 				= Q0	'lo stato interno della TM
dim as integer				HALT			: HALT				= FALSE	'if something wrong occurred (e.g. an error) exits
dim as integer 				i,j,n
dim as string				row
dim as integer 				pass				: pass					= 1						'passi del programma
dim as string*1				COMMENT				: COMMENT				= "'"					'indica una riga di commento nei files del nastro e delle quintuple
dim as string				TAPE_FILENAME 		: TAPE_FILENAME			= "tapes/tape.t"		'nome file di default
dim as string				QUINTUPLES_FILENAME	: QUINTUPLES_FILENAME	= "tm/quintuples.tm"	'nome file di default
dim as integer				DISPLAY				: DISPLAY				= TRUE					'visualizes the tape
dim as integer 				DEBUG 				: DEBUG					= FALSE

randomize timer

'parse the parameters given in input
gosub TM_ParseParameters

'load the tape in memory to speed-up calculations
if FileExists(TAPE_FILENAME) then gosub TAPE_GetFromFile else print "error: tape file ";TAPE_FILENAME;" does not exists!" : end -1

'load quintuples from the given file
if FileExists(QUINTUPLES_FILENAME) then gosub QUINTUPLES_GetFromFile else print "error: quintuples file ";QUINTUPLES_FILENAME;" does not exists!" : end -1

'TM initialization
gosub TM_Initialize														'initialize the TM
if DEBUG then gosub TM_Debug else if DISPLAY then gosub TAPE_PrintTape	'prints some debug informations 

'TM Run!
do
	gosub TM_ExecuteQuintuple												'ricerca della quintupla con configurazione (q,s) e ne esegue le istruzioni (s',m,q')
	if DEBUG then gosub TM_Debug else if DISPLAY then gosub TAPE_PrintTape	'prints some debug informations or only prints the tape status
	pass = pass + 1
loop until HALT
'TM Stops!

print "TM terminates after ";pass;" steps"

print "final tape configuration:" : gosub TAPE_PrintTape

'save the output tape to file
gosub TAPE_ToFile

'print "(press a key to print quintuples, ESC to exit)" : sleep
'if not inkey$ = chr$(27) then gosub TM_PrintQuintuples
end 0

'sub-routines
TM_ParseParameters:			'parse the commands parameters
	i = 1
	do
		Select Case UCase$(command$(i))
			Case "-TAPE"
				TAPE_FILENAME		= "tapes/" & command$(i+1)
			Case "-QUINT"
				QUINTUPLES_FILENAME	= "tm/" & command$(i+1)
			Case "-P0"
				P0					= cint(command$(i+1))
			Case "-B"
				BLANK				= UCase$(command$(i+1))
			Case "-Q0"
				Q0					= UCase$(command$(i+1))
			Case "-QF"
				QF					= UCase$(command$(i+1))
			Case "-T"
				TAPE_SYMBOLS		= UCase$(command$(i+1)) : N_TAPE_SYMBOLS = Len(command$(i+1))
			Case "-S"
				SYMBOLS				= UCase$(command$(i+1)) : N_OF_SYMBOLS	 = Len(command$(i+1))
			Case "-Q"
				STATES				= UCase$(command$(i+1)) : N_OF_STATES    = Len(command$(i+1))
			Case "-M"
				MOVES				= UCase$(command$(i+1)) : N_OF_MOVES	 = Len(command$(i+1))	
				MOVES_TO_RIGHT		= mid$(MOVES,TO_RIGHT,1)
				MOVES_TO_LEFT		= mid$(MOVES,TO_LEFT,1)
				MOVES_TO_NOWHERE	= mid$(MOVES,NO_MOVE,1)
			Case "-NO-DISPLAY"
				DISPLAY = FALSE
			Case "-DEBUG"
				DEBUG = TRUE
			Case "-H"
				print "TM options:"
				print "     -TAPE  <tape file name>        defines the input TM tape file name e.g. -TF " & chr$(34) & "tape.t" & chr$(34)
				print "     -QUINT <quintuples file name>  defines the TM instruction quintuples file name to read/write e.g. -QUINT " & chr$(34) & "mult.tm" & chr$(34)
				print "     -P0    <initial head position> defines the initial position of the head on the tape e.g. -P0 256"
				print "     -B     <blank symbol>          defines the blank symbol e.g. -B " & chr$(34) & "B" & chr$(34)
				print "     -Q0    <initial state>         defines the initial starting state  e.g. -Q0 " & chr$(34) & "0" & chr$(34)
				print "     -QF    <final state>           defines the final state used to stop the TM, e.g. -QF " & chr$(34) & "8" & chr$(34)
				print "     -T     <tape symbols>          defines the tape symbols e.g. -T " & chr$(34) & "01XYB" & chr$(34)
				print "     -S     <string of symbols>     defines the symbols used by TM, e.g. -S " & chr$(34) & "0123456789" & chr$(34)
				print "     -Q     <string of states>      defines the states used by TM, e.g. -Q " & chr$(34) & "0123456789ABCDEF" & chr$(34)
				print "     -M     <string of moves>       defines the moves allowed by TM, e.g. -M " & chr$(34) & "HRL" & chr$(34)
				print "     -NO-DISPLAY                    inhibits the visualization of the tape (usefull to speed-up calculations)"
				print "     -DEBUG                         activates debug"
				print "     -H                             this help"
				end 0
		End Select
		i = i + 1
	loop until command$(i) = EMPTY
return
TM_Initialize:				'TM initialization
	Q = Q0			'inizializza lo stato q	allo stato iniziale	
	P = P0			'inizializza la posizione iniziale della testina
	HALT = FALSE
	pass = 1
return
TAPE_GetFromFile:			'read the tape from a file
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	TAPE = ""
	open TAPE_FILENAME for input as #1
	while not eof(1)
		input #1,row
		if left$(row,1) <> COMMENT then
			'copia su nastro
			if Len(row) < MAX_TAPE_LENGTH + 1 then		
				TAPE_LENGTH = Len(row)
				'now write the tape with the given symbols from file
				for i = 1 to TAPE_LENGTH : TAPE = TAPE & mid$(row,i,1) : next i
			else
				print "Error: input tape is too long (max length has to be ";TAPE_LENGTH;")"
			end if
			exit while
		else
			print row
		end if
	wend
	close #1
return
TAPE_ToFile:			'save the tape to a file
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	open TAPE_FILENAME for output as #2
	print #2,"'nastro nello stato finale"
	for i = 1 to TAPE_LENGTH		
		'copia da memoria su file
		print #2, mid$(TAPE,i,1);
	next i
	print #2, EMPTY
	close #2
return
TAPE_PrintTape:				'prints the tape
	print "TAPE[";format$(pass,"0000");"] ";TAPE
return
TM_Debug:					'prints some debug informations
	print "TAPE[";format$(pass,"0000");"] ";TAPE;" "; 
	if Q = QF then
		print "HALT"
	else
		print QUINTUPLE;
		print " Q:";mid$(QUINTUPLE,CFG_STATE,1);
		print " S:";mid$(QUINTUPLE,CFG_SYMBOL,1);
		print " S':";mid$(QUINTUPLE,NEW_SYMBOL,1);
		print " M:";mid$(QUINTUPLE,NEW_MOVE,1);
		print " Q':";mid$(QUINTUPLE,NEW_STATE,1);
		print " POS:";P
	end if
	locate CsrLin-1,len("TAPE[0000]:")+p : color 2 : print mid$(TAPE,P,1) : color 15
return
QUINTUPLES_GetFromFile:		'read the quintuples from a file
	'prende da file lle quintuple della TM
	N_OF_QUINTUPLES = 0
	open QUINTUPLES_FILENAME for input as #1
	while not eof(1)
		input #1,row
		if left$(row,1) <> COMMENT then
			'copia in memoria
			N_OF_QUINTUPLES = N_OF_QUINTUPLES + 1
			if N_OF_QUINTUPLES < MAX_QUINTUPLES + 1 then
				for i = 1 to 5
					mid(QUINTUPLES(N_OF_QUINTUPLES),i,1) = mid$(row,i,1)
				next i		
			else
				print "WARNING:input quintuples are too much (max quintuples = ";MAX_QUINTUPLES;") so are truncated."				
			end if
		else
			print row
		end if
	wend
	close #1
return
QUINTUPLES_ToFile:			'save the TM's quintuples to file
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	open QUINTUPLES_FILENAME for output as #2
	for i = 0 to N_OF_QUINTUPLES
		if i = 0 then 
			print #2,"these are some random quintuples generated by TM-RND.bas  (" & date$ & " at " & time$ & ")" 
		else
			'copia da memoria su file			
			for j = 1 to 5
				print #2, mid$(QUINTUPLES(i),j,1);
			next j
			print #2, EMPTY
		end if
	next i
	close #2
return
TM_PrintQuintuples:			'print the TM's Quintuples
	n = 0
	if EXEC then
		for i = 1 to N_OF_QUINTUPLES
			if USED_QUINTUPLE(i) > 0 then 'color 2 else color 15
				n = n + 1
				print QUINTUPLES(i);";";
			end if
		next i
		print : print "Were generated ";N_OF_QUINTUPLES;" QUINTUPLES, but only ";n;" of them were effectively used."	
	else
		for i = 1 to N_OF_QUINTUPLES
			print QUINTUPLES(i);";";
		next i
		print : print "Were generated ";N_OF_QUINTUPLES;" QUINTUPLES."
	end if
return
TM_ExecuteQuintuple:		'cerca la quintupla con configurazione (s,q) e ne esegue le istruzioni (s',m,q')
	HALT = TRUE
	for i = 1 to N_OF_QUINTUPLES
		QUINTUPLE = QUINTUPLES(i)
		USED_QUINTUPLE(i) = USED_QUINTUPLE(i) + 1
		'se trovo la quintupla con configurazione (q,s)
		if mid$(QUINTUPLE,CFG_STATE,1) = Q and mid$(QUINTUPLE,CFG_SYMBOL,1) = mid$(TAPE,P,1) then	
			'allora prende la terna (s',m,q')
			Q = mid$(QUINTUPLE,NEW_STATE,1) 				'prende dalla quintupla il nuovo stato q'
			mid(TAPE,P,1) = mid$(QUINTUPLE,NEW_SYMBOL,1)	'prende dalla quintupla il nuovo simbolo s' e lo scrive su nastro
			
			'legge dalla quintupla come deve muovere la testina
			Select Case mid$(QUINTUPLE,NEW_MOVE,1)
				Case MOVES_TO_RIGHT
					if P < TAPE_LENGTH then	P = P + 1 else exit for
				Case MOVES_TO_LEFT
					if P > 1 then P = P - 1	else exit for
				Case MOVES_TO_NOWHERE
					'exit for	'ferma la TM!
				Case else
					print "errors in the quintuples" : exit for
			End Select
			
			if Q = QF then exit for							'se ha raggiunto lo stato finale ferma la TM!
				
			HALT = FALSE
			exit for
		end if
	next i
return
