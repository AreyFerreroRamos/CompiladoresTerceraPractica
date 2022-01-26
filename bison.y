%{
  #include <stdio.h>
  #include <stdlib.h>
  #include <stdbool.h>
  #include <string.h>

  #include "tipus.h"
  #include "utils.h"
  #include "functions.h"

  #define YYLMAX 100

  extern FILE *yyout;
  extern int yylex();
  extern void yyerror(char *);

  	// Variables necesarias para la inicialización de un tensor.
  int *vector_dims_tensor;	// Vector con el número de elementos de cada dimensión del tensor.
  int num_dims_tensor = 0;	// Número de dimensiones del tensor.
  bool *ampliar_vector_dims; 	// Vector de booleanos para limitar la ampliación de memoria del vector de dimensiones a una sola ampliación por dimensión.

	//Variables para controlar el flujo de variables temporales en la symtab.
  char **list_tmp_variables_symtab;
  int num_tmp_variable = 1;
  int sq = 0;
  int lengthCode = 0;
  char **c3a;
%}

%code requires
{
  #include "utils.h"
  #include "functions.h"
  #include "tipus.h"
}

%union
{
	int enter;
	float real;
	char *cadena;
	ident ident;
	value_info valueInfo;
	boolean_info booleanInfo;
	integer_list integerList;
	tensor_info tensorInfo;
	tensor_ini_info tensorIniInfo;
	func_param_info funcParamInfo;
	elements_list elementsList;
	sym_value_type symValueType;
	rang_info rangInfo;
	for_info forInfo;
	elseif_info elseIfInfo;
	void *no_definit;
}

%token <no_definit> ASSIGN START VALUE_RETURN DIRECT_RETURN END DOS_PUNTOS DOBLE_DOS_PUNTOS LLAVE_ABIERTA LLAVE_CERRADA IF ELSEIF ELSE WHILE FOR IN OP_BOOL_AND OP_BOOL_OR NEGACION
%token <enter> INTEGER
%token <real> FLOAT
%token <cadena> OP_ARIT_P1 OP_ARIT_P2 ASTERISCO OP_RELACIONAL PARENTESIS_ABIERTO PARENTESIS_CERRADO DIV COMA CORCHETE_ABIERTO CORCHETE_CERRADO PUNTO_Y_COMA TIPO ID_PROC BOOLEAN
%token <ident> ID ID_FUNC ID_ACC
%token <valueInfo> ID_ARIT

%type <enter> m
%type <tensorInfo> id lista_indices lista_indices_arit
%type <tensorIniInfo> tensor componente lista_componentes lista_valores
%type <cadena> op_arit_p1 for_ini
%type <funcParamInfo> cabecera_procedimiento cabecera_funcion cabecera_accion lista_params
%type <elementsList> lista_args
%type <valueInfo> param expresion_aritmetica lista_sumas lista_productos terminal_aritmetico id_arit funcion
%type <booleanInfo> expresion_booleana lista_or lista_and expresion_booleana_base expresion_relacional terminal_booleano
%type <integerList> lista_de_sentencias sentencia n if
%type <rangInfo> rango
%type <forInfo> for
%type <elseIfInfo> elseif

%start programa


%%


programa : lista_de_procedimientos main | main

lista_de_procedimientos : lista_de_procedimientos procedimiento | procedimiento

procedimiento : cabecera_procedimiento lista_de_sentencias END	{
									completa($2, sq);
									if ($1.returnType == NULL)
									{
										emet(INSTR_END, 1, 1);
									}
									else
									{
										emet(INSTR_END, 1, 0);
									}
									popSymtab();
									sym_value_type entry = createSymValueType($1.returnType, $1.elemList.numElem, 0, NULL, $1.elemList.elements, FUNC_T);
									addOrUpdateEntry($1.funcName, entry);
									restartNumberTmpId();
								}

cabecera_procedimiento : cabecera_funcion | cabecera_accion

main : lista_de_sentencias	{
					completa($1, sq);
					writeLine(sq, "HALT");
					writeLine(sq, "END");
				}

lista_de_sentencias : lista_de_sentencias m sentencia	{
								completa($1, $2);
								$$ = $3;
							}
 		| sentencia	{
 					$$ = $1;
 				}

sentencia : asignacion	{
				$$.elements = NULL;
				$$.numElem = 0;
			}
	| expresion_aritmetica	{
					$$.elements = NULL;
					$$.numElem = 0;
					emet(INSTR_PUT, 1, $1.value);
				}
	| expresion_booleana	{
					$$.elements = NULL;
					$$.numElem = 0;
				}
	| ID	{
			$$.elements = NULL;
			$$.numElem = 0;
			emet(INSTR_PUT, 1, $1.lexema);
		}
	| VALUE_RETURN expresion_aritmetica	{
							$$.elements = NULL;
							$$.numElem = 0;
							emet(INSTR_RETURN, 1, $2.value);
						}
	| DIRECT_RETURN	{
				$$.elements = NULL;
				$$.numElem = 0;
				emet(INSTR_RETURN, 0);
			}
	| accion	{
				$$.elements = NULL;
				$$.numElem = 0;
			}
	| if END	{
				$$ = $1;
			}
        | WHILE m expresion_booleana m lista_de_sentencias END	{
									completa($3.listaCiertos, $4);
									completa($5, $2);
									emet(INSTR_BRANCH, 1, $2);
									$$ = $3.listaFalsos;
								}
	| for lista_de_sentencias END	{
						completa($2, sq);
						emet(INSTR_ADDI, 3, $1.idFor, $1.idFor, $1.rangInfo.despl);
						emet(INSTR_BRANCH, 1, $1.sqComp);
						$$ = $1.nextList;
					}

if : IF expresion_booleana m lista_de_sentencias	{
								completa($2.listaCiertos, $3);
								$$ = joinIntegerLists($2.listaFalsos, $4);
							}

	| IF expresion_booleana m lista_de_sentencias n ELSE m lista_de_sentencias	{
												completa($2.listaCiertos, $3);
												completa($2.listaFalsos, $7);
												$$ = joinIntegerLists($4, joinIntegerLists($5, $8));
											}
	| IF expresion_booleana m lista_de_sentencias n m elseif	{
									completa($2.listaCiertos, $3);
									completa($2.listaFalsos, $6);
									$$ = joinIntegerLists(joinIntegerLists($4,$5), joinIntegerLists($7.listaFalsos, $7.listaSiguientes));
								}
	| IF expresion_booleana m lista_de_sentencias n m elseif n ELSE m lista_de_sentencias	{
													completa($2.listaCiertos, $3);
                                                                                                        completa($2.listaFalsos, $6);
                                                                                                        completa($7.listaFalsos, $10);
                                                                                                        $$ = joinIntegerLists(joinIntegerLists($4,$5), joinIntegerLists($7.listaSiguientes, joinIntegerLists($8, $11)));
                                                                                                }

elseif : elseif n ELSEIF m expresion_booleana m lista_de_sentencias	{
										completa($1.listaFalsos, $4);
										completa($5.listaCiertos, $6);
										$$.listaFalsos = $5.listaFalsos;
										$$.listaSiguientes = joinIntegerLists($1.listaSiguientes,joinIntegerLists($2, $7));
									}
	| ELSEIF expresion_booleana m lista_de_sentencias	{
									completa($2.listaCiertos, $3);
									$$.listaFalsos = $2.listaFalsos;
									$$.listaSiguientes = $4;
								}

for : for_ini IN rango	{
				$$.idFor = $1;
				$$.sqComp = sq;
				$$.rangInfo = $3;
				emet(INSTR_LEI, 3, $1, $3.fin, itos($$.sqComp + 2));
				$$.nextList.elements = createIntegerList(sq);
				$$.nextList.numElem = 1;
				emet(INSTR_BRANCH, 0);
			}

rango : expresion_aritmetica DOS_PUNTOS expresion_aritmetica	{
									if (isSameType($1.type, INT32_T) && isSameType($3.type, INT32_T))
									{
										$$.ini = $1.value;
										$$.despl = "1";
										$$.fin = $3.value;
									}
									else
									{
										yyerror("Los valores del rango deben ser enteros.");
									}
								}
	| expresion_aritmetica DOS_PUNTOS expresion_aritmetica DOS_PUNTOS expresion_aritmetica	{
													if (isSameType($1.type, INT32_T) && isSameType($3.type, INT32_T) && isSameType($5.type, INT32_T))
													{
														$$.ini = $1.value;
														$$.despl = $3.value;
														$$.fin = $5.value;
													}
													else
													{
														yyerror("Los valores del rango deben ser enteros.");
													}
                                                                                              	}

for_ini : FOR ID	{
				char *idFor = generateTmpId();
				emet(INSTR_COPY, 2, idFor, $2.lexema);
				$$ = idFor;
			}

asignacion : ID ASSIGN expresion_aritmetica	{
							sym_value_type entry;
							entry = createSymValueType($3.type, calculateSizeType($3.type), 0, NULL, NULL, VAR_T);
							addOrUpdateEntry($1.lexema, entry);
							emet(INSTR_COPY, 2,$1.lexema, $3.value);
						}
	| id ASSIGN expresion_aritmetica	{
							sym_value_type entry = getEntry($1.lexema);
							entry.type = $3.type;
							entry.size = getAcumElemDim(entry.elem_dims, entry.num_dim) * calculateSizeType($3.type);
							addOrUpdateEntry($1.lexema, entry);
							controlTensorIndex(&($1.calcIndex),entry.type);
							emet(INSTR_COPY_TO_TENSOR, 3, $1.lexema, $3.value,$1.calcIndex.value);
						}
	| ID ASSIGN tensor	{
					invertVector(vector_dims_tensor, $3.dim);
					sym_value_type entry = createSymValueType($3.type, calculateSizeType($3.type) * $3.elemList.numElem, $3.dim, vector_dims_tensor, $3.elemList.elements, TENS_T);
					addOrUpdateEntry($1.lexema, entry);
					emetTensor($1.lexema, $3,$3.type);
					vector_dims_tensor = NULL;
					ampliar_vector_dims = NULL;
					num_dims_tensor = 0;
				}

id : lista_indices CORCHETE_CERRADO	{
						$$ = $1;
					}
   
lista_indices : lista_indices COMA lista_sumas	{
							if (isSameType($3.type, INT32_T))
							{
								int dim = getDim($1.lexema, $1.index_dim);
								if (isSameType($1.calcIndex.valueInfoType, VAR_T) || isSameType($3.valueInfoType, VAR_T))
								{
									char *tmp = calculateNewIndex(dim, $1.calcIndex, $3);
									value_info calcIndexNew = createValueInfo(tmp, INT32_T, VAR_T);
									$$ = createTensorInfo($1.index_dim + 1, calcIndexNew, $1.lexema);
								}
								else
								{
									value_info calcIndex = createValueInfo(itos(atoi($1.calcIndex.value) * dim + (atoi($3.value) - 1)), INT32_T, LIT_T);
									$$ = createTensorInfo($1.index_dim + 1, calcIndex, $1.lexema);
								}
							}
							else
							{
								yyerror(generateString("El indice -> %s es de tipo %s. El tipo debería ser INT32.", 2, $3.value, $3.type));
							}
						}
		| ID CORCHETE_ABIERTO lista_sumas	{
		      						if (isSameType($3.type, INT32_T))
								{
									value_info calcIndex;
									if (isSameType($3.valueInfoType, VAR_T))
									{
										char *nameTmp = generateTmpId();
										emet(INSTR_SUBI, 3, nameTmp, $3.value, "1");
										calcIndex = createValueInfo(nameTmp, INT32_T, VAR_T);
									}
									else
									{
										calcIndex = createValueInfo(itos(atoi($3.value) - 1), INT32_T, LIT_T);
									}
									$$ = createTensorInfo(1, calcIndex, $1.lexema);
								}
								else
								{
									yyerror(generateString("El indice -> %s es de tipo %s. El tipo debería ser INT32.", 2, $3.value, $3.type));
								}
		     					}

expresion_aritmetica : lista_sumas

lista_sumas : lista_sumas OP_ARIT_P2 lista_productos	{
								if (isNumberType($3.type))
								{	
									if (isSameType($1.valueInfoType, LIT_T) && isSameType($3.valueInfoType, LIT_T))
									{
										$$.value = (char *) malloc(sizeof(char) * FLOAT_MAX_LENGTH_STR);
										doAritmeticOperation($1, $2, $3, &$$);
									}
									else
									{

										char *newType = getNewType($1.type, $3.type);
										checkIfIsNeededCast(newType,&$1);
										checkIfIsNeededCast(newType,&$3);
											// CONTROLAR OPERACIÓN VALIDA? (Ex: MODULO CON FLOATS)
										$$ = createValueInfo(generateTmpId(),newType, VAR_T);
										classifyOperation($2, $$, $1, $3);
									}
								}
								else
								{
									yyerror(generateString("4.No se pueden realizar operaciones aritméticas con el tipo %s.", 1, $3.type));
								}
							}	
		| lista_productos	{
						if (isNumberType($1.type))
						{
							$$ = $1;
						}
						else
						{
							yyerror(generateString("3.No se pueden realizar operaciones aritméticas con el tipo %s.", 1, $1.type));
						}
					}

lista_productos : lista_productos op_arit_p1 terminal_aritmetico	{
										if (isNumberType($3.type))
										{
											if (isSameType($1.valueInfoType, LIT_T) && isSameType($3.valueInfoType, LIT_T))
											{
												$$.value = (char *) malloc(sizeof(char) * FLOAT_MAX_LENGTH_STR);
												doAritmeticOperation($1, $2, $3, &$$);
											}
											else
											{
												char *newType = getNewType($1.type, $3.type);
												checkIfIsNeededCast(newType,&$1);
                                                                                        	checkIfIsNeededCast(newType,&$3);
													//CONTROLAR OPERACIÓN VALIDA? (Ex: MODULO CON FLOATS)
												$$ = createValueInfo(generateTmpId(), getNewType($1.type, $3.type), VAR_T);
												classifyOperation($2, $$, $1, $3);
											}
										}
										else
										{
											yyerror(generateString("2.No se pueden realizar operaciones aritméticas con el tipo %s.", 1, $3.type));
										}
									}
		| terminal_aritmetico	{
						if (isNumberType($1.type))
						{
							$$ = $1;
						}
						else
						{
							yyerror(generateString("1.No se pueden realizar operaciones aritméticas con el tipo %s.", 1, $1.type));
						}
					}

op_arit_p1: OP_ARIT_P1	{
				$$ = strdup($1);
			} 
	| ASTERISCO	{
				$$ = strdup($1);
			}

terminal_aritmetico : INTEGER	{
					$$ = createValueInfo(itos($1), INT32_T, LIT_T);
				}
	| FLOAT		{
				$$ = createValueInfo(ftos($1), FLOAT64_T, LIT_T);
			}
	| id_arit 	{
			}
	| PARENTESIS_ABIERTO lista_sumas PARENTESIS_CERRADO	{
									if (isNumberType($2.type))
									{
										$$ = $2;
									}
									else
									{
										yyerror(generateString("No se pueden realizar operaciones aritméticas con el tipo %s.", 1, $2.type));
									}
								}
	| DIV lista_sumas COMA lista_sumas PARENTESIS_CERRADO	{
								/*	if ((isNumberType($2.type)) && (isNumberType($4.type)))
									{
										$$.value = (char *) malloc(sizeof(char) * FLOAT_MAX_LENGTH_STR);
										if (!doAritmeticOperation($2, "/", $4, &$$))
										{
											yyerror("Ha habido algun problema realizando la operación");
										}
									}
									else
									{
										yyerror(generateString,"No se pueden realizar operaciones aritméticas con el tipo %s",1, $2.type);
									}*/
								}
	| funcion	{
				$$ = $1;
			}

id_arit : ID_ARIT	{
				$$ = $1;
			}
	| lista_indices_arit CORCHETE_CERRADO	{
								sym_value_type entry = getEntry($1.lexema);
								controlTensorIndex(&($1.calcIndex),entry.type);
								char *nameTmp = generateTmpId();
								emet(INSTR_COPY_FROM_TENSOR, 3, nameTmp, $1.lexema,$1.calcIndex.value);
								$$ = createValueInfo(nameTmp, entry.type, TENS_T);
						}

lista_indices_arit : lista_indices_arit COMA lista_sumas	{
									if (isSameType($3.type, INT32_T))
									{
										int dim = getDim($1.lexema, $1.index_dim);
										if (isSameType($1.calcIndex.valueInfoType, VAR_T) || isSameType($3.valueInfoType, VAR_T))
										{
											char *tmp = calculateNewIndex(dim, $1.calcIndex, $3);
											value_info calcIndex = createValueInfo(tmp, INT32_T, VAR_T);
											$$ = createTensorInfo($1.index_dim + 1, calcIndex, $1.lexema);
										}
										else
										{
											value_info calcIndex = createValueInfo(itos(atoi($1.calcIndex.value) * dim + (atoi($3.value) - 1)), INT32_T, LIT_T);
											$$ = createTensorInfo($1.index_dim + 1, calcIndex, $1.lexema);
										}
									}
									else
									{
										yyerror(generateString("El indice -> %s es de tipo %s. El tipo debería ser INT32.", 2, $3.value, $3.type));
									}
								}
		| ID_ARIT CORCHETE_ABIERTO lista_sumas	{
	   							if (isSameType($3.type, INT32_T)) 
								{
									value_info calcIndex;
									if (isSameType($3.valueInfoType, VAR_T))
									{
										char *nameTmp = generateTmpId();
										emet(INSTR_SUBI, 3, nameTmp, $3.value, "1");
										calcIndex = createValueInfo(nameTmp, INT32_T, VAR_T);
									}
									else
									{
										calcIndex = createValueInfo(itos(atoi($3.value) - 1), INT32_T, LIT_T);
									}
									$$ = createTensorInfo(1, calcIndex, $1.value);
								}
								else
								{
									yyerror(generateString("El indice -> %s es de tipo %s. El tipo debería ser INT32.", 2, $3.value, $3.type));
								}
							}

expresion_booleana : lista_or	{
					$$ = $1;
				}

lista_or : lista_or OP_BOOL_OR m lista_and	{
							completa($1.listaFalsos, $3);
							$$.listaCiertos = joinIntegerLists($1.listaCiertos, $4.listaCiertos);
							$$.listaFalsos = $4.listaFalsos
						}
	| lista_and	{
				$$ = $1;
			}

lista_and : lista_and OP_BOOL_AND m expresion_booleana_base	{
									completa($1.listaCiertos, $3);
									$$.listaCiertos = $4.listaCiertos;
									$$.listaFalsos = joinIntegerLists($1.listaFalsos, $4.listaFalsos);
								}
			| expresion_booleana_base	{
								$$ = $1;
							}

expresion_booleana_base : NEGACION expresion_relacional	{
								$$.listaCiertos = $2.listaFalsos;
								$$.listaFalsos = $2.listaCiertos;
							}
			| expresion_relacional	{
							$$ = $1;
						}

expresion_relacional : lista_sumas OP_RELACIONAL lista_sumas	{
									if (isSameType($1.type, $3.type))
									{
										$$.listaCiertos.elements = createIntegerList(sq);
										$$.listaCiertos.numElem = 1;
										$$.listaFalsos.elements = createIntegerList(sq + 1);
										$$.listaFalsos.numElem = 1;
										classifyRelationalOperation($2, $1, $3);
										emet(INSTR_BRANCH, 0);
									}
									else
									{
										yyerror("No se puede comparar expresiones aritméticas de distinto tipo.");
									}
								}
			| terminal_booleano	{
							$$ = $1;
						}

terminal_booleano : BOOLEAN	{
					if (isSameType($1, TRUE_VAL))
					{
						$$.listaCiertos.elements = createIntegerList(sq);
						$$.listaCiertos.numElem = 1;
						$$.listaFalsos.elements = NULL;
						$$.listaFalsos.numElem = 0;
					}
					else
					{
						$$.listaCiertos.elements = NULL;
						$$.listaCiertos.numElem = 0;
						$$.listaFalsos.elements = createIntegerList(sq);
						$$.listaFalsos.numElem = 1;
					}
					emet(INSTR_BRANCH, 0);
				}
		| PARENTESIS_ABIERTO expresion_booleana PARENTESIS_CERRADO	{
											$$ = $2;
										}

tensor : CORCHETE_ABIERTO lista_componentes CORCHETE_CERRADO	{
       									if (ampliar_vector_dims[$2.dim])
       									{
       										ampliar_vector_dims[$2.dim] = false;
       									}
       					                		$2.dim++;
       					                		$$ = $2;
								}

lista_componentes : lista_componentes PUNTO_Y_COMA componente	{
									$$ = createTensorIniInfo($1.dim, getNewType($1.type, $3.type), joinElementsVectors($1.elemList.elements, $3.elemList.elements, $1.elemList.numElem, $3.elemList.numElem), $1.elemList.numElem + $3.elemList.numElem);
									if (ampliar_vector_dims[$1.dim])
									{
										vector_dims_tensor[$1.dim] += 1;
									}
								}
		| componente	{
					$$ = $1;
					if ($1.dim >= num_dims_tensor)
					{
						vector_dims_tensor = realloc(vector_dims_tensor, ++num_dims_tensor * 4);					
						vector_dims_tensor[$1.dim] = 1;
						ampliar_vector_dims = realloc(ampliar_vector_dims, num_dims_tensor);
						ampliar_vector_dims[$1.dim] = true;
					}
				}

componente : tensor	{
				$$ = $1;
			}
	| lista_valores	{
				$$ = $1;
			}

lista_valores : lista_valores COMA lista_sumas	{
							$$ = createTensorIniInfo(0, getNewType($1.type, $3.type), joinElementsVectors($1.elemList.elements, &$3, $1.elemList.numElem, 1), $1.elemList.numElem + 1);
							if (ampliar_vector_dims[0])
							{
								vector_dims_tensor[0] += 1;
							}
						}
		| lista_sumas	{
					$$ = createTensorIniInfo(0, $1.type, joinElementsVectors(NULL, &$1, 0, 1), 1);
					if (ampliar_vector_dims == NULL)
					{
						ampliar_vector_dims = malloc(1);
						ampliar_vector_dims[0] = true;
						vector_dims_tensor = malloc(4);
						vector_dims_tensor[0] = 1;
						num_dims_tensor++;
					}
				}

cabecera_funcion : cabecera_accion DOBLE_DOS_PUNTOS TIPO	{
									$1.returnType = strdup($3);
									$$ = $1;
								}

cabecera_accion : START ID_PROC PARENTESIS_ABIERTO lista_params PARENTESIS_CERRADO	{
												emet(INSTR_START, 1, $2);
												$4.funcName = strdup($2);
												$4.returnType = NULL;
												$$ = $4;
											}

lista_params : lista_params COMA param	{
						$$ = $1;
						$$.elemList.elements = addValueInfoBase($1.elemList.elements, $1.elemList.numElem, $3);
						$$.elemList.numElem++;

					}
		| param	{
				$$.elemList.numElem=0;
				$$.elemList.elements = addValueInfoBase($$.elemList.elements, $$.elemList.numElem, $1);
				$$.elemList.numElem++;
			}

param : ID DOBLE_DOS_PUNTOS TIPO	{
						value_info v = createValueInfo($1.lexema, $3, VAR_T);
						sym_value_type entry = castValueInfoBaseToSymValueType(v);
						addOrUpdateEntry(v.value, entry);
						$$ = v;
					}
	| ID DOBLE_DOS_PUNTOS TIPO LLAVE_ABIERTA TIPO LLAVE_CERRADA	{
										if (isSameType($3, TENSOR_T))
										{
											value_info v = createValueInfo($1.lexema, $5, TENS_T);
											sym_value_type entry = castValueInfoBaseToSymValueType(v);
											addOrUpdateEntry(v.value, entry);
											$$ = v;
										}
										else
										{
											yyerror("El tipo debería ser Tensor.");
										}
									}

funcion : ID_FUNC PARENTESIS_ABIERTO lista_args PARENTESIS_CERRADO	{
										if ($1.length == $3.numElem)
										{
											sym_value_type entry = getEntry($1.lexema);
											checkTypesInFuction(((value_info*) entry.elements), $3.elements, $3.numElem);
    											emetParams($3.elements,$3.numElem);
											char *nameTmp = generateTmpId();
											emet(INSTR_CALL, 3, $1.lexema, $3.numElem, nameTmp);
											$$ = createValueInfo(nameTmp, entry.type, VAR_T);
										}
										else
										{
											yyerror(generateString("El número de parámetros que se le ha pasado a la función no es correcto. Se han de pasar %i parámetros.", 1, $1.length));
										}
									}

accion : ID_ACC PARENTESIS_ABIERTO lista_args PARENTESIS_CERRADO	{
										if ($1.length == $3.numElem)
										{
											sym_value_type entry = getEntry($1.lexema);
                                                                                        checkTypesInFuction(((value_info*) entry.elements), $3.elements, $3.numElem);
											emetParams($3.elements, $3.numElem);
											emet(INSTR_CALL, 2, $1.lexema, $3.numElem);
										}
										else
										{
											yyerror(generateString("El número de parámetros que se le ha pasado a la función no es correcto. Se han de pasar %i parámetros.", 1, $1.length));
										}
									}

lista_args : lista_args COMA expresion_aritmetica	{
								$$ = $1;
								$$.elements = addValueInfoBase($1.elements, $1.numElem, $3);
								$$.numElem++;
							}
	| expresion_aritmetica	{
					$$.numElem=0;
					$$.elements = addValueInfoBase($$.elements, $$.numElem, $1);
					$$.numElem++;
				}

m :	{
		$$ = sq;
	}

n :	{
		$$.elements = createIntegerList(sq);
		$$.numElem = 1;
		emet(INSTR_BRANCH, 0);
	}


%%
