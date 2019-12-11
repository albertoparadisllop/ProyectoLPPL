/*****************************************************************************/
/**  GRUPO 1 ANALIZADOR SINTACTICO                          				**/
/*****************************************************************************/
%{
#include <stdio.h>
#include <string.h>
#include "header.h"
#include "libtds.h"
#include "libgci.h"
%}

%union {
        char *ident;
        int cent;
        REG regi;
        EXP exp;
        ITER iter;
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
        : {dvar = 0; si = 0;} LLAVA_ secuenciaSentencias LLAVC_         
                                {
                                        if(verTDS){
                                                verTdS();
                                        }
                                        emite(FIN,crArgNul(),crArgNul(),crArgNul());
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
                                                //FALTA ASIGNAR
						SIMB simb = obtTdS($2);
						emite(EASIG,crArgPos($4.pos),crArgNul(),crArgPos(simb.desp));
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
        : READ_ PARA_ ID_ PARC_ PCOMA_ { 
                                                SIMB simb = obtTdS($3);
                                                if(simb.tipo == T_ERROR){ yyerror (ERROR_VAR_NO_DECLARADA);}
                                                else {
                                                        if(simb.tipo != T_ENTERO){yyerror ("El argumento del Read debe ser entero");}
                                                }
                                                emite(EREAD,crArgNul(),crArgNul(),crArgPos(simb.desp));
                                        } 
        | PRINT_ PARA_ expresion PARC_ PCOMA_  { 
                                                        if ($3.tipo != T_ENTERO){
                                                                yyerror("El argumento del print debe ser un entero");}
                                                        
                                                        emite(EWRITE,crArgNul(),crArgNul(),crArgPos($3.pos));

                                              }
        ; 
/****************************************************************************/
instruccionSeleccion
        : IF_ PARA_ expresion PARC_ {
                                            if($3.tipo != T_LOGICO && $3.tipo != T_ERROR){
                                                    yyerror("Error, tipo no lógico como condición en IF ELSE");
                                            }
                                            $<iter>$.lf = creaLans(si);
                                            emite(EIGUAL,crArgPos($3.pos),crArgEnt(0),crArgEtq(-1));
                                    } 
                                    
                                    instruccion 

                                    {
                                            $<iter>$.fin = creaLans(si);
                                            emite(GOTOS,crArgNul(),crArgNul(),crArgEtq(-1));
                                            completaLans($<iter>$.lf,crArgEnt(si));
                                    }

                                    ELSE_ instruccion

                                    {
                                            completaLans($<iter>$.fin,crArgEnt(si));
                                    }
                                                
        ;
/****************************************************************************/
instruccionIteracion
        :  WHILE_ {$<iter>$.ini = si;} PARA_ expresion PARC_  
                                                {
                                                        if($4.tipo != T_LOGICO && $4.tipo != T_ERROR){
                                                                yyerror("Error, tipo no lógico como condición en WHILE");
                                                        }
                                                        
                                                        $<iter>$.lf = creaLans(si);
                                                        //Si $4 == false, salimos del bucle
                                                        emite(EIGUAL,crArgPos($4.pos),crArgEnt(0),crArgEtq(-1));
                                                } 

                                                instruccion   
                                                
                                                {
                                                        //Saltamos al principio del while
                                                        emite(GOTOS,crArgNul(),crArgNul(),crArgEtq($<iter>2.ini));
                                                        completaLans($<iter>$.lf,crArgEnt(si));

                                                }
                                                
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
                                                                        $$.tipo = $3.tipo;
									$$.pos = simb.desp;
	        							if(simb.tipo == T_ERROR){
	        								yyerror(ERROR_VAR_NO_DECLARADA);
	        							} else if(simb.tipo != $3.tipo) {
	        								yyerror("Tipo inconsistente en expresión de asignación");
	        							} else if( $2 == EASIG){
	        								//Asignar
	        								emite(EASIG,crArgPos($3.pos),crArgNul(),crArgPos(simb.desp));
										//emite(EASIG,crArgPos($3.pos),crArgNul(),crArgPos($$.pos));
	        							} else if($3.tipo != T_ENTERO){
	        								yyerror("Tipo no valido para asignacion con operación aritmética");
	        							} else { 
	        								emite($2,crArgPos(simb.desp),crArgPos($3.pos),crArgPos(simb.desp));
										//emite($2,crArgPos(simb.desp),crArgPos($3.pos),crArgPos($$.pos));
	        							}
	        						}
        						}
        | ID_ CORA_ expresion CORC_ operadorAsignacion expresion
        						{
        							$$.tipo = T_ERROR;
        							if($6.tipo != T_ERROR){
	        							SIMB simb = obtTdS($1);
                                                                        $$.tipo = $6.tipo;
									$$.pos = creaVarTemp();
	        							if(simb.tipo == T_ERROR){
	        								yyerror("Estructura no declarada");
	        							} else {
        									if(simb.tipo == T_ARRAY){
	        									DIM dim = obtTdA(simb.ref);
	        									if(dim.telem == T_ERROR){
	        										yyerror("Error de array");
				    							} else if($3.tipo != T_ENTERO){
				    								yyerror("Se debe acceder al array con un entero");
				    							} else if(dim.telem != $6.tipo) {
				    								yyerror("Tipo inconsistente en expresión de asignación");
				    							} else if( $5 == EASIG){
				    								emite(EVA,crArgPos(simb.desp),crArgPos($3.pos),crArgPos($6.pos));
												emite(EASIG,crArgPos($6.pos),crArgNul(),crArgPos($$.pos));
				    							} else { //COMPROBAMOS SI ESTA DECLARADA LA VARIABLE
				    								emite(EAV,crArgPos(simb.desp),crArgPos($3.pos),crArgPos($$.pos));
				    								emite($5,crArgPos($$.pos),crArgPos($6.pos),crArgPos($$.pos));
				    								emite(EVA,crArgPos(simb.desp),crArgPos($3.pos),crArgPos($$.pos));
				    							}
				    						} else {
				    							yyerror("Acceso vector sobre una variable no array");
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
											$$.tipo = $5.tipo;
											$$.pos = simb.desp+camp.desp;
	        									if(camp.tipo == T_ERROR){
	        										yyerror("Error campo no existente");
				    							} else if(camp.tipo != $5.tipo){
				    								yyerror("Inconsistencia de tipos en asignacion en campo");
				    							} else if( $4 == EASIG){
				    								emite(EASIG,crArgPos($5.pos),crArgNul(),crArgPos(simb.desp+camp.desp));
												//emite(EASIG,crArgPos($5.pos),crArgNul(),crArgPos($$.pos));
				    							} else if($5.tipo != T_ENTERO){
			        								yyerror("Tipo no valido para asignacion con operación aritmética");
			        							} else {
			        								emite($4,crArgPos(simb.desp+camp.desp),crArgPos($5.pos),crArgPos(simb.desp+camp.desp));
												//emite($4,crArgPos(simb.desp+camp.desp),crArgPos($5.pos),crArgPos($$.pos));
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
                                                {$$ = $1;}
        | expresionLogica operadorLogico expresionIgualdad
                                {
                                        $$.tipo = T_ERROR;
                                        if ($1.tipo != T_ERROR && $3.tipo != T_ERROR){
                                                if ($1.tipo != $3.tipo){
                                                        yyerror("No coinciden los tipos del operador lógico");
                                                } else if (!($1.tipo == T_LOGICO && $3.tipo == T_LOGICO) ){
                                                        yyerror("Error de tipos en expresión lógica");
                                                } else {
                                                        $$.tipo = T_LOGICO;
                                                }
                                        }

                                    $$.pos = creaVarTemp();
                                    if($2 == AND){
                                    	emite(EMULT,crArgPos($1.pos),crArgPos($3.pos),crArgPos($$.pos));
                                    } else {
                                    	emite(ESUM,crArgPos($1.pos),crArgPos($3.pos),crArgPos($$.pos));
                                    	emite(EMENEQ,crArgPos($$.pos),crArgEnt(1),crArgEtq(si+2));
                                    	emite(EASIG,crArgEnt(1),crArgNul(),crArgPos($$.pos));
                                    }

                                }

        ;
/****************************************************************************/
expresionIgualdad
        : expresionRelacional                   {$$ = $1;}
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

                                    $$.pos = creaVarTemp();

                                    emite(EASIG,crArgEnt(1),crArgNul(),crArgPos($$.pos));
					                emite($2,crArgPos($1.pos),crArgPos($3.pos),crArgEtq(si+2));
					                emite(EASIG,crArgEnt(0),crArgNul(),crArgPos($$.pos));

                                }
        ;
/****************************************************************************/
expresionRelacional
        : expresionAditiva			{$$ = $1;}
        | expresionRelacional operadorRelacional expresionAditiva
        		{ $$.tipo = T_ERROR;
                 if($3.tipo != T_ERROR && $1.tipo != T_ERROR){
                         if (!($1.tipo == T_ENTERO && $3.tipo == T_ENTERO)){
                                 yyerror("Los tipos de una operacion relacional deben ser enteros");
                         }
                         else {$$.tipo = T_LOGICO;}
                 }
            	$$.pos = creaVarTemp();

            	emite(EASIG,crArgEnt(1),crArgNul(),crArgPos($$.pos));
                emite($2,crArgPos($1.pos),crArgPos($3.pos),crArgEtq(si+2));
                emite(EASIG,crArgEnt(0),crArgNul(),crArgPos($$.pos));
            }
        ;
/****************************************************************************/
expresionAditiva
        : expresionMultiplicativa 	{$$ = $1;}
        | expresionAditiva operadorAditivo expresionMultiplicativa 
            { 
                $$.tipo = T_ERROR;
                if($3.tipo != T_ERROR && $1.tipo != T_ERROR){
                         if (!($1.tipo == T_ENTERO && $3.tipo == T_ENTERO)){
                            yyerror("Los tipos de una operacion aditiva deben ser enteros");
                         } else {
                         	$$.tipo = $1.tipo;
                         }
                }
                $$.pos = creaVarTemp();
                emite($2,crArgPos($1.pos),crArgPos($3.pos),crArgPos($$.pos));
            }
        ;
/****************************************************************************/
expresionMultiplicativa
        : expresionUnaria {$$ = $1;} 
        | expresionMultiplicativa operadorMultiplicativo expresionUnaria
                { $$.tipo = T_ERROR;
                  if($3.tipo != T_ERROR && $1.tipo != T_ERROR){
                        if (!($1.tipo == T_ENTERO && $3.tipo == T_ENTERO)){
                                    yyerror("Los tipos de una operacion multiplicativa deben de ser enteros");
                                } else {
                                    $$.tipo = $1.tipo;
                                }
                            }
                	$$.pos = creaVarTemp();
                	emite($2,crArgPos($1.pos),crArgPos($3.pos),crArgPos($$.pos));
                }
        ;
/****************************************************************************/
expresionUnaria
        : expresionSufija      {$$ = $1;} 
        | operadorUnario expresionUnaria 	{ 
        										$$.tipo = T_ERROR;
							                  	if($2.tipo != T_ERROR){
							                        if ($1 == EDIF && $2.tipo != T_LOGICO){
					                                    yyerror("Operador negación debe ser aplicado a tipo lógico");
					                                } else if (($1 == ESUM || $1 == ESIG)  && $2.tipo != T_ENTERO){
					                                    yyerror("Operador signo debe ser aplicado a tipo lógico");
					                                } else {
					                                	//Tipos estan bien
					                                    $$.tipo = $2.tipo;
					                                    $$.pos = creaVarTemp();
					                                    if($1 == ESUM){
					                                    	//Simbolo +
					                                    	emite($1,crArgPos($2.pos),crArgEnt(0),crArgPos($$.pos));
					                                    } else if($1 == ESIG){
					                                    	//Simbolo -
					                                    	emite($1,crArgPos($2.pos),crArgNul(),crArgPos($$.pos));
					                                    } else {
					                                    	//Simbolo !
					                                    	emite($1,crArgEnt(1),crArgPos($2.pos),crArgPos($$.pos));
					                                    }
					                                }
							                 	}
							                }


        | operadorIncremento ID_        {
        									$$.tipo = T_ERROR;
                                        	SIMB simb = obtTdS($2);
                                        	if (simb.tipo == T_ERROR){yyerror("Objeto no declarado");}
                                        	else if (simb.tipo == T_ENTERO){ 
                                                 	$$.tipo = simb.tipo;
                                                 	$$.pos = creaVarTemp();
                                                 	emite($1,crArgPos(simb.desp),crArgEnt(1),crArgPos(simb.desp));
                                                 	emite(EASIG,crArgPos(simb.desp),crArgNul(),crArgPos($$.pos));

                                                } else {
                                                	yyerror("Operacion unaria debe ser aplicada a un entero");
                                                }
                                        }
        ;
/****************************************************************************/
expresionSufija
        : PARA_ expresion PARC_ {$$ = $2;}
        | ID_ operadorIncremento {      $$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($1);
                                        if (simb.tipo != T_ENTERO){yyerror("Identificador debe ser entero");}
                                        else if (simb.tipo == T_ERROR){yyerror("Objeto no declarado");}
                                        else{
                                                $$.tipo = simb.tipo;
                                                $$.pos = creaVarTemp();

                                                emite(EASIG,crArgPos(simb.desp),crArgNul(),crArgPos($$.pos));
                                                emite($2,crArgPos(simb.desp),crArgEnt(1),crArgPos(simb.desp));

                                        }
                        

        }
        | ID_ CORA_ expresion CORC_ {   $$.tipo = T_ERROR;
                                        SIMB simb = obtTdS($1);
                                        if (simb.tipo == T_ERROR) {yyerror("Array no declarado");}
                                        else {
                                                if(simb.tipo == T_ARRAY){
                                                        if($3.tipo == T_ENTERO){
                                                                DIM arr = obtTdA(simb.ref);
                                                                if (arr.telem == T_ERROR) {yyerror("Array no declarado");}
                                                                else {
                                                                	$$.tipo = arr.telem;
                                                                	$$.pos = creaVarTemp();
                                                                	/*emite(EMULT,crArgPos($3.pos),crVarEnt(TALLA_TIPO_SIMPLE),crArgPos($3.pos));
                                                                	emite(ESUM,crVarEnt(simb.desp), crArgPos($3.pos),crArgPos($3.pos))
                                                                	emite(EASIG,crArgPos(),crArgNul(),crArgPos($$.pos));*/
                                                                	emite(EAV,crArgPos(simb.desp),crArgPos($3.pos),crArgPos($$.pos));
                                                                }
                                                        }

                                                }else yyerror("Variable no es un array");
                                        }
                                 
                                     

                                }
        | ID_       {
		                $$.tipo = T_ERROR;
		                SIMB sim = obtTdS($1);
		                if(sim.tipo == T_ERROR) {yyerror("Objeto no declarado");}
		                else {
		                        $$.tipo = sim.tipo;
		                        $$.pos = creaVarTemp();
		                        emite(EASIG,crArgPos(sim.desp),crArgNul(),crArgPos($$.pos));
		                }

                	}                    
        | ID_ PUNTO_ ID_  { $$.tipo = T_ERROR;
                            SIMB simb = obtTdS($1);
                            if (simb.tipo == T_ERROR) {yyerror("Estructura no declarado");}
                            else{
                                if (simb.tipo == T_RECORD){
                                        CAMP simb2 = obtTdR(simb.ref, $3);
                                        if (simb2.tipo == T_ERROR){yyerror("Nombre de registro invalido");}
                                        else{
                                                $$.tipo = simb2.tipo;
                                                $$.pos = creaVarTemp();

                                                //desplazamiento = simb2.desp
                                                emite(EASIG,crArgPos(simb.desp + simb2.desp),crArgNul(),crArgPos($$.pos));

                                        }

                                }
                                else {yyerror("Objeto no de tipo registro"); }  
                            }


                        }              
        | constante   	{
        					$$.tipo = $1.tipo;
        					$$.pos = $1.pos;
        				}          
        ;
/****************************************************************************/
constante
        : CTE_         	{
        					$$.tipo = T_ENTERO;
        					$$.pos = creaVarTemp();
        					emite(EASIG,crArgEnt($1),crArgNul(),crArgPos($$.pos));
        				}
        | TRUE_        	{
        					$$.tipo = T_LOGICO;
        					$$.pos = creaVarTemp();
        					emite(EASIG,crArgEnt(1),crArgNul(),crArgPos($$.pos));
        				}
        | FALSE_       	{
        					$$.tipo = T_LOGICO;
        					$$.pos = creaVarTemp();
        					emite(EASIG,crArgEnt(0),crArgNul(),crArgPos($$.pos));
        				} 
        ;
/****************************************************************************/
operadorAsignacion
        : ASIG_         {$$ = EASIG;}
        | MASASIG_      {$$ = ESUM;}
        | MENOSASIG_    {$$ = EDIF;}
        | PORASIG_      {$$ = EMULT;}
        | DIVASIG_      {$$ = EDIVI;}
        ;
/****************************************************************************/
operadorLogico
        : AND_          {$$ = AND;}
        | OR_           {$$ = OR;}
        ;
/****************************************************************************/
operadorIgualdad
        : IGU_          {$$ = EIGUAL;}       
        | DIF_          {$$ = EDIST;}       
        ;
/****************************************************************************/
operadorRelacional
        : MAYOR_        {$$ = EMAY;}
        | MENOR_        {$$ = EMEN;}
        | MAYORIG_      {$$ = EMAYEQ;}
        | MENORIG_      {$$ = EMENEQ;}
        ;
/****************************************************************************/
operadorAditivo
        : MAS_          {$$ = ESUM;}
        | MENOS_        {$$ = EDIF;}
        ;
/****************************************************************************/
operadorMultiplicativo
        : POR_          {$$ = EMULT;}      
        | DIV_          {$$ = EDIVI;}      
        | MOD_          {$$ = RESTO;}      
        ;
/****************************************************************************/
operadorUnario
        : MAS_          {$$ = ESUM;}
        | MENOS_        {$$ = ESIG;}
        | NEG_          {$$ = EDIF;}      
        ;
/****************************************************************************/
operadorIncremento
        : INCRE_        {$$ = ESUM;}
        | DECRE_        {$$ = EDIF;}
        ;
/****************************************************************************/
                
%%

