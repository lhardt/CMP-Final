#ifndef _SEMANTIC_H_
#define _SEMANTIC_H_

#include "symbol_table.h"
#include "asd.h"

#define TABLE_SIZE 100

// Inicialização e finalização
void semantic_init();
void semantic_finish();

// Gerenciamento de escopos
void semantic_push_scope();
void semantic_pop_scope();

// Verificações de declaração
void semantic_check_declared(const char *id, int linha);
symbol_entry_t *semantic_check_undeclared(const char *id, int linha);

// Declarações
void semantic_declare_variable(const char *id, tipo_dado_t tipo, int linha, const char *valor);
void semantic_declare_function(const char *id, tipo_dado_t tipo_retorno,int linha);
void semantic_add_function_parameter( scope_stack_t* scope_stack, char* func_id, tipo_dado_t arg_type);

// Verificação de uso correto
void semantic_check_variable_usage(const char *id, int linha);
void semantic_check_function_usage(const char *id, int linha);

// Inferência de tipos
tipo_dado_t semantic_infer_type(tipo_dado_t tipo1, tipo_dado_t tipo2, int linha);

// Verificações de compatibilidade
void semantic_check_attribution(tipo_dado_t tipo_var, tipo_dado_t tipo_expr, int linha);
void semantic_check_return(tipo_dado_t tipo_funcao, tipo_dado_t tipo_retorno, int linha);

// Verificação de chamadas de função
void semantic_check_function_call(const char *id, arg_list_t *args_chamada, int linha);

// Utilitários
tipo_dado_t semantic_get_literal_type(const char *valor);
void semantic_print_current_scope(void);
arg_list_t* tree_to_arg_list(asd_tree_t *param_tree);
#endif // _SEMANTIC_H_
