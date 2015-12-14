%{
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>

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
	 struct{
	     ic_quad *i_code;
	     ic_symbol *i_var;
	     //ic_ql* true_list;
	     //ic_ql* false_list;
	     //ic_label* next;
	 }exp_val;
	 struct{
	     ic_quad *i_code;
	     ic_symbol *i_var;
	     ic_ql* true_list;
	     ic_ql* false_list;
	 }bexp_val;	     
	 struct{
	     ic_quad *i_code;
	     ic_symbol *i_var;
    	     ic_ql* next_list;
         }stmt_val;
	 struct{
	     typ_m t;
	     int line;
	 }typ_val;
         struct{
	     typ_m type;
	     ic_symb_val val;
	 }const_val;
	 struct{
	     fd_param *param;
	     int line;
	 }fun_param;
}
			
%token IF WHILE FOR
%nonassoc "then"
%right ELSE
%token <typ_val> TYPE 
%token <const_val> CONST_TOKEN
%left OR AND
%nonassoc EQ DIFF
%left '!'
%left '+' '-'
%left '*'
%token <id_val> ID
%type <exp_val> exp
%type <bexp_val> bool_exp
%type <stmt_val> proc_call assign var_decl if_stmt while_stmt atom_stm stm_list prog bloc_stm
%type <fun_param> param
%error-verbose
%start prog
			
%%

prog : TYPE ID '(' ')' bloc_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
/*var_print_table();
ic_print_table();
ic_print_code($1.i_code);*/
    if($1.t == INT && strcmp($2.str_val,"main") == 0)
    {
        q_buff = $5.i_code;
        if($5.next_list != NULL)
        {
            ic_quad* sup_stmt = ic_quad_gen(NULL,NULL,NULL,SKIP);
            ic_label* l = ic_new_label_gen(sup_stmt);
	    ic_backpatch($5.next_list,l);
        //ic_label_set_code($1.next,sup_stmt);
            q_buff = ic_quad_concat(q_buff,sup_stmt);
        }
      
    }else{
        fprintf(stderr,"only main function allowed\n");
    }

}
;
bloc_stm : '{' stm_list '}' {
/*****************************************************************************************************/
/*****************************************************************************************************/
    $$.i_code = $2.i_code;
    $$.next_list = $2.next_list;
}
;
stm_list :    atom_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"stm_list : atom_stm -> line %d\n",src_line);
    $$.i_code = $1.i_code;
    $$.next_list = $1.next_list;
//    ic_print_code($1.i_code);
}
| stm_list atom_stm   {
/*****************************************************************************************************/
//v_append($$.vars_d,$1,$2);???
 //fprintf(stderr,"stm_list :atom_stm stm_list -> line %d\n",src_line);

     $$.i_code =  ic_quad_concat($1.i_code,$2.i_code);

     if($1.next_list != NULL)
     {
         if($2.i_code != NULL)
	 {
             ic_label* l = ic_new_label_gen($2.i_code);
             ic_backpatch($1.next_list,l);
             $$.next_list = NULL;
         }else{
             $$.next_list = $1.next_list;
         }
     }else{
        $$.next_list = $2.next_list;
    }
}

;

atom_stm : var_decl ';'  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //$$.vars_d = $1.vars_d
    //fprintf(stderr,"var declaration\n");
    $$.next_list = $1.next_list;
    $$.i_code = $1.i_code;
}
	|	assign ';'    {
/*****************************************************************************************************/

//	    fprintf(stderr,"assignment\n");
    $$.i_code = $1.i_code;
    $$.next_list = $1.next_list;

}
	|	';'        {
/*****************************************************************************************************/
/*$$.i_code = NULL;
$$.next = NULL;*/
    $$.i_code = ic_quad_gen(NULL,NULL,NULL,SKIP);
    $$.next_list = NULL;

}
	|	if_stmt  {
/*****************************************************************************************************/
	    //fprintf(stderr,"if statement \n");
    $$.i_code = $1.i_code;
    $$.next_list = $1.next_list;
    //fprintf(stderr," if_stmt printcode :\n");
//ic_print_code($$.i_code);
}
	|	'{' stm_list '}' {
/*****************************************************************************************************/
//move to bloc
    $$.i_code = $2.i_code;
    $$.next_list = $2.next_list;

}
	|	while_stmt {
/*****************************************************************************************************/
    $$.i_code = $1.i_code;
    $$.next_list = $1.next_list;
//fprintf(stderr,"while statement \n");ic_print_code($$.i_code);
}
	|	proc_call ';' {
/*****************************************************************************************************/
    $$.i_code = $1.i_code;
assert($1.i_code != NULL);
    $$.next_list = NULL;
}
;

if_stmt : IF '(' bool_exp ')' atom_stm %prec "then"{
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"simple if statement\n");
    ic_label* true_l = ic_new_label_gen($5.i_code);
    ic_backpatch($3.true_list,true_l);
    $$.next_list = ic_ql_concat($3.false_list,$5.next_list);
    $$.i_code = ic_quad_concat($3.i_code,$5.i_code);
 
}
	|   IF '(' bool_exp ')' atom_stm ELSE atom_stm {
/*****************************************************************************************************/
//$$.i_code = NULL;
    ic_label* true_l = ic_new_label_gen($5.i_code);
    ic_label* false_l = ic_new_label_gen($7.i_code);
    ic_backpatch($3.true_list,true_l);
    ic_backpatch($3.false_list,false_l);
    $$.i_code = ic_quad_concat($3.i_code,$5.i_code);
    $$.i_code = ic_quad_concat($$.i_code,$7.i_code);

    $$.next_list = ic_ql_concat($5.next_list,$7.next_list);
}
;

while_stmt : WHILE '(' bool_exp ')' atom_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
    ic_label* true_l = ic_new_label_gen($5.i_code);
    ic_backpatch($3.true_list,true_l);
    ic_label* e_l;
    e_l = ic_new_label_gen($3.i_code);
    ic_label_set_code(true_l,$5.i_code);
    $$.i_code = ic_quad_concat($3.i_code,$5.i_code);
    $$.i_code = ic_quad_concat($$.i_code,
                               ic_quad_gen_gl(e_l,NULL,NULL,GOTO));

    $$.next_list = $3.false_list;

//debug
    //fprintf(stderr,"while_stmt : printcode\n");
//ic_print_code($$.i_code);
};


var_decl : TYPE ID   {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"simple var declaration of %s\n",$2.str_val);
    id_s v = new_id_s($2.str_val,$1.t,$1.line);
//    v.ic_var = ic_gen_temp(0,$1.t);

    if(!var_add_global(v))
    {
        fprintf(stderr,"Error : var %s already declared line : %d\n",$2.str_val,$1.line);
        exit(1);
    }
    $$.i_code = NULL;
    $$.next_list = NULL;

}
	|	TYPE ID '=' exp   {
/*****************************************************************************************************/
    //fprintf(stderr,"var declaration and assignment of %s\n",$2.str_val);
    id_s v = new_id_s($2.str_val,$1.t,$1.line);
//    v.ic_var = ic_gen_temp(0,$1.t);
    //assert(v.ic_var != NULL);

    if(!var_add_global(v))
    {
        fprintf(stderr,"var already declared %s \n",$2.str_val);
        exit(1);
    }
    else{
        ic_quad* q;
        
        assert(v.ic_var != NULL);
        assert($4.i_var != NULL);
        q = ic_symb_conv(v.ic_var,$4.i_var);
        if(q == NULL)
	{
            fprintf(stderr,"line %d : type not compatible\n",$1.line);
            exit(1);
        }
        $$.i_code = ic_quad_concat($4.i_code,q);
        $$.next_list = NULL;
    }
}
;


exp : '('  exp ')' {
/*****************************************************************************************************/
/*****************************************************************************************************/
$$.i_var = $2.i_var;
$$.i_code = $2.i_code;
}
	|  	ID {
/*****************************************************************************************************/
    //fprintf(stderr,"exp ID\n");

    if(!var_is_global($1.str_val))
    {
        fprintf(stderr,"var %s not global!\n",$1.str_val);
        exit(1);
    }
    else{
        $$.i_var = var_lookup($1.str_val)->ic_var;
        $$.i_code = NULL;

    }
}
	|	CONST_TOKEN  {
/*****************************************************************************************************/
//    fprintf(stderr,"exp lval\n");
    $$.i_var = ic_gen_temp_const($1.val,$1.type);
    $$.i_code = NULL;
//    $$.next_list = NULL;

}
	|	exp '+' exp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp($1.i_var->type);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    if($1.i_var->type != $3.i_var->type)
    {
        ic_symbol* tmp = ic_gen_temp($1.i_var->type);
        $$.i_code = ic_quad_concat($$.i_code,ic_symb_conv(tmp,$3.i_var));
        $$.i_code = ic_quad_concat($$.i_code,ic_quad_gen($$.i_var,$1.i_var,tmp,PLUS));
    }else{
        $$.i_code = ic_quad_concat($$.i_code,ic_quad_gen($$.i_var,$1.i_var,$3.i_var,PLUS));
    }
//    $$.next_list = NULL;
}
	|	exp '-' exp {
/*****************************************************************************************************/
//fprintf(stderr,"MINUS\n");


    $$.i_var = ic_gen_temp($1.i_var->type);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    if($1.i_var->type != $3.i_var->type)
    {
        ic_symbol* tmp = ic_gen_temp($1.i_var->type);
        $$.i_code = ic_quad_concat($$.i_code,ic_symb_conv(tmp,$3.i_var));
        $$.i_code = ic_quad_concat($$.i_code,ic_quad_gen($$.i_var,$1.i_var,tmp,MINUS));
    }else{
        $$.i_code = ic_quad_concat($$.i_code,ic_quad_gen($$.i_var,$1.i_var,$3.i_var,MINUS));
    }

//    $$.next_list = NULL;
}
	|	exp '*' exp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp($1.i_var->type);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    if($1.i_var->type != $3.i_var->type)
    {
        ic_symbol* tmp = ic_gen_temp($1.i_var->type);
        $$.i_code = ic_quad_concat($$.i_code,ic_symb_conv(tmp,$3.i_var));
        $$.i_code = ic_quad_concat($$.i_code,ic_quad_gen($$.i_var,$1.i_var,tmp,MULT));
    }else{
	//fprintf(stderr,"exp '*' exp\n");
        $$.i_code = ic_quad_concat($$.i_code,ic_quad_gen($$.i_var,$1.i_var,$3.i_var,MULT));
    }

//    $$.next_list = NULL;

}
;

bool_exp : '(' bool_exp ')' {
/*****************************************************************************************************/
    $$.i_var = $2.i_var;
    $$.true_list = $2.true_list;
    $$.false_list = $2.false_list;
    $$.i_code = $2.i_code;
}
        |  exp EQ exp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp(INT);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_label* l_true = ic_new_label_gen(NULL);
    ic_quad* test_q = ic_quad_gen_gl(l_true,$1.i_var,$3.i_var,IFEQ_GOTO);
    $$.i_code = ic_quad_concat($$.i_code,test_q);
    ic_symbol* const_true = ic_gen_temp_const(true_val,INT);
    ic_symbol* const_false = ic_gen_temp_const(false_val,INT);
    ic_quad* false_q = ic_quad_gen($$.i_var,const_false,NULL,ASSIGN);
    $$.i_code = ic_quad_concat($$.i_code,false_q);
    $$.false_list = ic_ql_new(ic_quad_gen_gl(NULL,NULL,NULL,GOTO));
    $$.i_code = ic_quad_concat($$.i_code,$$.false_list->q);
    ic_quad* true_q = ic_quad_gen($$.i_var,const_true,NULL,ASSIGN);
    ic_label_set_code(l_true,true_q);
    $$.i_code = ic_quad_concat($$.i_code,true_q);
    $$.true_list = ic_ql_new(ic_quad_gen_gl(NULL,NULL,NULL,GOTO));
    $$.i_code = ic_quad_concat($$.i_code,$$.true_list->q);
//    $$.next_list = NULL;



//
 /*fprintf(stderr,"exp EQ exp => printcode\n");
ic_print_code($$.i_code);
fprintf(stderr,"end printcode\n");
*/
}
	| exp DIFF exp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp(INT);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_label* l_false = ic_new_label_gen(NULL);
    ic_quad* test_q = ic_quad_gen_gl(l_false,$1.i_var,$3.i_var,IFEQ_GOTO);
    $$.i_code = ic_quad_concat($$.i_code,test_q);

    ic_symbol* const_true = ic_gen_temp_const(true_val,INT);
    ic_symbol* const_false = ic_gen_temp_const(false_val,INT);
// exp1 != exp2 case
    ic_quad* true_q = ic_quad_gen($$.i_var,const_true,NULL,ASSIGN);
    $$.i_code = ic_quad_concat($$.i_code,true_q);

    $$.true_list = ic_ql_new(ic_quad_gen_gl(NULL,NULL,NULL,GOTO));
    $$.i_code = ic_quad_concat($$.i_code,$$.true_list->q);
    assert($$.true_list->q->dest == NULL);
//case exp1 == exp2
    ic_quad* false_q = ic_quad_gen($$.i_var,const_false,NULL,ASSIGN);
    ic_label_set_code(l_false,false_q);
    $$.i_code = ic_quad_concat($$.i_code,false_q);
    $$.false_list = ic_ql_new(ic_quad_gen_gl(NULL,NULL,NULL,GOTO));
    $$.i_code = ic_quad_concat($$.i_code,$$.false_list->q);
    assert($$.false_list->q->dest == NULL);

//fprintf(stderr,"exp DIFF exp => printcode\n");
//ic_print_code($$.i_code);
//fprintf(stderr,"end printcode\n");


//
}
	| bool_exp OR bool_exp  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    ic_label* false_1 = ic_new_label_gen($3.i_code);
    ic_backpatch($1.false_list,false_1);
    $$.true_list =ic_ql_concat($1.true_list,$3.true_list);
    $$.false_list = $3.false_list;
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
//    $$.next_list = NULL;
}
	| 	bool_exp AND bool_exp  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    ic_label* true_1 = ic_new_label_gen($3.i_code);
    ic_backpatch($1.true_list,true_1);
    $$.false_list = ic_ql_concat($1.false_list,$3.false_list);
    $$.true_list = $3.true_list;
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);

//    $$.next_list = NULL;
}
      |  '!' bool_exp  {
/*****************************************************************************************************/
    $$.true_list = $2.false_list;
    $$.false_list = $2.true_list;
    $$.i_code = $2.i_code;
//    $$.next_list = NULL;
}
;


assign : ID '=' exp  {
/*****************************************************************************************************/
/*****************************************************************************************************/

    if(!var_is_global($1.str_val))
    {
        fprintf(stderr,"var %s not global!\n",$1.str_val);
        exit(1);
    }
    else{
        assert($3.i_var != NULL);
    //
        if(var_lookup($1.str_val)->t_id == $3.i_var->type)
	{
            $$.i_code = ic_quad_concat($3.i_code,ic_quad_gen(var_lookup($1.str_val)->ic_var,
                                    $3.i_var,
                                    NULL,
                                    ASSIGN));
            $$.next_list = NULL;
        }else{
            $$.i_code = ic_quad_concat($3.i_code,ic_symb_conv(var_lookup($1.str_val)->ic_var,$3.i_var));
            $$.next_list = NULL;
        }
    } 
//eventuellement mettre une valeur de retour pour cette instruction : un nouveau temp
/*$$.i_var = ic_gen_temp(0);
 $$.i_code = ic_quad_concat($$.i_code,
                            ic_quad_gen($$.i_var,$3.i_var,NULL,ASSIGN));
$$.next = NULL;*/
}
;

proc_call : ID '(' param ')'  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    $$.i_code = ic_quad_proc_gen($1.str_val,$3.param->val);
    $$.i_var = NULL;
    $$.next_list = NULL;

}
;
param : ID {
/*****************************************************************************************************/
/*****************************************************************************************************/
    if(var_is_global($1.str_val))
    {
        $$.param = fd_new_param($1.str_val);
        $$.line = $1.line;
    }else{
        fprintf(stderr,"var %s not declared\n",$1.str_val);
        exit(1);
    }

}
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
    true_val.i_val = 1;
    false_val.i_val = 0;
    
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
    assert(ic_symb_buff != NULL);
    assert(q_buff != NULL);
    icm_print_to_file(argv[2],ic_symb_buff,q_buff);
  //printf("?");
  //return yyparse();
  return 0;
}
