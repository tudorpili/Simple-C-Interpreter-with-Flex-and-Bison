CC=g++
CFLAGS=-Wno-register

all: interpreter2

interpreter2: lex.yy.c parser.tab.c
	$(CC) $(CFLAGS) parser.tab.c lex.yy.c -o interpreter2

parser.tab.c parser.tab.h: parser.y enum.h
	bison -d -Wcounterexamples --report=all -v parser.y

lex.yy.c: lexer.l parser.tab.h enum.h
	flex lexer.l

clean:
	rm -f interpreter2 lex.yy.c parser.tab.c parser.tab.h

