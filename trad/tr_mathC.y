%{
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include "trad_mathC.h"
#include "ic_to_mips.h"



//int yylex(union YYSTYPE *, void *);
int yylex();
void yyerror(const char* m);

ic_quad* q_buff;

%}

			
%union { struct{
             char* str_val;
	     int line;
         }id_val;
	 int int_val;
	 struct{
	     ic_quad *i_code;
	     ic_int_symbol *i_var;
	     ic_label* exp_true;
	     ic_label* exp_false;
	     ic_label* next;
	 }exp_val;
	 float f_val;
	 struct{
	     typ_m t;
	     int line;
	 }typ_val;
}
			
%token END
%token IF ELSE WHILE FOR
%token <typ_val> TYPE 
%token <id_val> ID
%token <int_val> CONST_VAL
%nonassoc EQ
%left '+'
%left '*'
%type <exp_val> exp assign var_decl if_stmt while_stmt atom_stm stm_list prog
%error-verbose
%start prog
			
%%

prog : stm_list {
/*****************************************************************************************************/
/*****************************************************************************************************/
/*var_print_table();
ic_print_table();
ic_print_code($1.i_code);*/
q_buff = $1.i_code;
     if($1.next != NULL)
		{
ic_quad* sup_stmt = ic_quad_gen(NULL,NULL,NULL,SKIP);
 ic_label_set_code($1.next,sup_stmt);
 q_buff = ic_quad_concat(q_buff,sup_stmt);
}

}

stm_list :    atom_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
//fprintf(stderr,"no suplementar statement\n");
    //fprintf(stderr,"stm_list : atom_stm -> line %d\n",src_line);
    $$.i_code = $1.i_code;
    $$.next = $1.next;
    //ic_print_code($1.i_code);
}
| stm_list atom_stm   {
/*****************************************************************************************************/
//v_append($$.vars_d,$1,$2);???
 //fprintf(stderr,"stm_list :atom_stm stm_list -> line %d\n",src_line);
     $$.i_code =  ic_quad_concat($1.i_code,$2.i_code);
     $$.next = $2.next;
     ic_print_code($2.i_code);

//
     if($1.next != NULL)
		{
          if($2.i_code != NULL)
		{
    //ic_backpatch($1.i_code,$2.i_code);
                ic_label_set_code($1.next, $2.i_code);
          }else{
                $$.next = $1.next;
                //assert(false);
          }

      }
}

;

atom_stm : var_decl ';'  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //$$.vars_d = $1.vars_d
    //fprintf(stderr,"var declaration\n");
$$.next = $1.next;
$$.i_code = $1.i_code;
}
	|	assign ';'    {
/*****************************************************************************************************/

//	    fprintf(stderr,"assignment\n");
$$.i_code = $1.i_code;
$$.next = $1.next;

}
	|	';'        {
/*****************************************************************************************************/
//	    fprintf(stderr,"quedale\n");

/*$$.i_code = NULL;
$$.next = NULL;*/
	    $$.i_code = ic_quad_gen(NULL,NULL,NULL,SKIP);
$$.next = NULL;

}
	|	if_stmt  {
/*****************************************************************************************************/
	    //fprintf(stderr,"if statement \n");
$$.i_code = $1.i_code;
$$.next = $1.next;
    //fprintf(stderr," if_stmt printcode :\n");
//ic_print_code($$.i_code);
}
	|	'{' stm_list '}' {
/*****************************************************************************************************/
//move to bloc
$$.i_code = $2.i_code;
$$.next = $2.next;

}
	|	while_stmt {
/*****************************************************************************************************/
$$.i_code = $1.i_code;
$$.next = $1.next;
//fprintf(stderr,"while statement \n");ic_print_code($$.i_code);
}
;

if_stmt : IF '(' exp ')' atom_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"simple if statement\n");

    if($5.next != NULL)
        $$.next = $5.next;
    else
        $$.next = ic_new_label_gen(NULL);

    /*ic_quad* if_code = ic_quad_concat($3.i_code,
                                   ic_quad_gen_g($$.next->label_name,
                                                 $3.i_var,
                                                 NULL,
                                                 IFZ_GOTO));*/
    ic_quad* q = ic_quad_gen_g($$.next->label_name,
                               $3.i_var,
                               NULL,
                               IFZ_GOTO);
    if($3.next != NULL)
        ic_label_set_code($3.next,q);
    ic_quad* if_code = ic_quad_concat($3.i_code,q);
    $$.i_code = ic_quad_concat(if_code,
                            $5.i_code);

//
//    fprintf(stderr,"ifexp : $$.i_code  printcode\n");ic_print_code($$.i_code);


 
}
	|   IF '(' exp ')' atom_stm ELSE atom_stm {
/*****************************************************************************************************/
$$.i_code = NULL;
}
;

while_stmt : WHILE '(' exp ')' atom_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
    if($5.next != NULL)
        $$.next = $5.next;// ?
    else
        $$.next = ic_new_label_gen(NULL);
    ic_quad* while_code = ic_quad_gen_g($$.next->label_name,
                                                 $3.i_var,
                                                 NULL,
                                                 IFZ_GOTO);
    if($3.next != NULL)
	ic_label_set_code($3.next,while_code);
    while_code = ic_quad_concat($3.i_code,while_code);
    ic_label* while_label = ic_new_label_gen(while_code);
    $$.i_code = ic_quad_concat(while_code,
                            $5.i_code);
    $$.i_code = ic_quad_concat($$.i_code,
                               ic_quad_gen_g(while_label->label_name,
                                             NULL,
                                             NULL,
                                             GOTO));
};


var_decl : TYPE ID   {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"simple var declaration of %s\n",$2.str_val);
id_s v = new_id_s($2.str_val,$1.t,$1.line);
v.ic_var = ic_gen_temp(0);

    if(!var_add_global(v))
		{
        fprintf(stderr,"Error : var %s already declared\n",$2.str_val);
exit(1);
}
$$.i_code = NULL;
$$.next = NULL;

}
	|	TYPE ID '=' exp   {
/*****************************************************************************************************/
    //fprintf(stderr,"var declaration and assignment of %s\n",$2.str_val);
    id_s v = new_id_s($2.str_val,$1.t,$1.line);
    v.ic_var = ic_gen_temp(0);
assert(v.ic_var != NULL);

    if(!var_add_global(v))
		{
        fprintf(stderr,"var already declared %s \n",$2.str_val);
exit(1);
}
else{
assert(v.ic_var != NULL);
assert($4.i_var != NULL);
 $$.i_code = ic_quad_concat($4.i_code,
                            ic_quad_gen(v.ic_var,$4.i_var,NULL,ASSIGN));
$$.next = NULL;
}
}
;

exp : ID {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"exp ID\n");

if(!var_is_global($1.str_val))
		{
    fprintf(stderr,"var %s not global!\n",$1.str_val);
exit(1);
}
else{
$$.i_code = NULL;
$$.i_var = var_lookup($1.str_val)->ic_var;
 $$.next = NULL;

}
}
	|	CONST_VAL  {
/*****************************************************************************************************/
//    fprintf(stderr,"exp lval\n");
$$.i_code = NULL;
$$.i_var = ic_gen_temp($1);
$$.next = NULL;

}
	|	exp '+' exp {
/*****************************************************************************************************/
$$.i_var = ic_gen_temp(0);
 $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
// $$.i_code = ic_quad_concat($$.i_code,
 ic_quad* p_q = ic_quad_gen($$.i_var,$1.i_var,$3.i_var,PLUS);
//branch
if($1.next != NULL && $3.i_code != NULL)
   {
    ic_label_set_code($1.next,$3.i_code);
   }
else if($1.next != NULL)
   {
       ic_label_set_code($1.next,p_q);
}else if ($3.next != NULL)
       ic_label_set_code($3.next,p_q);
$$.i_code = ic_quad_concat($$.i_code,p_q);
$$.next = NULL;


}
	|	exp '*' exp {
/*****************************************************************************************************/
$$.i_var = ic_gen_temp(0);
 $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
// $$.i_code = ic_quad_concat($$.i_code,
 ic_quad* p_q = ic_quad_gen($$.i_var,$1.i_var,$3.i_var,MULT));
//branch
if($1.next != NULL && $3.i_code != NULL)
   {
    ic_label_set_code($1.next,$3.i_code);
   }
else if($1.next != NULL)
   {
       ic_label_set_code($1.next,p_q);
}else if ($3.next != NULL)
       ic_label_set_code($3.next,p_q);
$$.i_code = ic_quad_concat($$.i_code,p_q);
$$.next = NULL;


}
	|	exp EQ exp {
/*****************************************************************************************************/
$$.i_var = ic_gen_temp(0);
 $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
ic_label* l_true = ic_new_label_gen(NULL);
//$$.i_code = ic_quad_concat($$.i_code,
ic_quad* test_q = ic_quad_gen_gl(l_true,$1.i_var,$3.i_var,IFEQ);
ic_label* exp_next = NULL;
if($1.next != NULL)
    {
       if($3.i_code == NULL)
             exp_next = $1.next;
       else
           ic_label_set_code($1.next,$3.i_code);
    }
if($3.next != NULL)
    {
     if(exp_next != NULL)
	{
            ic_quad_replace_label($3.i_code,$3.next,$1.next);
        }
     else
          exp_next = $3.next;
}

if(exp_next != NULL)
    ic_label_set_code(exp_next,test_q);
$$.i_code = ic_quad_concat($$.i_code,test_q);
ic_int_symbol* false_const = ic_gen_temp(0);
$$.i_code = ic_quad_concat($$.i_code,
                           ic_quad_gen($$.i_var,false_const,NULL,ASSIGN));
$$.next = ic_new_label_gen(NULL);
$$.i_code = ic_quad_concat($$.i_code,
                           ic_quad_gen_gl($$.next,NULL,NULL,GOTO));

/*$$.i_code = ic_quad_concat($$.i_code,
                           ic_quad_gen_gl(l_false,NULL,NULL,GOTO));*/
ic_int_symbol* true_const = ic_gen_temp(1);
 ic_quad* true_code = ic_quad_gen($$.i_var,true_const,NULL,ASSIGN);
 ic_label_set_code(l_true,true_code);
 $$.i_code = ic_quad_concat($$.i_code,true_code);

//
 fprintf(stderr,"exp EQ exp => printcode\n");
ic_print_code($$.i_code);
fprintf(stderr,"end printcode\n");

}
;

assign : ID '=' exp  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"assign \n");
    if(!var_is_global($1.str_val))
		{
       fprintf(stderr,"var %s not global!\n",$1.str_val);
exit(1);
}
    else{
    assert($3.i_var != NULL);
    //
    ic_quad* q = ic_quad_gen(var_lookup($1.str_val)->ic_var,
                                           $3.i_var,
                                           NULL,
                                           ASSIGN);
if($3.next != NULL)
    ic_label_set_code($3.next,q);
$$.i_code = ic_quad_concat($3.i_code,q);
//eventuellement mettre une valeur de retour pour cette instruction : un nouveau temp
$$.i_var = ic_gen_temp(0);
 $$.i_code = ic_quad_concat($$.i_code,
                            ic_quad_gen($$.i_var,$3.i_var,NULL,ASSIGN));
$$.next = NULL;
}
}
;

%%

extern int yylex();
extern int yyparse();
extern FILE *yyin;

void yyerror(const char* m)
{
    printf("erreur de syntaxe ligne  %d : %s \n",src_line,m);
}

int main(int argc,char **argv)
{
    //curr_lookup_size = 0;
    //BLOCK_LEVEL = 0;
    curr_glob_var_number = 0;
    src_line = 0;
    
    if(argc >= 2)
    { 
      FILE *input = fopen(argv[1],"r");
      if(!input)
        {
          fprintf(stderr,"Cannot open %s\n",argv[1]);
          exit(2);
        }
      yyin=input;
    }

    //do{
    yyparse();
    //}while(!feof(yyin));
    ic_print_code(q_buff);
    icm_print_to_file(argv[2],ic_symb_buff,q_buff);
  //printf("?");
  //return yyparse();
  return 0;
}
