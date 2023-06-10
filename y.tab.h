/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

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

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_Y_TAB_H_INCLUDED
# define YY_YY_Y_TAB_H_INCLUDED
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
    VAR = 258,
    NEWLINE = 259,
    NOT = 260,
    INT = 261,
    FLOAT = 262,
    BOOL = 263,
    STRING = 264,
    INC = 265,
    DEC = 266,
    GEQ = 267,
    LOR = 268,
    LAND = 269,
    EQL = 270,
    NEQ = 271,
    GTR = 272,
    LSS = 273,
    LEQ = 274,
    ADD = 275,
    SUB = 276,
    MUL = 277,
    QUO = 278,
    REM = 279,
    ASSIGN = 280,
    ADD_ASSIGN = 281,
    SUB_ASSIGN = 282,
    MUL_ASSIGN = 283,
    QUO_ASSIGN = 284,
    REM_ASSIGN = 285,
    IF = 286,
    ELSE = 287,
    FOR = 288,
    SWITCH = 289,
    CASE = 290,
    PRINT = 291,
    PRINTLN = 292,
    PACKAGE = 293,
    FUNC = 294,
    DEFAULT = 295,
    RETURN = 296,
    INT_LIT = 297,
    FLOAT_LIT = 298,
    STRING_LIT = 299,
    IDENT = 300,
    TRUE = 301,
    FALSE = 302
  };
#endif
/* Tokens.  */
#define VAR 258
#define NEWLINE 259
#define NOT 260
#define INT 261
#define FLOAT 262
#define BOOL 263
#define STRING 264
#define INC 265
#define DEC 266
#define GEQ 267
#define LOR 268
#define LAND 269
#define EQL 270
#define NEQ 271
#define GTR 272
#define LSS 273
#define LEQ 274
#define ADD 275
#define SUB 276
#define MUL 277
#define QUO 278
#define REM 279
#define ASSIGN 280
#define ADD_ASSIGN 281
#define SUB_ASSIGN 282
#define MUL_ASSIGN 283
#define QUO_ASSIGN 284
#define REM_ASSIGN 285
#define IF 286
#define ELSE 287
#define FOR 288
#define SWITCH 289
#define CASE 290
#define PRINT 291
#define PRINTLN 292
#define PACKAGE 293
#define FUNC 294
#define DEFAULT 295
#define RETURN 296
#define INT_LIT 297
#define FLOAT_LIT 298
#define STRING_LIT 299
#define IDENT 300
#define TRUE 301
#define FALSE 302

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 82 "compiler_hw3.y"

    int i_val;
    bool b_val;
    float f_val;
    char *s_val;

#line 158 "y.tab.h"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_H_INCLUDED  */
