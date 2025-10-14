%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "parser.tab.h"
#include "asd.h"
int yylex(void);
void yyerror(const char *mensagem);

asd_tree_t* make_binop(asd_tree_t * lhs, valor_lexico_t op, asd_tree_t * rhs){
  asd_tree_t * root = asd_new(op.value);
  asd_add_child(root, lhs);
  asd_add_child(root, rhs);
  free(op.value);
  return root;
}
%}

%define parse.error verbose

%union {
  valor_lexico_t valor_lexico;
  asd_tree_t * asd_tree_t;

}


%code requires {
#include "asd.h"
extern asd_tree_t * arvore;
typedef struct valor_lexico {
  int line_no;
  int type;
  char* value;
} valor_lexico_t;
}

%type <asd_tree_t> programa lista_elementos  definicao_funcao tipo lista_parametros  parametro declaracao_variavel declaracao_variavel_sem_init inicializacao_opt literal comando bloco lista_comandos atribuicao chamada_funcao lista_argumentos_opt lista_argumentos comando_retorna comando_se comando_enquanto expressao expressao_or
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
    : lista_elementos ';' {
      $$ = $1;
      arvore = $$;
      free($2.value);
    }
    | /* vazio */ { 
      $$ = asd_new("programa_vazio");
      arvore = $$;
    }
    ;

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

definicao_funcao
    : TK_ID TK_SETA tipo TK_ATRIB bloco { 
      /* Listas de funções, onde cada função tem dois filhos, 
         um que é o seu primeiro comando e outro que é a próxima função; */
      $$ = asd_new($1.value);

      free($1.value);
      free($2.value);
      asd_free($3);
      free($4.value);
      if( $5 ) asd_add_child($$, $5);
    } 
    | TK_ID TK_SETA tipo TK_COM lista_parametros TK_ATRIB bloco { 
      $$ = asd_new($1.value);

      free($1.value);
      free($2.value);
      asd_free($3);
      free($4.value);
      if($5) asd_add_child($$, $5);
      free($6.value);
      if($7) asd_add_child($$, $7);
    }
    | TK_ID TK_SETA tipo lista_parametros TK_ATRIB bloco { 
      $$ = asd_new($1.value);

      free($1.value);
      free($2.value);
      asd_free($3);
      asd_add_child($$, $4);
      free($5.value);
      if($6) asd_add_child($$, $6);
    }
    ;

tipo 
    : TK_DECIMAL { $$ = asd_new($1.value);  free($1.value); } 
    | TK_INTEIRO { $$ = asd_new($1.value);  free($1.value); } 
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
      free($1.value);
      free($2.value);
      if($3) asd_free($3);
      $$ = NULL;
      // unused
    } 
    ;

declaracao_variavel
    : TK_VAR TK_ID TK_ATRIB tipo inicializacao_opt {
      if($5){
        $$ = asd_new("com"); /* TODO REVIEW DOCS */
        asd_add_child($$, asd_new($2.value));
        asd_add_child($$, $5);
      } else {
        $$ = NULL;
      }

      free($1.value);
      free($2.value);
      free($3.value);
      asd_free($4);
    }
    ;

declaracao_variavel_sem_init
    : TK_VAR TK_ID TK_ATRIB tipo {
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
    : TK_LI_INTEIRO { $$ = asd_new($1.value); free($1.value); } 
    | TK_LI_DECIMAL { $$ = asd_new($1.value); free($1.value); } 
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
      $$ = asd_new($2.value); 
      
      asd_add_child( $$, asd_new($1.value) );
      asd_add_child( $$, $3 );

      free($1.value);
      free($2.value);
    }
    ;

chamada_funcao
    : TK_ID '(' lista_argumentos_opt ')' {
      char* buf = calloc( strlen($1.value) + strlen("call ") + 1, sizeof(char));
      strcat(buf, "call ");
      strcat(buf, $1.value);

      $$ = asd_new(buf);
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
        free($1.value);
        asd_add_child($$, $2);
        free($3.value);
        asd_free($4);
      } 
    ;

comando_se
    : TK_SE '(' expressao ')' bloco {
      /* O comando if com else opcional deve ter pelo 
         menos três filhos, um para a expressão, outro para 
         o primeiro comando quando verdade, e o último – 
         opcional – para o segundo comando quando falso */
      $$ = asd_new($1.value);
      
      free($1.value);
      free($2.value);
      asd_add_child($$, $3);
      free($4.value);
      asd_add_child($$, $5);
    }
    | TK_SE '(' expressao ')' bloco TK_SENAO bloco {
      $$ = asd_new($1.value);
      free($1.value);
      free($2.value);
      asd_add_child($$, $3);
      free($4.value);
      asd_add_child($$, $5);
      free($6.value);
      asd_add_child($$, $7);

    }
    ;

comando_enquanto
    : TK_ENQUANTO '(' expressao ')' bloco { 
      /* 
         Para os comandos de controle de fluxo, 
         deve-se utilizar como nome o lexema do 
         token TK_SE para o comando if com else 
         opcional, e o lexema do token TK_ENQUANTO 
         para o comando while. 
      */ 
      $$ = asd_new($1.value); 
      free($1.value);
      free($2.value);
      asd_add_child($$, $3);
      free($4.value);
      asd_add_child($$, $5);
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
    | TK_ID { $$ = asd_new($1.value); free($1.value); } 
    | literal { $$ = $1; } 
    ;

%%

void yyerror(const char *mensagem) {
    extern int get_line_number(void);
    fprintf(stderr, "Erro sintático na linha %d: %s\n", get_line_number(), mensagem);
}
