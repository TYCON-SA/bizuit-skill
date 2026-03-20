# Validation Rules — BIZUIT BPMN Linting

> 53 reglas para validar BPMN generado antes de persistir en BIZUIT.
> Cada regla tiene: categoría, ID, descripción, severidad (BLOCKER/WARNING), auto-corregible (sí/no).
> Cargada por `workflows/create.md` Phase 3 (Paso 15) después de generar el BPMN.

## Cómo usar

1. Ejecutar TODAS las reglas contra el BPMN XML generado
2. Clasificar violaciones: BLOCKER (no persistir) vs WARNING (informar, puede continuar)
3. Auto-corregir las que son auto-corregibles
4. Reportar resultado al usuario
5. Máximo 3 pasadas de auto-corrección (evitar loops infinitos)

## Formato de reporte

```
✅ BPMN validado — {N}/{total} reglas OK
⚠️ {W} warnings (auto-corregidos)
❌ {B} blockers (requieren acción)
```

---

## 1. Estructura (8 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| S01 | Exactamente 1 StartEvent | BLOCKER | No |
| S02 | Al menos 1 EndEvent | BLOCKER | No |
| S03 | Todos los elementos tienen name no vacío | BLOCKER | No |
| S04 | Nombres únicos en todo el proceso | BLOCKER | No |
| S05 | ProcessId no contiene espacios ni caracteres especiales | BLOCKER | Sí — slugificar |
| S06 | `isExecutable="true"` presente en el proceso | BLOCKER | Sí — agregar |
| S07 | Namespaces BPMN correctos (bpmn2, bizuit, bpmndi) | BLOCKER | Sí — reemplazar |
| S08 | BPMNDI presente con al menos 1 BPMNShape | BLOCKER | No — regenerar |

## 2. Conectividad (5 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| C01 | No hay actividades sin incoming (excepto StartEvent) | BLOCKER | No |
| C02 | No hay actividades sin outgoing (excepto EndEvent) | BLOCKER | No |
| C03 | Todos los sequence flows tienen sourceRef y targetRef válidos | BLOCKER | No |
| C04 | No hay elementos desconectados del flujo principal | BLOCKER | No |
| C05 | Cada actividad tiene al menos 1 incoming Y 1 outgoing flow | BLOCKER | No |

## 3. Gateways (5 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| G01 | Solo Exclusive (XOR) y Parallel (AND) — no otros tipos | BLOCKER | No |
| G02 | Cada Exclusive Gateway tiene exactamente 1 default flow | BLOCKER | Sí — usar último flow |
| G03 | Cada Exclusive Gateway tiene condición en todos los non-default flows | BLOCKER | No |
| G04 | Simetría fork/join: cada Parallel Gateway fork tiene matching join | BLOCKER | No |
| G05 | Default flow no tiene conditionExpression | WARNING | Sí — remover condición |

## 4. No Loops (3 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| L01 | El grafo es un DAG (Directed Acyclic Graph) | BLOCKER | No |
| L02 | DFS no encuentra back edges | BLOCKER | No |
| L03 | No hay ciclos entre actividades | BLOCKER | No |

## 5. IDs (4 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| I01 | Todos los IDs únicos en el proceso | BLOCKER | No |
| I02 | IDs solo alfanuméricos + underscore | BLOCKER | Sí — sanitizar |
| I03 | En create: IDs siguen formato `Type_SlugifiedName` | WARNING | Sí — renombrar |
| I04 | En edit: IDs originales preservados | BLOCKER | No |

## 6. XSLT Consistency — FR65 (6 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| X01 | `Xslt` == `RuntimeInputXslt` para cada actividad | BLOCKER | Sí — copiar Xslt → Runtime |
| X02 | `OutParametersXslt` == `RuntimeOutputXslt` para cada actividad | BLOCKER | Sí — copiar OutParams → Runtime |
| X03 | Actividad con mappings tiene Xslt no vacío | BLOCKER | No |
| X04 | Actividad sin mappings tiene default XSLT vacío del tipo | WARNING | Sí — insertar default |
| X05 | `selectedInputSources` es JSON array válido | BLOCKER | No |
| X06 | `selectedOutputTargets` es JSON array válido | BLOCKER | No |

## 7. Formato BIZUIT (4 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| F01 | Booleans: "True"/"False" con mayúscula | WARNING | Sí — capitalizar |
| F02 | Enums case-sensitive (CommandType, ReturnType, etc.) | BLOCKER | Sí — corregir case |
| F03 | ConnectionStringSource: "FromConfigurationFile" o "FromActivity" | BLOCKER | No |
| F04 | Connection strings via ConfigFile (no hardcodeadas) | WARNING | No |

## 8. Service Tasks por tipo (8 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| T01 | SQL: `serviceTaskType="sql"`, CommandText no vacío | BLOCKER | No |
| T02 | SQL: ConnectionString o ConfigFileCnnStringName definido | BLOCKER | No |
| T03 | REST: `serviceTaskType="ws"`, restUrl no vacío | BLOCKER | No |
| T04 | Email: emailTo y emailBody no vacíos | BLOCKER | No |
| T05 | UserTask: performers definido, formId == activityId | BLOCKER | Sí — igualar formId |
| T06 | ScriptTask: expression no vacía si mode="sp" | BLOCKER | No |
| T07 | For/SubProcess: tiene StartEvent y EndEvent internos | BLOCKER | Sí — agregar |
| T08 | Timer: timeDuration en formato ISO 8601 válido | BLOCKER | No |

## 9. Parámetros (5 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| P01 | Cada parámetro tiene Name único | BLOCKER | No |
| P02 | Cada parámetro tiene type definido | BLOCKER | No |
| P03 | Parámetros de sistema presentes: InstanceId, LoggedUser, ExceptionParameter, OutputParameter | BLOCKER | Sí — agregar faltantes |
| P04 | Nombres de parámetros no contienen espacios | WARNING | Sí — remover espacios |
| P05 | Parámetros referenciados en condiciones existen | BLOCKER | No |

## 10. Conditional Flows (3 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| CF01 | Cada condición referencia parámetros existentes | BLOCKER | No |
| CF02 | Operadores válidos (==, !=, >, <, >=, <=, IsEmpty, HasValue, Contains, NotContains) | BLOCKER | No |
| CF03 | Formato pipe-delimited tiene 10 campos separados por `|` | BLOCKER | No |

## 11. Inter-proceso (2 reglas)

| # | Regla | Severidad | Auto-corregible |
|---|---|---|---|
| IP01 | SendMessage tiene targetProcess definido | BLOCKER | No |
| IP02 | CallActivity tiene calledElement definido | BLOCKER | No |

---

## Resumen por severidad

| Severidad | Cantidad | Auto-corregibles |
|---|---|---|
| BLOCKER | 40 | 12 |
| WARNING | 13 | 10 |
| **Total** | **53** | **22** |

## Auto-corrección

Reglas auto-corregibles y su algoritmo:

| Regla | Corrección determinística |
|---|---|
| S05 | Slugificar ProcessId (PascalCase, sin espacios) |
| S06 | Agregar `isExecutable="true"` |
| S07 | Reemplazar namespaces con los correctos de `bpmn-structure.md` |
| G02 | Asignar default al último outgoing flow (o al que contiene "no"/"default"/"else") |
| G05 | Remover conditionExpression del default flow |
| I02 | Reemplazar caracteres inválidos con underscore |
| I03 | Renombrar IDs al formato `Type_SlugifiedName` |
| X01 | Copiar `Xslt` → `RuntimeInputXslt` |
| X02 | Copiar `OutParametersXslt` → `RuntimeOutputXslt` |
| X04 | Insertar default XSLT vacío del tipo (de `activity-defaults.md`) |
| F01 | Capitalizar "true"→"True", "false"→"False" |
| F02 | Corregir case de enums conocidos |
| T05 | Igualar `formId` al `id` de la actividad |
| T07 | Agregar StartEvent/EndEvent internos al subProcess |
| P03 | Agregar parámetros de sistema faltantes |
| P04 | Remover espacios de nombres de parámetros |

## Gotchas

- Máximo 3 pasadas de auto-corrección para evitar loops infinitos
- Si una auto-corrección genera nueva violación → reportar como BLOCKER
- El BPMN inválido se guarda en disco pero NO se persiste en BIZUIT
- Las reglas L01-L03 (loops) son las más caras computacionalmente — ejecutar al final
- Los 22 auto-corregibles son determinísticos (un solo resultado posible)
