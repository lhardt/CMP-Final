#include <stdio.h>
#include "asd.h"
#include "iloc.h"

extern int yyparse(void);
extern int yylex_destroy(void);

asd_tree_t *arvore = NULL;

int main(int argc, char **argv) {
  int ret = yyparse();
  //asd_print_graphviz(arvore);
  if( arvore )
    code_list_print(arvore->instructions);
  asd_free(arvore);
  yylex_destroy();
  return ret;
}
