#ifndef _SEMANTIC_H_
#define _SEMANTIC_H_

#include "symbol_table.h"
#include "asd.h"

#define TABLE_SIZE 100

// inicialização e finalização
void semantic_init();
void semantic_finish();

// gerenciamento de escopos
void semantic_push_scope();
void semantic_pop_scope();

// verificações de declaração
void semantic_check_declared(const char *id, int linha);
symbol_entry_t *semantic_check_undeclared(const char *id, int linha);

// declarações
void semantic_declare_variable(const char *id, tipo_dado_t tipo, int linha, const char *valor);
void semantic_declare_function(const char *id, tipo_dado_t tipo_retorno,int linha);
void semantic_add_function_parameter( scope_stack_t* scope_stack, char* func_id, tipo_dado_t arg_type);

// verificação de uso correto
void semantic_check_variable_usage(const char *id, int linha);
void semantic_check_function_usage(const char *id, int linha);

// inferência de tipos
tipo_dado_t semantic_infer_type(tipo_dado_t tipo1, tipo_dado_t tipo2, int linha);

// verificações de compatibilidade
void semantic_check_attribution(tipo_dado_t tipo_var, tipo_dado_t tipo_expr, int linha);
void semantic_check_return(tipo_dado_t tipo_funcao, tipo_dado_t tipo_retorno, int linha);
void semantic_check_condition(tipo_dado_t tipo, int linha);

// verificação de chamadas de função
void semantic_check_function_call(const char *id, arg_list_t *args_chamada, int linha);

// util
void semantic_print_current_scope(void);
#endif // _SEMANTIC_H_
