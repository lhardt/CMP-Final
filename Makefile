RM   := rm -f
CC   := gcc
FLEX := flex

C_SRC   := main.c
LEX_SRC := scanner.l
LEX_C   := scanner.yy.c
OBJ     := main.o scanner.yy.o
TARGET  := etapa1

CFLAGS  := -Wall -g -Wno-unused-function
LNKFLAG := -fsanitize=address,undefined

all: $(TARGET)

# Gerar lexer com flex
$(LEX_C): $(LEX_SRC)
	$(FLEX) -o $@ $<

# Compilar objetos
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Linkar executável final
$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $@ $(LNKFLAG)

# Limpeza
clean:
	$(RM) $(OBJ) $(LEX_C) $(TARGET)


.PHONY: all clean tar

