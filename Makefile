RM      := rm -f
CC      := gcc
FLEX    := flex
BISON   := bison

# Arquivos fonte C
C_SRC   := main.c asd.c semantic.c symbol_table.c

# Arquivos fonte Flex/Bison
LEX_SRC := scanner.l
YACC_SRC := parser.y

# Arquivos gerados
LEX_C   := scanner.yy.c
YACC_C  := parser.tab.c
YACC_H  := parser.tab.h

# Objetos: todos os .c viram .o
OBJ     := main.o scanner.yy.o parser.tab.o asd.o semantic.o symbol_table.o

# Nome do executável
TARGET  := etapa4

# Flags de compilação e linking
CFLAGS  := -Wall -g -Wno-unused-function -fsanitize=address,undefined
LNKFLAG := -fsanitize=address,undefined

all: $(TARGET)

# Gerar parser com bison
$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -d -o $(YACC_C) $<

# Gerar lexer com flex (precisa do parser.tab.h)
$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) -o $@ $<

# Compilar main.c (precisa do parser.tab.h e headers)
main.o: main.c $(YACC_H) asd.h
	$(CC) $(CFLAGS) -c main.c -o main.o

# Compilar asd.c (precisa dos headers)
asd.o: asd.c asd.h symbol_table.h
	$(CC) $(CFLAGS) -c asd.c -o asd.o

# Compilar symbol_table.c
symbol_table.o: symbol_table.c symbol_table.h
	$(CC) $(CFLAGS) -c symbol_table.c -o symbol_table.o

# Compilar semantic.c (precisa de symbol_table.h e errors.h)
semantic.o: semantic.c semantic.h symbol_table.h errors.h
	$(CC) $(CFLAGS) -c semantic.c -o semantic.o

# Compilar parser.tab.c (precisa de semantic.h e symbol_table.h)
parser.tab.o: $(YACC_C) $(YACC_H) asd.h semantic.h symbol_table.h
	$(CC) $(CFLAGS) -c $(YACC_C) -o parser.tab.o

# Compilar scanner.yy.c
scanner.yy.o: $(LEX_C) $(YACC_H)
	$(CC) $(CFLAGS) -c $(LEX_C) -o scanner.yy.o

# Linkar executável final
$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $@ $(LNKFLAG)

# Limpeza
clean:
	$(RM) $(OBJ) $(LEX_C) $(YACC_C) $(YACC_H) $(TARGET) parser.output




.PHONY: all clean 
