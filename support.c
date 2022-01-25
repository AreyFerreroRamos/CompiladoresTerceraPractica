#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "support.h"

extern int yyparse();

extern FILE *yyin;
extern FILE *yyout;
extern int lengthCode;
extern char **c3a;

//-------------------------EMET FUNCTIONS----------------------------

char *emetReturn(char *var) {
    char *instr;
    if (var == NULL) {
        instr = strdup(INSTR_RETURN);
    } else {
        instr = generateString("RETURN %s", 1, var);
    }
    return instr;
}


//-------------------------------------------------------------------

void printCode3Adresses() {
    printf("---------------------------------\n");
    for (int i = 0; i < lengthCode; i++) {
        printf("%s\n", c3a[i]);
        fprintf(yyout, "%s\n", c3a[i]);
    }
    printf("---------------------------------\n");
}

void intOperations(int num1, int num2, char *operand, int *res) {
    if (strcmp(operand, OP_ARIT_SUMA) == 0) {
        simpleDebug("Estoy en suma.\n", 1);
        *res = num1 + num2;
    } else if (strcmp(operand, OP_ARIT_RESTA) == 0) {
        simpleDebug("Estoy en resta.\n", 1);
        *res = num1 - num2;
    } else if (strcmp(operand, OP_ARIT_MULT) == 0) {
        simpleDebug("Estoy en producto.\n", 1);
        *res = num1 * num2;
    } else if (strcmp(operand, OP_ARIT_DIV) == 0) {
        simpleDebug("Estoy en division.\n", 1);
        if (num2 != 0) {
            *res = num1 / num2;
        } else {
            yyerror("No esta permitido dividir por 0.");
        }
    } else if (strcmp(operand, OP_ARIT_MOD) == 0) {
        simpleDebug("Estoy en modulo.\n", 1);
        if (num2 != 0) {
            *res = num1 % num2;
        } else {
            yyerror("No esta permitido dividir por 0.");
        }
    } else if (strcmp(operand, OP_ARIT_POTENCIA) == 0) {
        simpleDebug("Estoy en la potencia.\n", 1);
        *res = (int) pow((double) num1, (double) num2);
    }
}

void floatOperations(float num1, float num2, char *operand, float *res) {
    if (strcmp(operand, OP_ARIT_SUMA) == 0) {
        *res = num1 + num2;
    } else if (strcmp(operand, OP_ARIT_RESTA) == 0) {
        *res = num1 - num2;
    } else if (strcmp(operand, OP_ARIT_MULT) == 0) {
        *res = num1 * num2;
    } else if (strcmp(operand, OP_ARIT_DIV) == 0) {
        if (num2 != 0) {
            *res = num1 / num2;
        } else {
            yyerror("No esta permitido dividir por 0.");
        }
    } else if (strcmp(operand, OP_ARIT_POTENCIA) == 0) {
        *res = (float) pow((double) num1, (double) num2);
    }
}

int intRelationalOperations(int num1, char *op, int num2)
{
    if (strcmp(op, OP_REL_HIGH) == 0)
    {
        return num1 > num2;
    }
    if (strcmp(op, OP_REL_HE) == 0)
    {
        return num1 >= num2;
    }
    if (strcmp(op, OP_REL_LESS) == 0)
    {
        return num1 < num2;
    }
    if (strcmp(op, OP_REL_LE) == 0)
    {
        return num1 <= num2;
    }
    if (strcmp(op, OP_REL_EQUAL) == 0)
    {
        return num1 == num2;
    }
    if (strcmp(op, OP_REL_DIFF) == 0)
    {
        return num1 != num2;
    }
}

int floatRelationalOperations(float num1, char *op, float num2)
{
    if (strcmp(op, OP_REL_HIGH) == 0)
    {
        return num1 > num2;
    }
    if (strcmp(op, OP_REL_HE) == 0)
    {
        return num1 >= num2;
    }
    if (strcmp(op, OP_REL_LESS) == 0)
    {
        return num1 < num2;
    }
    if (strcmp(op, OP_REL_LE) == 0)
    {
        return num1 <= num2;
    }
    if (strcmp(op, OP_REL_EQUAL) == 0)
    {
        return num1 == num2;
    }
    if (strcmp(op, OP_REL_DIFF) == 0)
    {
        return num1 != num2;
    }
}

// FUNCIONES BASE PARA EJECUCIÓN DEL COMPILADOR

int init_analisi_lexic(char *file_name) {
    int error;
    yyin = fopen(file_name, "r");
    if (yyin == NULL) {
        error = EXIT_FAILURE;
    } else {
        error = EXIT_SUCCESS;
    }
    return error;
}

int init_analisi_sintactic(char *filename) {
    int error = EXIT_SUCCESS;
    yyout = fopen(filename, "w");
    if (yyout == NULL) {
        error = EXIT_FAILURE;
    }
    return error;
}

int analisi_semantic() {
    int error;
    if (yyparse() == 0) {
        error = EXIT_SUCCESS;
    } else {
        error = EXIT_FAILURE;
    }
    return error;
}

int end_analisi_lexic() {
    int error;
    error = fclose(yyin);
    if (error == 0) {
        error = EXIT_SUCCESS;
    } else {
        error = EXIT_FAILURE;
    }
    return error;
}

int end_analisi_sintactic() {
    int error;
    error = fclose(yyout);
    if (error == 0) {
        error = EXIT_SUCCESS;
    } else {
        error = EXIT_FAILURE;
    }
    return error;
}
