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

%type <regi>  listaCampos
%type <exp> expresion expresionLogica expresionRelacional expresionAditiva  
%type <exp> expresionUnario expresionSufijaexpresionIgualdad expresionMultiplicativa

%%
/****************************************************************************/
/*                ESPECIFICACION SINTACTICA MENOSC                          */
/****************************************************************************/

/****************************************************************************/
programa
        : {dvar = 0;} LLAVA_ secuenciaSentencias LLAVC_         
                                {
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
                                                {
                                                        if($3.tipo != T_LOGICO){
                                                                yyerror("Error, tipo no lógico como condición en IF ELSE");
                                                        }
                                                }
        ;
/****************************************************************************/
instruccionIteracion
        :  WHILE_ PARA_ expresion PARC_ instruccion     
                                                {
                                                        if($3.tipo != T_LOGICO){
                                                                yyerror("Error, tipo no lógico como condición en IF ELSE");
                                                        }
                                                }
        ;
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
                                                {$$.tipo = $1.tipo; $$.pos = $1.pos;} //creo que .pos  no hace falta
        | expresionLogica operadorLogico expresionIgualdad
                                {
                                        $$.tipo = T_ERROR;
                                        if ($1.tipo != T_ERROR && $3.tipo != T_ERROR){
                                                if ($1.tipo != $3.tipo){
                                                        yyerror("No coinciden los tipos del operador lógico");
                                                } else if (!($1.tipo == T_LOGICO) ){
                                                        yyerror("Error de tipos en la igualdad");
                                                } else {
                                                        $$.tipo = T_LOGICO;
                                                }
                                        }
                                }

        ;
/****************************************************************************/
expresionIgualdad
        : expresionRelacional                   {$$.tipo = $1.tipo; $$.pos = $1.pos;} //creo que .pos no hace falta
        | expresionIgualdad operadorIgualdad expresionRelacional
                                {
                                        $$.tipo = T_ERROR;
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
        : expresionMultiplicativa {$$.tipo = $1.tipo;}
        | expresionAditiva operadorAditivo expresionMultiplicativa 
                { $$.tipo = T_ERROR;
                 if($3.tipo != T_ERROR && $1.tipo != T_ERROR){
                         if (!($1.tipo == T_ENTERO && $3.tipo == T_ENTERO)){
                                 yyerror("Los tipos de una operacion aditiva deben ser enteros");
                         }
                         else {$$.tipo = $1.tipo;}
                 }
                }
        ;
/****************************************************************************/
expresionMultiplicativa
        : expresionUnaria {$$.tipo = $1.tipo; $$.pos = $1.pos;}  //creo que .pos no hace falta 
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
        : expresionSufija      {$$.tipo = $1.tipo;} 
        | operadorUnario expresionUnaria {$$.tipo = $2.tipo;}
        | operadorIncremento ID_         {$$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($2);
                                        if (simb.tipo == T_ERROR){yyerror("Objeto no declarado")}
                                        else { if !(simb.tipo == T_RECORD || simb.tipo == T_ARRAY){ //DUDA!!!! 
                                                 $$.tipo = simb.tipo;
                                                }
                                               }
                                        }
        ;
/****************************************************************************/
expresionSufija
        : PARA_ expresion PARC_ {$$.tipo = $2.tipo;}
        | ID_ operadorIncremento {      $$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($1);
                                        if (simb.tipo == T_ERROR){yyerror("Objeto no declarado");}
                                        else{
                                                $$.tipo = $1.tipo;
                                        }
                        

        }
        | ID_ CORA_ expresion CORC_ {   $$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($1);
                                        if (simb.tipo == T_ERROR) {yyerror("Objeto no declarado);}
                                        else {
                                                if(simb.tipo == T_ARRAY){
                                                        if($3.tipo == T_ENTERO){
                                                                DIM arr = obtTdA(simb.ref);
                                                                if (arr.telem == T_ERROR) {yyerror("objeto array invalido");}
                                                                else {$$.tipo = arr.telem;}
                                                        }

                                                }else yyerror("objeto no de tipo array");
                                        }
                                 
                                     

                                }
        | ID_       {
                $$.tipo = T_ERROR;
                SIMB sim = obtTdS($1);
                if(sim.tipo == T_ERROR) {yyerror("Objeto no declarado");}
                else {
                        $$.tipo = sim.tipo;
                }

                }                    
        | ID_ PUNTO_ ID_  { $$.tipo = T_ERROR;
                            SIMB simb = obtTdS($1);
                            if (simb.tipo == T_ERROR) {yyerror("Objeto no declarado");}
                            else{
                                if (simb.tipo == T_RECORD){
                                        CAMP simb2 = obtTdR(simb.ref, $3);
                                        if (simb2.tipo == T_ERROR){yyerror("Nombre de registro invalido);}
                                        else{
                                                $$.tipo = simb2.tipo;
                                        }

                                }
                                else yyerror("objeto no de tipo registro");    
                            }


                        }              
        | constante   {$$.tipo = $1.tipo;}          
        ;
/****************************************************************************/
constante
        : CTE_         {$$.tipo = T_ENTERO; $$.pos = $1;} // Creo que las asignaciones de pos aqui no tienen sentido
        | TRUE_        {$$.tipo = T_LOGICO; $$.pos = 1;}
        | FALSE_       {$$.tipo = T_LOGICO; $$.pos = 0;} 
        ;
/****************************************************************************/
operadorAsignacion
        : ASIG_         {$$ =ASIG;}
        | MASASIG_      {$$ =MASASIG;}
        | MENOSASIG_    {$$ =MENOSASIG;}
        | PORASIG_      {$$ =PORASIG;}
        | DIVASIG_      {$$ =DIVASIG;}
        ;
/****************************************************************************/
operadorLogico
        : AND_          {$$ = AND;}
        | OR_           {$$ = OR;}
        ;
/****************************************************************************/
operadorIgualdad
        : IGU_          {$$ = IGU;}       
        | DIF_          {$$ = DIF;}       
        ;
/****************************************************************************/
operadorRelacional
        : MAYOR_        {$$ = MAYOR;}
        | MENOR_        {$$ = MENOR;}
        | MAYORIG_      {$$ = MAYORIG;}
        | MENORIG_      {$$ = MENORIG;}
        ;
/****************************************************************************/
operadorAditivo
        : MAS_          {$$ = MAS_UN;}
        | MENOS_        {$$ = MENOS_UN;}
        ;
/****************************************************************************/
operadorMultiplicativo
        : POR_          {$$ = POR;}      
        | DIV_          {$$ = DIV;}      
        | MOD_          {$$ = MOD;}      
        ;
/****************************************************************************/
operdorUnario
        : MAS_          {$$ = MAS_UN;}
        | MENOS_        {$$ = MENOS_UN;}
        | NEG_          {$$ = NEG_UN;}      
        ;
/****************************************************************************/
operadorIncremento
        : INCRE_        {$$ = INCRE;}
        | DECRE_        {$$ = DECRE;}
        ;
/****************************************************************************/
                
%%

