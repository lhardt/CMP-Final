%{
#include <stdio.h>
#include "parser.tab.h"
#include "asd.h"
int yylex(void);
void yyerror(const char *mensagem);
%}

%define parse.error verbose

%union {
  struct valor_lexico {
    int line_no;
    int type;
    char* value;
  } valor_lexico;
  asd_tree_t * asd_tree_t;

}


%code requires {
#include "asd.h"
extern asd_tree_t * arvore;
}

%type <asd_tree_t> programa lista_elementos elemento definicao_funcao tipo lista_parametros_opt lista_parametros  parametro declaracao_variavel declaracao_variavel_sem_init inicializacao_opt literal comando bloco lista_comandos atribuicao chamada_funcao lista_argumentos_opt lista_argumentos comando_retorna comando_se comando_senao_opt comando_enquanto expressao expressao_or 
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

%nonassoc UNARY_PREC

%%

programa
    : lista_elementos ';' { $$ = asd_new("heyoh"); arvore = $$; }
    | /* vazio */ { $$ = asd_new("heyoh"); arvore = $$; }
    ;

lista_elementos
    : /* vazio */ { $$ = asd_new("heyoh"); } 
    | lista_elementos ',' elemento { $$ = asd_new("heyoh"); } 
    | elemento { $$ = asd_new("heyoh"); } 
    ;

elemento
    : definicao_funcao { $$ = asd_new("heyoh"); } 
    | declaracao_variavel_sem_init { $$ = asd_new("heyoh"); } 
    ;

definicao_funcao
    : TK_ID TK_SETA tipo lista_parametros_opt TK_ATRIB bloco { $$ = asd_new("heyoh"); } 
    ;

tipo 
    : TK_DECIMAL { $$ = asd_new("heyoh"); } 
    | TK_INTEIRO { $$ = asd_new("heyoh"); } 
    ;

lista_parametros_opt
    : /* vazio */ { $$ = asd_new("heyoh"); } 
    | TK_COM lista_parametros { $$ = asd_new("heyoh"); } 
    | lista_parametros { $$ = asd_new("heyoh"); } 
    ;

lista_parametros
    : parametro { $$ = asd_new("heyoh"); } 
    | lista_parametros ',' parametro { $$ = asd_new("heyoh"); } 
    ;

parametro
    : TK_ID TK_ATRIB tipo { $$ = asd_new("heyoh"); } 
    ;

declaracao_variavel
    : TK_VAR TK_ID TK_ATRIB tipo inicializacao_opt { $$ = asd_new("heyoh"); } 
    ;

declaracao_variavel_sem_init
    : TK_VAR TK_ID TK_ATRIB tipo { $$ = asd_new("heyoh"); } 
    ;

inicializacao_opt
    : /* vazio */ { $$ = asd_new("heyoh"); } 
    | TK_COM literal { $$ = asd_new("heyoh"); } 
    ;

literal
    : TK_LI_INTEIRO { $$ = asd_new("heyoh"); } 
    | TK_LI_DECIMAL { $$ = asd_new("heyoh"); } 
    ;

comando
    : bloco { $$ = asd_new("heyoh"); } 
    | declaracao_variavel { $$ = asd_new("heyoh"); } 
    | atribuicao { $$ = asd_new("heyoh"); } 
    | chamada_funcao { $$ = asd_new("heyoh"); } 
    | comando_retorna { $$ = asd_new("heyoh"); } 
    | comando_se { $$ = asd_new("heyoh"); } 
    | comando_enquanto { $$ = asd_new("heyoh"); } 
    ;

bloco
    : '[' lista_comandos ']' { $$ = asd_new("heyoh"); } 
    ;

lista_comandos
    : /* vazio */ { $$ = asd_new("heyoh"); } 
    | lista_comandos comando { $$ = asd_new("heyoh"); } 
    ;

atribuicao
    : TK_ID TK_ATRIB expressao { $$ = asd_new("heyoh"); } 
    ;

chamada_funcao
    : TK_ID '(' lista_argumentos_opt ')' { $$ = asd_new("heyoh"); } 
    ;

lista_argumentos_opt
    : /* vazio */ { $$ = asd_new("heyoh"); } 
    | lista_argumentos { $$ = asd_new("heyoh"); } 
    ;

lista_argumentos
    : expressao { $$ = asd_new("heyoh"); } 
    | lista_argumentos ',' expressao { $$ = asd_new("heyoh"); } 
    ;

comando_retorna
    : TK_RETORNA expressao TK_ATRIB tipo { $$ = asd_new("heyoh"); } 
    ;

comando_se
    : TK_SE '(' expressao ')' bloco comando_senao_opt { $$ = asd_new("heyoh"); } 
    ;

comando_senao_opt
    : /* vazio */ { $$ = asd_new("heyoh"); } 
    | TK_SENAO bloco { $$ = asd_new("heyoh"); } 
    ;

comando_enquanto
    : TK_ENQUANTO '(' expressao ')' bloco { $$ = asd_new("heyoh"); } 
    ;


expressao
    : expressao_or { $$ = asd_new("heyoh"); } 
    ;

expressao_or
    : expressao_or '|' expressao_and { $$ = asd_new("heyoh"); } 
    | expressao_and { $$ = asd_new("heyoh"); } 
    ;

expressao_and
    : expressao_and '&' expressao_igualdade { $$ = asd_new("heyoh"); } 
    | expressao_igualdade { $$ = asd_new("heyoh"); } 
    ;

expressao_igualdade
    : expressao_igualdade TK_OC_EQ expressao_relacional { $$ = asd_new("heyoh"); } 
    | expressao_igualdade TK_OC_NE expressao_relacional { $$ = asd_new("heyoh"); } 
    | expressao_relacional { $$ = asd_new("heyoh"); } 
    ;

expressao_relacional
    : expressao_relacional '<' expressao_aditiva { $$ = asd_new("heyoh"); } 
    | expressao_relacional '>' expressao_aditiva { $$ = asd_new("heyoh"); } 
    | expressao_relacional TK_OC_LE expressao_aditiva { $$ = asd_new("heyoh"); } 
    | expressao_relacional TK_OC_GE expressao_aditiva { $$ = asd_new("heyoh"); } 
    | expressao_aditiva { $$ = asd_new("heyoh"); } 
    ;

expressao_aditiva
    : expressao_aditiva '+' expressao_multiplicativa { $$ = asd_new("heyoh"); } 
    | expressao_aditiva '-' expressao_multiplicativa { $$ = asd_new("heyoh"); } 
    | expressao_multiplicativa { $$ = asd_new("heyoh"); } 
    ;

expressao_multiplicativa
    : expressao_multiplicativa '*' expressao_unaria { $$ = asd_new("heyoh"); } 
    | expressao_multiplicativa '/' expressao_unaria { $$ = asd_new("heyoh"); } 
    | expressao_multiplicativa '%' expressao_unaria { $$ = asd_new("heyoh"); } 
    | expressao_unaria
    { $$ = asd_new("heyoh"); } ;

expressao_unaria
    : '+' expressao_unaria %prec UNARY_PREC { $$ = asd_new("heyoh"); } 
    | '-' expressao_unaria %prec UNARY_PREC { $$ = asd_new("heyoh"); } 
    | '!' expressao_unaria %prec UNARY_PREC { $$ = asd_new("heyoh"); } 
    | expressao_primaria
    { $$ = asd_new("heyoh"); } ;

expressao_primaria
    : '(' expressao ')' { $$ = asd_new("heyoh"); } 
    | chamada_funcao { $$ = asd_new("heyoh"); } 
    | TK_ID { $$ = asd_new("heyoh"); } 
    | literal { $$ = asd_new("heyoh"); } 
    ;

%%

void yyerror(const char *mensagem) {
    extern int get_line_number(void);
    fprintf(stderr, "Erro sintático na linha %d: %s\n", get_line_number(), mensagem);
}
