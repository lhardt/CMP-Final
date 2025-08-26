# --------------------
# Comandos
# --------------------
# o sinal de menos significa "se der erro, ignora e não para"
# ou seja, quando ele não conseguir deletar um arquivo (já
# deletado, ou não gerado), ele ignora.
RM 		:= -rm
CC 		:= gcc
# --------------------
# Pastas
# --------------------
SRCDIR 	:= src
OBJDIR 	:= obj
BINDIR 	:= bin
INCDIR  := inc
LIBDIR  := lib
# --------------------
# Arquivos
# --------------------

LEXSRC:= $(wildcard $(SRCDIR)/*.l)
LEXOBJ:= $(LEXSRC:$(SRCDIR)/%.l=$(SRCDIR)/%.yy.c)

SRC 	:= $(wildcard $(SRCDIR)/*.c) $(LEXOBJ)
TARGET 	:= $(BINDIR)/main
# -lXXX vai procurar um arquivo com nome libXXX.a
LIB		:= $(wildcard $(LIBDIR)/*.o) $(wildcard $(LIBDIR)/*.a)
OBJ 	:= $(SRC:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
# --------------------
# Flags para o compilador
# --------------------
# Sobre as flags utilizadas: I é para a diretiva #include encontrar arquivos em
# tal pasta. -Wall pede todos os avisos (Warning:all) e -g ajuda no debugger
# porque preserva o número da linha de código.
CFLAGS 	:= -Iinc -Wall -g -Wno-unused-function
TSTFLAG :=
LNKFLAG := -fsanitize=address,undefined

# --------------------
# Regras de compilação
# --------------------

all: $(TARGET)

clean:
	$(RM) $(OBJ) $(LEXOBJ)

obj/%.o: src/%.c
	$(CC)  $(CFLAGS) -c $(@:$(OBJDIR)/%.o=$(SRCDIR)/%.c) -o $@

# usar option noyyrwap
# usar option yylineno
$(LEXOBJ): $(LEXSRC)
	flex --outfile=$(LEXOBJ) $(@:$(SRCDIR)/%.yy.c=$(SRCDIR)/%.l)

$(TARGET) : $(OBJ)
	$(CC) -o $(TARGET) $^ $(LIB)

