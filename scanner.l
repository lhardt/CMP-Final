
/* Only multiline comments work. */
%{ 
  #include "parser.tab.h"
  #include "asd.h"

  int make_val(int type) {
    yylval.valor_lexico = (struct valor_lexico) {
      .line_no = yylineno,
        .type = type,
        .value = strdup(yytext)
    };
    return type;
  }
%}


%option noyywrap
%option yylineno

/* Tries to get a match in the order below. Last element should be the error return */
%%

tipo { return make_val( TK_TIPO ); }
var { return make_val( TK_VAR ); }
senao { return make_val( TK_SENAO ); }
decimal { return make_val(TK_DECIMAL); }
se { return make_val(TK_SE); }
inteiro { return make_val(TK_INTEIRO); }
retorna { return make_val(TK_RETORNA); }
enquanto { return make_val(TK_ENQUANTO); }
com { return make_val(TK_COM); }


[>][=] { return make_val(TK_OC_GE); }
[<][=] { return make_val(TK_OC_LE); }
[=][=] { return make_val(TK_OC_EQ); }
[!][=] { return make_val(TK_OC_NE); }
[:][=] { return make_val(TK_ATRIB); }
[-][>] { return make_val(TK_SETA); }


\/\/[^\n]*
[\;] { return make_val( (int) yytext[0] ); }
[(] { return make_val( (int) yytext[0] ); }
[*] { return make_val( (int) yytext[0] ); }
[)] { return make_val( (int) yytext[0] ); }
[-] { return make_val( (int) yytext[0] ); }
[%] { return make_val( (int) yytext[0] ); }
[[] { return make_val( (int) yytext[0] ); }
[]] { return make_val( (int) yytext[0] ); }
[&] { return make_val( (int) yytext[0] ); }
[|] { return make_val( (int) yytext[0] ); }
[!:<>,=+!/] { return make_val( (int) yytext[0] ); }
[{}a-z_][a-zA-Z0-9_]* { return make_val(TK_ID); }


[0-9]*\.[0-9][0-9]* { return make_val(TK_LI_DECIMAL); }
[0-9][0-9]* { return make_val(TK_LI_INTEIRO); }


[ \n\r\t]
. { return make_val(TK_ER); }

%%

int get_line_number(){
  return yylineno;
}
