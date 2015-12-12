#include <stdio.h>
#include <stdlib.h>

#include "ic_to_mips.h"


void icm_print_to_file(char* filename,ic_int_symbol *i_table,ic_quad* i_code)
{
  FILE *asm_file = fopen(filename,"w+");

  if(asm_file == NULL)
    {
      fprintf(stderr,"could not open dest file : %s\n",filename);
      exit(1);
    }
  //
  icm_alloc_vars(asm_file,i_table);

  icm_print_code(asm_file,i_table,i_code);

  fclose(asm_file);
}
void icm_alloc_vars(FILE *dest_file,ic_int_symbol *i_table)
{
  fprintf(dest_file,"    .data\n");

  ic_int_symbol* scan = i_table;
  while(scan != NULL)
    {
      fprintf(dest_file,"%s: ",scan->name);
      fprintf(dest_file,".word  %d\n",scan->val);
  /*      if(scan->next != NULL)
	  fprintf(dest_file,",");*/
      scan = scan->next;
    }
  //fprintf(dest_file,"\n");
}
void icm_print_code(FILE* dest_file,ic_int_symbol *i_table,ic_quad* i_code)
{
  fprintf(dest_file,"    .text\n");
  fprintf(dest_file,"    .globl __start \n");

  fprintf(dest_file,"__start:\n");
  ic_quad* scan = i_code;
  while(scan != NULL)
    {
      icm_print_stmt(dest_file,*scan);
      scan = scan->next;
    }
}
void icm_print_stmt(FILE* dest_file,ic_quad i_stm)
{
  if(i_stm.q_name != NULL)
    fprintf(dest_file,"%s:\n",i_stm.q_name);
  
  switch(i_stm.op)
    {
    case ASSIGN:
      fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
      fprintf(dest_file,"    sw $t0, %s\n",((i_stm.dest)->dest_symb)->name);
      break;
    case IFZ_GOTO:
      fprintf(dest_file,"    lw $t0, %s\n",(i_stm.arg1)->name);
      fprintf(dest_file,"    beq $t0, $0, %s\n",(i_stm.dest)->dest_label);
      break;
    case IFEQ_GOTO:
	fprintf(dest_file,"    lw $t0, %s\n",(i_stm.arg1)->name);
	fprintf(dest_file,"    lw $t1, %s\n",(i_stm.arg2)->name);
      fprintf(dest_file,"    beq $t0, $t1, %s\n",(i_stm.dest)->dest_label);
      break;
    case GOTO:
      fprintf(dest_file,"    j  %s\n",(i_stm.dest)->dest_label);
      break;
    case PLUS:
      fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
      fprintf(dest_file,"    lw	$t1, %s\n",(i_stm.arg2)->name);
      fprintf(dest_file,"    add $t2, $t0, $t1\n");
      fprintf(dest_file,"    sw $t2, %s\n",((i_stm.dest)->dest_symb)->name);
      break;
    case MINUS:
      fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
      fprintf(dest_file,"    lw	$t1, %s\n",(i_stm.arg2)->name);
      fprintf(dest_file,"    sub $t2, $t0, $t1\n");
      fprintf(dest_file,"    sw $t2, %s\n",((i_stm.dest)->dest_symb)->name);
      break;	
    case MULT:
      fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
      fprintf(dest_file,"    lw	$t1, %s\n",(i_stm.arg2)->name);
      fprintf(dest_file,"    mul $t2, $t0, $t1\n");
      fprintf(dest_file,"    sw $t2, %s\n",((i_stm.dest)->dest_symb)->name);
      break;
    case PRINT_INT:
      fprintf(dest_file,"    li $v0, 1\n");
      fprintf(dest_file,"    lw $a0, %s\n",(i_stm.arg1)->name);
      fprintf(dest_file,"    syscall\n");
    case SKIP:
      fprintf(dest_file,"    nop\n");
      break;
    default :
      fprintf(stderr,"error operator not an existing operator\n");
      break;
	
    }
}
      
