/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

#ifndef YY_YY_ASIN_H_INCLUDED
# define YY_YY_ASIN_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    STRUCT_ = 258,
    READ_ = 259,
    PRINT_ = 260,
    IF_ = 261,
    ELSE_ = 262,
    WHILE_ = 263,
    TRUE_ = 264,
    FALSE_ = 265,
    INT_ = 266,
    BOOL_ = 267,
    PARA_ = 268,
    PARC_ = 269,
    MAS_ = 270,
    MENOS_ = 271,
    POR_ = 272,
    DIV_ = 273,
    ASIG_ = 274,
    MASASIG_ = 275,
    MENOSASIG_ = 276,
    PORASIG_ = 277,
    DIVASIG_ = 278,
    AND_ = 279,
    OR_ = 280,
    IGU_ = 281,
    DIF_ = 282,
    MAYOR_ = 283,
    MENOR_ = 284,
    MAYORIG_ = 285,
    MENORIG_ = 286,
    MOD_ = 287,
    NEG_ = 288,
    INCRE_ = 289,
    DECRE_ = 290,
    CORA_ = 291,
    CORC_ = 292,
    LLAVA_ = 293,
    LLAVC_ = 294,
    PCOMA_ = 295,
    PUNTO_ = 296,
    CTE_ = 297,
    ID_ = 298
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{
#line 11 "src/asin.y" /* yacc.c:1909  */

        char *ident;
        int cent;
        REG reg;
        EXP exp;

#line 105 "asin.h" /* yacc.c:1909  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_ASIN_H_INCLUDED  */
