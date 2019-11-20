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

%type <cent> tipoSimple operadorUnario operadorMultiplicativo operadorAsignacion operadorIncremento operadorAditivo operadorRelacional operadorIgualdad  operadorLogico

%type <regi>  listaCampos
%type <exp> expresion expresionLogica expresionRelacional expresionAditiva constante
%type <exp> expresionUnaria expresionSufija expresionIgualdad expresionMultiplicativa

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
                                        if($1 != $4.tipo){
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
                                                yyerror("El argumento del print debe ser entero");}
                                              }
        ; 
/****************************************************************************/
instruccionSeleccion
        : IF_ PARA_ expresion PARC_ {
                                                        if($3.tipo != T_LOGICO && $3.tipo != T_ERROR){
                                                                yyerror("Error, tipo no lógico como condición en IF ELSE");
                                                        }
                                                } instruccion ELSE_ instruccion
                                                
        ;
/****************************************************************************/
instruccionIteracion
        :  WHILE_ PARA_ expresion PARC_ {
                                                        if($3.tipo != T_LOGICO && $3.tipo != T_ERROR){
                                                                yyerror("Error, tipo no lógico como condición en WHILE");
                                                        }
                                                } instruccion     
                                                
        ;
        ;
/****************************************************************************/
instruccionExpresion
        : expresion PCOMA_
        | PCOMA_
        ;
/****************************************************************************/
expresion
        : expresionLogica		{$$.tipo = $1.tipo; $$.pos = $1.pos;}
        | ID_ operadorAsignacion expresion 		
        						{
        							$$.tipo = T_ERROR;
        							if($3.tipo != T_ERROR){
	        							SIMB simb = obtTdS($1);
	        							if(simb.tipo == T_ERROR){
	        								yyerror("Variable no declarada");
	        							} else if(simb.tipo != $3.tipo) {
	        								yyerror("Tipo inconsistente en expresión de asignación");
	        							} else if( $2 == ASIG){
	        								//Asignar
	        							} else if($3.tipo != T_ENTERO){
	        								yyerror("Tipo no valido para asignacion con operación aritmética");
	        							} else if(1){ //COMPROBAMOS SI ESTA DECLARADA LA VARIABLE
	        								//switch para cada tipo de operadorAsignacion excepto ASIG
	        								switch($2){
	        									case MASASIG:
	        										//Asignar sumando
	        										break;
	        									case MENOSASIG:
	        										//Asignar restando
	        										break;
	        									case PORASIG:
	        										//Asignar multiplicando
	        										break;
	        									case DIVASIG:
	        										//Asignar dividiendo
	        										break;
	        								}
	        							} else {
	        								yyerror("Variable no inicializada");
	        							}
	        						}
        						}
        | ID_ CORA_ expresion CORC_ operadorAsignacion expresion
        						{
        							$$.tipo = T_ERROR;
        							if($6.tipo != T_ERROR){
	        							SIMB simb = obtTdS($1);
	        							if(simb.tipo == T_ERROR){
	        								yyerror("Estructura no declarada");
	        							} else {
        									if(simb.tipo == T_ARRAY){
	        									DIM dim = obtTdA(simb.ref);
	        									if(dim.telem == T_ERROR){
	        										yyerror("Error de array");
				    							} else if($3.tipo != T_ENTERO){
				    								yyerror("Se debe acceder al vector con un entero");
				    							} else if(dim.telem != $6.tipo) {
				    								yyerror("Tipo inconsistente en expresión de asignación");
				    							} else if( $5 == ASIG){
				    								//Asignar
				    							} else if(1){ //COMPROBAMOS SI ESTA DECLARADA LA VARIABLE
				    								//switch para cada tipo de operadorAsignacion excepto ASIG
				    								switch($5){
				    									case MASASIG:
				    										//Asignar sumando
				    										break;
				    									case MENOSASIG:
				    										//Asignar restando
				    										break;
				    									case PORASIG:
				    										//Asignar multiplicando
				    										break;
				    									case DIVASIG:
				    										//Asignar dividiendo
				    										break;
				    								}
				    							} else {
				    								yyerror("Variable no inicializada");
				    							}
				    						} else {
				    							yyerror("Acceso vector sobre una variable no vector");
				    						}
        								}
	        						}	
        						}
        | ID_ PUNTO_ ID_ operadorAsignacion expresion
        						{
        							$$.tipo = T_ERROR;
        							if($5.tipo != T_ERROR){
	        							SIMB simb = obtTdS($1);
	        							if(simb.tipo == T_ERROR){
	        								yyerror("Registro no declarado");
	        							} else {
        									if(simb.tipo == T_RECORD){
	        									CAMP camp = obtTdR(simb.ref,$3);
	        									if(camp.tipo == T_ERROR){
	        										yyerror("Error, campo no existente");
				    							} else if(camp.tipo != $5.tipo){
				    								yyerror("Inconsistencia de tipos en asignacion en campo");
				    							} else if( $4 == ASIG){
				    								//Asignar
				    							} else if($5.tipo != T_ENTERO){
			        								yyerror("Tipo no valido para asignacion con operación aritmética");
			        							} elseif(1){ //COMPROBAMOS SI ESTA DECLARADA LA VARIABLE
				    								//switch para cada tipo de operadorAsignacion excepto ASIG
				    								switch($4){
				    									case MASASIG:
				    										//Asignar sumando
				    										break;
				    									case MENOSASIG:
				    										//Asignar restando
				    										break;
				    									case PORASIG:
				    										//Asignar multiplicando
				    										break;
				    									case DIVASIG:
				    										//Asignar dividiendo
				    										break;
				    								}
				    							} else {
				    								yyerror("Variable no inicializada");
				    							}
				    						} else {
				    							yyerror("Acceso como estructura de una variable no estructura.");
				    						}
        								}
	        						}
        						}
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
                                                } else if (!($1.tipo == T_LOGICO && $3.tipo == T_LOGICO) ){
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
                                                } else if (!($1.tipo == $3.tipo && ($1.tipo == T_LOGICO || $1.tipo ==T_ENTERO)) ){
                                                        yyerror("Error de tipos en la igualdad");
                                                } else {
                                                        $$.tipo = T_LOGICO;
                                                }
                                        }
                                }
        ;
/****************************************************************************/
expresionRelacional
        : expresionAditiva			{$$.tipo = $1.tipo;}
        | expresionRelacional operadorRelacional expresionAditiva
        		{ $$.tipo = T_ERROR;
                 if($3.tipo != T_ERROR && $1.tipo != T_ERROR){
                         if (!($1.tipo == T_ENTERO && $3.tipo == T_ENTERO)){
                                 yyerror("Los tipos de una operacion relacional deben ser enteros");
                         }
                         else {$$.tipo = T_LOGICO;}
                 }
                }
        ;
/****************************************************************************/
expresionAditiva
        : expresionMultiplicativa 	{$$.tipo = $1.tipo;}
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
                }
        ;
/****************************************************************************/
expresionUnaria
        : expresionSufija      {$$.tipo = $1.tipo;} 
        | operadorUnario expresionUnaria {$$.tipo = $2.tipo;}
        | operadorIncremento ID_         {$$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($2);
                                        if (simb.tipo == T_ERROR){yyerror("Objeto no declarado");}
                                        else if (!(simb.tipo == T_RECORD || simb.tipo == T_ARRAY)){ 
                                        		//DUDA!!!! 
                                                 $$.tipo = simb.tipo;
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
                                                $$.tipo = simb.tipo;
                                        }
                        

        }
        | ID_ CORA_ expresion CORC_ {   $$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($1);
                                        if (simb.tipo == T_ERROR) {yyerror("Objeto no declarado");}
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
                                        if (simb2.tipo == T_ERROR){yyerror("Nombre de registro invalido");}
                                        else{
                                                $$.tipo = simb2.tipo;
                                        }

                                }
                                else {yyerror("objeto no de tipo registro"); }  
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
operadorUnario
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

