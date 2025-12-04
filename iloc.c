#include "iloc.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
code_list_t * code_list_create(){
  code_list_t * code = calloc(1, sizeof(code_list_t));
  code->size = 0;

  return code;
}

void code_list_add(code_list_t * code_list, char* code){
  if( code_list->instructions == NULL){
    code_list->instructions = calloc(1, sizeof(char*));
    code_list->size = 0;
  } else {
    code_list->instructions = realloc( code_list->instructions, (code_list->size + 2)*sizeof(char*));
  }
 
  code_list->instructions[code_list->size] = strdup(code);
  ++code_list->size;
}

void code_list_add_all(code_list_t * code_list, code_list_t * to_add){
  if( code_list == NULL ){
    printf("Calling add with NULL! %p %p\n", code_list, to_add);
    code_list[-1231].instructions = NULL;
  }
  if( to_add == NULL ){
    return;
  }
  for(int i = 0; i < to_add->size; ++i){
    code_list_add(code_list, to_add->instructions[i]);
  }
}

void code_list_free(code_list_t* code_list){
  for(int i = 0; i < code_list->size; ++i){
    free( code_list->instructions[i]);
  }
  free(code_list->instructions);
  free(code_list);
}

void code_list_print(code_list_t * code_list){
  if( code_list == NULL ){
    printf("(null)\n");
    return;
  }
  for(int i = 0; i < code_list->size; i++){
    printf("%s\n", code_list->instructions[i]);
  }
}

