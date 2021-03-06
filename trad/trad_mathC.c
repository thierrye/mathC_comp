#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "trad_mathC.h"

/*****************************************************************************************************
                                    type
/*****************************************************************************************************/
char *type_buff[3] = {"int","float","matrix"};

int l_istype(char *str_t)
{
    for(int i=0;i<TYPE_NUMBER;i++)
    {
	if(strcmp(type_buff[i],str_t) == 0)
	    return 1;
    }
    return 0;
}
typ_m str_to_type_m(char * str)
{
    if(strcmp(str,"int") == 0)
	return INT;
    if(strcmp(str,"float") == 0)
	return FLOAT;
    return MATRIX;
}
/*****************************************************************************************************
                              src variables
/*****************************************************************************************************/

int var_is_global(char *str)
{
    for(int i=0;i<curr_glob_var_number;i++)
	{
	    if(strcmp(glob_symb_buff[i].name,str) == 0)
		return 1;
	}
    return 0;
}
int var_add_global(id_s var)
{
    if(var_is_global(var.name))
	return 0;
    
    glob_symb_buff[curr_glob_var_number] = var;
    curr_glob_var_number++;
    return 1;
}
	    
int var_is_declared(char *str)
{
    if(var_is_global(str))
	return 1;

    return 0;
}
id_s *var_lookup(char *str)
{
  for(int i=0;i<curr_glob_var_number;i++)
    if(strcmp(glob_symb_buff[i].name,str) == 0)
      return glob_symb_buff + i;
  return NULL;
}

id_s new_id_s(char *str,typ_m t,int line)
{
    id_s var;
    var.name = strdup(str);
    var.t_id = t;

    var.decl_line = line;
    ic_symb_val dummy;
    /*if(t == INT)
      dummy.i_val = 0;
    else
    dummy.f_val = 0.0;*/
    var.ic_var = ic_gen_temp(t);
    return var;
}
void var_print_table()
{
  for(int i = 0;i < curr_glob_var_number;i++)
    {
      id_s tmp = glob_symb_buff[i];
      fprintf(stderr,"var %s declared line %d\n",tmp.name,tmp.decl_line);
    }
}

id_s *var_copy(id_s* arg)
{
  id_s* ret = malloc(sizeof(*ret));
  //ret->ic_var = ic_add_symb_s(arg->ic_var->name,arg->ic_var->val,false);//pour matrix allouer avant v_id
  ret->ic_var = ic_gen_temp(0);
  ret->t_id = arg->t_id;
  ret->v_id = arg->v_id;
  ret->decl_line = arg->decl_line;

  return ret;
}
/*****************************************************************************************************
                               intermediate code
/*****************************************************************************************************/
ic_symbol* ic_symb_buff = NULL;
int ic_n_temp = 0;
int ic_label_n = 0;
ic_label* label_buff = NULL;
ic_symb_val true_val;
ic_symb_val false_val;

ic_symbol* ic_gen_temp_const(ic_symb_val val,typ_m type)
{
  ic_symbol* new_tmp = malloc(sizeof(*new_tmp));
  new_tmp->name = malloc(sizeof("temp")+4);
  sprintf(new_tmp->name,"temp%d",ic_n_temp);

  while(ic_lookup(new_tmp->name) != NULL)
    {
      ic_n_temp ++;
      sprintf(new_tmp->name,"temp%d",ic_n_temp);
    }
  new_tmp->val = val;
  new_tmp->next = NULL;
  new_tmp->type = type;
  ic_add_symb(new_tmp);
  return new_tmp;
}
ic_symbol* ic_gen_temp(typ_m type)
{
  ic_symb_val dummy;
  if(type == INT)
      dummy.i_val = 0;
  else
    dummy.f_val = 0.0;
  return ic_gen_temp_const(dummy,type);
}
  
//return NULL if type of dest and src are not compatible
ic_quad* ic_symb_conv(ic_symbol* dest,ic_symbol* src)
{
  if(dest->type == src->type)
    return ic_quad_gen(dest,src,NULL,ASSIGN);
  ic_quad* ret;
  if(dest->type == FLOAT && src->type == INT)
    {
      return ic_quad_gen(dest,src,NULL,ITOF);
    }
  if(dest->type == INT && src->type == FLOAT)
    {
      return ic_quad_gen(dest,src,NULL,FTOI);
    }
  return NULL;
}
  
void ic_add_symb(ic_symbol* next)
{
  if(ic_symb_buff == NULL)
    ic_symb_buff = next;
  else{
    ic_symbol* scan = ic_symb_buff;
    while(scan->next != NULL)
      scan = scan->next;
    scan->next = next;
  }
}

ic_symbol* ic_lookup(char *str)
{
  if(ic_symb_buff == NULL)
    return NULL;
  
  ic_symbol *scan = ic_symb_buff;
  while(scan != NULL)
    {
      if(strcmp(scan->name,str) == 0)
	return scan;
      scan = scan->next;
    }
  return NULL;
}
/*ic_symbol* ic_add_symb_s(char* name,int val,bool is_const)
{
  if(ic_symb_buff == NULL)
    {
      ic_symb_buff = malloc(sizeof(*ic_symb_buff));
      ic_symb_buff->name = strdup(name);
      ic_symb_buff->val = val;
      ic_symb_buff->is_const = is_const;
      ic_symb_buff->next = NULL;
      return ic_symb_buff;
    }
  
  ic_symbol *scan = ic_symb_buff;
  while(scan->next != NULL)
    scan = scan->next;
  scan->next = malloc(sizeof(*scan));
  scan->next->name = strdup(name);
  scan->next->val = val;
  scan->next->is_const = is_const;
  scan->next->next = NULL;
  return scan->next;
  }*/
ic_quad* ic_quad_gen(ic_symbol* dest,ic_symbol* arg1,ic_symbol* arg2,ic_op op)
{
  ic_quad* ret_q = malloc(sizeof(*ret_q));
  ret_q->q_name = NULL;
  if(dest != NULL)
    {
      ret_q->dest = malloc(sizeof(*(ret_q->dest)));
      ret_q->dest->dest_symb = dest;
    }
  ret_q->arg1 = arg1;
  ret_q->arg2 = arg2;
  ret_q->op = op;
  ret_q->next = NULL;

  return ret_q;
}
//gen of a GOTO statement
ic_quad* ic_quad_gen_g(char* dest,ic_symbol* arg1,ic_symbol* arg2,ic_op op)
{
  ic_quad* ret_q = malloc(sizeof(*ret_q));
  ret_q->q_name = NULL;
  ret_q->dest = malloc(sizeof(*(ret_q->dest)));
  assert(dest != NULL);
  ret_q->dest->dest_label = dest;
  ret_q->arg1 = arg1;
  ret_q->arg2 = arg2;
  ret_q->op = op;
  ret_q->next = NULL;

  return ret_q;
}
ic_quad* ic_quad_gen_gl(ic_label* l,ic_symbol* arg1,ic_symbol* arg2,ic_op op)
{
  ic_quad* ret_q = malloc(sizeof(*ret_q));
  ret_q->q_name = NULL;
  //  assert(dest != NULL);
  if(l != NULL)
    {
      ret_q->dest = malloc(sizeof(*(ret_q->dest)));
      ret_q->dest->dest_label = strdup(l->label_name);
    }
  else
    ret_q->dest = NULL;
  ret_q->arg1 = arg1;
  ret_q->arg2 = arg2;
  ret_q->op = op;
  ret_q->next = NULL;

  return ret_q;
}
ic_quad* ic_quad_concat(ic_quad* arg1,ic_quad *arg2)
{
  ic_quad *ret = arg1;
  if(arg1 == NULL)
    return arg2;
  ic_quad *scan = arg1;

  while(scan->next != NULL)
    {
	scan = scan->next;
    }
  scan->next = arg2;
  return ret;
}
void ic_quad_set_name(ic_quad* q,char* name)
{
  assert(q!= NULL);
  assert(name != NULL);
  q->q_name = strdup(name);
}
ic_quad* ic_quad_proc_gen(char* proc_name,id_s* first_param)
{
  id_s* param_new_id = var_copy(first_param);
  
  if(strcmp(proc_name,"print_int") == 0)
    {
      //first param shouldn't be null
      assert(first_param != NULL);
      ic_quad* q = ic_quad_gen(param_new_id->ic_var,first_param->ic_var,NULL,ASSIGN);
      return ic_quad_concat(q,
			    ic_quad_gen(NULL,param_new_id->ic_var,NULL,PRINT_INT));
    }
  else if(strcmp(proc_name,"print_float") == 0)
    {
      ic_quad* q = ic_quad_gen(param_new_id->ic_var,first_param->ic_var,NULL,ASSIGN);
      return ic_quad_concat(q,
			    ic_quad_gen(NULL,param_new_id->ic_var,NULL,PRINT_FLOAT));
    }

  else{
    fprintf(stderr,"function name : %s not defined\n",proc_name);
    return NULL;
  }
}
ic_label* ic_new_label(char* name,ic_quad* q)
{
  if(label_buff == NULL)
    {
      label_buff = malloc(sizeof(*label_buff));
      label_buff->label_name = strdup(name);
      label_buff->q = q;
      label_buff->next = NULL;
      return label_buff;
    }
  ic_label* scan = label_buff;
  while(scan->next != NULL)
    scan = scan->next;

  scan->next = malloc(sizeof(*scan));
  scan->next->label_name =  strdup(name);
  scan->next->q = q;
  scan->next->next = NULL;
  return scan->next;
}
ic_label* ic_new_label_gen(ic_quad* q)
{
  char *name = malloc(sizeof("label")+4);
  sprintf(name,"label%d",ic_label_n);
  if(q != NULL)
    ic_quad_set_name(q,name);
  
  if(label_buff == NULL)
    {
      label_buff = malloc(sizeof(*label_buff));
      label_buff->label_name = name;
      label_buff->q = q;
      label_buff->next = NULL;
      assert(ic_label_n == 0);
      ic_label_n ++;
      return label_buff;
    }
  ic_label* scan = label_buff;
  while(scan->next != NULL)
    scan = scan->next;

  scan->next = malloc(sizeof(*scan));
  scan->next->label_name =  name;
  scan->next->q = q;
  scan->next->next = NULL;
  ic_label_n ++;
  return scan->next;
}
ic_label* ic_label_lookup(char* name)
{
  ic_label* scan = label_buff;
  while(scan != NULL)
    {
      if(strcmp(name,scan->label_name) == 0)
	return scan;
      scan = scan->next;
    }
  return NULL;
}
void ic_label_set_code(ic_label* l,ic_quad* dest)
{
  if(dest != NULL && dest->q_name == NULL)
    dest->q_name = strdup(l->label_name);
  l->q = dest;
  //
  //fprintf(stderr,"ic_label_set_code : dest->q_name %s && printcode : \n",dest->q_name);
  //ic_print_code(dest);
}
void ic_label_set_quad(ic_label* l,ic_quad* q)
{
  assert(l != NULL);
  l->q = q;
  if(q->q_name == NULL)
    q->q_name = strdup(l->label_name);
  assert(strcmp(q->q_name,l->label_name) == 0);
}
/*void ic_backpatch(ic_quad* q1,ic_quad* q2)
{
  ic_quad* scan = q1;

  while(scan != NULL)
    {
      switch(scan->op)
	{
	case IFZ_GOTO:
	  if(scan->dest == NULL)
	    {
	      scan->dest = malloc(sizeof(*(scan->dest)));
	      assert(q2->q_name != NULL);
	      scan->dest->dest_label = strdup(q2->q_name);
	    }
	  break;
	case GOTO:
	  if(scan->dest == NULL)
	    {
	      scan->dest = malloc(sizeof(*(scan->dest)));
	      assert(q2->q_name != NULL);
	      scan->dest->dest_label = strdup(q2->q_name);
	    }
	  break;
	}
      scan = scan->next;
    }
    }*/
void ic_backpatch(ic_ql* ql,ic_label* l)
{
  while(ql != NULL)
    {
      ql->q->dest = malloc(sizeof(*(ql->q->dest)));
      ql->q->dest->dest_label = strdup(l->label_name);
      ql = ql->next;
    }
}
void ic_quad_replace_label(ic_quad* q,ic_label* old_label,ic_label* new_label)
{
  ic_quad* scan = q;
  while(scan != NULL)
    {
      if(scan->op == IFZ_GOTO || scan->op == IFEQ_GOTO || scan->op == GOTO)
	{
	  if(strcmp(scan->dest->dest_label,old_label->label_name) == 0)
	    {
	      free(scan->dest->dest_label);
	      scan->dest->dest_label = strdup(new_label->label_name);
	    }
	}
    }
}


void ic_print_table()
{
  fprintf(stderr,"printing intermediate code table!\n");

  ic_symbol* scan = ic_symb_buff;
  if(scan == NULL)
    {
      fprintf(stderr,"empty intermediate code table\n");
    }
  else{
    while(scan->next != NULL)
      {
	if(scan->type == INT)
	  {
	    fprintf(stderr,"ic var : %s val :%d \n",
		    scan->name,
		    scan->val.i_val);
	  }
	else if (scan->type == FLOAT)
	  {
	    fprintf(stderr,"ic var : %s val :%f \n",
		    scan->name,
		    scan->val.f_val);
	  }	    
	scan = scan->next;
      }
  }
}
void ic_print_code(ic_quad* code)
{
  fprintf(stdout,"Printing intermediate code instructions\n");
  ic_quad* c = code;
  while(c != NULL)
    {
      if(c->q_name != NULL)
	fprintf(stderr,"labelled statement with label : %s\n",c->q_name);

      switch(c->op)
	{
	case ASSIGN:
	  //fprintf(stdout,"ic_print_code : \n");
	  assert(c->dest != NULL);
	  assert(c->dest->dest_symb->name != NULL);
	  assert(c->arg1 != NULL);
	  assert(c->arg1->name != NULL);
	  fprintf(stdout,"    %s <- %s\n",c->dest->dest_symb->name,c->arg1->name);
	  break;
	case IFZ_GOTO:
	  fprintf(stdout,"    if %s == 0 goto %s\n",c->arg1->name,c->dest->dest_label);
	  break;
	case IFEQ_GOTO:
	  if(c->dest != NULL)
	    fprintf(stdout,"    if %s == %s goto %s\n",c->arg1->name,c->arg2->name,c->dest->dest_label);
	  else
	    fprintf(stdout,"    if %s == %s goto null\n",c->arg1->name,c->arg2->name);

	  break;
	case GOTO:
	  if(c->dest != NULL)
	    fprintf(stdout,"    goto %s\n",c->dest->dest_label);
	  else
	    fprintf(stdout,"    goto null\n");

	  break;
	case EQUAL:
	  fprintf(stdout,"    %s <- (%s == %s)\n",c->dest->dest_symb->name,c->arg1->name,c->arg2->name);
	  break;
	case INFERIOR:
	  fprintf(stdout,"    %s <- (%s <= %s)\n",c->dest->dest_symb->name,c->arg1->name,c->arg2->name);
	  break;
	case PLUS:
	  fprintf(stdout,"    %s <- (%s + %s)\n",c->dest->dest_symb->name,c->arg1->name,c->arg2->name);
	  break;
	case MINUS:
	  fprintf(stdout,"    %s <- (%s - %s)\n",c->dest->dest_symb->name,c->arg1->name,c->arg2->name);
	  break;
	case MULT:
	  fprintf(stdout,"    %s <- (%s * %s)\n",c->dest->dest_symb->name,c->arg1->name,c->arg2->name);
	  break;
	case SKIP:
	  fprintf(stdout,"    skip\n");
	  break;
	}
      c = c->next;
    }
}
ic_ql* ic_ql_new(ic_quad* q)
{
  ic_ql* ret = malloc(sizeof(*ret));
  ret->q = q;
  ret->next = NULL;
  return ret;
}
ic_ql* ic_ql_concat(ic_ql* q1,ic_ql* q2)
{
  if(q1 == NULL)
    return q2;
  while(q1->next != NULL)
    q1 = q1->next;
  q1->next = q2;
  return q1;
}
fd_param* fd_new_param(char* id)
{
  fd_param* ret = malloc(sizeof(*ret));
  ret->val = var_lookup(id);
  //ret->param_typ = 
  ret->next = NULL;

  return ret;
}
