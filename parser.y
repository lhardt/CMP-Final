%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
#include "asd.h"
#include "symbol_table.h"
#include "semantic.h"
int yylex(void);
void yyerror(const char *mensagem);

asd_tree_t* make_binop(asd_tree_t * lhs, valor_lexico_t op, asd_tree_t * rhs){
  asd_tree_t * root = asd_new(op.value);
  asd_add_child(root, lhs);
  asd_add_child(root, rhs);
  
  // Inferência de tipo para operação binária
  root->tipo = semantic_infer_type(lhs->tipo, rhs->tipo, op.line_no);
  
  free(op.value);
  return root;
}
char* current_function_name = NULL;
%}

%define parse.error verbose

%union {
  valor_lexico_t valor_lexico;
  asd_tree_t * asd_tree_t;

}


%code requires {
#include "asd.h"
#include "semantic.h"
extern asd_tree_t * arvore;
extern scope_stack_t *global_scope_stack ;
typedef struct valor_lexico {
  int line_no;
  int type;
  char* value;
} valor_lexico_t;
}

%type <asd_tree_t> programa lista_elementos  definicao_funcao tipo lista_parametros  parametro declaracao_variavel declaracao_variavel_sem_init inicializacao_opt literal comando bloco cabecalho_funcao bloco_funcao declaracao_funcao lista_comandos atribuicao chamada_funcao lista_argumentos_opt lista_argumentos comando_retorna comando_se comando_enquanto expressao expressao_or
%type <asd_tree_t> expressao_and expressao_igualdade expressao_relacional expressao_aditiva expressao_multiplicativa expressao_primaria expressao_unaria

/* Declaração dos tokens */
%token <valor_lexico> TK_TIPO
%token <valor_lexico> TK_VAR
%token <valor_lexico> TK_SENAO
%token <valor_lexico> TK_DECIMAL
%token <valor_lexico> TK_SE
%token <valor_lexico> TK_INTEIRO
%token <valor_lexico> TK_ATRIB
%token <valor_lexico> TK_RETORNA
%token <valor_lexico> TK_SETA
%token <valor_lexico> TK_ENQUANTO
%token <valor_lexico> TK_COM
%token <valor_lexico> TK_OC_LE
%token <valor_lexico> TK_OC_GE
%token <valor_lexico> TK_OC_EQ
%token <valor_lexico> TK_OC_NE
%token <valor_lexico> TK_ID
%token <valor_lexico> TK_LI_INTEIRO
%token <valor_lexico> TK_LI_DECIMAL
%token <valor_lexico> TK_ER
%token <valor_lexico> '[' ']' '(' ')' '*' ';' '%' '|' '!' ':' '<' '>' ',' '=' '+' '-' '/' '&'

%nonassoc UNARY_PREC

/* A raiz da árvore é o nó da primeira função */
/* deve-se liberar a memória assim que a informação do valor léxico tiver sido consumida para a criação da AST. Isso deve ocorrer em todas as regras gramaticais (parser.y) que referenciam estes elementos léxicos. */

%%

programa
    : semantic_init lista_elementos semantic_finish ';' {
      $$ = $2;
      arvore = $$;
      free($4.value);
    }
    | /* vazio */ { 
      $$ = asd_new("programa_vazio");
      arvore = $$;
    }
    ;

semantic_init: {semantic_init();};
semantic_finish: { semantic_finish(); };
escopo_ini: {
          /*
          1.cria tabela vazia
          2.empilha tabela
          type(escopo_ini) = tabela
          */
          semantic_push_scope();
          };
escopo_fim: {
          semantic_pop_scope();
          };

lista_elementos
    : declaracao_variavel_sem_init ',' lista_elementos {
      if($1) asd_free($1);
      free($2.value);
      $$ = $3;
    } 
    | definicao_funcao ',' lista_elementos {
      if($1 && $3) asd_add_child($1, $3);
      $$ = $1;
      free($2.value);
    } 
    | declaracao_variavel_sem_init { $$ = NULL; } 
    | definicao_funcao { $$ = $1; } 
    ;


declaracao_funcao: TK_ID TK_SETA tipo{
              semantic_declare_function($1.value, $3->tipo, $1.line_no);
              current_function_name = strdup($1.value);
              semantic_push_scope();
              $$ = asd_new($1.value);
              free($1.value);
              free($2.value);
              asd_free($3);
                 };

cabecalho_funcao
    : declaracao_funcao TK_ATRIB {
        $$ = $1;
        //$$->tipo = $3->tipo;
        
        free($2.value);
    }
    | declaracao_funcao TK_COM lista_parametros TK_ATRIB {
        // current_function_type = $3->tipo;
        $$=$1;
        free($2.value);
        asd_free($3);
        free($4.value);
    }
   | declaracao_funcao lista_parametros TK_ATRIB {
        $$ = $1;
        //$$->tipo = $3->tipo;
        
        asd_free($2);
        free($3.value);
    }
    ;
    ;

definicao_funcao
    /* tenho que inserir a função e o tipo dela no escopo global, implementar talvez um novo não terminal que faça isso
      bloco_funcao tem que ser um tipo de bloco especial que NÃO cria e fecha escopos.
        p.q. senão, quando tu cria uma função, ia ser criado um escopo que inclui os parametros e depois mais um escopo pro
        bloco do corpo da função, quando na verdade, a gente quer que esse seja um escopo só
    */
    :cabecalho_funcao bloco_funcao { 
       $$ = $1;
        if($2) asd_add_child($$, $2);
        semantic_pop_scope();
        free(current_function_name);
        current_function_name = NULL;
    }
    ;
    

tipo 
    : TK_DECIMAL { $$ = asd_new($1.value); $$->tipo=TIPO_FLOAT;  free($1.value); } 
    | TK_INTEIRO { $$ = asd_new($1.value); $$->tipo=TIPO_INT; free($1.value); } 
    ;

lista_parametros
    : parametro { $$ = $1; } 
    | parametro ',' lista_parametros {
      $$ = $1;
      free($2.value);
      if( $1 && $3 ) asd_add_child($$, $3);
    } 
    ;

parametro
    : TK_ID TK_ATRIB tipo { 
      //$$ = NULL;
      $$=asd_new($1.value);
      $$->tipo=$3->tipo;
       semantic_add_function_parameter(global_scope_stack, current_function_name,$3->tipo);
      semantic_declare_variable($1.value,$3->tipo,$1.line_no,NULL);
      free($1.value);
      free($2.value);
      if($3) asd_free($3);
      // unused
    } 
    ;

declaracao_variavel
    : TK_VAR TK_ID TK_ATRIB tipo inicializacao_opt {
      if($5){
        $$ = asd_new("com"); /* TODO REVIEW DOCS */
        semantic_check_attribution($4->tipo, $5->tipo, $1.line_no);
        semantic_declare_variable($2.value,$4->tipo,$1.line_no,$5->label);
        asd_add_child($$, asd_new($2.value));
        asd_add_child($$, $5);
      } else {
        $$ = NULL;
        semantic_declare_variable($2.value,$4->tipo,$1.line_no,NULL);
      }

      free($1.value);
      free($2.value);
      free($3.value);
      asd_free($4);
    }
    ;

declaracao_variavel_sem_init
    : TK_VAR TK_ID TK_ATRIB tipo {
      semantic_declare_variable($2.value,$4->tipo,$1.line_no,NULL);
      $$ = NULL;

      free($1.value);
      free($2.value);
      free($3.value);
      asd_free($4);
    } 
    ;

inicializacao_opt
    : /* vazio */ { $$ = NULL; } 
    | TK_COM literal {
      $$ = $2;
      free($1.value);
    } 
    ;

literal
    : TK_LI_INTEIRO { $$ = asd_new($1.value); $$->tipo=TIPO_INT; free($1.value); } 
    | TK_LI_DECIMAL { $$ = asd_new($1.value); $$->tipo=TIPO_FLOAT; free($1.value); } 
    ;

comando
    : bloco { $$ = $1; } 
    | declaracao_variavel { $$ = $1; } 
    | atribuicao { $$ = $1; } 
    | chamada_funcao { $$ = $1; } 
    | comando_retorna { $$ = $1; } 
    | comando_se { $$ = $1; } 
    | comando_enquanto { $$ = $1; } 
    ;

bloco
    : '[' lista_comandos ']' {
      /* cria escopo */
      $$ = $2;
      free($1.value);
      free($3.value);
    } 
    ;

bloco_funcao 
    : '[' lista_comandos ']' {
      // não cria escopo
      $$ = $2;
      free($1.value);
      free($3.value);
    } 
    ;

lista_comandos
    : /* vazio */ { $$ = NULL; } 
    | comando lista_comandos {
      if($1 && $2){
        asd_add_child($1, $2);
        $$ = $1;
      } else if($1) {
        $$ = $1;
      } else {
        $$ = $2;
      }
    } 
    ;

atribuicao
    : TK_ID TK_ATRIB expressao {
      semantic_check_variable_usage($1.value, $1.line_no);
      symbol_entry_t *var = scope_stack_lookup(global_scope_stack, $1.value);
      
      // Verifica compatibilidade de tipos
      semantic_check_attribution(var->tipo, $3->tipo, $1.line_no);
      $$ = asd_new($2.value); 
      
      asd_add_child( $$, asd_new($1.value) );
      asd_add_child( $$, $3 );

      free($1.value);
      free($2.value);
    }
    ;

chamada_funcao
    : TK_ID '(' lista_argumentos_opt ')' {
      semantic_check_function_usage($1.value, $1.line_no);
      symbol_entry_t *func = scope_stack_lookup(global_scope_stack, $1.value);

      // Cria lista de tipos dos argumentos fornecidos
      arg_list_t *args_chamada = NULL;
      asd_tree_t *arg_node = $3;
      while (arg_node) {
        arg_list_append(&args_chamada, arg_node->tipo);
        if (arg_node->number_of_children > 0)
          arg_node = arg_node->children[0];
        else
          break;
      }
      
      // Verifica argumentos
      semantic_check_function_call($1.value, args_chamada, $1.line_no);
      arg_list_free(args_chamada);

      char* buf = calloc( strlen($1.value) + strlen("call ") + 1, sizeof(char));
      strcat(buf, "call ");
      strcat(buf, $1.value);

      $$ = asd_new(buf);
      $$->tipo = func->tipo;
      if( $3 ) asd_add_child($$, $3);

      free(buf);
      free($1.value);
      free($2.value);
      free($4.value);
    }
    ;

lista_argumentos_opt
    : /* vazio */ { $$ = NULL; } 
    | lista_argumentos { $$ = $1; } 
    ;

lista_argumentos
    : expressao { $$ = $1; } 
    | expressao ',' lista_argumentos {
      if( $1 && $3 ){
        asd_add_child($1, $3);
        $$ = $1;
      } else if( $1 ){
        $$ = $1;
      } else if( $3 ){
        $$ = $3;
      }
      free($2.value);
    } 
    ;

comando_retorna
    : TK_RETORNA expressao TK_ATRIB tipo {
        /* O comando return tem um filho, que é uma expressão. */
        $$ = asd_new("retorna"); 
        //tipo de retorno deve ser compativel com o tipo da funcao
        symbol_entry_t* func=scope_stack_lookup(global_scope_stack,current_function_name);
        semantic_check_return(func->tipo,$2->tipo,$1.line_no);
        semantic_check_attribution($2->tipo,$4->tipo,$1.line_no);
        $$->tipo = $4->tipo;
        free($1.value);
        asd_add_child($$, $2);
        free($3.value);
        asd_free($4);
      } 
    ;

comando_se
    : TK_SE '(' expressao ')' escopo_ini bloco escopo_fim {
      /* O comando if com else opcional deve ter pelo 
         menos três filhos, um para a expressão, outro para 
         o primeiro comando quando verdade, e o último – 
         opcional – para o segundo comando quando falso */
      $$ = asd_new($1.value);
      $$->tipo = $3->tipo;
      
      free($1.value);
      free($2.value);
      asd_add_child($$, $3);
      free($4.value);
      asd_add_child($$, $6);
    }
    | TK_SE '(' expressao ')' escopo_ini bloco escopo_fim TK_SENAO escopo_ini bloco escopo_fim {
      // qual o tipo de um bloco?
      if ($6 && $10 && $6->tipo != TIPO_INDEFINIDO && $10->tipo != TIPO_INDEFINIDO) {
        semantic_infer_type($6->tipo, $10->tipo, $1.line_no);
      }
      $$ = asd_new($1.value);
      free($1.value);
      free($2.value);
      asd_add_child($$, $3);
      free($4.value);
      asd_add_child($$, $6);
      free($8.value);
      asd_add_child($$, $10);

    }
    ;

comando_enquanto
    : TK_ENQUANTO '(' expressao ')' escopo_ini bloco escopo_fim { 
      /* 
         Para os comandos de controle de fluxo, 
         deve-se utilizar como nome o lexema do 
         token TK_SE para o comando if com else 
         opcional, e o lexema do token TK_ENQUANTO 
         para o comando while. 
      */ 
      $$ = asd_new($1.value); 
      $$->tipo = $3->tipo;
      free($1.value);
      free($2.value);
      asd_add_child($$, $3);
      free($4.value);
      asd_add_child($$, $6);
    } 
    ;


expressao
    : expressao_or { $$ = $1; } 
    ;

expressao_or
    : expressao_or '|' expressao_and { $$ = make_binop($1, $2, $3); } 
    | expressao_and { $$ = $1; /* acima não deveriam ser 2 expressões OR? */ } 
    ;

expressao_and
    : expressao_and '&' expressao_igualdade { $$ = make_binop($1, $2, $3); } 
    | expressao_igualdade { $$ = $1; } 
    ;

expressao_igualdade
    : expressao_igualdade TK_OC_EQ expressao_relacional { $$ = make_binop($1, $2, $3); }
    | expressao_igualdade TK_OC_NE expressao_relacional { $$ = make_binop($1, $2, $3); }
    | expressao_relacional { $$ = $1; } 
    ;

expressao_relacional
    : expressao_relacional '<' expressao_aditiva { $$ = make_binop($1, $2, $3); }
    | expressao_relacional '>' expressao_aditiva { $$ = make_binop($1, $2, $3); }
    | expressao_relacional TK_OC_LE expressao_aditiva { $$ = make_binop($1, $2, $3); }
    | expressao_relacional TK_OC_GE expressao_aditiva { $$ = make_binop($1, $2, $3); }
    | expressao_aditiva { $$ = $1; } 
    ;

expressao_aditiva
    : expressao_aditiva '+' expressao_multiplicativa { $$ = make_binop($1, $2, $3); }
    | expressao_aditiva '-' expressao_multiplicativa { $$ = make_binop($1, $2, $3); }
    | expressao_multiplicativa { $$ = $1; }
    ;

expressao_multiplicativa
    : expressao_multiplicativa '*' expressao_unaria { $$ = make_binop($1, $2, $3); }
    | expressao_multiplicativa '/' expressao_unaria { $$ = make_binop($1, $2, $3); }
    | expressao_multiplicativa '%' expressao_unaria { $$ = make_binop($1, $2, $3); }
    | expressao_unaria { $$ = $1; } ;

expressao_unaria
    : '+' expressao_unaria %prec UNARY_PREC { 
      $$ = asd_new($1.value);
      asd_add_child($$, $2);
      free($1.value);
    }
    | '-' expressao_unaria %prec UNARY_PREC {
      $$ = asd_new($1.value);
      asd_add_child($$, $2);
      free($1.value);
    } 
    | '!' expressao_unaria %prec UNARY_PREC {
      $$ = asd_new($1.value);
      asd_add_child($$, $2);
      free($1.value);
    } 
    | expressao_primaria { $$ = $1; } ;

expressao_primaria
    : '(' expressao ')' { $$ = $2; free($1.value); free($3.value); } 
    | chamada_funcao { $$ = $1; } 
    | TK_ID { $$ = asd_new($1.value); $$->tipo=scope_stack_lookup(global_scope_stack,$1.value)->tipo; free($1.value); } 
    | literal { $$ = $1; } 
    ;

%%

void yyerror(const char *mensagem) {
    extern int get_line_number(void);
    fprintf(stderr, "Erro sintático na linha %d: %s\n", get_line_number(), mensagem);
}
