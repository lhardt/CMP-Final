#ifndef _SYMBOL_TABLE_H_
#define _SYMBOL_TABLE_H_

#include <stdbool.h>

// Tipos de natureza dos símbolos
typedef enum {
    NATUREZA_LITERAL,
    NATUREZA_VARIAVEL,
    NATUREZA_FUNCAO
} natureza_t;

// Tipos de dados
typedef enum {
    TIPO_INT,
    TIPO_FLOAT,
    TIPO_INDEFINIDO
} tipo_dado_t;

// Estrutura para argumentos de função
typedef struct arg_list {
    tipo_dado_t tipo;
    struct arg_list *next;
} arg_list_t;

// Entrada da tabela de símbolos
typedef struct symbol_entry {
    char *chave;              // identificador
    natureza_t natureza;      // literal, variável ou função
    tipo_dado_t tipo;         // int ou float
    arg_list_t *args;         // lista de argumentos (para funções)
    int linha;                // linha de declaração
    char *valor;              // valor do lexema
    struct symbol_entry *next; // próxima entrada (hash collision)
} symbol_entry_t;

// Tabela de símbolos (hash table)
typedef struct symbol_table {
    symbol_entry_t **entries; // array de ponteiros para entradas
    int size;                 // tamanho da tabela
} symbol_table_t;

// Pilha de tabelas de símbolos (para escopos)
typedef struct scope_stack {
    symbol_table_t *table;
    struct scope_stack *next;
} scope_stack_t;

// Funções para gerenciar tabelas de símbolos
symbol_table_t *symbol_table_create(int size);
void symbol_table_free(symbol_table_t *table);
void symbol_table_insert(symbol_table_t *table, const char *chave, 
                        natureza_t natureza, tipo_dado_t tipo, 
                        int linha, const char *valor);
symbol_entry_t *symbol_table_lookup(symbol_table_t *table, const char *chave);

// Funções para gerenciar pilha de escopos
scope_stack_t *scope_stack_create();
void scope_stack_push(scope_stack_t **stack, symbol_table_t *table);
symbol_table_t *scope_stack_pop(scope_stack_t **stack);
symbol_table_t *scope_stack_curr_lookup(scope_stack_t **stack);
symbol_entry_t *scope_stack_lookup(scope_stack_t *stack, const char *chave);
void scope_stack_free(scope_stack_t *stack);

// Funções auxiliares para argumentos
arg_list_t *arg_list_create(tipo_dado_t tipo);
void arg_list_append(arg_list_t **list, tipo_dado_t tipo);
void arg_list_free(arg_list_t *list);
int arg_list_count(arg_list_t *list);

// Conversão de strings para tipos
tipo_dado_t string_to_tipo(const char *str);
const char *tipo_to_string(tipo_dado_t tipo);
const char *natureza_to_string(natureza_t natureza);

#endif // _SYMBOL_TABLE_H_
