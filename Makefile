RM      := rm -f
CC      := gcc
FLEX    := flex
BISON   := bison
C_SRC   := main.c asd.c
LEX_SRC := scanner.l
YACC_SRC := parser.y
LEX_C   := scanner.yy.c
YACC_C  := parser.tab.c
YACC_H  := parser.tab.h
OBJ     := main.o scanner.yy.o parser.tab.o asd.o
TARGET  := etapa3
CFLAGS  := -Wall -g -Wno-unused-function -fsanitize=address,undefined
LNKFLAG := -fsanitize=address,undefined

all: $(TARGET)

# Gerar parser com bison
$(YACC_C) $(YACC_H): $(YACC_SRC)
	$(BISON) -d -o $(YACC_C) $<

# Gerar lexer com flex (precisa do parser.tab.h)
$(LEX_C): $(LEX_SRC) $(YACC_H)
	$(FLEX) -o $@ $<

# Compilar main.c (precisa do parser.tab.h)
main.o: main.c $(YACC_H)
	$(CC) $(CFLAGS) -c main.c -o main.o

# Compilar parser.tab.c
parser.tab.o: $(YACC_C)
	$(CC) $(CFLAGS) -c $(YACC_C) -o parser.tab.o

# Compilar scanner.yy.c
scanner.yy.o: $(LEX_C)
	$(CC) $(CFLAGS) -c $(LEX_C) -o scanner.yy.o

# Linkar executável final
$(TARGET): $(OBJ)
	$(CC) $(OBJ) -o $@ $(LNKFLAG)

# Limpeza
clean:
	$(RM) $(OBJ) $(LEX_C) $(YACC_C) $(YACC_H) $(TARGET)

TESTDIR := testfiles
TESTFILES := $(wildcard $(TESTDIR)/*)

test: $(TARGET)
	@echo ">> Rodando testes em $(TESTDIR)..."
	@for f in $(TESTFILES); do \
		echo "==> Testando $$f"; \
		if ./$(TARGET) < $$f > /dev/null 2>&1; then \
			echo "   [OK] $$f"; \
		else \
			echo "   [FAIL] $$f"; \
		fi \
	done

# Teste detalhado - mostra onde falhou
test-detailed: $(TARGET)
	@echo ">> Rodando testes DETALHADOS em $(TESTDIR)..."
	@for f in $(TESTFILES); do \
		echo; \
		echo "======================================"; \
		echo "==> Testando: $$f"; \
		echo "--- Conteúdo do arquivo:"; \
		cat $$f; \
		echo; \
		echo "--- Resultado:"; \
		if ./$(TARGET) < $$f; then \
			echo "    [OK] Análise sintática passou (código: $$?)"; \
		else \
			EXIT_CODE=$$?; \
			echo "    [FAIL] Análise sintática falhou (código: $$EXIT_CODE)"; \
		fi; \
	done
	@echo "======================================"

# Teste individual - para testar apenas um arquivo
test-single: $(TARGET)
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make test-single FILE=caminho/para/arquivo"; \
		exit 1; \
	fi
	@echo ">> Testando arquivo específico: $(FILE)"
	@echo "--- Conteúdo do arquivo:"
	@cat $(FILE)
	@echo
	@echo "--- Resultado da análise:"
	@if ./$(TARGET) < $(FILE); then \
		echo " [OK] Análise sintática passou"; \
	else \
		EXIT_CODE=$$?; \
		echo " [FAIL] Análise sintática falhou (código: $$EXIT_CODE)"; \
	fi

# Debug de um arquivo específico - mostra tokens + parse
debug: $(TARGET)
	@if [ -z "$(FILE)" ]; then \
		echo "Uso: make debug FILE=caminho/para/arquivo"; \
		exit 1; \
	fi
	@echo ">> DEBUG do arquivo: $(FILE)"
	@echo "--- Conteúdo:"
	@cat $(FILE)
	@echo
	@echo "--- Análise completa:"
	@./$(TARGET) < $(FILE)

# Teste com diferentes categorias
test-categorized: $(TARGET)
	@echo ">> Testando arquivos por categoria..."
	@echo
	@echo "=== TESTES QUE DEVEM PASSAR ==="
	@for f in $(TESTDIR)/*.txt; do \
		if [ -f "$$f" ]; then \
			case "$$(basename $$f)" in \
				erro*) ;; \
				*) \
					printf "%-35s: " "$$(basename $$f)"; \
					if ./$(TARGET) < $$f > /dev/null 2>&1; then \
						echo "PASSOU"; \
					else \
						echo "FALHOU (deveria passar)"; \
					fi; \
					;; \
			esac; \
		fi; \
	done
	@echo
	@echo "=== TESTES QUE DEVEM FALHAR ==="
	@for f in $(TESTDIR)/erro*.txt; do \
		if [ -f "$$f" ]; then \
			printf "%-35s: " "$$(basename $$f)"; \
			if ./$(TARGET) < $$f > /dev/null 2>&1; then \
				echo "PASSOU (deveria falhar)"; \
			else \
				echo "FALHOU como esperado"; \
			fi; \
		fi; \
	done

.PHONY: all clean test test-detailed test-single debug test-categorized
