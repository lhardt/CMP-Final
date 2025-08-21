
/* Only multiline comments work. */
%{ 
  #include "tokens.h"
%}

%option noyywrap
%option yylineno

/* Tries to get a match in the order below. Last element should be the error return */
%%

tipo { return TK_TIPO; }
var { return TK_VAR; }
senao { return TK_SENAO; }
decimal { return TK_DECIMAL; }
se { return TK_SE; }
inteiro { return TK_INTEIRO; }
retorna { return TK_RETORNA; }
enquanto { return TK_ENQUANTO; }
com { return TK_COM; }


[>][=] { return TK_OC_GE; } 
[<][=] { return TK_OC_LE; }
[=][=] { return TK_OC_EQ; }
[!][=] { return TK_OC_NE; }
[:][=] { return TK_ATRIB; }
[-][>] { return TK_SETA; }


\/\/[^\n]*
[!:<>,=+!/] { return (int) yytext[0]; }
[{}a-z_][a-zA-Z0-9_]* { return TK_VAR; }


[0-9]*\.[0-9][0-9]* { return TK_LI_DECIMAL; }
[0-9][0-9]* { return TK_LI_INTEIRO; }


[ \n\r\t]
. { return TK_ER; }

%%

int get_line_number(){
  return yylineno;
}
