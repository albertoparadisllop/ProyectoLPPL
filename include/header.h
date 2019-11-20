/*****************************************************************************/
/**   Ejemplo de un posible fichero de cabeceras ("header.h") donde situar  **/
/** las definiciones de constantes, variables y estructuras para MenosC.20  **/
/** Los alumos deberan adaptarlo al desarrollo de su propio compilador.     **/ 
/*****************************************************************************/
#ifndef _HEADER_H
#define _HEADER_H

/***************************ERRORES*******************************************/
#define ERROR_ID_YA_DECLARADO           "Identificador ya declarado"
#define ERROR_CAMPO_YA_DECLARADO        "Campo ya declarado en la estructura"
#define ERROR_TALLA_ARRAY               "Talla del array incorrecta"
#define ERROR_TIPOS_DECLARACION         "Tipo inconsistente en declaración"
#define ERROR_VAR_NO_DECLARADA          "Identificador no declarado"
#define ERROR_VAR_NO_INI                "Variable no inicializada a un valor"

/****************************************************** Constantes generales */
#define TRUE  1
#define FALSE 0
/****************************************** Tallas asociadas a tipos simples */
#define TALLA_TIPO_SIMPLE 1

/****************************************** Operador Asignacion */
#define ASIG 0
#define MASASIG 1
#define MENOSASIG 2
#define PORASIG 3
#define DIVASIG 4

/****************************************** Operador Logico */
#define AND 0
#define OR 1

/****************************************** Operador Igualdad */
#define IGU 0
#define DIF 1

/****************************************** Operador Relacional */
#define MAYOR 0
#define MENOR 1
#define MAYORIG 2
#define MENORIG 3

/****************************************** Operador Unario */
#define MAS 0
#define MENOS 1

/****************************************** Operador Multiplicativo */
#define POR 0
#define DIV 1
#define MOD 2

/****************************************** Operador Unario */
#define MAS_UN 0
#define MENOS_UN 1
#define NEG_UN 2

/****************************************** Operador Incremento */
#define INCRE 0
#define DECRE 1



/************************************* Variables externas definidas en el AL */
extern int yylex();
extern int yyparse();


//
extern int verTDS;
//
extern int dvar;

extern FILE *yyin;                           /* Fichero de entrada           */
extern int   yylineno;                       /* Contador del numero de linea */
extern char *yytext;                         /* Patron detectado             */
/********* Funciones y variables externas definidas en el Programa Principal */
extern void yyerror(const char * msg) ;   /* Tratamiento de errores          */

extern int verbosidad;                   /* Flag si se desea una traza       */
extern int numErrores;              /* Contador del numero de errores        */

/************************************************ Struct para los registros */
typedef struct regi {
    int ref;
    int talla;
} REG;

/************************************************ Struct para las expresions */
typedef struct exp {
    int pos;
    int tipo;
} EXP;

#endif  /* _HEADER_H */
/*****************************************************************************/
