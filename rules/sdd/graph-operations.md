# Graph Operations — Knowledge Graph

## Qué hace

Gestiona el índice de Knowledge Graph: build, rebuild, query, validate, stale detection, auto-update, y health status. El índice es un archivo JSON derivado de las specs locales en `processes/`.

## Archivos

- **Índice:** `processes/.graph-index.json` (excluido de git y build — NFR50)
- **Schema version:** 1.0

## Comandos disponibles

| Comando | Keywords | Acción |
|---|---|---|
| graph build | "construir grafo", "graph build", "indexar procesos" | Rebuild completo desde specs |
| graph rebuild | "reconstruir grafo", "graph rebuild" | = graph build (alias) |
| graph query | "qué procesos usan", "dependencias de", "quién usa" | Query sobre el índice |
| graph validate | "validar grafo", "graph validate" | Comparar índice vs specs |
| graph status | "estado del grafo", "health", "dashboard" | Health summary sin rebuild |
| blast radius | "blast radius de", "qué se rompe si cambio", "impacto de cambiar" | Análisis de impacto |

## Graph Build

### Algoritmo

```
1. Escanear processes/**/spec.md
2. Para cada spec encontrada:
   a. Leer frontmatter YAML (processName, org, version, source)
   b. Si frontmatter corrupto o ausente → skip + warning, continuar con siguiente
   c. Leer sección "## Parámetros" → extraer tabla markdown de parámetros
   d. Leer sección "## Actores" → extraer lista de actores
   e. Leer sección "## Integraciones" o secciones de detalle técnico → extraer sistemas externos:
      - Tablas con header Connection/ConnectionString → SQL table
      - Tablas con header URL/Endpoint → REST API
      - Tablas con header To/Destinatario → Email
      - Formato no reconocido → skip sección + warning
   f. Calcular Health Status:
      - 🟢 Green: completedSections ≥ 8, 0 anomalías error, índice sync
      - 🟡 Yellow: draftedSections > 0, o anomalías warning, o stale
      - 🔴 Red: sin spec completa, anomalías error, o drift detectado
   g. Agregar nodos y aristas al índice
3. Calcular healthSummary: { green: N, yellow: N, red: N }
4. Escribir processes/.graph-index.json
5. Reportar: "Índice construido: {N} procesos, {N} parámetros, {N} actores, {N} sistemas. Health: {green}🟢 {yellow}🟡 {red}🔴"
```

### Para >20 specs: build progresivo
- Mostrar progreso: "Procesando spec {N} de {total}..."
- Escribir índice incrementalmente — si se interrumpe, el índice parcial es usable

### Archivos procesados
- Solo archivos nombrados `spec.md` se procesan. Otros `.md` en processes/ se ignoran.

## Graph Index Schema (v1.0)

```json
{
  "schemaVersion": "1.0",
  "lastRebuilt": "ISO8601 timestamp",
  "processCount": "number",
  "nodes": {
    "processes": {
      "{org}/{processName}": {
        "org": "string",
        "version": "string",
        "source": "reverse|create|edit",
        "activityCount": "number",
        "healthStatus": "green|yellow|red",
        "specPath": "string — path relativo a processes/"
      }
    },
    "parameters": {
      "{paramName}": {
        "type": "string|null — tipo inferido si disponible",
        "usedBy": ["org/processName"],
        "direction": { "org/processName": "in|out|in-out" }
      }
    },
    "actors": {
      "{actorName}": {
        "participatesIn": ["org/processName"]
      }
    },
    "externalSystems": {
      "{systemName}": {
        "type": "SQL|REST|Email",
        "usedBy": ["org/processName"]
      }
    }
  },
  "edges": [
    { "from": "string", "to": "string", "type": "reads|writes|calls|depends_on|shared_with" }
  ],
  "healthSummary": {
    "green": "number",
    "yellow": "number",
    "red": "number"
  }
}
```

**Keys de proceso:** `{org}/{processName}` para evitar colisiones multi-org.

## Graph Query

### Queries soportadas (lenguaje natural → operación)

| Query natural | Operación | Resultado |
|---|---|---|
| "qué procesos usan {param}" | Buscar en nodes.parameters | Lista de procesos |
| "qué procesos llaman a {API}" | Buscar en nodes.externalSystems | Lista de procesos |
| "qué procesos usan tabla {tabla}" | Buscar en nodes.externalSystems tipo SQL | Lista de procesos |
| "quién participa en {proceso}" | Buscar en nodes.actors por proceso | Lista de actores |
| "qué APIs usa {proceso}" | Filtrar externalSystems por proceso | Lista de APIs/tablas |
| "procesos con anomalías" | Filtrar processes por healthStatus red | Lista de procesos |
| "parámetros compartidos entre {A} y {B}" | Intersección de params de A y B | Lista de parámetros |
| "graph status" / "health" | Leer healthSummary | Resumen verde/amarillo/rojo |

### Formato de respuesta

```
📊 Query: "qué procesos usan pMontoAprobado"
Encontrados: 3 procesos

1. RDAFF/ComprasAprobacion — usa como in-out
2. RDAFF/CobranzaEntidad — usa como in
3. BANCO/AprobacionCredito — usa como in

Índice: {N} procesos indexados. Última reconstrucción: {fecha}.
```

### Query no encontrada

```
❌ No encontré el parámetro 'MontoAprobdo' en el índice.
Procesos indexados: 47. ¿Verificar el nombre exacto?
```

## Blast Radius

### Input
Nombre de entidad + tipo (parámetro/tabla/API/actor). Si el tipo es ambiguo (mismo nombre en tipos distintos), preguntar al usuario.

### Algoritmo

```
1. Buscar entidad en el índice por tipo
2. Si no encontrada → "No encontré '{nombre}' en el índice."
3. Si encontrada en 0 procesos → "'{nombre}' existe pero no es utilizado."
4. Para cada proceso que la usa:
   a. Listar el proceso con org
   b. Si es posible, listar actividades específicas que la referencian
5. Si el índice está stale → warning "Resultado puede ser parcial."
```

### Formato

```
💥 Blast Radius: tabla Proveedores (SQL)
Afecta: 5 procesos

1. RDAFF/ComprasAprobacion
   - ConsultarProveedores (serviceTask/SQL) — reads
   - ActualizarStock (serviceTask/SQL) — writes
2. RDAFF/ReporteCompras
   - GenerarReporte (serviceTask/SQL) — reads
3. RDAFF/SincronizarERP
   - SyncProveedores (serviceTask/REST) — calls API que accede a tabla
...

⚠️ Índice: última reconstrucción hace 3 días. Resultado puede ser parcial.
```

### Ambigüedad de tipo

Si "Proveedores" existe como tabla SQL Y como actor:
```
❓ "Proveedores" aparece como:
  1. Tabla SQL (usada por 5 procesos)
  2. Actor (participa en 2 procesos)
¿Cuál querés analizar?
```

## Stale Detection

### Cuándo se ejecuta
Al inicio de cualquier graph query (query, blast radius, status).

### Algoritmo

```
1. Leer lastRebuilt del graph-index.json
2. Para cada spec en processes/**/spec.md:
   a. Comparar mtime del archivo con lastRebuilt
3. Si alguna spec es más nueva:
   → Warning: "⚠️ El índice está desactualizado (última reconstrucción: {fecha}). {N} specs modificadas después. ¿Reconstruir ahora? (sí/no)"
4. Si ninguna spec es más nueva → proceder silenciosamente
```

## Auto-Update Post-Workflow

### Cuándo se ejecuta
Al final de reverse/create/edit exitoso.

### Algoritmo

```
1. Si processes/.graph-index.json NO existe:
   → Informar: "💡 Índice no construido. Ejecutar 'graph build' para habilitar queries cross-process."
   → NO crear automáticamente (el usuario decide)
2. Si processes/.graph-index.json existe:
   a. Leer el índice actual
   b. Actualizar SOLO los nodos del proceso que se acaba de reverse/create/edit
   c. Recalcular healthSummary
   d. Actualizar lastRebuilt timestamp
   e. Guardar el índice
3. Si error al escribir → warning, no bloquear workflow principal
```

## Graph Validate

### Qué verifica

| Tipo | Descripción | Severidad |
|---|---|---|
| 1 | Spec existente no indexada | Warning |
| 2 | Proceso en índice sin spec en disco | Warning |
| 3 | Parámetro con tipos distintos entre procesos | Governance issue |
| 4 | Dependencia circular (A↔B via Send/Receive) | Info (no error) |

### Formato

```
🔍 Graph Validate

✅ Procesos: 45 indexados, 45 specs en disco — consistente
⚠️ 2 inconsistencias encontradas:

  [Warning] Spec processes/BANCO/NuevoProceso/spec.md no indexada
  [Governance] Parámetro 'pMonto': decimal en RDAFF/Compras, string en BANCO/Credito

ℹ️ 1 info:
  [Info] Dependencia circular: RDAFF/Cobranza ↔ RDAFF/Facturacion (Send/Receive)
```

### Si no hay índice
```
❌ No hay índice. Ejecutar 'graph build' primero.
```

## Graph Status (Health Summary)

### Cuándo se usa
Query rápida sin rebuild. Lee el healthSummary del índice.

### Formato — Vista Organizacional (≥3 procesos)

Cuando el graph tiene ≥3 procesos documentados, mostrar tabla con health indicators:

```
📊 Vista Organizacional — 6 procesos, 28 parámetros, 12 actores, 8 sistemas

| Proceso | Health | Última actualización | Nodos | Dependencias |
|---------|--------|---------------------|-------|--------------|
| arielsch/eqv-procesar-request | 🔴 | 2026-03-18 | 200 | 12 |
| arielsch/ackp-planes-accion | 🟡 | 2026-03-19 | 21 | 5 |
| arielsch/onboarding-de-empleados | 🟢 | 2026-03-19 | 11 | 3 |
| arielsch/pedido-de-soporte | 🟢 | 2026-03-19 | 13 | 4 |
| arielsch/proceso-compras | 🟢 | 2026-03-19 | 12 | 6 |
| arielsch/pruebaisadmin | 🟢 | 2026-03-18 | 3 | 1 |

Health: 🟢 4 OK, 🟡 1 warnings, 🔴 1 críticos

🔴 Procesos críticos:
  - arielsch/eqv-procesar-request — stale (spec editada fuera del skill)
```

**Reglas de la tabla:**
- **Ordenamiento:** 🔴 primero, luego 🟡, luego 🟢
- **Columna Health:** mapea health status del graph index:
  - 🟢 = spec completa (≥8 secciones), 0 anomalías error, índice sync
  - 🟡 = secciones draft, anomalías warning, o stale menor
  - 🔴 = spec incompleta, anomalías error, drift detectado, o stale
  - Prioridad: 🔴 gana sobre 🟡 gana sobre 🟢
- **Columna Última actualización:** `lastModifiedAt` del frontmatter YAML de la spec. Fallback: `createdAt`. Si ninguno existe → "desconocido"
- **Columna Nodos:** `activityCount` del proceso en el graph index
- **Columna Dependencias:** cantidad de edges compartidos con otros procesos (parámetros + tablas SQL + APIs en común). Se cuentan edges totales, no tipos
- **Header stats:** totales del graph: procesos, parámetros, actores, sistemas

### Formato — Status Básico (<3 procesos)

Cuando el graph tiene 1-2 procesos, mostrar status básico sin tabla:

```
📊 Estado del Knowledge Graph

Última reconstrucción: 2026-03-19 14:00
Procesos indexados: 2

Health:
  🟢 1 proceso OK
  🟡 1 proceso con warnings

Documentá más procesos para activar la vista organizacional (requiere ≥3).
```

### Índice desactualizado

Si `lastRebuilt` del graph index es anterior a cualquier `lastModifiedAt` de las specs en disco → agregar nota al final:

```
⚠️ Índice puede estar desactualizado (última reconstrucción: 2026-03-18 10:00).
Ejecutar `graph rebuild` para datos frescos.
```

## Edge Cases

- **0 specs:** "No hay procesos documentados. Ejecute reverse para documentar procesos existentes."
- **1-2 specs:** Status básico sin tabla + mensaje "Documentá más procesos para activar la vista organizacional (requiere ≥3)."
- **3 specs:** Tabla visible (threshold es ≥3, no >3)
- **1 spec:** Grafo funcional con 1 proceso
- **graph-index.json corrupto (JSON inválido):** "Índice corrupto. Ejecutar 'graph rebuild' para regenerar."
- **graph-index.json vacío:** "Índice vacío. Ejecutar 'graph rebuild'."
- **Directorio processes/ no existe:** "Directorio processes/ no encontrado."
- **2 workflows rápidos seguidos:** 2 auto-updates secuenciales, sin conflicto (write secuencial)
- **Spec con frontmatter corrupto:** Skip + warning, build continúa (NFR52)
- **Spec sin lastModifiedAt ni createdAt:** Columna "Última actualización" muestra "desconocido"
- **Proceso stale + anomalías warning:** Health 🔴 (stale gana sobre warning)
- **Spec referenciada en graph pero archivo borrado:** Health 🔴 + nota "spec no encontrada — ejecutar `graph rebuild`"
- **>20 procesos en tabla:** Mostrar completa sin truncar

## Gotchas

- El índice es DERIVADO — siempre se puede reconstruir desde las specs. Perder el índice = rebuild, no pérdida de datos.
- Keys de parámetros se normalizan: trim, case-sensitive (pMontoAprobado ≠ pmontoAprobado).
- Los edges se generan del análisis de las specs, no se declaran manualmente. `depends_on` opcional en frontmatter para dependencias tácitas.
- Graph status lee el índice SIN reconstruir — puede estar stale. El warning lo indica.
- El auto-update es incremental (solo 1 proceso). El rebuild es completo (todos los procesos).
