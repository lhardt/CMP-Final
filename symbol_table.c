#include "symbol_table.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#define TABLE_SIZE 100

// Função hash simples
static unsigned int hash(const char *str, int size) {
    unsigned int hash = 5381;
    int c;
    while ((c = *str++))
        hash = ((hash << 5) + hash) + c;
    return hash % size;
}

// Cria uma nova tabela de símbolos
symbol_table_t *symbol_table_create(int size) {
    symbol_table_t *table = malloc(sizeof(symbol_table_t));
    table->size = size;
    table->entries = calloc(size, sizeof(symbol_entry_t*));
    return table;
}

// Libera memória da tabela
void symbol_table_free(symbol_table_t *table) {
    if (!table) return;
    
    for (int i = 0; i < table->size; i++) {
        symbol_entry_t *entry = table->entries[i];
        while (entry) {
            symbol_entry_t *tmp = entry;
            entry = entry->next;
            free(tmp->chave);
            free(tmp->valor);
            arg_list_free(tmp->args);
            free(tmp);
        }
    }
    free(table->entries);
    free(table);
}

// Insere um símbolo na tabela
void symbol_table_insert(symbol_table_t *table, const char *chave,
                        natureza_t natureza, tipo_dado_t tipo,
                        int linha, const char *valor) {
    unsigned int idx = hash(chave, table->size);
    
    symbol_entry_t *entry = malloc(sizeof(symbol_entry_t));
    entry->chave = strdup(chave);
    entry->natureza = natureza;
    entry->tipo = tipo;
    entry->linha = linha;
    entry->valor = valor ? strdup(valor) : NULL;
    entry->args = NULL;
    entry->next = table->entries[idx];
    table->entries[idx] = entry;
}

// Busca um símbolo na tabela
symbol_entry_t *symbol_table_lookup(symbol_table_t *table, const char *chave) {
    if (!table) return NULL;
  if(!chave){
    printf("erro chave null\n"); return NULL;
  }
    
  printf("aehoo\n");
    unsigned int idx = hash(chave, table->size);
    symbol_entry_t *entry = table->entries[idx];
    
    while (entry) {
        if (strcmp(entry->chave, chave) == 0)
            return entry;
        entry = entry->next;
    }
    return NULL;
}

// Cria pilha de escopos
scope_stack_t *scope_stack_create() {
    return NULL;
}

// Empilha uma nova tabela
void scope_stack_push(scope_stack_t **stack, symbol_table_t *table) {
    scope_stack_t *node = malloc(sizeof(scope_stack_t));
    node->table = table;
    node->next = *stack;
    *stack = node;
}

// Desempilha e retorna a tabela do topo
symbol_table_t *scope_stack_pop(scope_stack_t **stack) {
    if (!*stack) return NULL;
    
    scope_stack_t *node = *stack;
    symbol_table_t *table = node->table;
    *stack = node->next;
    free(node);
    return table;
}

// Busca um símbolo em toda a pilha de escopos
symbol_entry_t *scope_stack_lookup(scope_stack_t *stack, const char *chave) {
    scope_stack_t *current = stack;
    
    while (current) {
        symbol_entry_t *entry = symbol_table_lookup(current->table, chave);
        if (entry)
            return entry;
        current = current->next;
    }
    return NULL;
}

// Libera a pilha de escopos
void scope_stack_free(scope_stack_t *stack) {
    while (stack) {
        scope_stack_t *tmp = stack;
        stack = stack->next;
        symbol_table_free(tmp->table);
        free(tmp);
    }
}

// Cria um nó de lista de argumentos
arg_list_t *arg_list_create(tipo_dado_t tipo) {
    arg_list_t *arg = malloc(sizeof(arg_list_t));
    arg->tipo = tipo;
    arg->next = NULL;
    return arg;
}

// Adiciona um argumento ao final da lista
void arg_list_append(arg_list_t **list, tipo_dado_t tipo) {
    arg_list_t *new_arg = arg_list_create(tipo);
    
    if (!*list) {
        *list = new_arg;
        return;
    }
    
    arg_list_t *current = *list;
    while (current->next)
        current = current->next;
    current->next = new_arg;
}

// Libera lista de argumentos
void arg_list_free(arg_list_t *list) {
    while (list) {
        arg_list_t *tmp = list;
        list = list->next;
        free(tmp);
    }
}

// Conta argumentos na lista
int arg_list_count(arg_list_t *list) {
    int count = 0;
    while (list) {
        count++;
        list = list->next;
    }
    return count;
}

// Converte string para tipo
tipo_dado_t string_to_tipo(const char *str) {
    if (strcmp(str, "inteiro") == 0)
        return TIPO_INT;
    if (strcmp(str, "decimal") == 0)
        return TIPO_FLOAT;
    return TIPO_INDEFINIDO;
}

// Converte tipo para string
const char *tipo_to_string(tipo_dado_t tipo) {
    switch (tipo) {
        case TIPO_INT: return "inteiro";
        case TIPO_FLOAT: return "decimal";
        default: return "indefinido";
    }
}

// Converte natureza para string
const char *natureza_to_string(natureza_t natureza) {
    switch (natureza) {
        case NATUREZA_LITERAL: return "literal";
        case NATUREZA_VARIAVEL: return "variável";
        case NATUREZA_FUNCAO: return "função";
        default: return "desconhecido";
    }
}

symbol_table_t *scope_stack_curr_lookup(scope_stack_t **stack) {
  // Verificar se a pilha está vazia
  if (stack == NULL || *stack == NULL) {
    fprintf(stderr, "Erro: Pilha de escopos está vazia.\n");
    return NULL;
  }
  // Retornar a tabela de símbolos do topo da pilha
  return (*stack)->table;
}
