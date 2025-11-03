#include "semantic.h"
#include "errors.h"
#include "asd.h"
#include "symbol_table.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Pilha global de escopos
scope_stack_t *global_scope_stack = NULL;

void semantic_init() {
    printf("iniciando escopo\n");
    global_scope_stack = scope_stack_create();
    // Cria escopo global
    symbol_table_t *global_table = symbol_table_create(TABLE_SIZE);
    scope_stack_push(&global_scope_stack, global_table);
}

void semantic_finish() {
    printf("terminando escopo\n");
    scope_stack_free(global_scope_stack);
    global_scope_stack = NULL;
}

void semantic_push_scope() {
    symbol_table_t *new_table = symbol_table_create(TABLE_SIZE);
    scope_stack_push(&global_scope_stack, new_table);
}

void semantic_pop_scope() {
    symbol_table_t *table = scope_stack_pop(&global_scope_stack);
    if (table) {
        symbol_table_free(table);
    }
}

void semantic_check_declared(const char *id, int linha) {
    symbol_entry_t *entry = scope_stack_lookup(global_scope_stack, id);
    if (entry) {
        fprintf(stderr, "Erro semântico na linha %d: identificador '%s' já foi declarado na linha %d\n",
                linha, id, entry->linha);
        exit(ERR_DECLARED);
    }
}

symbol_entry_t *semantic_check_undeclared(const char *id, int linha) {
    symbol_entry_t *entry = scope_stack_lookup(global_scope_stack, id);
    if (!entry) {
        fprintf(stderr, "Erro semântico na linha %d: identificador '%s' não foi declarado\n",
                linha, id);
        exit(ERR_UNDECLARED);
    }
    return entry;
}

void semantic_declare_variable(const char *id, tipo_dado_t tipo, int linha, const char *valor) {
    // Verifica se já foi declarado no escopo atual
    symbol_table_t *current_scope = global_scope_stack->table;
    if (symbol_table_lookup(current_scope, id)) {
        fprintf(stderr, "Erro semântico na linha %d: variável '%s' já foi declarada neste escopo\n",
                linha, id);
        exit(ERR_DECLARED);
    }
    
    symbol_table_insert(current_scope, id, NATUREZA_VARIAVEL, tipo, linha, valor);
}

//argumentos vão sendo postos depois!
void semantic_declare_function(const char *id, tipo_dado_t tipo_retorno, int linha) {
    // Funções são sempre declaradas no escopo global
    // Busca apenas no escopo global (base da pilha)
    /*printf("procurando se funcao ja declarada\n");*/
    scope_stack_t *current = global_scope_stack;
    while (current->next) current = current->next;
    
    if (symbol_table_lookup(current->table, id)) {
        fprintf(stderr, "Erro semântico na linha %d: função '%s' já foi declarada\n",
                linha, id);
        exit(ERR_DECLARED);
    }
    
    printf("inserindo funcao %s no escopo global\n",id);
    symbol_table_insert(current->table, id, NATUREZA_FUNCAO, tipo_retorno, linha, NULL);
    /*printf("atribuindo argumentos na tabela");*/
    /*symbol_entry_t *entry = symbol_table_lookup(current->table, id);*/
    /*entry->args = args;*/
    semantic_print_current_scope();
}

void semantic_add_function_parameter(symbol_table_t* curr_table,char* func_id, tipo_dado_t arg_type){

  printf("adicionando parametro a funcao!!\n");

  symbol_entry_t* func_entry=symbol_table_lookup(curr_table, func_id);
  if(!func_entry) return;

if (!func_entry->args) {
    printf("adicionando novo\n");
    func_entry->args = arg_list_create(arg_type);
  } else {
    arg_list_append(&func_entry->args, arg_type);
  }

}

void semantic_check_variable_usage(const char *id, int linha) {
    symbol_entry_t *entry = semantic_check_undeclared(id, linha);
    
    if (entry->natureza == NATUREZA_FUNCAO) {
        fprintf(stderr, "Erro semântico na linha %d: '%s' é uma função e não pode ser usado como variável\n",
                linha, id);
        exit(ERR_FUNCTION);
    }
}

void semantic_check_function_usage(const char *id, int linha) {
    symbol_entry_t *entry = semantic_check_undeclared(id, linha);
    
    if (entry->natureza != NATUREZA_FUNCAO) {
        fprintf(stderr, "Erro semântico na linha %d: '%s' é uma variável e não pode ser usado como função\n",
                linha, id);
        exit(ERR_VARIABLE);
    }
}

tipo_dado_t semantic_infer_type(tipo_dado_t tipo1, tipo_dado_t tipo2, int linha) {
    if (tipo1 == TIPO_INT && tipo2 == TIPO_INT)
        return TIPO_INT;
    
    if (tipo1 == TIPO_FLOAT && tipo2 == TIPO_FLOAT)
        return TIPO_FLOAT;
    
    // Mistura de int e float não é permitida
    fprintf(stderr, "Erro semântico na linha %d: tipos incompatíveis (%s e %s)\n",
            linha, tipo_to_string(tipo1), tipo_to_string(tipo2));
    exit(ERR_WRONG_TYPE);
}

void semantic_check_attribution(tipo_dado_t tipo_var, tipo_dado_t tipo_expr, int linha) {
    if (tipo_var != tipo_expr) {
        fprintf(stderr, "Erro semântico na linha %d: atribuição com tipos incompatíveis (%s := %s)\n",
                linha, tipo_to_string(tipo_var), tipo_to_string(tipo_expr));
        exit(ERR_WRONG_TYPE);
    }
}

void semantic_check_return(tipo_dado_t tipo_funcao, tipo_dado_t tipo_retorno, int linha) {
    if (tipo_funcao != tipo_retorno) {
        fprintf(stderr, "Erro semântico na linha %d: tipo de retorno incompatível (esperado %s, recebido %s)\n",
                linha, tipo_to_string(tipo_funcao), tipo_to_string(tipo_retorno));
        exit(ERR_WRONG_TYPE);
    }
}

void semantic_check_function_call(const char *id, arg_list_t *args_chamada, int linha) {
    symbol_entry_t *entry = semantic_check_undeclared(id, linha);
    
    if (entry->natureza != NATUREZA_FUNCAO) {
        fprintf(stderr, "Erro semântico na linha %d: '%s' não é uma função\n", linha, id);
        exit(ERR_VARIABLE);
    }
    
    int count_esperados = arg_list_count(entry->args);
    int count_fornecidos = arg_list_count(args_chamada);
    
    if (count_fornecidos < count_esperados) {
        fprintf(stderr, "Erro semântico na linha %d: função '%s' espera %d argumentos mas recebeu %d\n",
                linha, id, count_esperados, count_fornecidos);
        exit(ERR_MISSING_ARGS);
    }
    
    if (count_fornecidos > count_esperados) {
        fprintf(stderr, "Erro semântico na linha %d: função '%s' espera %d argumentos mas recebeu %d\n",
                linha, id, count_esperados, count_fornecidos);
        exit(ERR_EXCESS_ARGS);
    }
    
    // Verifica tipos dos argumentos
    arg_list_t *param = entry->args;
    arg_list_t *arg = args_chamada;
    int pos = 1;
    
    while (param && arg) {
        if (param->tipo != arg->tipo) {
            fprintf(stderr, "Erro semântico na linha %d: argumento %d de '%s' tem tipo incorreto (esperado %s, recebido %s)\n",
                    linha, pos, id, tipo_to_string(param->tipo), tipo_to_string(arg->tipo));
            exit(ERR_WRONG_TYPE_ARGS);
        }
        param = param->next;
        arg = arg->next;
        pos++;
    }
}

tipo_dado_t semantic_get_literal_type(const char *valor) {
    // Se contém ponto decimal, é float
    if (strchr(valor, '.'))
        return TIPO_FLOAT;
    return TIPO_INT;
}

void semantic_print_current_scope(void) {
    if (!global_scope_stack) {
        printf("Nenhum escopo ativo\n");
        return;
    }
    
    symbol_table_t *current_table = global_scope_stack->table;
    printf("=== Escopo Atual ===\n");
    
    int symbol_count = 0;
    for (int i = 0; i < current_table->size; i++) {
        symbol_entry_t *entry = current_table->entries[i];
        while (entry) {
            printf("  Identificador: %s\n", entry->chave);
            printf("    - Natureza: %s\n", natureza_to_string(entry->natureza));
            printf("    - Tipo: %s\n", tipo_to_string(entry->tipo));
            printf("    - Linha de declaração: %d\n", entry->linha);
            
            if (entry->valor) {
                printf("    - Valor: %s\n", entry->valor);
            }
            
            if (entry->natureza == NATUREZA_FUNCAO && entry->args) {
                printf("    - Argumentos: ");
                arg_list_t *arg = entry->args;
                while (arg) {
                    printf("%s", tipo_to_string(arg->tipo));
                    if (arg->next) printf(", ");
                    arg = arg->next;
                }
                printf("\n");
            }
            
            printf("\n");
            symbol_count++;
            entry = entry->next;
        }
    }
    
    if (symbol_count == 0) {
        printf("  (vazio)\n");
    }
    printf("===================\n");
}

arg_list_t* tree_to_arg_list(asd_tree_t *param_tree) {
    printf("percorrendo arvore de paramentros\n");
    if (!param_tree) return NULL;
    
    arg_list_t *args = NULL;
    arg_list_t *current = NULL;
    
    // Percorre a árvore de parâmetros
    asd_tree_t *node = param_tree;
    while (node) {
        // Cria novo argumento com o tipo do nó atual
        /*printf("parametro %s",node->label);*/
        arg_list_t *new_arg = arg_list_create(node->tipo);
        
        if (!args) {
            args = new_arg;
            current = args;
        } else {
            current->next = new_arg;
            current = current->next;
        }
        
        // Move para o próximo parâmetro (próximo filho)
        if (node->children && node->number_of_children > 0) {
            node = node->children[0];
        } else {
            break;
        }
    }
    
    return args;
}
