'listato del programma, ovvero le quintuple (condizione,istruzione);(condizione,istruzione);... :
'il ; separa le quintuple ossia separa le differenti coppie (condizione,istruzione)
'ove condizione è una coppia (q,s) ossia stato,simbolo e istruzione e' una terna (s',m,q') con m
'che indica il movimento della testina sul nastro (<,.,>)
'programmi di esempio:
'programma = "1||>1;1 |.2"																	'aggiunge un simbolo finale ( implementa l'incremento INC )
'programma = "1| >2;2| >1;1 |.3;2 |>4;4 |.3"												'scrive due simboli se il numero di simboli e' dispari e un simbolo se il numero di simboli e' pari
'programma = "1| >2;2  >3;3 |>4;5||<5;6||<7;7||<7;2||>2;3||>3;4 |<5;5  <6;6  .8;7  >1"		'raddoppia il numero di simboli che trova su nastro
'programma = "1| >2;2  >3;3 |>4;5||<5;6||<7;7||<7;2||>2;3||>3;4 |<5;5  <6;6  .0;7  >1"		'?

'scrive due simboli se il numero di simboli e' dispari e un simbolo se il numero di simboli e' pari
1| >2
2| >1
1 |.3
2 |>4
4 |.3
 
'aggiunge un simbolo finale ( implementa l'incremento INC )
1||>1
1 |.2

'raddoppia il numero di simboli che trova su nastro
1| >2
2  >3
3 |>4
5||<5
6||<7
7||<7
2||>2
3||>3
4 |<5
5  <6
6  .0
7  >1

'cambia gli 1 con 0 e viceversa
1 |>1
1| >1

'sposta a sinistra un blocco di 1 di esattamente di tante celle quante quelle da esso occupate
1  .1 
1| >2 
2 |<1 
2||>3 
3  >4 
3||>3 
4 |<5 
4||>7 
5  <6 
5||.5 
6  >1 
6||<6 
7 |<8 
7||>7 
8  <6 
8||<8 

'counter
101R2
200L1
301L1
111L3
210R2
310H0


'busy beaver game
101R2
201L2
301L3
111R0
210R3
311L1
