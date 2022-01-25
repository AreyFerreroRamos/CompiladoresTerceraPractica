/***************** ESPECIFICACIO LEX ***************/

/*

*/

/***************************************************/

%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <stdbool.h>
  #include <string.h> 

  #include "bison.tab.h"
  #include "functions.h"
  #include "utils.h"

  extern void yyerror(char *);
  bool assignFounded = false;
  bool corcheteOpenFounded = false;

  /* CONTROL FOR KNOW START MAIN */
  bool inMain = false;

  /* CONTROL FOR FUNCTION DEFINITION */
  bool inFunction = false;
  bool inHeader = false;
  bool inParams = false;
  bool idProcReaded = false;
  bool isReturnLine = false;
  bool isAction;

  /* CONTROL CALL FUNCTION */
  bool isFunctionCall = false;
  int numParenthesis = 0;
%}

%option yylineno
%option noyywrap

lletra	[a-zA-Z]
digit	[0-9]
id {lletra}({lletra}|{digit}|_({lletra}|{digit}))*


%%


({digit})+  {
                if(inFunction == false && inMain ==false){
                    emet(INSTR_START, 1, "main");
                    inMain=true;
                }
                debug("%s\n", yytext, 0);
                yylval.enter = atoi(yytext);
                return INTEGER;
            }

({digit})+"."({digit})+(e(-)?({digit})+)?   {
                                                if(inFunction == false && inMain ==false){
                                                    emet(INSTR_START, 1, "main");
                                                    inMain=true;
                                                }
                                                debug("%s\n", yytext, 0);
                                                yylval.real = atof(yytext);
                                                return FLOAT;
                                            }

(true|false)	{
                    debug("%s\n", yytext, 0);
                    yylval.cadena = strdup(yytext);
                    return BOOLEAN;
                }

(#(.)*|#=(.|\n)*=#) {
                        debug("COMMENT: %s\n", yytext, 0);
                    }

("/"|"%")   {
                debug("%s\n", yytext, 0);
                yylval.cadena = strdup(yytext);
                return OP_ARIT_P1;
            }

"*" {
		debug("%s\n", yytext, 0);
		yylval.cadena = strdup(yytext);
		return ASTERISCO;
	}

("+"|"-")   {
                debug("%s\n", yytext, 0);
                yylval.cadena = strdup(yytext);
                return OP_ARIT_P2;
            }

(">"|">="|"=="|"<="|"<"|"!=")	{
                                    debug("%s\n", yytext, 0);
                                    yylval.cadena = strdup(yytext);
                                    return OP_RELACIONAL;
                                }

"!"	{
		debug("%s\n", yytext, 0);
		return NEGACION;
	}

&&  {
        debug("%s\n", yytext, 0);
        return OP_BOOL_AND;
    }

"||"    {
            debug("%s\n", yytext, 0);
            return OP_BOOL_OR;
        }

"(" {
        debug("%s\n", yytext, 0);
        if (inHeader == true)
        {
            inParams = true;
        }
        else if (isFunctionCall == true)
        {
            numParenthesis++;
        }
		return PARENTESIS_ABIERTO;
	}

")" {
        debug("%s\n", yytext, 0);
        if (inHeader == true)
        {
            inHeader = false;
            inParams = false;
        }
        else if (isFunctionCall == true)
        {
            numParenthesis--;
            if (numParenthesis == 0)
            {
                isFunctionCall = false;
            }
        }
		return PARENTESIS_CERRADO;
	}

,	{
		debug("%s\n", yytext, 0);
		return COMA;
	}

"div("  {
            debug("%s\n", yytext, 0);
            return DIV;
        }

"=" {
		debug("%s\n", yytext, 0);
		assignFounded = true;
		return ASSIGN;
	}

"["	{
		debug("%s\n", yytext, 0);
		corcheteOpenFounded = true;
		return CORCHETE_ABIERTO;
	}

"]"	{
		debug("%s\n", yytext, 0);
		return CORCHETE_CERRADO;
	}

"{" {
        debug("%s\n", yytext, 0);
        return LLAVE_ABIERTA;
    }

"}" {
        debug("%s\n", yytext, 0);
        return LLAVE_CERRADA;
    }

;   {
		debug("%s\n", yytext, 0);
		return PUNTO_Y_COMA;
	}

::  {
        debug("%s\n", yytext, 0);
        if (inFunction == true && inParams == false)
        {
            isAction = false;
        }
        else
        {
            isAction = true;
        }
        return DOBLE_DOS_PUNTOS;
    }

"while" {
            debug("%s\n", yytext, 0);
            return WHILE;
        }

"function"  {
                debug("%s\n", yytext, 0);
                inFunction = true;
                inHeader = true;
                pushSymtab();
                return START;
            }

"return"    {
		        isReturnLine = true;
                if (isAction == true)
                {
                    debug("%s\n", yytext, 0);
                    return DIRECT_RETURN;
                }
                else
                {
                    debug("%s with action\n", yytext, 0);
                    return VALUE_RETURN;
                }
            }

"end"	{
            debug("%s\n", yytext, 0);
            inFunction = false;
            idProcReaded = false;
            return END;
        }

("Int32"|"Float64"|"String"|"Bool"|"Tensor")    {
                                                    debug("%s\n", yytext, 0);
                                                    yylval.cadena = strdup(yytext);
                                                    return TIPO;
                                                }

{id}	{
            if (strlen(yytext) > ID_MAX_LENGTH)
            {
                yyerror(generateString("ID -> %s demasiado largo.", 1, yytext));
            }
            if (inFunction == false && inMain == false)
            {
                emet(INSTR_START, 1, "main");
                inMain = true;
            }
            sym_value_type entry;
            int response = getEntryMessage(yytext, &entry);
            if ((response == SYMTAB_OK) && (isSameType(entry.entryType, FUNC_T)))
            {
                isFunctionCall = true;
                yylval.ident.lexema = strdup(yytext);
                yylval.ident.length = entry.size;
                yylval.ident.line = yylineno;
                if (entry.type == NULL)
                {
                    debug("ID ACC: %s\n", yytext, 0);
                    return ID_ACC;
                }
                else
                {
                    debug("ID FUNC: %s\n", yytext, 0);
                    return ID_FUNC;
                }
            }
            else
            {
                if (assignFounded == false && corcheteOpenFounded == false && isReturnLine == false && isFunctionCall == false && (inFunction == false || (inFunction == true && idProcReaded == true)))
                {
                    debug("ID POINTER: %s\n", yytext, 0);
                    yylval.ident.lexema = strdup(yytext);
                    yylval.ident.length = strlen(yytext);
                    yylval.ident.line = yylineno;
                    return ID;
                }
                else if (inHeader == true && idProcReaded == false)
                {
                    debug("ID PROC: %s\n", yytext, 0);
                    yylval.cadena = strdup(yytext);
                    idProcReaded = true;
                    return ID_PROC;
                }
                else
                {
                    debug("ID ARIT: %s\n", yytext, 0);
                    if (isSameType(entry.type, INT32_T) || isSameType(entry.type, FLOAT64_T))
                    {
                        yylval.valueInfo = createValueInfo(yytext, entry.type, entry.entryType);
                        return ID_ARIT;
                    }
                }
            }
        }

\n	{
		debug("%s\n", yytext, 0);
		assignFounded = false;
		corcheteOpenFounded = false;
		isReturnLine = false;
	}

.	{}


%%
