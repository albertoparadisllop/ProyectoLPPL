/*****************************************************************************/
/**  ANGEL ANDUJAR CARRACEDO ANALIZADOR SINTACTICO                          **/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
%}

%union {
        char *ident;
        int cent;
        REG reg;
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

/*ALBERTO********************************************************************/
programa
        : {dvar = 0;} LLAVA_ secuenciaSentencias LLAVC_         {
                                                                        if(verTDS){
                                                                                verTdS();
                                                                        }
                                                                }
        ;
/*RAQUEL*********************************************************************/
secuenciaSentencias
        : sentencia        
        | secuenciaSentencias sentencia
        ;
/*ANGEL**********************************************************************/
sentencia
        : declaracion
        | instruccion
        ;
/*ALBERTO********************************************************************/ 
declaracion
        : tipoSimple ID_ PCOMA_
                                {
                                        if(insTdS($2, $1, dvar, -1) == 0){
                                                //Ya se ha declarado
                                                yyerror("Declaracion repetida");
                                        } else {
                                                dvar += TALLA_TIPO_SIMPLE;
                                        }
                                }
        | tipoSimple ID_ ASIG_ constante PCOMA_
                                {
                                        if($1 != $4){
                                                //Tipo declarado != tipo constante
                                                yyerror("Tipo inconsistente");
                                        } else if(insTdS($2, $1, dvar, -1) == 0){
                                                //Ya se ha declarado
                                                yyerror("Declaracion repetida");
                                        } else {
                                                //Falta asignar
                                                dvar += TALLA_TIPO_SIMPLE;
                                        }
                                }
        | tipoSimple ID_ CORA_ CTE_ CORC_ PCOMA_
                                {

                                        

                                        if($4 <= 0){
                                                yyerror("Error al definir talla del array");
                                        } else{
                                                int ref = insTdA($1,$4);
                                                if(!insTdS($2,T_ARRAY,dvar,ref)){
                                                        yyerror("Declaracion array repetida");
                                                } else {
                                                        dvar += TALLA_TIPO_SIMPLE * $4;
                                                }
                                        }
                                }
        | STRUCT_ LLAVA_ listaCampos LLAVC_ ID_ PCOMA_
                                {
                                        if(!insTdS($5, T_RECORD, dvar, $3.ref)){
                                                //Fallo al insertar
                                                yyerror("Struct ya definida");
                                        }
                                        else{
                                                dvar += $3.talla;
                                        }

                                }
        ;
/*RAQUEL*********************************************************************/
tipoSimple
        : INT_          {$$ = T_ENTERO;}
        | BOOL_         {$$ = T_LOGICO;}
        ;
/*ANGEL**********************************************************************/
listaCampos
        : tipoSimple ID_ PCOMA_ { 
                                $$.ref = insTdR(-1,$2,$1,0);
                                $$.talla = TALLA_TIPO_SIMPLE;
                    }
        }
        | listaCampos tipoSimple ID_ PCOMA_ {
                                int ref = insTdR($1.ref,$3,$2,$1.talla);
                                if(ref == -1){ yyerror("ID ya existente");}
                                else{
                                        $$.ref = ref;
                                        $$.talla = $1.talla + TALLA_TIPO_SIMPLE;
                                }

                }
        ;
/*ALBERTO********************************************************************/
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
        | PRINT_ PARA_ expresion PARC_ PCOMA_ { if ($3.tipo != T_ENTERO){
                                                yyerror("El argumento del read debe ser entero")}

                                              }
        ; 
/*ALBERTO********************************************************************/
instruccionSeleccion
        : IF_ PARA_ expresion PARC_ instruccion ELSE_ instruccion
        ;
/*RAQUEL*********************************************************************/
instruccionIteracion
        :  WHILE_ PARA_ expresion PARC_ instruccion
        ;
/*ANGEL**********************************************************************/
instruccionExpresion
        : expresion PCOMA_
        | PCOMA_
        ;
/*ALBERTO********************************************************************/
expresion
        : expresionLogica
        | ID_ operadorAsignacion expresion
        | ID_ CORA_ expresion CORC_ operadorAsignacion expresion
        | ID_ PUNTO_ ID_ operadorAsignacion expresion
        ;
/*RAQUEL*********************************************************************/
expresionLogica
        : expresionIgualdad
        | expresionLogica operadorLogico expresionIgualdad
        ;
/*ANGEL**********************************************************************/
/************************creo que en valor en vez de false deberia poner 0 y en true 1 ...****************************************************/
expresionIgualdad
        : expresionRelacional {$$.tipo = $1.tipo; $$.valor = $1.valor;}
        | expresionIgualdad operadorIgualdad expresionRelacional
            {$$.tipo = T_ERROR;
                if ($1.tipo != T_ERROR && $3.tipo != T_ERROR){
                        if ($1.tipo != $3.tipo){
                                yyerror("No coinciden los tipos de la igualdad");
                        } else if ($1.tipo == T_ARRAY){
                                yyerror("No se puede hacer igualdad para arrays");
                               } else {
                                        $$.tipo = T_LOGICO;
                                        if($2 == IGU){
                                                if($1.valor == $3.valor){$$.valor = TRUE;}
                                                else{$$.valor = FALSE;}
                                        }else if($2 == DIF){
                                                if($1.valor != $3.valor){$$.valor = TRUE;}
                                                else{$$.valor = FALSE;}
                                        }
                                 }
           }}
        ;
/*ALBERTO********************************************************************/
expresionRelacional
        : expresionAditiva
        | expresionRelacional operadorRelacional expresionAditiva
        ;
/*RAQUEL*********************************************************************/
expresionAditiva
        : expresionMultiplicativa
        | expresionAditiva operadorAditivo expresionMultiplicativa
        ;
/*ANGEL**********************************************************************/
expresionMultiplicativa
        : expresionUnaria       {$$.tipo = $1.tipo; $$.valor = $1.valor;}
        | expresionMultiplicativa operadorMultiplicativo expresionUnaria
          {$$.tipo = T_ERROR;
           if($1.tipo != T_ERROR && $3.tipo != T_ERROR){
                   if ( $1.tipo != T_ENTERO || $3.tipo != T_ENTERO){
                           yyerror("Los tipos de una operacion multiplicativa deben de ser enteros")
                        }else{
                                   $$.tipo = T_ENTERO;
                                   if($2 == DIV){
                                           if($3.valor == 0){$$.tipo =T_ERROR; yyerror("NO se puede dividir entre 0");}
                                           else{$$.valor = $1.valor / $3.valor;}
                                   }else if($2 == POR){$$.valor = $1.valor * $3.valor;}
                                         else if($2 == MOD){
                                                 if($3.valor == 0){$$.tipo = T_ERROR; yyerror("No se puede hacer modulo entre 0");}
                                                 else {$$.valor = $1.valor % $3.valor;}
                                         }
                                }
                }
          }
        ;
/*ALBERTO********************************************************************/
expresionUnaria
        : expresionSufija       {$$.tipo = $1.tipo; $$.valor = $1.valor;}
        | operdorUnario expresionUnaria
        | operadorIncremento ID_
        ;
/*RAQUEL*********************************************************************/
expresionSufija
        : PARA_ expresion PARC_
        | ID_ operadorIncremento
        | ID_ CORA_ expresion CORC_ 
        | ID_                           {
                                                SIMB var = obtTds($1);
                                                $$.tipo = T_ERROR;
                                                if(var.tipo == T_ERROR){
                                                        yyerror();
                                                } else if(var.tipo == T_ARRAY) {
                                                        yyerror();
                                                } else {
                                                        $$.tipo = var.tipo;
                                                }
                                        }
        | ID_ PUNTO_ ID_                {
                                                SIMB var = obtTds($1);
                                                CAMP var2 = obtTdR($3);
                                                $$.tipo = T_ERROR;
                                                if(var.tipo != T_RECORD){
                                                        yyerror();
                                                } else if(var2.tipo == T_ERROR){
                                                        yyerror();
                                                } else {
                                                        $$.tipo = var2.tipo;
                                                }
        | constante                     {$$.val = $1.val;       $$.tipo = $1.tipo;}
        ;
/*ANGEL**********************************************************************/
constante
        : CTE_          {$$.val = $<cent>1;     $$.tipo = T_ENTERO;}
        | TRUE_         {$$.val = TRUE;         $$.tipo = T_LOGICO;}
        | FALSE_        {$$.val = FALSE;        $$.tipo = T_LOGICO;}
        ;
/*ALBERTO********************************************************************/
operadorAsignacion
        : ASIG_         {$$ = ASIG;}
        | MASASIG_      {$$ = MASASIG;}
        | MENOSASIG_    {$$ = MENOSASIG;}
        | PORASIG_      {$$ = PORASIG;}
        | DIVASIG_      {$$ = DIVASIG;}
        ;
/*RAQUEL*********************************************************************/
operadorLogico
        : AND_          {$$ = AND;}
        | OR_           {$$ = OR;}
        ;
/*ANGEL**********************************************************************/
operadorIgualdad
        : IGU_          {$$ = IGU;}
        | DIF_          {$$ = DIF;}
        ;
/*ALBERTO********************************************************************/
operadorRelacional
        : MAYOR_        {$$ = MAYOR;}
        | MENOR_        {$$ = MENOR;}
        | MAYORIG_      {$$ = MAYORIG;}
        | MENORIG_      {$$ = MENORIG;}
        ;
/*RAQUEL*********************************************************************/
operadorAditivo
        : MAS_          {$$ = MAS;}
        | MENOS_        {$$ = MENOS;}
        ;
/*ANGEL**********************************************************************/
operadorMultiplicativo
        : POR_          {$$ = POR;}
        | DIV_          {$$ = DIV;}
        | MOD_          {$$ = MOD;}
        ;
/*ALBERTO********************************************************************/
operdorUnario
        : MAS_          {$$ = MAS_UN;}
        | MENOS_        {$$ = MENOS_UN;}
        | NEG_          {$$ = NEG_UN;}
        ;
/*RAQUEL*********************************************************************/
operadorIncremento
        : INCRE_        {$$ = INCRE;}
        | DECRE_        {$$ = DECRE;}
        ;
/****************************************************************************/
                
%%

