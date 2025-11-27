'avvio di due tm in sequenza
const as string VIRG		= chr$(34)
const as string TAPE		= "tape.t"
const as string QUINTUPLES	= "quintuples.tm"
const as string BLANK		= VIRG & "0" & VIRG
const as string Q0			= VIRG & "1" & VIRG
const as string QF			= VIRG & "0" & VIRG
const as string TAPE_SYMBS	= VIRG &"01AB" & VIRG
const as string ALPHABET	= VIRG &"0123456789" & VIRG
const as string STATES		= VIRG &"0123456789ABCDEF" & VIRG
const as string MOVES		= VIRG &"HRL" & VIRG

print "genera le quintuple casuali di partenza."
shell "TM-RND -quint " & QUINTUPLES & " -b " & BLANK & " -s " & ALPHABET & " -q " & STATES & " -m " & MOVES & " -no-exec -debug"

do
	print "esegue le quintuple."
	shell "TM-EXEC -tape " & TAPE & " -quint " & QUINTUPLES & " -b " & BLANK & " -q0 " & Q0 & " -qf " & QF & " -s " & ALPHABET & " -q " & STATES & " -m " & MOVES & " -debug"

	print "travasa il nastro nel file delle quintuple"	'legge il nastro come se si trattasse di quintuple
	shell "TAPE_TO_QUINT -tape " & TAPE & " -quint " & QUINTUPLES
	
	print "[ press a key to continue ]"
	sleep
loop
	
end 0