%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "trad_mathC.h"
#include "tr_mathC.h"
  
int curr_glob_var_number;
id_s glob_symb_buff[MAX_SYMB_SIZE];
int src_line;
//char *type_buff[3] = {"int","float","matrix"};
%}

id_type_keyw        [a-zA-Z_][a-zA-Z_0-9]*
integer             [0-9]+


%%

[ \t]+    {
  /***************************************************************************************************/

}

\n      {
  /***************************************************************************************************/
  src_line++;
}

{id_type_keyw}     {
  /***************************************************************************************************/
  //keyword
  if(strcmp("if",yytext)==0)
    return IF;
  if(strcmp("else",yytext)==0)
    return ELSE;
  if(strcmp("while",yytext)==0)
    return WHILE;
  if(strcmp("for",yytext)==0)
    return FOR;
  //type
  if(l_istype(yytext))
    {
      //fprintf(stderr,"type :%s\n",yytext);
      yylval.typ_val.t = str_to_type_m(yytext);
      yylval.typ_val.line = src_line;
      return TYPE;
    }
  //id

  //fprintf(stderr,"id :%s\n",yytext);
  yylval.id_val.str_val = strdup(yytext);
  yylval.id_val.line = src_line;
  return ID;
}

{integer}      {
  /***************************************************************************************************/
  fprintf(stderr,"integer :%s \n",yytext);
  yylval.int_val = atoi(yytext);
  return CONST_VAL;

 }

[{};+/=*()!-]      {
  /***************************************************************************************************/
  //fprintf(stderr,"token :%s \n",yytext);
  return yytext[0];
}

==  {
  /***************************************************************************************************/
  return EQ;
}

\!=  {
  /***************************************************************************************************/
  fprintf(stderr,"lex : DIFF : %s \n",yytext);
  return DIFF;
}

'|''|'  {
  /***************************************************************************************************/
  return OR;
}

&&  {
  return AND;
}

.   {
  /***************************************************************************************************/
  //fprintf(stderr,"illegal char : %s\n",yytext);
  //  return ERROR;
}
  
