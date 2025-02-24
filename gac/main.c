/*
 * gak2019s65
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
char *get_duplicate(char** string);
int check_space(char* str);
int main(int argc, char **argv) {
  char* str = NULL;
  if (argc < 2) {
    fprintf(stdout, "Use:\n");
    fprintf(stdout, "\tmake run str=<string>\n");
    fprintf(stdout, "\t./binary <string>\n");
    fprintf(stdout, "NOTE: Example for spaces with make\n");
    fprintf(stdout, "make run str=\"\\\"Example Example\\\"\"\n");
    exit(1);
  }
  str = (char*)malloc(strlen(argv[1]) * sizeof(char));
  if (str == NULL) {
    fprintf(stderr, "Malloc Error\n");
    return -1; 
  }
  strcpy(str, argv[1]);
  fprintf(stdout, "Your string text: %s\n", str);
  fprintf(stdout, "Your string addr: %p\n", str);
  char *ptr = NULL;
  ptr = get_duplicate(&str);
  if (ptr != NULL)
    fprintf(stdout, "First duplicate string addr: %p\n", ptr);
  else
    fprintf(stdout, "No match\n");
  free(str);
  return 0;
}

char *get_duplicate(char** string) {
  char tmp = 0;
  size_t len = 0;
  size_t curr_size = 1;
  size_t curr_index_start = 0;
  size_t dup_index_start = 0;
  size_t tmp_index = 0;
  if (string == NULL || *string == NULL) {
    fprintf(stderr, "Nullptr in get_dupplicate\n");
    return NULL;
  }
  char *curr = (char*)malloc(strlen(*string) * sizeof(char));
  if (curr == NULL) {
    fprintf(stderr, "Malloc Error\n");
    return NULL; 
  }
  char *dup = (char*)malloc(strlen(*string) * sizeof(char));
  if (dup == NULL) {
    fprintf(stderr, "Malloc Error\n");
    free(curr);
    return NULL; 
  }
  len = strlen(*string);
  curr_size = len - 1; 
  while (curr_size > 0) {
    for (curr_index_start = 0; curr_index_start + curr_size <= len; curr_index_start++) {
      for (dup_index_start = curr_index_start + 1; dup_index_start + curr_size <= len; dup_index_start++) {
        memcpy(curr, &((*string)[curr_index_start]), curr_size);
        curr[curr_size] = 0;
        memcpy(dup, &((*string)[dup_index_start]), curr_size);
        dup[curr_size] = 0;
        if (check_space(curr) == 0 && check_space(dup) == 0) {
          if (!strcmp(curr,dup)) {
            fprintf(stdout, "Match: [%s | %s]\n", curr, dup);
            free(curr);
            free(dup);
            return &((*string)[curr_index_start]);
          }
        }
      }
    }
    --curr_size;
  }
  free(curr);
  free(dup);
  return NULL;
}

int check_space(char* str) {
  int i = 0;
  for (i = 0; i < strlen(str); ++i) {
    if (str[i] == ' ') return 1;
  }
  return 0;
}
