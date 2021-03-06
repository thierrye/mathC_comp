#ifndef TRAD_MATHC
#define TRAD_MATHC

#include "stdbool.h"

#define TYPE_NUMBER 3
#define MAX_SYMB_SIZE 100
#define MAX_IC_NUM 100
#define MAX_FUN_PARAM 1

/*****************************************************************************************************
                                      type declaration
******************************************************************************************************/

enum type_mathC {INT,FLOAT,MATRIX};
typedef enum type_mathC typ_m;
extern char *type_buff[TYPE_NUMBER];

int l_istype(char *str_t);
typ_m str_to_type_m(char * str);
/*****************************************************************************************************
                                 intermediate code
******************************************************************************************************/
typedef union{int i_val;float f_val;}ic_symb_val;
typedef struct ic_s{
  char* name;
  typ_m type;
  ic_symb_val val;
  bool is_const;
  struct ic_s* next;
}ic_symbol;
typedef struct ic_symbol_list{
  ic_symbol* s;
  struct ic_symbol_list* next;
}ic_symbol_list;

typedef enum{ASSIGN,
	     IFZ_GOTO,IFEQ_GOTO,GOTO,
	     EQUAL,INFERIOR,SUPERIOR,
	     PLUS,MINUS,MULT,
	     PRINT_INT,PRINT_FLOAT,PRINTF,PRINTMAT,
	     ITOF,FTOI,
	     SKIP}ic_op;
typedef union {ic_symbol* dest_symb; char* dest_label;}ic_q_dest;
typedef struct ic_q{
  //ic_symbol* dest;
  char *q_name;//label : if NULL no label
  ic_q_dest* dest;
  ic_symbol* arg1;
  ic_symbol* arg2;
  ic_op op;
  struct ic_q* next;
}ic_quad;
typedef struct ic_l{
  char* label_name;
  ic_quad* q;
  struct ic_l* next;
}ic_label;
typedef struct ic_quad_list{
  ic_quad* q;
  struct ic_quad_list* next;
}ic_ql;

extern ic_symbol* ic_symb_buff;
extern ic_label* label_buff;
extern ic_quad* q_buff;
extern int ic_n_temp;
extern int ic_label_n;
extern ic_symb_val true_val;
extern ic_symb_val false_val;

ic_symbol* ic_gen_temp_const(ic_symb_val val,typ_m type);
ic_symbol* ic_gen_temp(typ_m type);
//ic_symbol* ic_add_symb_s(char* str,int val,bool is_const);
ic_symbol* ic_lookup(char *str);
ic_quad* ic_symb_conv(ic_symbol* dest,ic_symbol* src);
void ic_add_symb(ic_symbol* next);
ic_quad* ic_quad_gen(ic_symbol* dest,ic_symbol* arg1,ic_symbol* arg2,ic_op op);
ic_quad* ic_quad_gen_g(char* dest,ic_symbol* arg1,ic_symbol* arg2,ic_op op);
ic_quad* ic_quad_gen_gl(ic_label *l,ic_symbol* arg1,ic_symbol* arg2,ic_op op);
ic_quad* ic_quad_concat(ic_quad* arg1,ic_quad *arg2);
void ic_quad_set_name(ic_quad* q,char* name);
ic_label* ic_new_label(char* name,ic_quad* q);
ic_label* ic_new_label_gen(ic_quad* q);
ic_label* ic_label_lookup(char* name);
void ic_label_set_code(ic_label* l,ic_quad* dest);
void ic_label_set_quad(ic_label* l,ic_quad* q);
//void ic_backpatch(ic_quad* q1,ic_quad* q2);
void ic_backpatch(ic_ql* ql,ic_label* l);
void ic_quad_replace_label(ic_quad* q,ic_label* old_label,ic_label* new_label);
void ic_print_table();
void ic_print_code(ic_quad* c);
ic_ql* ic_ql_new(ic_quad* q);
ic_ql* ic_ql_concat(ic_ql* q1,ic_ql* q2);

/*****************************************************************************************************
                                      var declaration
******************************************************************************************************/
// type of the value of a matrix
typedef struct {int m_nline;int m_ncol;float *val;}matrix_v;
// value of a variable
typedef union {int i_val;float f_val;matrix_v m_val;} val;
//contains info of the var
typedef struct {
    char *name;
    typ_m t_id;
    val v_id;
    ic_symbol* ic_var;
    int decl_line;
}id_s;
    
extern id_s glob_symb_buff[MAX_SYMB_SIZE];
extern int curr_glob_var_number;

int var_is_global(char *str);
int var_add_global(id_s v);
int var_is_declared(char *str);
id_s *var_lookup(char *str);
id_s *var_copy(id_s* arg);
id_s new_id_s(char *str,typ_m t,int line);
void var_print_table();

/*****************************************************************************************************
                               function declaration
******************************************************************************************************/
//typedef enum fd_typ{INT, FLOAT, MATRIX, VOID};

typedef struct fd_param{
  id_s* val;
  //typ_m param_typ;
  struct fd_param *next;
}fd_param;

typedef struct fd_id{
  //typ_m  fun_typ;
  char *name;
  fd_param* p;
  struct fd_id* next;
}fd_id;

//char* std_proc_name[3] = {"print", "printf", "printmat"};

fd_param* fd_new_param(char* id);
ic_quad* ic_quad_proc_gen(char* proc_name,id_s *first_param);

/*****************************************************************************************************
                               statement block
******************************************************************************************************/
// global level when BLOCK_LEVEL is 0
//extern int BLOCK_LEVEL;

/*****************************************************************************************************
                                 error information
******************************************************************************************************/
extern int src_line;

#endif
