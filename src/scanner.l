
/* Only multiline comments work. */
%{ 
  #include "tokens.h"
%}

%option noyywrap
%option yylineno

/* Tries to get a match in the order below. Last element should be the error return */
%%

tipo { return TK_TIPO; }
:= { return TK_ATRIB; }
[:<>,=+!/] { return yytext[0]; }
[{}a-z_][a-zA-Z0-9_]* { return TK_VAR; }
[ \n\r\t]
. { return TK_ER; }

%%

int get_line_number(){
  return yylineno;
}
