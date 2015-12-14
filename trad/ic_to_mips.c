#include <stdio.h>
#include <stdlib.h>

#include "ic_to_mips.h"


void icm_print_to_file(char* filename,ic_symbol *i_table,ic_quad* i_code)
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
void icm_alloc_vars(FILE *dest_file,ic_symbol *i_table)
{
  fprintf(dest_file,"    .data\n");
  ic_symbol_list* int_vars = icm_get_int_from_table(i_table);
  ic_symbol_list* float_vars = icm_get_float_from_table(i_table);
  
  while(int_vars != NULL)
    {
      fprintf(dest_file,"%s: ",int_vars->s->name);
      fprintf(dest_file,".word  %d\n",int_vars->s->val.i_val);
  /*      if(scan->next != NULL)
	  fprintf(dest_file,",");*/
      int_vars = int_vars->next;
    }
  while(float_vars != NULL)
      {
	  fprintf(dest_file,"%s: ",float_vars->s->name);
	  fprintf(dest_file,".float  %f\n",float_vars->s->val.f_val);
          float_vars = float_vars->next;
      }

  //fprintf(dest_file,"\n");
}
void icm_print_code(FILE* dest_file,ic_symbol *i_table,ic_quad* i_code)
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
  
  /*  if((i_stm.arg1)->type == INT)
      {*/
  //arg1 and arg2 if one of them
  switch(i_stm.op)
      {
      case ASSIGN:
	  if(((i_stm.dest)->dest_symb)->type == INT )
	      {
		  fprintf(dest_file,"    lw $t0, %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    sw $t0, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  else if(((i_stm.dest)->dest_symb)->type == FLOAT)
	      {
		  fprintf(dest_file,"    l.s $f0 %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    s.s $f0 %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  break;
      case IFZ_GOTO:
	  fprintf(dest_file,"    lw $t0, %s\n",(i_stm.arg1)->name);
	  fprintf(dest_file,"    beq $t0, $0, %s\n",(i_stm.dest)->dest_label);
	  break;
      case IFEQ_GOTO:
	  if((i_stm.arg1)->type == INT)
	      {
		  fprintf(dest_file,"    lw $t0, %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    lw $t1, %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    beq $t0, $t1, %s\n",(i_stm.dest)->dest_label);
	      }
	  else{
	      fprintf(dest_file,"    l.s $f0, %s\n",(i_stm.arg1)->name);
	      fprintf(dest_file,"    l.s $f1, %s\n",(i_stm.arg2)->name);
	      fprintf(dest_file,"    c.eq.s $f0, $f1\n");
	      fprintf(dest_file,"    bc1t %s\n",(i_stm.dest)->dest_label);
	      }
	  break;
      case GOTO:
	  fprintf(dest_file,"    j  %s\n",(i_stm.dest)->dest_label);
	  break;
      case PLUS:
	  if(((i_stm.dest)->dest_symb)->type == INT )
	      {
		  fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    lw	$t1, %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    add $t2, $t0, $t1\n");
		  fprintf(dest_file,"    sw $t2, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  else if(((i_stm.dest)->dest_symb)->type == FLOAT)
	      {
		  fprintf(dest_file,"    l.s $f0 %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    l.s $f1 %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    add.s $f2, $f0, $f1\n");
		  fprintf(dest_file,"    s.s $f2, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  break;
      case MINUS:
	  if(((i_stm.dest)->dest_symb)->type == INT )
	      {
		  fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    lw	$t1, %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    sub $t2, $t0, $t1\n");
		  fprintf(dest_file,"    sw $t2, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  else if(((i_stm.dest)->dest_symb)->type == FLOAT)
	      {
		  fprintf(dest_file,"    l.s $f0 %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    l.s $f1 %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    sub.s $f2, $f0, $f1\n");
		  fprintf(dest_file,"    s.s $f2, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  break;	
      case MULT:
	  if(((i_stm.dest)->dest_symb)->type == INT )
	      {
		  fprintf(dest_file,"    lw	$t0, %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    lw	$t1, %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    mul $t2, $t0, $t1\n");
		  fprintf(dest_file,"    sw $t2, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  else if(((i_stm.dest)->dest_symb)->type == FLOAT)
	      {
		  fprintf(dest_file,"    l.s $f0 %s\n",(i_stm.arg1)->name);
		  fprintf(dest_file,"    l.s $f1 %s\n",(i_stm.arg2)->name);
		  fprintf(dest_file,"    mul.s $f2, $f0, $f1\n");
		  fprintf(dest_file,"    s.s $f2, %s\n",((i_stm.dest)->dest_symb)->name);
	      }
	  else{
	      fprintf(stderr,"error in type of multiplication\n");
	      exit(1);
	  }
	  break;
      case PRINT_INT:
	  fprintf(dest_file,"    li $v0, 1\n");
	  fprintf(dest_file,"    lw $a0, %s\n",(i_stm.arg1)->name);
	  fprintf(dest_file,"    syscall\n");
	  break;
      case PRINT_FLOAT:
	  fprintf(dest_file,"    l.s $f12, %s\n",(i_stm.arg1)->name);
	  fprintf(dest_file,"    li $v0, 2\n");
	  fprintf(dest_file,"    syscall\n");
	  break;
      case ITOF:
	  fprintf(dest_file,"    lw $t0, %s\n",(i_stm.arg1)->name);
	  fprintf(dest_file,"    mtc1 $t0, $f0\n");
	  fprintf(dest_file,"    cvt.s.w $f1 $f0\n");
	  fprintf(dest_file,"    s.s $f1, %s\n",((i_stm.dest)->dest_symb)->name);
	  break;
      case FTOI:
	  fprintf(dest_file,"    l.s $f0, %s\n",(i_stm.arg1)->name);
	  fprintf(dest_file,"    cvt.w.s $f1, $f0\n");
	  fprintf(dest_file,"    mfc1 $t0, $f1\n");
	  fprintf(dest_file,"    sw $t0, %s\n",((i_stm.dest)->dest_symb)->name);
      case SKIP:
	  fprintf(dest_file,"    nop\n");
	  break;
      default :
	  fprintf(stderr,"error not an existing operator\n");
	  break;
      }
	
       
}
ic_symbol_list* icm_get_int_from_table(ic_symbol* i_table)
{
    ic_symbol_list* ret_scan = NULL;
    ic_symbol_list** ret_addr = malloc(sizeof(ret_scan));
    *ret_addr = NULL;

    while(i_table != NULL)
	{
	    if(i_table->type == INT)
		{
		    if(ret_scan == NULL)
			{
			    ret_scan = malloc(sizeof(*ret_scan));
			    *ret_addr = ret_scan;
			    ret_scan->s = i_table;
			}
		    else{
			ret_scan->next = malloc(sizeof(*ret_scan));
			ret_scan->next->s = i_table;
			ret_scan = ret_scan->next;
		    }
			
		}
	    i_table = i_table->next;
	}
    ret_scan->next = NULL;
    return *ret_addr;
}
ic_symbol_list* icm_get_float_from_table(ic_symbol* i_table)
{
    ic_symbol_list* ret_scan = NULL;
    ic_symbol_list** ret_addr = malloc(sizeof(ret_scan));
    *ret_addr = NULL;

    while(i_table != NULL)
	{
	    if(i_table->type == FLOAT)
		{
		    if(ret_scan == NULL)
			{
			    ret_scan = malloc(sizeof(*ret_scan));
			    *ret_addr = ret_scan;
			    ret_scan->s = i_table;
			}
		    else{
			ret_scan->next = malloc(sizeof(*ret_scan));
			ret_scan->next->s = i_table;
			ret_scan = ret_scan->next;
		    }
		}
	    i_table = i_table->next;
	}
    ret_scan->next = NULL;
    return *ret_addr;
}

