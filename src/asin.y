/*****************************************************************************/
/**  ANGEL ANDUJAR CARRACEDO ANALIZADOR SINTACTICO                          **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "libtds.h"
%}

%union {
        char *ident;
        int cent;
        REG regi;
        EXP exp;
}

/***************************PALABRAS ESPECIALES*******************************/
%token STRUCT_ READ_ PRINT_ IF_ ELSE_ WHILE_ TRUE_ FALSE_
%token <cent> INT_ BOOL_
/*****************************************************************************/

/**************************OPERACIONES***************************************/
%token PARA_ PARC_ MAS_ MENOS_ POR_ DIV_ ASIG_ MASASIG_ MENOSASIG_ PORASIG_
%token DIVASIG_ AND_ OR_ IGU_ DIF_ MAYOR_ MENOR_ MAYORIG_ MENORIG_ MOD_
%token NEG_ INCRE_ DECRE_
/****************************************************************************/

/**************************SEPARADORES***************************************/
%token CORA_ CORC_ LLAVA_ LLAVC_ PCOMA_ PUNTO_
/****************************************************************************/

/*************************ESPECIALES*****************************************/
%token <cent> CTE_ 
%token <ident> ID_
/****************************************************************************/

%type <cent> tipoSimple constante 

%type <reg>  listaCampos
%type <exp> expresion expresionLogica expresionRelacional expresionAditiva  
%type <exp> expresionUnario expresionSufijaexpresionIgualdad expresionMultiplicativa

%%
/****************************************************************************/
/*                ESPECIFICACION SINTACTICA MENOSC                          */
/****************************************************************************/

/****************************************************************************/
programa
        : {dvar = 0;} LLAVA_ secuenciaSentencias LLAVC_         {
                                                                        if(verTDS){
                                                                                verTdS();
                                                                        }
                                                                }
        ;
/****************************************************************************/
secuenciaSentencias
        : sentencia        
        | secuenciaSentencias sentencia
        ;
/****************************************************************************/
sentencia
        : declaracion
        | instruccion
        ;
/****************************************************************************/ 
declaracion
        : tipoSimple ID_ PCOMA_
                                {
                                        if(insTdS($2, $1, dvar, -1) == 0){
                                                //Ya se ha declarado
                                                yyerror(ERROR_ID_YA_DECLARADO);
                                        } else {
                                                dvar += TALLA_TIPO_SIMPLE;
                                        }
                                }
        | tipoSimple ID_ ASIG_ constante PCOMA_
                                {
                                        if($1 != $4){
                                                //Tipo declarado != tipo constante
                                                yyerror(ERROR_TIPOS_DECLARACION);
                                        } else if(insTdS($2, $1, dvar, -1) == 0){
                                                //Ya se ha declarado
                                                yyerror(ERROR_ID_YA_DECLARADO);
                                        } else {
                                                //Falta asignar
                                                dvar += TALLA_TIPO_SIMPLE;
                                        }
                                }
        | tipoSimple ID_ CORA_ CTE_ CORC_ PCOMA_
                                {

                                        

                                        if($4 <= 0){
                                                yyerror(ERROR_TALLA_ARRAY);
                                        } else{
                                                int ref = insTdA($1,$4);
                                                if(!insTdS($2,T_ARRAY,dvar,ref)){
                                                        yyerror(ERROR_ID_YA_DECLARADO);
                                                } else {
                                                        dvar += TALLA_TIPO_SIMPLE * $4;
                                                }
                                        }
                                }
        | STRUCT_ LLAVA_ listaCampos LLAVC_ ID_ PCOMA_
                                {
                                        if(!insTdS($5, T_RECORD, dvar, $3.ref)){
                                                //Fallo al insertar
                                                yyerror(ERROR_ID_YA_DECLARADO);
                                        }
                                        else{
                                                dvar += $3.talla;
                                        }

                                }
        ;
/****************************************************************************/
tipoSimple
        : INT_          {$$ = T_ENTERO;}
        | BOOL_         {$$ = T_LOGICO;}
        ;
/****************************************************************************/
listaCampos
        : tipoSimple ID_ PCOMA_ { 
                                        $$.ref = insTdR(-1,$2,$1,0);
                                        $$.talla = TALLA_TIPO_SIMPLE;
                                }
        | listaCampos tipoSimple ID_ PCOMA_ {
                                int ref = insTdR($1.ref,$3,$2,$1.talla);
                                if(ref == -1){ yyerror(ERROR_CAMPO_YA_DECLARADO);}
                                else{
                                        $$.ref = ref;
                                        $$.talla = $1.talla + TALLA_TIPO_SIMPLE;
                                }

                }
        ;
/****************************************************************************/
instruccion
        : LLAVA_ LLAVC_
        | LLAVA_ listaInstrucciones LLAVC_ 
        | instruccionEntradaSalida
        | instruccionSeleccion
        | instruccionIteracion
        | instruccionExpresion
        ;
/****************************************************************************/
listaInstrucciones
        : instruccion 
        | listaInstrucciones instruccion
        ;
/****************************************************************************/
instruccionEntradaSalida
        : READ_ PARA_ ID_ PARC_ PCOMA_ { SIMB simb = obtTdS($3);
                                         if(simb.tipo == T_ERROR){ yyerror ("no existe");}
                                         else {
                                                if(simb.tipo != T_ENTERO){yyerror ("El argumento del read debe ser entero");}
                                              }
                                        } 
        | PRINT_ PARA_ expresion PARC_ PCOMA_  { if ($3.tipo != T_ENTERO){
                                                yyerror("El argumento del print debe ser entero")}
                                              }
        ; 
/****************************************************************************/
instruccionSeleccion
        : IF_ PARA_ expresion PARC_ instruccion ELSE_ instruccion
        ;
/****************************************************************************/
instruccionIteracion
        :  WHILE_ PARA_ expresion PARC_ instruccion
        ;
/****************************************************************************/
instruccionExpresion
        : expresion PCOMA_
        | PCOMA_
        ;
/****************************************************************************/
expresion
        : expresionLogica
        | ID_ operadorAsignacion expresion
        | ID_ CORA_ expresion CORC_ operadorAsignacion expresion
        | ID_ PUNTO_ ID_ operadorAsignacion expresion
        ;
/****************************************************************************/
expresionLogica
        : expresionIgualdad
        | expresionLogica operadorLogico expresionIgualdad
        ;
/****************************************************************************/
expresionIgualdad
        : expresionRelacional {$$.tipo = $1.tipo; $$.pos = $1.pos;}
        | expresionIgualdad operadorIgualdad expresionRelacional
                {$$.tipo = T_ERROR;
                if ($1.tipo != T_ERROR && $3.tipo != T_ERROR){
                        if ($1.tipo != $3.tipo){
                                yyerror("No coinciden los tipos de la igualdad");
                        } else if (!($1.tipo == T_LOGICO || $1.tipo == T_ENTERO) ){
                                yyerror("Error de tipos en la igualdad");
                               } else {
                                        $$.tipo = T_LOGICO;
                                        }
                                 }
           }
        ;
/****************************************************************************/
expresionRelacional
        : expresionAditiva
        | expresionRelacional operadorRelacional expresionAditiva
        ;
/****************************************************************************/
expresionAditiva
        : expresionMultiplicativa
        | expresionAditiva operadorAditivo expresionMultiplicativa
        ;
/****************************************************************************/
expresionMultiplicativa
        : expresionUnaria {$$.tipo = $1.tipo; $$.pos = $1.pos;}   
        | expresionMultiplicativa operadorMultiplicativo expresionUnaria
                { $$.tipo = T_ERROR;
                  if($3.tipo != T_ERROR && $1.tipo != T_ERROR){
                        if (!($1.tipo == T_ENTERO && $3.tipo == T_ENTERO)){
                                    yyerror("Los tipos de una operacion multiplicativa deben de ser enteros");
                                } else {
                                    $$.tipo = $1.tipo;
                                }
                            }
        ;
/****************************************************************************/
expresionUnaria
        : expresionSufija       
        | operdorUnario expresionUnaria
        | operadorIncremento ID_
        ;
/****************************************************************************/
expresionSufija
        : PARA_ expresion PARC_
        | ID_ operadorIncremento
        | ID_ CORA_ expresion CORC_ 
        | ID_                           
        | ID_ PUNTO_ ID_                
        | constante                     
        ;
/****************************************************************************/
constante
        : CTE_         {$$.tipo = T_ENTERO; $$.pos = $1;} 
        | TRUE_        {$$.tipo = T_LOGICO; $$.pos = 1;}
        | FALSE_       {$$.tipo = T_LOGICO; $$.pos = 0;} 
        ;
/****************************************************************************/
operadorAsignacion
        : ASIG_         
        | MASASIG_      
        | MENOSASIG_    
        | PORASIG_      
        | DIVASIG_      
        ;
/****************************************************************************/
operadorLogico
        : AND_          
        | OR_           
        ;
/****************************************************************************/
operadorIgualdad
        : IGU_   {$$ = IGU;}       
        | DIF_   {$$ = DIF;}       
        ;
/****************************************************************************/
operadorRelacional
        : MAYOR_        
        | MENOR_        
        | MAYORIG_      
        | MENORIG_      
        ;
/****************************************************************************/
operadorAditivo
        : MAS_          
        | MENOS_        
        ;
/****************************************************************************/
operadorMultiplicativo
        : POR_    {$$ = POR;}      
        | DIV_    {$$ = DIV;}      
        | MOD_    {$$ = MOD;}      
        ;
/****************************************************************************/
operdorUnario
        : MAS_          
        | MENOS_        
        | NEG_          
        ;
/****************************************************************************/
operadorIncremento
        : INCRE_        
        | DECRE_        
        ;
/****************************************************************************/
                
%%

