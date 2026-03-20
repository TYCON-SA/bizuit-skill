# Anomalies — BIZUIT

> Anomalías a detectar durante reverse de VDW. Diferentes de anti-patterns (que se detectan en create).

## Cuándo aplica

Cargada por `workflows/reverse.md` después de parsear el VDW. Cada actividad se verifica contra estas reglas.

## 9 Anomalías

| # | Anomalía | Severidad | Threshold | Detección | Mensaje |
|---|---|---|---|---|---|
| 1 | SQL sin parámetros tipados | ⚠️ Warning | Query con literales numéricos hardcodeados (ej: `RoleID=8`) | SQL | "{nombre}: query con valor hardcodeado '{literal}' — debería ser parámetro" |
| 2 | Gateway sin default flow | 🔴 Error | ExclusiveGateway sin condición marcada como default | Gateways | "Gateway '{nombre}': sin default flow — proceso puede quedar sin camino" |
| 3 | Actividad sin connections | 🔴 Error | `incoming == 0 AND NOT StartEvent` | Todas | "Actividad '{nombre}' sin conexiones — inalcanzable" |
| 4 | Connection string hardcodeada | ⚠️ Warning | `ConnectionStringSource != "FromConfigurationFile"` AND `ConnectionString` tiene valor | SQL | "{nombre}: connection string hardcodeada — debería usar ConfigFile" |
| 5 | Password en texto plano | 🔴 Error | Regex: `/[Pp]assword\s*=\s*[^";\s]+/` o `Secret=` o `Token=` o `Key=` o `Pwd=` | Cualquier atributo | "{nombre}: password en texto plano detectada — enmascarar con ***" |
| 6 | Timer con valor 0 o negativo | ⚠️ Warning | `DelayDuration <= 0` | Timer | "{nombre}: timer con duración {valor} — no funcional" |
| 7 | For sin source data | 🔴 Error | ForActivity sin IterationXPath ni SourceData | For | "{nombre}: iteración sin datos de entrada — itera sobre nada" |
| 8 | Send Message sin proceso destino | 🔴 Error | SendMessageActivity sin `EventName` | Send Message | "{nombre}: mensaje sin proceso destino — no llega a nadie" |
| 9 | Valor hardcodeado en condición | ⚠️ Warning | Condición de gateway con literal numérico sin `@` prefix | Gateways | "Gateway '{nombre}': condición con valor hardcodeado '{literal}' — debería ser parámetro configurable" |

> **NO son anomalías:**
> - `CommandTimeout="0"` — significa "usar timeout default de la conexión" (normal en producción)
> - `FaultHandlersActivity` vacío (ExceptionContainer sin handlers) — es válido, el proceso simplemente no tiene manejo de errores global configurado

## Reglas de reporte

- Reportar CADA instancia por separado (si hay 3 SQL con connection string hardcodeada, reportar las 3)
- Incluir nombre de actividad en cada reporte
- Agrupar en la spec bajo `## 6. Edge Cases y Manejo de Errores`, subsección `### Anomalías detectadas`
- Formato: `{emoji} {descripción con nombre de actividad}`

## Thresholds (NFR37)

Los thresholds son EXPLÍCITOS — no generar warnings por configuraciones normales:

| Atributo | Normal (no reportar) | Anómalo (reportar) |
|---|---|---|
| CommandTimeout | 0 (default de conexión) y 1-300 seg | No aplica — 0 no es anomalía |
| DelayDuration | > 0 | 0 o negativo |
| ConnectionStringSource | "FromConfigurationFile" | "FromActivity" con valor directo |
| Password | No detectable / enmascarada | Regex match en atributo |

## Acción especial: Password masking (NFR11)

Si se detecta password en texto plano:
1. Marcar anomalía 🔴 Error
2. **ANTES de guardar la spec**: reemplazar el valor con `***ENMASCARADO***`
3. La spec generada NUNCA contiene passwords reales

## Gotchas

- Anomalías se detectan en REVERSE (procesos existentes), no en create (procesos nuevos)
- En create, los problemas se previenen con anti-patterns (archivo diferente)
- `CommandTimeout="0"` = default de la conexión (normal en producción). NO reportar como anomalía.
- El regex de password puede dar falsos positivos en strings que contienen "Password" como dato — verificar contexto del atributo
