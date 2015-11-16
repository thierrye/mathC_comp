#ifndef TRAD_MATHC
#define TRAD_MATHC

#include "stdbool.h"

#define TYPE_NUMBER 3
#define MAX_SYMB_SIZE 100
#define MAX_IC_NUM 100

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
typedef struct ic_s{
  char* name;
  int val;
  bool is_const;
  struct ic_s* next;
}ic_int_symbol;
typedef enum{ASSIGN,IFZ_GOTO,GOTO,EQUAL,INFERIOR,PLUS,MULT,SKIP}ic_op;
typedef union {ic_int_symbol* dest_symb; char* dest_label;}ic_q_dest;
typedef struct ic_q{
  //ic_int_symbol* dest;
  char *q_name;//label : if NULL no label
  ic_q_dest* dest;
  ic_int_symbol* arg1;
  ic_int_symbol* arg2;
  ic_op op;
  struct ic_q* next;
}ic_quad;
typedef struct ic_l{
  char* label_name;
  ic_quad* q;
  struct ic_l* next;
}ic_label;

extern ic_int_symbol* ic_symb_buff;
extern ic_label* label_buff;
extern ic_quad* q_buff;
extern int ic_n_temp;
extern int ic_label_n;

ic_int_symbol* ic_gen_temp(int val);
ic_int_symbol* ic_add_symb_s(char* str,int val,bool is_const);
ic_int_symbol* ic_lookup(char *str);
void ic_add_symb(ic_int_symbol* next);
ic_quad* ic_quad_gen(ic_int_symbol* dest,ic_int_symbol* arg1,ic_int_symbol* arg2,ic_op op);
ic_quad* ic_quad_gen_g(char* dest,ic_int_symbol* arg1,ic_int_symbol* arg2,ic_op op);
ic_quad* ic_quad_gen_gl(ic_label *l,ic_int_symbol* arg1,ic_int_symbol* arg2,ic_op op);
ic_quad* ic_quad_concat(ic_quad* arg1,ic_quad *arg2);
void ic_quad_set_name(ic_quad* q,char* name);
ic_label* ic_new_label(char* name,ic_quad* q);
ic_label* ic_new_label_gen(ic_quad* q);
ic_label* ic_label_lookup(char* name);
void ic_label_set_code(ic_label* l,ic_quad* dest);
void ic_label_set_quad(ic_label* l,ic_quad* q);
void ic_backpatch(ic_quad* q1,ic_quad* q2);
void ic_print_table();
void ic_print_code(ic_quad* c);

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
    ic_int_symbol* ic_var;
    int decl_line;
}id_s;
    
extern id_s glob_symb_buff[MAX_SYMB_SIZE];
extern int curr_glob_var_number;

int var_is_global(char *str);
int var_add_global(id_s v);
int var_is_declared(char *str);
id_s *var_lookup(char *str);
id_s new_id_s(char *str,typ_m t,int line);
void var_print_table();

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
