######################################################################
# 
#
#                           Compiladors I 
#             
#			 			Jordi Castella Roca
#
#                            Makefile
#            
#		            		Curs 06/07
#  
######################################################################

# General defines
CC = gcc
LEX = flex
YACC = bison 
ELEX = flex.l
EYACC = bison.y
OBJ = main.o bison.o flex.o
SRC = main.c utils.c support.c functions.c symtab.c
SRCL = lex.yy.c
SRCY = bison.tab.c
BIN = executable
LFLAGS = -n 
YFLAGS = -d -v
OTHERS = bison.tab.h bison.output
TEST_FILE = fitxerDeProves.jl
EXIT_FILE = sortida-c3a.txt

######################################################################

all : $(SRCY) $(SRCL)
	$(CC) -o $(BIN) $(SRCL) $(SRCY) $(SRC) -lm

$(SRCL) : $(ELEX)	
	$(LEX) $(LFLAGS) $<

$(SRCY) : $(EYACC)
	$(YACC) $(YFLAGS) $<

clean : 
	rm -f *~ $(BIN).exe $(OBJ) $(SRCL) $(SRCY) $(OTHERS) $(EXIT_FILE)

run : 
	./$(BIN).exe $(TEST_FILE) $(EXIT_FILE)

