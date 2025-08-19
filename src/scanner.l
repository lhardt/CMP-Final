
/* Only multiline comments work. */
%{ 
  #include "tokens.h"
%}

%option noyywrap
%option yylineno

%%

%%

int get_line_number(){
  return yylineno;
}
