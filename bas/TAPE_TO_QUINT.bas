
'TM Turing Machine tape to quintuples copier in QBasic (compilata con FreeBasic   'fbc -lang qb tape_to_quint.bas' )
'by CosMax2016, june 2016

'consente di considerare come quintuple il contenuto del nastro e copiarlo in modo opportuno sul file delle quintuple

'ex: > TAPE_TO_QUINT -tape tape.t -quint quintuples.tm 
'    > TAPE_TO_QUINT -h  (to have an help!)

#include once "file.bi"
#include once "string.bi"

const as string				EMPTY								= ""
const as string				CR									= chr$(10)
const as string				LF									= chr$(13)
dim as string*1				COMMENT			: COMMENT			= "'"	'indica una riga di commento nei files del nastro e delle quintuple
dim as string*1 			BLANK			: BLANK 			= "0"
dim as integer				MAX_TAPE_LENGTH	: MAX_TAPE_LENGTH	= 4096	'max tape length permissible (4K bytes)
dim as integer				TAPE_LENGTH		: TAPE_LENGTH		= 0		'the actual tape length
dim as string				TAPE			: TAPE				= EMPTY	'il nastro
dim as integer				MAX_QUINTUPLES	: MAX_QUINTUPLES	= 20000	'massimo numero di quintuple gestibili
dim as integer				N_OF_QUINTUPLES	: N_OF_QUINTUPLES	= 0		'numero di quintuple effettivo
dim as string*5				QUINTUPLES(1 to MAX_QUINTUPLES)				'array of quintuples (q,s,s',m,q')
dim as string*5				QUINTUPLE
dim as string				TAPE_FILENAME 		: TAPE_FILENAME			= "tapes/tape.t"		'nome file di default
dim as string				QUINTUPLES_FILENAME	: QUINTUPLES_FILENAME	= "tm/quintuples.tm"	'nome file di default
dim as integer 				i,j,n
dim as string				row

'parse the parameters given in input
gosub TM_ParseParameters

'legge il nastro
gosub TAPE_GetFromFile
'gosub TAPE_PrintTape
'print "tape length:";TAPE_LENGTH

'converte i simboli del nastro in quintuple
gosub Convert_TAPE_to_QUINTUPLES

'salva le quintuple convertite
gosub QUINTUPLES_ToFile
gosub TM_PrintQuintuples

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

			Case "-H"
				print "TM options:"
				print "     -TAPE  <tape file name>        defines the input TM tape file name e.g. -TF " & chr$(34) & "tape.t" & chr$(34)
				print "     -QUINT <quintuples file name>  defines the TM instruction quintuples file name to read e.g. -QUINT " & chr$(34) & "mult.tm" & chr$(34)
				print "     -H                             this help"
				end 0
		End Select
		i = i + 1
	loop until command$(i) = EMPTY
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
TAPE_PrintTape:				'prints the tape
	print "TAPE[";format$(pass,"0000");"] ";TAPE
return
Convert_TAPE_to_QUINTUPLES:	'converts tape symbols to quintuples
	n = 0
	for i = 1 to TAPE_LENGTH step 5
		QUINTUPLE = ""
		for j = i to i+5
			if j <= TAPE_LENGTH then
				QUINTUPLE += mid$(TAPE,j,1)
			else
				QUINTUPLE += BLANK 'riempio il rimanente coi blank
			end if
		next j
		n += 1
		QUINTUPLES(n) = QUINTUPLE
	next i
	N_OF_QUINTUPLES = n
return
TM_PrintQuintuples:			'print the TM's Quintuples
	for i = 1 to N_OF_QUINTUPLES
		print QUINTUPLES(i);";";
	next i
	print : print "Were generated from tape ";N_OF_QUINTUPLES;" QUINTUPLES."
return
QUINTUPLES_ToFile:			'save the TM's quintuples to file
	'prende da file la sequenza di simboli da dare in input alla TM e la mette su nastro
	open QUINTUPLES_FILENAME for output as #2
	print #2,"'these are the quintuples extracted from the tape  (" & date$ & " at " & time$ & ")" 
	for i = 1 to N_OF_QUINTUPLES
		'copia da memoria su file			
		for j = 1 to 5
			print #2, mid$(QUINTUPLES(i),j,1);
		next j
		print #2, EMPTY
	next i
	close #2
return