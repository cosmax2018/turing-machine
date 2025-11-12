
'TM Turing Machine fatta in QBasic (compilata con FreeBasic   'fbc -lang qb tm-match.bas' )
'by CosMax2016, april 2016

'ex: > TM-MATCH -ti tape-in.tm -to tape-out.tm -s "01" -q "012345" -m "HRL" -debug
'    > TM-MATCH -h  (to have an help!)

#include "file.bi"

const as integer			FALSE					= 0
const as integer			TRUE					= -1
const as integer			NO_MOVE					= 1
const as integer			TO_RIGHT				= 2
const as integer			TO_LEFT					= 3
const as integer			FINAL_STATE				= 1 'Q0 e' lo stato finale
const as integer			FIRST_STATE				= 2 'Q1 e' lo stato iniziale
const as integer			CFG_STATE				= 1	'first char of the quintuple
const as integer			CFG_SYMBOL				= 2 'second    "  "  "  "
const as integer			NEW_SYMBOL				= 3 'third     "  "  "  "
const as integer			NEW_MOVE				= 4 'etc..
const as integer			NEW_STATE				= 5 'etc...
const as string				EMPTY					= ""
dim as integer				N_OF_SYMBOLS, N_OF_STATES, N_OF_MOVES
dim as string				SYMBOLS			: SYMBOLS	= "01"					: N_OF_SYMBOLS	= Len(SYMBOLS)
dim as string				STATES			: STATES	= "0123456789ABCDEF"	: N_OF_STATES	= Len(STATES)
dim as string				MOVES			: MOVES		= "HRL"					: N_OF_MOVES	= Len(MOVES)
const as integer			TAPE_MAX_LENGTH				= 4096				'max tape length permissible
dim as integer				TAPE_LENGTH										'the actual tape length (both for in and out tapes)
dim as string				TAPE_IN, TAPE_OUT								'il nastro di input e di output
const as integer			MAX_QUINTUPLES 			= 20000					'massimo numero di quintuple gestibili
dim as integer				N_OF_QUINTUPLES									'numero di quintuple effettivo
dim as string*5				QUINTUPLES(1 to MAX_QUINTUPLES)					'array of quintuples (q,s,s',m,q')
dim as integer				USED_QUINTUPLE(1 to MAX_QUINTUPLES)				'how many times the i-th quintuple was used?
dim as string*1				Q												'state
dim as integer				P												'head position
dim as integer				HALT											'if something wrong occurred (e.g. an error) exits
dim as integer 				i,j,n
dim as string				row
dim as integer 				pass
const as string				COMMENT									= "'"
dim as string				TAPE_FILENAME
dim as string				TAPE_IN_FILENAME 	: TAPE_IN_FILENAME	= "tm/tape-in.tm"		'nome file di default per il nastro di input
dim as string				TAPE_OUT_FILENAME 	: TAPE_OUT_FILENAME	= "tm/tape-out.tm"		'nome file di default per il nastro di output
dim as integer 				DEBUG 				: DEBUG				= FALSE

randomize timer
	
'parse the parameters given in input
gosub TM_ParseCommandParameters

dim as string*1 BLANK			: BLANK				= left$(SYMBOLS,1)
dim as string*1 MOVES_TO_RIGHT	: MOVES_TO_RIGHT	= mid$(MOVES,TO_RIGHT,1)
dim as string*1 MOVES_TO_LEFT	: MOVES_TO_LEFT		= mid$(MOVES,TO_LEFT,1)
dim as string*1 MOVES_TO_NOWHERE: MOVES_TO_NOWHERE	= mid$(MOVES,NO_MOVE,1)
dim as string*1 THE_FINAL_STATE	: THE_FINAL_STATE	= mid$(STATES,FINAL_STATE,1)
dim as string*1 THE_FIRST_STATE	: THE_FIRST_STATE	= mid$(STATES,FIRST_STATE,1)

'check if files exists
if FileExists(TAPE_IN_FILENAME) and FileExists(TAPE_OUT_FILENAME) then
	gosub TAPE_OUT_GetFromFile						'il nastro di output lo legge solo una volta
	do
		'initializations
		gosub TAPE_IN_GetFromFile
		gosub QUINTUPLES_GetRnd
		gosub TAPE_IN_PrintTape						'print the initial tape status
		gosub TM_Initialize
		
		start! = timer
		
		'TM Run !
		do
			gosub TM_ExecuteQuintuple				'ricerca della quintupla con configurazione (q,s) e ne esegue le istruzioni (s',m,q')
			if DEBUG then gosub TAPE_IN_PrintTape	'print the tape status
			pass = pass + 1
		loop until HALT or (timer - start!) > 1		'se si inlooppa esco..
		'TM Stops!
		
		gosub TAPE_IN_PrintTape						'print the final tape status
	loop until TAPE_IN = TAPE_OUT
else
	if not FileExists(TAPE_IN_FILENAME) 		then print "error!...";TAPE_IN_FILENAME;	" does not exists!"
	if not FileExists(TAPE_OUT_FILENAME) 		then print "error!...";TAPE_OUT_FILENAME;	" does not exists!"
end if

gosub TAPE_OUT_PrintTape			'print the initial tape status
print "TM termina dopo ";pass;" passi."
print 
print "Press a key to print quintuples or ESC to exit" : sleep
if not inkey$ = chr$(27) then gosub TM_PrintQuintuples
end 0

'sub-routines
TM_ParseCommandParameters:	'parse the commands parameters
	i = 1
	do
		Select Case UCase$(command$(i))
			Case "-TI"
				TAPE_IN_FILENAME	= "tm/" & command$(i+1)
			Case "-TO"
				TAPE_OUT_FILENAME	= "tm/" & command$(i+1)
			Case "-S"
				SYMBOLS				= UCase$(command$(i+1)) : N_OF_SYMBOLS	= Len(command$(i+1))
			Case "-Q"
				STATES				= UCase$(command$(i+1)) : N_OF_STATES	= Len(command$(i+1))
			Case "-M"
				MOVES				= UCase$(command$(i+1)) : N_OF_MOVES	= Len(command$(i+1))				
			Case "-DEBUG"
				DEBUG = TRUE
			Case "-H"
				print "TM-MATCH options:"
				print "		-TI <input tape file name>		defines the input TM tape file name						"
				print "		-TO <output tape file name>		defines the input TM tape file name						"
				print "		-S <string of symbols>			defines the symbols used by TM, e.g.  0123456789		"
				print "		-Q <string of states>			defines the states used by TM, e.g.   0123456789ABCDEF	"
				print "		-M <string of moves>			defines the moves allowed by TM, e.g. HRL				"
				print "		-DEBUG 					activates debug											"
				end 0
		End Select
		i = i + 1
	loop until command$(i) = EMPTY
return
TM_Initialize:				'TM initialization
	Q = THE_FIRST_STATE		'inizializza lo stato q		
	P = 1
	HALT = FALSE
	pass = 1
return
TAPE_IN_GetFromFile:		'read the input tape from a file
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	'TAPE_IN = ""
	open TAPE_IN_FILENAME for input as #1
	while not eof(1)
		input #1,row
		if left$(row,1) <> COMMENT then
			'copia su nastro
			if Len(row) < TAPE_MAX_LENGTH + 1 then
				TAPE_LENGTH = Len(row)
				'inizializza il nastro con i blank
				TAPE_IN = string$(TAPE_LENGTH,BLANK)				
				'now write the tape with the given symbols from file
				for i = 1 to TAPE_LENGTH : mid(TAPE_IN,i,1) = mid$(row,i,1) : next i
			else
				print "Error: input tape is too long (max length has to be ";TAPE_LENGTH;")"
			end if
			exit while
		else
			'print row
		end if
	wend
	close #1
return
TAPE_OUT_GetFromFile:		'read the input tape from a file
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	'TAPE_OUT = ""
	open TAPE_OUT_FILENAME for input as #1
	while not eof(1)
		input #1,row
		if left$(row,1) <> COMMENT then
			'copia su nastro
			if Len(row) < TAPE_MAX_LENGTH + 1 then
				TAPE_LENGTH = Len(row)
				'inizializza il nastro con i blank
				TAPE_OUT = string$(TAPE_LENGTH,BLANK)				
				'now write the tape with the given symbols from file
				for i = 1 to TAPE_LENGTH : mid(TAPE_OUT,i,1) = mid$(row,i,1) : next i
			else
				print "Error: input tape is too long (max length has to be ";TAPE_LENGTH;")"
			end if
			exit while
		else
			'print row
		end if
	wend
	close #1
return
TAPE_IN_PrintTape:			'prints the tape
	print TAPE_IN
return
TAPE_OUT_PrintTape:			'prints the tape
	print TAPE_OUT
return
QUINTUPLES_GetRnd:			'generates some random quintuples
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	N_OF_QUINTUPLES = cint(MAX_QUINTUPLES*rnd())
	'genera le quintuple
	for i = 1 to N_OF_QUINTUPLES
		mid(QUINTUPLES(i),CFG_STATE	,1) = mid$(STATES,	cint((N_OF_STATES-1)*rnd())	+1,1)	' q
		mid(QUINTUPLES(i),CFG_SYMBOL,1) = mid$(SYMBOLS,	cint((N_OF_SYMBOLS-1)*rnd())+1,1)	' s
		mid(QUINTUPLES(i),NEW_SYMBOL,1) = mid$(SYMBOLS,	cint((N_OF_SYMBOLS-1)*rnd())+1,1)	' s'
		mid(QUINTUPLES(i),NEW_MOVE	,1) = mid$(MOVES,	cint((N_OF_MOVES-1)*rnd())	+1,1)	' m
		mid(QUINTUPLES(i),NEW_STATE	,1) = mid$(STATES,	cint((N_OF_STATES-1)*rnd())	+1,1)	' q'
	next i
return
TM_PrintQuintuples:			'print the TM's Quintuples
	n = 0
	for i = 1 to N_OF_QUINTUPLES
		if USED_QUINTUPLE(i) > 0 then 'color 2 else color 15
			n = n + 1
			print QUINTUPLES(i);";";
		end if
	next i
	print : print "Were generated ";N_OF_QUINTUPLES;" QUINTUPLES, but only ";n;" of them where effectively used."
return
TM_ExecuteQuintuple:		'cerca la quintupla con configurazione (s,q) e ne esegue le istruzioni (s',m,q')
	HALT = TRUE
	for i = 1 to N_OF_QUINTUPLES
		'se trovo la quintupla con configurazione(q,s) ,allora..
		if mid$(QUINTUPLES(i),CFG_STATE,1) = Q and mid$(QUINTUPLES(i),CFG_SYMBOL,1) = mid$(TAPE_IN,P,1) then
			'..prende la terna (s',m,q')
			Q = mid$(QUINTUPLES(i),NEW_STATE,1) 				'prende dalla quintupla il nuovo stato q'
			mid(TAPE_IN,P,1) = mid$(QUINTUPLES(i),NEW_SYMBOL,1)	'prende dalla quintupla il nuovo simbolo s' e lo scrive su nastro
			
			'se ha raggiunto lo stato finale ferma la TM!
			if Q = THE_FINAL_STATE then exit for

			'legge dalla quintupla come deve muovere la testina
			Select Case mid$(QUINTUPLES(i),NEW_MOVE,1)
				Case MOVES_TO_RIGHT
					if P < TAPE_LENGTH then	P = P + 1 else exit for
				Case MOVES_TO_LEFT
					if P > 1 then P = P - 1	else exit for
				Case MOVES_TO_NOWHERE
					exit for	'ferma la TM!
				Case else
					print "errors in the quintuples" : exit for
			End Select

			USED_QUINTUPLE(i) = USED_QUINTUPLE(i) + 1
			HALT = FALSE
			exit for
		end if
	next i
return