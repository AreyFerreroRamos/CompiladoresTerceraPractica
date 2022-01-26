#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "functions.h"

extern int num_tmp_variable;
extern int sq;          // Siguiente linia que toca escribir.
extern int lengthCode;  // Nombre de linias de c3a.
extern char **c3a;      // Conjunto de lineas que formarán el c3a.

char *generateTmpId() {
    char *id;
    id = (char *) malloc(sizeof(char) * ID_MAX_LENGTH);
    sprintf(id, "%s%i", TMP_BASE_ID, num_tmp_variable);
    num_tmp_variable++;
    return id;
}

void restartNumberTmpId() {
    num_tmp_variable = 1;
}

void emet(char *type, int nArgs, ...) {
    va_list ap;
    va_start(ap, nArgs);

    char *instruction;
    if (isSameType(type, INSTR_COPY)) {
        char *var1, *var2;
        var1 = strdup(va_arg(ap,
        char*));
        var2 = strdup(va_arg(ap,
        char*));
        instruction = generateString("%s := %s", 2, var1, var2);
    }
    if (isSameType(type, INSTR_COPY_TO_TENSOR) || isSameType(type, INSTR_COPY_FROM_TENSOR)) {
        char *var1, *var2, *index;
        var1 = strdup(va_arg(ap,
        char*));
        var2 = strdup(va_arg(ap,
        char*));
        index = strdup(va_arg(ap,
        char*));
        if (isSameType(type, INSTR_COPY_FROM_TENSOR)) {
            instruction = generateString("%s := %s[%s]", 3, var1, var2, index);
        } else {
            instruction = generateString("%s[%s] := %s", 3, var1, index, var2);
        }
    } else if (isSameType(type, INSTR_ADDI) || isSameType(type, INSTR_ADDD)
               || isSameType(type, INSTR_SUBI) || isSameType(type, INSTR_SUBD)
               || isSameType(type, INSTR_MULI) || isSameType(type, INSTR_MULD)
               || isSameType(type, INSTR_DIVI) || isSameType(type, INSTR_DIVD)
               || isSameType(type, INSTR_MODI)) {
        char *var1, *var2, *var3;
        var1 = strdup(va_arg(ap,
        char*));
        var2 = strdup(va_arg(ap,
        char*));
        var3 = strdup(va_arg(ap,
        char*));
        instruction = generateString("%s := %s %s %s", 4, var1, var2, type, var3);
    } else if (isSameType(type, INSTR_EQ) || isSameType(type, INSTR_NE)
               || isSameType(type, INSTR_GTI) || isSameType(type, INSTR_GTD)
               || isSameType(type, INSTR_GEI) || isSameType(type, INSTR_GED)
               || isSameType(type, INSTR_LTI) || isSameType(type, INSTR_LTD)
               || isSameType(type, INSTR_LEI) || isSameType(type, INSTR_LED)) {
        char *var1, *var2;
        var1 = strdup(va_arg(ap,
        char*));
        var2 = strdup(va_arg(ap,
        char*));
        instruction = generateString("IF %s %s %s GOTO", 3, var1, type, var2);
        if (nArgs > 2) {
            char *gotoNum = strdup(va_arg(ap,
            char*));
            instruction = generateString("%s %s", 2, instruction, gotoNum);

        }
    } else if (isSameType(type, INSTR_BRANCH)) {
        if (nArgs == 0) {
            instruction = generateString("GOTO", 0);
        }
        else {
            int quad = va_arg(ap, int);
            instruction = generateString("GOTO %i", 1, quad);
        }
    } else if (isSameType(type, INSTR_PUT)) {
        char *element = strdup(va_arg(ap,
        char *));
        instruction = generateString("PUT %s", 1, element);
    } else if (isSameType(type, INSTR_START)) {
        char *func = strdup(va_arg(ap,
        char *));
        instruction = generateString("START %s", 1, func);
    } else if (isSameType(type, INSTR_END)) {
        int isAction = va_arg(ap,
        int);
        //Si no tiene valor de retorno y la última línea no es un RETURN.
        if (isAction == 1 && !isSameType(c3a[sq - 1], INSTR_RETURN)) {
            writeLine(sq, INSTR_RETURN);
        }
        writeLine(sq, INSTR_END);
        instruction = "";
    } else if (isSameType(type, INSTR_RETURN)) {
        if (nArgs == 0) {
            instruction = emetReturn(NULL);
        } else {
            char *value = strdup(va_arg(ap,
            char *));
            instruction = emetReturn(value);
        }
    } else if (isSameType(type, INSTR_PARAM)) {
        char *param = strdup(va_arg(ap,
        char *));
        instruction = generateString("PARAM %s", 1, param);
    } else if (isSameType(type, INSTR_CALL)) {
        char *nameFunc = strdup(va_arg(ap,
        char *));
        int numParams = va_arg(ap,
        int);
        char *tmp = "";
        if (nArgs == 3) {
            tmp = strdup(va_arg(ap,
            char *));
            tmp = generateString("%s := ", 1, tmp);
        }
        instruction = generateString("%sCALL %s,%i", 3, tmp, nameFunc, numParams);
    } else if (isSameType(type, INSTR_I2D)) {
        char *newVar = strdup(va_arg(ap,
        char *));
        char *varToCast = strdup(va_arg(ap,
        char *));
        instruction = generateString("%s := I2D %s", 2, newVar, varToCast);
    }
    va_end(ap);
    writeLine(sq, instruction);
}

void controlTensorIndex(value_info *v, char *tensorType) {
    // MULTIPLICAMOS POR ESPACIO DEL TIPO
    if (isSameType(v->valueInfoType, VAR_T)) {
        char *tmp = generateTmpId();
        emet(INSTR_MULI, 3, tmp, v->value, itos(calculateSizeType(tensorType)));
        *v = createValueInfo(tmp, INT32_T, VAR_T);
    } else {
        v->value = itos((atoi(v->value)) * calculateSizeType(tensorType));
    }
}

void emetTensor(char *lexema, tensor_ini_info tensor, char *tensorType) {
    for (int i = 0; i < tensor.elemList.numElem; i++) {
        emet(INSTR_COPY_TO_TENSOR, 3, lexema, tensor.elemList.elements[i].value,
             itos(i * calculateSizeType(tensorType)));
    }
}

void emetParams(value_info *listParams, int numParams) {
    for (int i = 0; i < numParams; i++) {
        emet(INSTR_PARAM, 1, listParams[i].value);
    }
}

void classifyOperation(char *operation, value_info v1, value_info v2, value_info v3) {
    if (isSameType(v1.type, INT32_T)) {
        if (isSameType(operation, OP_ARIT_SUMA)) {
            emet(INSTR_ADDI, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_RESTA)) {
            printf("%s, %s, %s\n", v1.value, v2.value, v3.value);
            fflush(stdout);
            emet(INSTR_SUBI, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_MULT)) {
            emet(INSTR_MULI, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_DIV)) {
            //TODO: si v3 es LIT_T comprobar que no sea un 0
            emet(INSTR_DIVI, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_MOD)) {
            emet(INSTR_MODI, 3, v1.value, v2.value, v3.value);
        }
    } else {
        if (isSameType(operation, OP_ARIT_SUMA)) {
            emet(INSTR_ADDD, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_RESTA)) {
            emet(INSTR_SUBD, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_MULT)) {
            //TODO: si v3 es LIT_T comprobar que no sea un 0
            emet(INSTR_MULD, 3, v1.value, v2.value, v3.value);
        } else if (isSameType(operation, OP_ARIT_DIV)) {
            emet(INSTR_DIVD, 3, v1.value, v2.value, v3.value);
        }
    }
}

void classifyRelationalOperation(char *operation, value_info v1, value_info v2) {
    if (isSameType(operation, OP_REL_EQUAL)) {
        emet(INSTR_EQ, 2, v1.value, v2.value);
    }
    else if (isSameType(operation, OP_REL_DIFF)) {
        emet(INSTR_NE, 2, v1.value, v2.value);
    }
    else {
        if (isSameType(v1.type, INT32_T)) {
            if (isSameType(operation, OP_REL_HIGH)) {
                emet(INSTR_GTI, 2, v1.value, v2.value);
            } else if (isSameType(operation, OP_REL_HE)) {
                emet(INSTR_GEI, 2, v1.value, v2.value);
            } else if (isSameType(operation, OP_REL_LESS)) {
                emet(INSTR_LTI, 2, v1.value, v2.value);
            } else if (isSameType(operation, OP_REL_LE)) {
                emet(INSTR_LEI, 2, v1.value, v2.value);
            }
        } else {
            if (isSameType(operation, OP_REL_HIGH)) {
                emet(INSTR_GTD, 2, v1.value, v2.value);
            } else if (isSameType(operation, OP_REL_HE)) {
                emet(INSTR_GED, 2, v1.value, v2.value);
            } else if (isSameType(operation, OP_REL_LESS)) {
                emet(INSTR_LTD, 2, v1.value, v2.value);
            } else if (isSameType(operation, OP_REL_LE)) {
                emet(INSTR_LED, 2, v1.value, v2.value);
            }
        }
    }
}

void writeLine(int line, char *instruction) {
    if (c3a == NULL) {
        c3a = malloc(sizeof(char *));
        lengthCode++;
        sq++;
    } else if (line >= lengthCode) {
        c3a = realloc(c3a, (lengthCode + 1) * sizeof(char *));
        lengthCode++;
        sq++;
    }
    c3a[line] = strdup(instruction);
}

char *getNewType(char *type1, char *type2) {
    if (isSameType(type1, INT32_T) && isSameType(type2, INT32_T)) {
        return INT32_T;
    } else {
        return FLOAT64_T;
    }
}

void doAritmeticOperation(value_info v1, char *operand, value_info v2, value_info *finish_val) {
    if (strcmp(v1.type, "Int32") == 0 && strcmp(v2.type, "Int32") == 0) {
        finish_val->type = "Int32";
        int resInt;
        intOperations(atoi(v1.value), atoi(v2.value), operand, &resInt);
        finish_val->value = itos(resInt);
    } else {
        if (strcmp(operand, "%") != 0) {
            finish_val->type = "Float64";
            float resFloat;
            floatOperations(atof(v1.value), atof(v2.value), operand, &resFloat);
            finish_val->value = ftos(resFloat);
        } else {
            yyerror("No es posible realizar la operación módulo entre dos números reales.");
        }
    }
    finish_val->valueInfoType = LIT_T;
}

char *doRelationalOperation(value_info element1, char *op, value_info element2)
{
    int res;
    if (isSameType(element1.type, INT32_T))
    {
        res = intRelationalOperations(atoi(element1.value), op, atoi(element2.value));
    }
    else
    {
        res = floatRelationalOperations(atof(element1.value), op, atof(element2.value));
    }
    if (res == 1)
    {
        return TRUE_VAL;
    }
    return FALSE_VAL;
}

char *negateBoolean(char *boolean)
{
    if (isSameType(boolean, TRUE_VAL))
    {
        return FALSE_VAL;
    }
    return TRUE_VAL;
}

value_info *joinElementsVectors(value_info *vec1, value_info *vec2, int numElemVec1, int numElemVec2) {
    int totalElem = numElemVec1 + numElemVec2;
    value_info *aux;
    if (numElemVec1 == 0) {
        aux = malloc(sizeof(value_info));
    } else {
        aux = realloc(vec1, totalElem * sizeof(value_info));
    }
    int cont = numElemVec1;
    for (int i = 0; i < numElemVec2; i++) {
        aux[cont++] = vec2[i];
    }
    return aux;
}

integer_list joinIntegerLists(integer_list list1, integer_list list2) {
    integer_list aux;
    aux.numElem = list1.numElem + list2.numElem;
    aux.elements = realloc(list1.elements, aux.numElem * sizeof(int));
    int cont = list1.numElem;
    for (int i = 0; i < list2.numElem; i++) {
        aux.elements[cont++] = list2.elements[i];
    }
    return aux;
}

void invertVector(int *vector, int dim) {
    int aux;
    for (int i = 0; i < dim / 2; i++) {   // Invertir el vector.
        aux = vector[i];
        vector[i] = vector[dim - i - 1];
        vector[dim - i - 1] = aux;
    }
}

int getDim(char *key, int index_dim) {
    sym_value_type entry = getEntry(key);
    if (index_dim >= entry.num_dim) {
        yyerror("Estás accediendo a una dimensión no válida.");
    }
    return entry.elem_dims[index_dim];
}

int getAcumElemDim(int *elem_dim, int num_dim) {
    int acum = 1;
    for (int i = 0; i < num_dim; i++) {
        acum *= elem_dim[i];
    }
    return acum;
}

value_info *addValueInfoBase(value_info *list, int numElem, value_info toAdd) {
    value_info *aux;
    if (numElem == 0) {
        aux = malloc(sizeof(value_info));
    } else {
        aux = realloc(list, sizeof(value_info) * (numElem + 1));
    }
    aux[numElem] = toAdd;
    return aux;
}

int *createIntegerList(int elem) {
    int *aux = malloc(sizeof(int));
    aux[0] = elem;
    return aux;
}

sym_value_type castValueInfoBaseToSymValueType(value_info v) {
    return createSymValueType(v.type, 0, 0, NULL, NULL, v.valueInfoType);
}

char *calculateNewIndex(int dim, value_info calcIndex, value_info index) {

    char *nameTmp1 = generateTmpId();
    value_info tmp1 = createValueInfo(nameTmp1, INT32_T, VAR_T);
    value_info one = createValueInfo("1", INT32_T, LIT_T);
    value_info calcIndexOld = createValueInfo(calcIndex.value, calcIndex.type, calcIndex.valueInfoType);
    value_info dimension = createValueInfo(itos(dim), INT32_T, LIT_T);
    emet(INSTR_MULI, 3, tmp1, calcIndexOld, dimension);
    if (isSameType(index.valueInfoType, VAR_T)) {
        char *nameTmp2 = generateTmpId();
        value_info tmp2 = createValueInfo(nameTmp2, INT32_T, VAR_T);
        emet(INSTR_SUBI, 3, tmp2, index, one);
        emet(INSTR_ADDI, 3, tmp1, tmp1, tmp2);
    } else {
        index.value = itos(atoi(index.value) - 1);
        emet(INSTR_ADDI, 3, tmp1, tmp1, index);
    }
    return nameTmp1;
}

void checkTypesInFuction(value_info *expectedParams, value_info *listParams, int numParams) {

    value_info expected, arrived;
    for (int i = 0; i < numParams; i++) {
        expected = expectedParams[i];
        arrived = listParams[i];
        if (isSameType(expected.valueInfoType, TENS_T) || isSameType(arrived.valueInfoType, TENS_T)) {
            if (!isSameType(expected.valueInfoType, TENS_T)) {
                yyerror(generateString("No se esperaba un tensor como %i parametro", 1, i + 1));
            } else if (!isSameType(arrived.valueInfoType, TENS_T)) {
                yyerror(generateString("Se esperaba un tensor como %i parametro", 1, i + 1));
            }
        }
        checkIfIsNeededCast(expected.type, &listParams[i]);
        arrived = listParams[i];
        if (!isSameType(expected.type, arrived.type)) {
            yyerror(generateString("El parametro %i del procedimiento deberia ser %s pero es %s", 3, i + 1,
                                   expected.type, arrived.type));
        }
    }
}

void checkIfIsNeededCast(char *expectedType, value_info *arrivedValue) {
    if (isSameType(expectedType, FLOAT64_T) && isSameType(arrivedValue[0].type, INT32_T)
        && !isSameType(arrivedValue[0].valueInfoType, LIT_T)) {
        //HACER I2D Y MODIFICAR EL PARAMETRO
        char *tmp = generateTmpId();
        emet(INSTR_I2D, 2, tmp, arrivedValue[0].value);
        arrivedValue[0].type = FLOAT64_T;
        arrivedValue[0].value = strdup(tmp);
    }

}

void completa(integer_list list, int numLinea)
{
    for(int i = 0;i < list.numElem; i++)
    {
        c3a[list.elements[i]] = generateString("%s %s",2,c3a[list.elements[i]], itos(numLinea));
    }
}
