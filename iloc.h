#ifndef ILOC_H
#define ILOC_H

typedef struct code_list {
  char ** instructions;
  int size;
} code_list_t;

code_list_t * code_list_create();
void code_list_free(code_list_t * code_list);
void code_list_add(code_list_t * code_list, char * code);
void code_list_add_all(code_list_t * code_list, code_list_t * to_add);
void code_list_print(code_list_t * code_list);


#endif /* ILOC_H */
