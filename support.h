#ifndef SUPPORT_H

#define SUPPORT_H

#include <math.h>
#include "tipus.h"
#include "utils.h"

/* FUNCIONES QUE SOLAMENTE SON LLAMADAS DESDE EL FICHERO FUNCTIONS.C O DESDE EL MAIN */

//-------------------------EMET FUNCTIONS----------------------------

/**
 * Dado el valor a devolver en un RETURN  devuelve la instrucción "RETURN [valor]".
 * Si el valor es NULL se devolvera solo "RETURN".
 */
char *emetReturn(char *var);

//-------------------------------------------------------------------

/**
 * Escribe el c3a por consola y en el fichero de salida.
 */
void printCode3Adresses();

/**
 * Dados dos enteros y un operando aritmético, devuelve el resultado de la expresión
 * "num1 op num2" dentro de res. Además si la operación no es válida devuelve 0, o 1 en
 * caso de que si sea correcta.
 */
void intOperations(int num1, int num2, char *op, int *res);

/**
 * Dados dos floats y un operando aritmético, devuelve el resultado de la expresión
 * "num1 op num2" dentro de res. Además si la operación no es válida devuelve 0, o 1 en
 * caso de que si sea correcta.
 */
void floatOperations(float num1, float num2, char *op, float *res);

/**
 *
 */
int intRelationalOperations(int num1, char *op, int num2);

/**
 *
 */
int floatRelationalOperations(float num1, char *op, float num2);

// FUNCIONES BASE PARA EJECUCIÓN DEL COMPILADOR

int init_analisi_lexic(char *);

int init_analisi_sintactic(char *);

int analisi_semantic();

int end_analisi_lexic();

int end_analisi_sintactic();

#endif