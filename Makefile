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

# Diretório de testes
TESTDIR := testfiles
TESTFILES := $(wildcard $(TESTDIR)/*)

test: $(TARGET)
	@echo ">> Rodando testes em $(TESTDIR)..."
	@for f in $(TESTFILES); do \
		echo "==> Testando $$f"; \
		if ./$(TARGET) < $$f > /dev/null 2>&1; then \
			echo "   [OK] $$f"; \
		else \
			echo "   [FAIL] $$f (código: $$?)"; \
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
			echo "    [OK] Análise passou (código: $$?)"; \
		else \
			EXIT_CODE=$$?; \
			echo "    [FAIL] Análise falhou (código: $$EXIT_CODE)"; \
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
		echo " [OK] Análise passou"; \
	else \
		EXIT_CODE=$$?; \
		echo " [FAIL] Análise falhou (código: $$EXIT_CODE)"; \
		case $$EXIT_CODE in \
			10) echo "     Erro: Identificador não declarado (ERR_UNDECLARED)";; \
			11) echo "     Erro: Identificador já declarado (ERR_DECLARED)";; \
			20) echo "     Erro: Variável usada como função (ERR_VARIABLE)";; \
			21) echo "     Erro: Função usada como variável (ERR_FUNCTION)";; \
			30) echo "     Erro: Tipos incompatíveis (ERR_WRONG_TYPE)";; \
			40) echo "     Erro: Argumentos faltando (ERR_MISSING_ARGS)";; \
			41) echo "     Erro: Argumentos em excesso (ERR_EXCESS_ARGS)";; \
			42) echo "     Erro: Tipo de argumento incorreto (ERR_WRONG_TYPE_ARGS)";; \
			*) echo "     Erro desconhecido";; \
		esac; \
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
	@./$(TARGET) < $(FILE) 2>&1

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
						echo "✓ PASSOU"; \
					else \
						EXIT_CODE=$$?; \
						echo "✗ FALHOU (código: $$EXIT_CODE, deveria passar)"; \
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
				echo "✗ PASSOU (deveria falhar)"; \
			else \
				EXIT_CODE=$$?; \
				echo "✓ FALHOU como esperado (código: $$EXIT_CODE)"; \
			fi; \
		fi; \
	done

# Teste de memória com valgrind (se disponível)
test-memory: $(TARGET)
	@if command -v valgrind > /dev/null 2>&1; then \
		echo ">> Testando vazamento de memória com valgrind..."; \
		for f in $(TESTDIR)/*.txt; do \
			if [ -f "$$f" ]; then \
				echo "Testando: $$f"; \
				valgrind --leak-check=full --error-exitcode=1 ./$(TARGET) < $$f > /dev/null 2>&1; \
				if [ $$? -eq 0 ]; then \
					echo "  ✓ Sem vazamento de memória"; \
				else \
					echo "  ✗ Vazamento detectado!"; \
				fi; \
			fi; \
		done; \
	else \
		echo "valgrind não encontrado, pulando teste de memória"; \
		echo "Instalação: sudo apt-get install valgrind (Ubuntu/Debian)"; \
	fi

# Gera relatório de conflitos do bison
conflicts: $(YACC_SRC)
	$(BISON) -d -o $(YACC_C) --report=all $(YACC_SRC)
	@if [ -f parser.output ]; then \
		echo ">> Relatório de conflitos gerado em parser.output"; \
		grep -E "(conflict|Conflict)" parser.output || echo "Nenhum conflito encontrado!"; \
	fi

# Mostra estatísticas do código
stats:
	@echo ">> Estatísticas do projeto:"
	@echo "Linhas de código C:"
	@wc -l $(C_SRC) | tail -n 1
	@echo "Linhas de código Flex:"
	@wc -l $(LEX_SRC)
	@echo "Linhas de código Bison:"
	@wc -l $(YACC_SRC)
	@echo "Total de headers:"
	@ls -1 *.h 2>/dev/null | wc -l

# Help - mostra comandos disponíveis
help:
	@echo "Comandos disponíveis:"
	@echo "  make              - Compila o projeto"
	@echo "  make clean        - Remove arquivos gerados"
	@echo "  make test         - Roda todos os testes"
	@echo "  make test-detailed - Roda testes com saída detalhada"
	@echo "  make test-single FILE=arquivo - Testa um arquivo específico"
	@echo "  make debug FILE=arquivo - Debug detalhado de um arquivo"
	@echo "  make test-categorized - Testes organizados por categoria"
	@echo "  make test-memory  - Testa vazamento de memória (requer valgrind)"
	@echo "  make conflicts    - Gera relatório de conflitos do parser"
	@echo "  make stats        - Mostra estatísticas do código"
	@echo "  make help         - Mostra esta mensagem"

.PHONY: all clean test test-detailed test-single debug test-categorized test-memory conflicts stats help
