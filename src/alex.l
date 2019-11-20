/*****************************************************************************/
/**        GRUPO 1 ANALIZADOR LEXICO				                        **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "asin.h"

#define  retornar(x) {if (verbosidad) ECHO;return(x);}
%}
/*-----------------------------------------------------------------------------
  Estas opciones evitan "warnings" innecesarios y permiten obtener el
  numero de linea actual en la variable global "yylineno".
-----------------------------------------------------------------------------*/
%option noinput       
%option nounput       
%option yylineno  

delimitador     [ \t\n]+
digito         [0-9]
entero         {digito}+
real           ({digito}+\.?{digito}*)|(\.{digito}+)
letra          [a-zA-Z]
identificador  {letra}({letra}|{digito}|_)*
comentario     \/\/.*


%%

"+"	           { retornar (MAS_);   }
"-"            { retornar (MENOS_); }
"*"            { retornar (POR_);   }
"/"            { retornar (DIV_);   }
"("            { retornar (PARA_);  }
")"            { retornar (PARC_);  }
"="            { retornar (ASIG_);  }
"+="           { retornar (MASASIG_);}
"-="           { retornar (MENOSASIG_);}
"*="           { retornar (PORASIG_);}
"/="           { retornar (DIVASIG_);}
"&&"           { retornar (AND_);   }
"||"           { retornar (OR_);    }
"=="           { retornar (IGU_);   }
"!="           { retornar (DIF_);   }
">"            { retornar (MAYOR_); }
"<"            { retornar (MENOR_); }
">="           { retornar (MAYORIG_);}
"<="           { retornar (MENORIG_);}
"%"            { retornar (MOD_);   }
"!"            { retornar (NEG_);   }
"++"           { retornar (INCRE_); }
"--"           { retornar (DECRE_); }
"["            { retornar (CORA_);  }
"]"            { retornar (CORC_);  }
"{"            { retornar (LLAVA_); }
"}"            { retornar (LLAVC_); }
";"            { retornar (PCOMA_);}
"."            { retornar (PUNTO_); }
{comentario}   { if (verbosidad) ECHO;}
"struct"       { retornar (STRUCT_);}
"int"          { retornar (INT_);   }
"bool"         { retornar (BOOL_);  }
"read"         { retornar (READ_);  }
"print"        { retornar (PRINT_); }
"if"           { retornar (IF_);    }
"else"         { retornar (ELSE_);  }
"while"        { retornar (WHILE_); }
"true"         { retornar (TRUE_);  }
"false"        { retornar (FALSE_);  }
{identificador} { yylval.ident = strdup(yytext); retornar (ID_);   	}
{real}       	{ yylval.cent = atoi(yytext); 	retornar (CTE_);   	}
{delimitador}  	{ if (verbosidad) ECHO; }
.	       		{ /*if (verbosidad) printf("\nError [%d]: %s\n", yylineno, yytext);*/
					char str[100] = {0};
					strcat(strcat(strcat(str, "Caracter desconocido "), yytext),"\0");
					yyerror(str); 
				}

%%

