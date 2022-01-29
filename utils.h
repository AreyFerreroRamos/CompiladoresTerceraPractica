#ifndef UTILS_H

#define UTILS_H

#include <stdbool.h>

#include "tipus.h"
#include "symtab.h"

/* FUNCIONES QUE SE USAN EN MÁS DE UN ÁMBITO, MAS DE UN SITIO ENTRE FLEX, BISON, FUNCTIONS Y SUPPORT */

/**
 * Muestra un mensaje de error y finaliza la ejecución de la compilación.
 */
void yyerror(char *);

/**
 * Dado un texto con "%s donde quiera poner un argumento, el numero de argumentos, y los argumentos
 * devuelve un string con los argumentos dentro del mensaje.
 */
char *generateString(char *message, int nArgs, ...);

/**
 * Dado un value_info comprueba que los parametros no estén a NULL.
 */
int isValueInfoBaseNull(value_info v);

/**
 * Dados los campos necesarios para gestionar un índice (literal, variable, tensor o función) para acceder a la posición de un tensor,
 * se genera una estructura (value_info) que contiene dichos campos y se devuelve.
 */
value_info createValueInfo(char *value, char *type, char *valueInfoType);

/**
 * Dados los campos necesarios para gestionar un tensor durante su uso en el programa,
 * se genera una estructura que contiene dichos campos y se devuelve.
 */
tensor_info createTensorInfo(int index_dim, value_info calcIndex, char *lexema);

/**
 * Dado los campos necesarios para gestionar un tensor durante su definición como variable del programa,
 * se genera una estructura que contiene dichos campos y se devuelve.
 */
tensor_ini_info createTensorIniInfo(int dim, char *type, value_info *elements, int num_elem);

/**
 * Dados los campos necesarios para crear una entrada en la tabla de símbolos,
 * se genera una estructura (sym_value_type) que contiene dichos campos y se devuele.
 */
sym_value_type createSymValueType(char *type, int size, int numDim, int *elemDims, void *elements, char *entryType);

/**
 * Dado un tipo controla si es entero o float y devuelve 1 en caso de serlo
 * o 0 si no lo es.
 */
int isNumberType(char *type);

/**
 * Dados dos tipos comprueba que son iguales y en ese caso devuelve 1,
 * en caso contrario 0.
 */
int isSameType(char *type1, char *type2);

/**
 * Convierte un entero a string.
 */
char *itos(int num);

/**
 * Convierte un float a string.
 */
char *ftos(float num);

/**
 * Reserva espacio en una variable char * para 200 carácteres como máximo y la devuleve.
 */
char *allocateSpaceForMessage();

/**
 * Función que hace un printf del texto pasado.
 * typeFile identificara si pertenece a flex (0) o bison/funciones (1).
 */
void simpleDebug(char *text, int typeFile);

/**
 * La función busca en la symtab la variable y la devuelve. Si se produce algún error
 * se lanzará un yyerror().
 */
sym_value_type getEntry(char *key);

/**
 * La función busca en la symtab la variable y la devuelve junto con el resultado
 * de la busqueda. El tratamiento del error se realizará externamente.
 */
int getEntryMessage(char *key, sym_value_type *entry);

/**
 * La función añade o actualiza (si ya existía) una entrada en la symtab. Si se produce algún error
 * se lanzará un yyerror().
 */
void addOrUpdateEntry(char *key, sym_value_type entry);

/**
 * La función hace push de la symtab para añadir un nuevo ámbito imbricado. Si se produce algún error
 * se lanzará un yyerror().
 */
void pushSymtab();

/**
 * La función hace un pop de la symtab para volver a un ámbito más global. Si se produce algún error
 * se lanzará un yyerror().
 */
void popSymtab();

#endif