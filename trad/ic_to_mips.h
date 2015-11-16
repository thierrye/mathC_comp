#ifndef IC_TO_MIPS_H
#define IC_TO_MIPS_H

#include "trad_mathC.h"

void icm_print_to_file(char* filename,ic_int_symbol *i_table,ic_quad* i_code);

void icm_alloc_vars(FILE *dest_file,ic_int_symbol *i_table);
void icm_print_code(FILE* dest_file,ic_int_symbol *i_table,ic_quad* i_code);
void icm_print_stmt(FILE* dest_file,ic_quad i_stm);



#endif
