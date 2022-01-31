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

    /* CONTROL INICIO DEL MAIN */
  bool inMain = false;

    /* CONTROL PARA DEFINICIÓN DE FUNCIONES */
  bool inFunction = false;
  bool inHeader = false;
  bool inParams = false;
  bool idProcReaded = false;
  bool isReturnLine = false;
  bool isAction;

    /* CONTROL PARA LLAMADAS A FUNCIONES */
  bool isFunctionCall = false;
  int numParenthesis = 0;

    /* CONTROL EN ESTRUCTURA DE CONTROL DE FLUJO */
  bool inFlowControl = false;
%}

%option yylineno
%option noyywrap

lletra	[a-zA-Z]
digit	[0-9]
id {lletra}({lletra}|{digit}|_({lletra}|{digit}))*


%%


\n	{
		simpleDebug("\n\n", 0);
		assignFounded = false;
		corcheteOpenFounded = false;
		isReturnLine = false;
        inFlowControl = false;
	}

({digit})+  {
                if (inFunction == false && inMain == false)
                {
                    simpleDebug("START MAIN\n\n", 0);
                    emet(INSTR_START, 1, "main");
                    inMain = true;
                }
                simpleDebug("INTEGER ", 0);
                yylval.enter = atoi(yytext);
                return INTEGER;
            }

({digit})+"."({digit})+(e(-)?({digit})+)?   {
                                                if (inFunction == false && inMain == false)
                                                {
                                                    simpleDebug("START MAIN\n\n", 0);
                                                    emet(INSTR_START, 1, "main");
                                                    inMain = true;
                                                }
                                                simpleDebug("FLOAT ", 0);
                                                yylval.real = atof(yytext);
                                                return FLOAT;
                                            }

(true|false)	{
                    simpleDebug("BOOLEAN ", 0);
                    yylval.cadena = strdup(yytext);
                    return BOOLEAN;
                }

(#(.)*|#=(.|\n)*=#) {
                        simpleDebug("COMMENT ", 0);
                    }

("/"|"%")   {
                simpleDebug("OP_ARIT_P1 ", 0);
                yylval.cadena = strdup(yytext);
                return OP_ARIT_P1;
            }

"*" {
		simpleDebug("ASTERISCO ", 0);
		yylval.cadena = strdup(yytext);
		return ASTERISCO;
	}

("+"|"-")   {
                simpleDebug("OP_ARIT_P2 ", 0);
                yylval.cadena = strdup(yytext);
                return OP_ARIT_P2;
            }

(">"|">="|"=="|"<="|"<"|"!=")	{
                                    simpleDebug("OP_RELACIONAL ", 0);
                                    yylval.cadena = strdup(yytext);
                                    return OP_RELACIONAL;
                                }

"!"	{
        simpleDebug("NEGACION ", 0);
		return NEGACION;
	}

&&  {
        simpleDebug("OP_BOOL_AND ", 0);
        return OP_BOOL_AND;
    }

"||"    {
            simpleDebug("OP_BOOL_OR ", 0);
            return OP_BOOL_OR;
        }

"(" {
        simpleDebug("PARENTESIS_ABIERTO ", 0);
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
        simpleDebug("PARENTESIS_CERRADO ", 0);
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
		simpleDebug("COMA ", 0);
		return COMA;
	}

"=" {
		simpleDebug("ASSIGN ", 0);
		assignFounded = true;
		return ASSIGN;
	}

"["	{
		simpleDebug("CORCHETE_ABIERTO ", 0);
		corcheteOpenFounded = true;
		return CORCHETE_ABIERTO;
	}

"]"	{
		simpleDebug("CORCHETE_CERRADO ", 0);
		return CORCHETE_CERRADO;
	}

"{" {
        simpleDebug("LLAVE_ABIERTA ", 0);
        return LLAVE_ABIERTA;
    }

"}" {
        simpleDebug("LLAVE_CERRADA ", 0);
        return LLAVE_CERRADA;
    }

;   {
		simpleDebug("PUNTO_Y_COMA ", 0);
		return PUNTO_Y_COMA;
	}

:   {
        simpleDebug("DOS_PUNTOS ", 0);
        return DOS_PUNTOS;
    }

::  {
        simpleDebug("DOBLE_DOS_PUNTOS ", 0);
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

"if"    {
            simpleDebug("IF ", 0);
            inFlowControl = true;
            return IF;
        }

"elseif"    {
                simpleDebug("ELSEIF ", 0);
                inFlowControl = true;
                return ELSEIF;
            }

"else"  {
            simpleDebug("ELSE ", 0);
            return ELSE;
        }

"while" {
            simpleDebug("WHILE ", 0);
            inFlowControl = true;
            return WHILE;
        }

"for"   {
            simpleDebug("FOR ", 0);
            return FOR;
        }

"in"    {
            simpleDebug("IN ", 0);
            inFlowControl = true;
            return IN;
        }

"function"  {
                simpleDebug("START ", 0);
                inFunction = true;
                inHeader = true;
                pushSymtab();
                return START;
            }

"return"    {
		        isReturnLine = true;
                if (isAction == true)
                {
                    simpleDebug("DIRECT_RETURN ", 0);
                    return DIRECT_RETURN;
                }
                else
                {
                    simpleDebug("VALUE_RETURN ", 0);
                    return VALUE_RETURN;
                }
            }

"end"	{
            simpleDebug("END ", 0);
            inFunction = false;
            idProcReaded = false;
            return END;
        }

("Int32"|"Float64"|"String"|"Bool"|"Tensor")    {
                                                    simpleDebug("TIPO ", 0);
                                                    yylval.cadena = strdup(yytext);
                                                    return TIPO;
                                                }

{id}	{
            if (strlen(yytext) > ID_MAX_LENGTH)
            {
                yyerror(generateString("ID -> %s demasiado largo", 1, yytext));
            }
            if (inFunction == false && inMain == false)
            {
                simpleDebug("START MAIN\n\n", 0);
                emet(INSTR_START, 1, "main");
                inMain = true;
            }
            sym_value_type entry;
            int response = getEntryMessage(yytext, &entry);
            if ((response == SYMTAB_OK) && (isSameType(entry.entryType, FUNC_T)))
            {
                isFunctionCall = true;
                yylval.identInfo.lexema = strdup(yytext);
                yylval.identInfo.length = entry.size;
                yylval.identInfo.line = yylineno;
                if (entry.type == NULL)
                {
                    simpleDebug("ID_ACC ", 0);
                    return ID_ACC;
                }
                else
                {
                    simpleDebug("ID_FUNC ", 0);
                    return ID_FUNC;
                }
            }
            else
            {
                if (!assignFounded && !corcheteOpenFounded && !isReturnLine && !isFunctionCall && !inFlowControl && (!inFunction || (inFunction && idProcReaded)))
                {
                    simpleDebug("ID ", 0);
                    yylval.identInfo.lexema = strdup(yytext);
                    yylval.identInfo.length = strlen(yytext);
                    yylval.identInfo.line = yylineno;
                    return ID;
                }
                else if (inHeader == true && idProcReaded == false)
                {
                    simpleDebug("ID_PROC ", 0);
                    yylval.cadena = strdup(yytext);
                    idProcReaded = true;
                    return ID_PROC;
                }
                else
                {
                    simpleDebug("ID_ARIT ",0);
                    if (isSameType(entry.type, INT32_T) || isSameType(entry.type, FLOAT64_T))
                    {
                        yylval.valueInfo = createValueInfo(yytext, entry.type, entry.entryType);
                        return ID_ARIT;
                    }
                }
            }
        }

.	{}


%%