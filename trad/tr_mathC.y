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
	     //ic_label* exp_true;
	     //ic_label* exp_false;
	     //ic_ql* true_list;
	     //ic_ql* false_list;
	     //ic_label* next;
	 }iexp_val;
	 struct{
	     ic_quad *i_code;
	     ic_int_symbol *i_var;
	     ic_ql* true_list;
	     ic_ql* false_list;
	 }bexp_val;	     
	 struct{
	     ic_quad *i_code;
	     ic_int_symbol *i_var;
    	     ic_ql* next_list;
         }stmt_val;
	 float f_val;
	 struct{
	     typ_m t;
	     int line;
	 }typ_val;
}
			
%token IF WHILE FOR
%nonassoc "then"
%right ELSE
%token <typ_val> TYPE 
%token <int_val> CONST_VAL
%left OR AND
%nonassoc EQ DIFF
%left '!'
%left '+' '-'
%left '*'
%token <id_val> ID
%type <iexp_val> iexp
%type <bexp_val> bool_exp
%type <stmt_val>	 assign var_decl if_stmt while_stmt atom_stm stm_list prog
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
    if($1.next_list != NULL)
    {
        ic_quad* sup_stmt = ic_quad_gen(NULL,NULL,NULL,SKIP);
        ic_label* l = ic_new_label_gen(sup_stmt);
	ic_backpatch($1.next_list,l);
        //ic_label_set_code($1.next,sup_stmt);
        q_buff = ic_quad_concat(q_buff,sup_stmt);
    }

}

stm_list :    atom_stm {
/*****************************************************************************************************/
/*****************************************************************************************************/
    //fprintf(stderr,"stm_list : atom_stm -> line %d\n",src_line);
    $$.i_code = $1.i_code;
    $$.next_list = $1.next_list;
    //ic_print_code($1.i_code);
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
         }else
             $$.next_list = $1.next_list;
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
//	    fprintf(stderr,"quedale\n");

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
    $$.next_list = NULL;

}
	|	TYPE ID '=' iexp   {
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
        ic_quad* q = ic_quad_gen(v.ic_var,$4.i_var,NULL,ASSIGN);
        $$.i_code = ic_quad_concat($4.i_code,q);

        $$.next_list = NULL;
    }
}
;

iexp : '('  iexp ')' {
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
	|	CONST_VAL  {
/*****************************************************************************************************/
//    fprintf(stderr,"exp lval\n");
    $$.i_var = ic_gen_temp($1);
    $$.i_code = NULL;
//    $$.next_list = NULL;

}
	|	iexp '+' iexp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp(0);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_quad* p_q = ic_quad_gen($$.i_var,$1.i_var,$3.i_var,PLUS);
    $$.i_code = ic_quad_concat($$.i_code,p_q);

//    $$.next_list = NULL;
}
	|	iexp '-' iexp {
/*****************************************************************************************************/
fprintf(stderr,"MINUS\n");


    $$.i_var = ic_gen_temp(0);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_quad* p_q = ic_quad_gen($$.i_var,$1.i_var,$3.i_var,MINUS);
    $$.i_code = ic_quad_concat($$.i_code,p_q);

//    $$.next_list = NULL;
}
	|	iexp '*' iexp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp(0);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_quad* p_q = ic_quad_gen($$.i_var,$1.i_var,$3.i_var,MULT);
    $$.i_code = ic_quad_concat($$.i_code,p_q);
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
        |  iexp EQ iexp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp(0);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_label* l_true = ic_new_label_gen(NULL);
    ic_quad* test_q = ic_quad_gen_gl(l_true,$1.i_var,$3.i_var,IFEQ_GOTO);
    $$.i_code = ic_quad_concat($$.i_code,test_q);
    ic_int_symbol* const_true = ic_gen_temp(1);
    ic_int_symbol* const_false = ic_gen_temp(0);
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
 fprintf(stderr,"exp EQ exp => printcode\n");
ic_print_code($$.i_code);
fprintf(stderr,"end printcode\n");

}
	| iexp DIFF iexp {
/*****************************************************************************************************/
    $$.i_var = ic_gen_temp(0);
    $$.i_code = ic_quad_concat($1.i_code,$3.i_code);
    ic_label* l_false = ic_new_label_gen(NULL);
    ic_quad* test_q = ic_quad_gen_gl(l_false,$1.i_var,$3.i_var,IFEQ_GOTO);
    $$.i_code = ic_quad_concat($$.i_code,test_q);

    ic_int_symbol* const_true = ic_gen_temp(1);
    ic_int_symbol* const_false = ic_gen_temp(0);
// exp1 != exp2 case
    ic_quad* true_q = ic_quad_gen($$.i_var,const_true,NULL,ASSIGN);
    $$.i_code = ic_quad_concat($$.i_code,true_q);

    $$.true_list = ic_ql_new(ic_quad_gen_gl(NULL,NULL,NULL,GOTO));
    $$.i_code = ic_quad_concat($$.i_code,$$.true_list->q);
//case exp1 == exp2
    ic_quad* false_q = ic_quad_gen($$.i_var,const_false,NULL,ASSIGN);
    ic_label_set_code(l_false,false_q);
    $$.i_code = ic_quad_concat($$.i_code,false_q);
    $$.false_list = ic_ql_new(ic_quad_gen_gl(NULL,NULL,NULL,GOTO));
    $$.i_code = ic_quad_concat($$.i_code,$$.false_list->q);
    


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
      |  '!' bool_exp  {
/*****************************************************************************************************/
    $$.true_list = $2.false_list;
    $$.false_list = $2.true_list;
    $$.i_code = $2.i_code;
//    $$.next_list = NULL;
}
;
assign : ID '=' iexp  {
/*****************************************************************************************************/
/*****************************************************************************************************/
    fprintf(stderr,"assigning %s \n",$1.str_val);
    fprintf(stderr,"assign code :\n");
ic_print_code($3.i_code);


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
        $$.i_code = ic_quad_concat($3.i_code,q);
        $$.next_list = NULL;
    } 
//eventuellement mettre une valeur de retour pour cette instruction : un nouveau temp
/*$$.i_var = ic_gen_temp(0);
 $$.i_code = ic_quad_concat($$.i_code,
                            ic_quad_gen($$.i_var,$3.i_var,NULL,ASSIGN));
$$.next = NULL;*/
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
