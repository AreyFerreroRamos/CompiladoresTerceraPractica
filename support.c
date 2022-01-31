#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "support.h"

extern int yyparse();

extern FILE *yyin;
extern FILE *yyout;
extern int lengthCode;
extern char **c3a;

/*-------------------------EMET FUNCTIONS----------------------------*/

char *emetReturn(char *var)
{
    char *instr;
    if (var == NULL)
    {
        instr = strdup(INSTR_RETURN);
    }
    else
    {
        instr = generateString("RETURN %s", 1, var);
    }
    return instr;
}


/*-------------------------------------------------------------------*/

void printCode3Adresses()
{
    printf("---------------------------------\n");
    for (int i = 0; i < lengthCode; i++)
    {
        printf("%i\t%s\n", i, c3a[i]);
        fprintf(yyout, "%i\t%s\n", i, c3a[i]);
    }
    printf("---------------------------------\n");
}

void intOperations(int num1, int num2, char *operand, int *res)
{
    if (isSameType(operand, OP_ARIT_SUMA))
    {
        *res = num1 + num2;
    }
    else if (isSameType(operand, OP_ARIT_RESTA))
    {
        *res = num1 - num2;
    }
    else if (isSameType(operand, OP_ARIT_MULT))
    {
        *res = num1 * num2;
    }
    else if (isSameType(operand, OP_ARIT_DIV))
    {
        if (num2 != 0)
        {
            *res = num1 / num2;
        }
        else
        {
            yyerror("No esta permitido dividir por 0");
        }
    }
    else if (isSameType(operand, OP_ARIT_MOD))
    {
        if (num2 != 0)
        {
            *res = num1 % num2;
        }
        else
        {
            yyerror("No esta permitido dividir por 0");
        }
    }
}

void floatOperations(float num1, float num2, char *operand, float *res)
{
    if (isSameType(operand, OP_ARIT_SUMA))
    {
        *res = num1 + num2;
    }
    else if (isSameType(operand, OP_ARIT_RESTA))
    {
        *res = num1 - num2;
    }
    else if (isSameType(operand, OP_ARIT_MULT))
    {
        *res = num1 * num2;
    }
    else if (isSameType(operand, OP_ARIT_DIV))
    {
        if (num2 != 0)
        {
            *res = num1 / num2;
        }
        else
        {
            yyerror("No esta permitido dividir por 0");
        }
    }
}

int intRelationalOperations(int num1, char *op, int num2)
{
    if (isSameType(op, OP_REL_HIGH))
    {
        return num1 > num2;
    }
    if (isSameType(op, OP_REL_HE))
    {
        return num1 >= num2;
    }
    if (isSameType(op, OP_REL_LESS))
    {
        return num1 < num2;
    }
    if (isSameType(op, OP_REL_LE))
    {
        return num1 <= num2;
    }
    if (isSameType(op, OP_REL_EQUAL))
    {
        return num1 == num2;
    }
    if (isSameType(op, OP_REL_DIFF))
    {
        return num1 != num2;
    }
}

int floatRelationalOperations(float num1, char *op, float num2)
{
    if (isSameType(op, OP_REL_HIGH))
    {
        return num1 > num2;
    }
    if (isSameType(op, OP_REL_HE))
    {
        return num1 >= num2;
    }
    if (isSameType(op, OP_REL_LESS))
    {
        return num1 < num2;
    }
    if (isSameType(op, OP_REL_LE))
    {
        return num1 <= num2;
    }
    if (isSameType(op, OP_REL_EQUAL))
    {
        return num1 == num2;
    }
    if (isSameType(op, OP_REL_DIFF))
    {
        return num1 != num2;
    }
}

/* FUNCIONES BASE PARA EJECUCIÓN DEL COMPILADOR */

int init_analisi_lexic(char *file_name)
{
    int error;
    yyin = fopen(file_name, "r");
    if (yyin == NULL)
    {
        error = EXIT_FAILURE;
    }
    else
    {
        error = EXIT_SUCCESS;
    }
    return error;
}

int init_analisi_sintactic(char *filename)
{
    int error = EXIT_SUCCESS;
    yyout = fopen(filename, "w");
    if (yyout == NULL)
    {
        error = EXIT_FAILURE;
    }
    return error;
}

int analisi_semantic()
{
    int error;
    if (yyparse() == 0)
    {
        error = EXIT_SUCCESS;
    }
    else
    {
        error = EXIT_FAILURE;
    }
    return error;
}

int end_analisi_lexic()
{
    int error;
    error = fclose(yyin);
    if (error == 0)
    {
        error = EXIT_SUCCESS;
    }
    else
    {
        error = EXIT_FAILURE;
    }
    return error;
}

int end_analisi_sintactic()
{
    int error;
    error = fclose(yyout);
    if (error == 0)
    {
        error = EXIT_SUCCESS;
    }
    else
    {
        error = EXIT_FAILURE;
    }
    return error;
}