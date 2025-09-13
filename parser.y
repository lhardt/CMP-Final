%{
#include <stdio.h>
#include "parser.tab.h"
int yylex(void);
void yyerror(const char *mensagem);
%}

%define parse.error verbose

/* Declaração dos tokens */
%token TK_TIPO
%token TK_VAR
%token TK_SENAO
%token TK_DECIMAL
%token TK_SE
%token TK_INTEIRO
%token TK_ATRIB
%token TK_RETORNA
%token TK_SETA
%token TK_ENQUANTO
%token TK_COM
%token TK_OC_LE
%token TK_OC_GE
%token TK_OC_EQ
%token TK_OC_NE
%token TK_ID
%token TK_LI_INTEIRO
%token TK_LI_DECIMAL
%token TK_ER

%nonassoc UNARY_PREC

%%

programa
    : lista_elementos ';'
    | /* vazio */
    ;

lista_elementos
    : /* vazio */
    | lista_elementos ',' elemento
    | elemento
    ;

elemento
    : definicao_funcao
    | declaracao_variavel_sem_init
    ;

definicao_funcao
    : TK_ID TK_SETA tipo lista_parametros_opt TK_ATRIB bloco
    ;

tipo
    : TK_DECIMAL
    | TK_INTEIRO
    ;

lista_parametros_opt
    : /* vazio */
    | TK_COM lista_parametros
    | lista_parametros
    ;

lista_parametros
    : parametro
    | lista_parametros ',' parametro
    ;

parametro
    : TK_ID TK_ATRIB tipo
    ;

declaracao_variavel
    : TK_VAR TK_ID TK_ATRIB tipo inicializacao_opt
    ;

declaracao_variavel_sem_init
    : TK_VAR TK_ID TK_ATRIB tipo
    ;

inicializacao_opt
    : /* vazio */
    | TK_COM literal
    ;

literal
    : TK_LI_INTEIRO
    | TK_LI_DECIMAL
    ;

comando
    : bloco
    | declaracao_variavel
    | atribuicao
    | chamada_funcao
    | comando_retorna
    | comando_se
    | comando_enquanto
    ;

bloco
    : '[' lista_comandos ']'
    ;

lista_comandos
    : /* vazio */
    | lista_comandos comando
    ;

atribuicao
    : TK_ID TK_ATRIB expressao
    ;

chamada_funcao
    : TK_ID '(' lista_argumentos_opt ')'
    ;

lista_argumentos_opt
    : /* vazio */
    | lista_argumentos
    ;

lista_argumentos
    : expressao
    | lista_argumentos ',' expressao
    ;

comando_retorna
    : TK_RETORNA expressao TK_ATRIB tipo
    ;

comando_se
    : TK_SE '(' expressao ')' bloco comando_senao_opt
    ;

comando_senao_opt
    : /* vazio */
    | TK_SENAO bloco
    ;

comando_enquanto
    : TK_ENQUANTO '(' expressao ')' bloco
    ;


expressao
    : expressao_or
    ;

expressao_or
    : expressao_or '|' expressao_and
    | expressao_and
    ;

expressao_and
    : expressao_and '&' expressao_igualdade
    | expressao_igualdade
    ;

expressao_igualdade
    : expressao_igualdade TK_OC_EQ expressao_relacional
    | expressao_igualdade TK_OC_NE expressao_relacional
    | expressao_relacional
    ;

expressao_relacional
    : expressao_relacional '<' expressao_aditiva
    | expressao_relacional '>' expressao_aditiva
    | expressao_relacional TK_OC_LE expressao_aditiva
    | expressao_relacional TK_OC_GE expressao_aditiva
    | expressao_aditiva
    ;

expressao_aditiva
    : expressao_aditiva '+' expressao_multiplicativa
    | expressao_aditiva '-' expressao_multiplicativa
    | expressao_multiplicativa
    ;

expressao_multiplicativa
    : expressao_multiplicativa '*' expressao_unaria
    | expressao_multiplicativa '/' expressao_unaria
    | expressao_multiplicativa '%' expressao_unaria
    | expressao_unaria
    ;

expressao_unaria
    : '+' expressao_unaria %prec UNARY_PREC
    | '-' expressao_unaria %prec UNARY_PREC
    | '!' expressao_unaria %prec UNARY_PREC
    | expressao_primaria
    ;

expressao_primaria
    : '(' expressao ')'
    | chamada_funcao
    | TK_ID
    | literal
    ;

%%

void yyerror(const char *mensagem) {
    extern int get_line_number(void);
    fprintf(stderr, "Erro sintático na linha %d: %s\n", get_line_number(), mensagem);
}
