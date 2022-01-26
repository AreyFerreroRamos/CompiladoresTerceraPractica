#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "utils.h"

extern int yylineno;

void yyerror(char *explanation) {
    fprintf(stderr, "Error: %s, in line %d\n", explanation, yylineno);
    exit(EXIT_FAILURE);
}

char *generateString(char *message, int nArgs, ...) {
    va_list ap;
    va_start(ap, nArgs);
    char **params = malloc(sizeof(char *) * nArgs);
    for (int i = 0; i < nArgs; i++) {
        params[i] = va_arg(ap,
        char *);
    }
    va_end(ap);

    char *string = allocateSpaceForMessage();
    switch (nArgs) {
        case 0:
            sprintf(string, message);
            break;
        case 1:
            sprintf(string, message, params[0]);
            break;
        case 2:
            sprintf(string, message, params[0], params[1]);
            break;
        case 3:
            sprintf(string, message, params[0], params[1], params[2]);
            break;
        case 4:
            sprintf(string, message, params[0], params[1], params[2], params[3]);
            break;
        case 5:
            sprintf(string, message, params[0], params[1], params[2], params[3], params[4]);
            break;
        case 6:
            sprintf(string, message, params[0], params[1], params[2], params[3], params[4], params[5]);
            break;
        case 7:
            sprintf(string, message, params[0], params[1], params[2], params[3], params[4], params[5], params[6]);
            break;
        default:
            yyerror("Estas usando mal la función generateString(). nArgs debe estar entre 0 y 7.");
            break;
    }
    return strdup(string);
}

int isValueInfoBaseNull(value_info v) {
    if (v.value == NULL || v.type == NULL || v.valueInfoType == NULL) {
        return 1;
    }
    return 0;
}

value_info createValueInfo(char *value, char *type, char *valueInfoType) {
    value_info aux;
    aux.valueInfoType = strdup(valueInfoType);
    aux.type = strdup(type);
    aux.value = strdup(value);
    return aux;
}

tensor_info createTensorInfo(int index_dim, value_info calcIndex, char *lexema) {
    tensor_info aux;
    aux.index_dim = index_dim;
    aux.calcIndex = calcIndex;
    aux.lexema = strdup(lexema);
    return aux;
}

tensor_ini_info createTensorIniInfo(int dim, char *type, value_info *elements, int numElem) {
    tensor_ini_info aux;
    aux.dim = dim;
    aux.type = strdup(type);
    aux.elemList.elements = elements;
    aux.elemList.numElem = numElem;
    return aux;
}

sym_value_type createSymValueType(char *type, int size, int numDim, int *elemDims, void *elements, char *entryType) {
    sym_value_type aux;
    if (type != NULL) {
        aux.type = strdup(type);
    } else {
        aux.type = NULL;
    }
    aux.size = size;
    aux.num_dim = numDim;
    aux.elem_dims = elemDims;
    aux.elements = elements;
    aux.entryType = strdup(entryType);
    return aux;
}

int isNumberType(char *type) {
    return (strcmp(type, INT32_T) == 0 || strcmp(type, FLOAT64_T) == 0);
}

int isSameType(char *type1, char *type2) {
    return (strcmp(type1, type2) == 0);
}

char *itos(int num) {
    char *string = (char *) malloc(sizeof(char) * INT_MAX_LENGTH_STR);
    sprintf(string, "%i", num);
    return string;
}

char *ftos(float num) {
    char *string = (char *) malloc(sizeof(char) * FLOAT_MAX_LENGTH_STR);
    sprintf(string, "%.2f", num);
    return string;
}

int calculateSizeType(char *type) {
    if (isSameType(type, FLOAT64_T)) {
        return 8;
    } else if (isSameType(type, INT32_T)) {
        return 4;
    } else {
        return 1;
    }
}

char *allocateSpaceForMessage() {
    char *message;
    message = (char *) malloc(sizeof(char) * MESSAGE_MAX_LENGTH);
    return message;
}

void debug(char *text, char *var, int typeFile) {
    // flex
    if (typeFile == 0) {
        printf(text, var);
    }
        // bison
    else {
        // printf(text, var);
    }
}

void simpleDebug(char *text, int typeFile) {
    // flex
    if (typeFile == 0) {
        // printf(text);
    }
        // bison
    else {
        // printf(text);
    }
}

sym_value_type getEntry(char *key) {
    sym_value_type entry;
    int response = sym_lookup(key, &entry);
    if (response == SYMTAB_NOT_FOUND) {
        yyerror(generateString("No se ha encontrado el elemento '%s' en la symtab.", 1, key));
    }
    return entry;
}

int getEntryMessage(char *key, sym_value_type *entry) {
    return sym_lookup(key, entry);
}

void addOrUpdateEntry(char *key, sym_value_type entry) {
    int response = sym_enter(key, &entry);
    if (response == SYMTAB_STACK_OVERFLOW) {
        yyerror("No hay más memoria (añadiendo entrada).");
    }
}

void pushSymtab() {
    int response = sym_push_scope();
    if (response == SYMTAB_STACK_OVERFLOW) {
        yyerror("Se ha desbordado la pila.");
    }
}

void popSymtab() {
    int response = sym_pop_scope();
    if (response == SYMTAB_STACK_UNDERFLOW) {
        yyerror("El ámbito actual es el global.");
    } else if (response == SYMTAB_NOT_TOP) {
        yyerror("El ámbito actual no esta en la cima de la pila.");
    }
}