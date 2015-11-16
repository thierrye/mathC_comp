all : verif

verif : lex.yy.c tr_mathC.tab.c ic_to_mips.c
	gcc -o comp tr_mathC.tab.c lex.yy.c trad_mathC.c ic_to_mips.c -lfl -g

lex.yy.c : tr_mathC.tab.c l_mathC.lex
	flex l_mathC.lex

tr_mathC.tab.c : tr_mathC.y
	bison --defines=tr_mathC.h --file-prefix=tr_mathC tr_mathC.y --report=states --report-file=tr_mathC.output

clean :
	rm -f tr_mathC.tab.c tr_mathC.h *~ lex.yy.c comp tr_mathC.output
