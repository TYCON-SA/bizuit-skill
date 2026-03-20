# API Auth — BIZUIT

> Flujo de autenticación lazy para las 2 APIs de BIZUIT.

## Cuándo aplica

Antes de la primera API call en cualquier workflow. Lazy: no se carga al inicio.

## Prerequisites — Config Lazy (v2.1)

**El skill NO requiere configuración al inicio.** CREATE, VALIDATE, y QUERY local funcionan sin credenciales.

Datos de conexión se guardan en `.bizuit-config.yaml` en el directorio del skill (`~/.claude/skills/bizuit-sdd/.bizuit-config.yaml`). Excluido de git y build. Password por sesión, nunca persiste en disco.

### Verificar configuración

1. ¿Existe `.bizuit-config.yaml` en el directorio del skill?
   - **SÍ** → detectar formato:
     - **Multi-env** (tiene `environments:`): leer ambiente de `active`. Usar URL, user, org del ambiente activo. Si no hay `active` → detectar por URL pattern (ver abajo)
     - **Single-env** (campos flat: `bizuit_api_url`, etc.): leer como antes (ambiente "default")
   - **NO** → ejecutar **Wizard Inline** (ver abajo)

2. ¿Existen env vars legacy (`BIZUIT_API_URL`, etc.)?
   - **SÍ** → usar env vars como fallback. Recomendar migrar a `.bizuit-config.yaml`.
   - **NO** → solo wizard

### Config Multi-Ambiente (FR92)

Formato multi-env en `.bizuit-config.yaml`:

```yaml
active: dev
environments:
  dev:
    url: https://dev.bizuit.com
    user: ariel
    org: arielsch
  qa:
    url: https://qa.bizuit.com
    user: ariel
    org: arielsch
  prod:
    url: https://prod.bizuit.com
    user: ariel
    org: arielsch-prod
```

**Regla de lectura:** `active` en config > URL pattern detection > default prod.

**Detección por URL pattern** (fallback si no hay `active`):
- URL contiene "dev" o "test" → ambiente `dev`
- URL contiene "qa" o "staging" → ambiente `qa`
- Otro → ambiente `prod` (conservador)
- Informar: "Detecté ambiente {env} por URL. ¿Correcto?"

**Primera sesión con multi-env** (>1 ambiente configurado): preguntar una vez "Tenés {N} ambientes configurados. Activo: {env}. ¿Correcto o querés cambiar?"

**Switch de ambiente** (intent "cambiar a {env}" / "switch to {env}" / "usar prod/dev/qa"):
1. Verificar que el ambiente existe en config
2. Actualizar `active: {env}` en `.bizuit-config.yaml`
3. Invalidar token de sesión actual
4. Confirmar: "✅ Ambiente activo: {env} ({url}). Credenciales se pedirán en el próximo uso de API."

**Safety gate extendido por ambiente:**
- `dev` → sin warning de ambiente (solo confirmación estándar FR54)
- `qa` → `🟡 [QA]` warning suave: "Estás en QA. ¿Confirmar persist?"
- `prod` → `🔴 [PROD]` warning fuerte: "⚠️ PRODUCCIÓN — ¿confirmar persist del proceso '{nombre}'?"
- Cambio de ambiente resetea safety gate (si pasé de dev a prod, vuelve a preguntar)

**Prefijo visual en outputs** (cuando multi-env está activo):
- `prod` → prefijo `🔴 [PROD]` en cada output
- `qa` → prefijo `🟡 [QA]` en cada output
- `dev` → sin prefijo

**Error handling multi-env:**
- `active` apunta a ambiente inexistente → error: "Ambiente '{env}' no configurado. Disponibles: {lista}"
- `url` faltante en un ambiente → error: "Ambiente '{env}' sin URL configurada"
- YAML malformado → error: "Config inválida. Formato esperado:" + ejemplo
- URLs iguales en 2 ambientes → warning: "{env1} y {env2} apuntan al mismo servidor"

### Wizard Inline (primer uso de API)

Cuando el skill necesita API y no hay configuración:

**Turno 1 (datos no-sensibles):**
```
"Para conectar con BIZUIT necesito estos datos:
 - URL del Dashboard API (ej: https://cliente.bizuit.com/BIZUITDashboardAPI/api)
 - URL del BPMN API (ej: https://cliente.bizuit.com/BIZUITBPMNEditorBackEnd/api)
 - Usuario
 - Organización (org_id / tenant)

Proporcioná los 4 datos."
```

**Turno 2 (password separado):**
```
"Password (solo por esta sesión, no se guarda en disco):"
```

**Guardar en `.bizuit-config.yaml`:**
```yaml
# Generado por bizuit-sdd wizard. Excluido de git.
bizuit_api_url: "https://..."
bizuit_bpmn_api_url: "https://..."
bizuit_username: "..."
bizuit_org_id: "..."
# password: nunca se guarda — solo por sesión
```

### Error handling al configurar

- **Datos incompletos (3 de 4)**: indicar qué dato falta. No guardar parcial.
- **URL malformada**: "Esa URL no parece válida. Verificá el formato."
- **Auth falla 2 veces**: "Las credenciales no funcionan. ¿Querés actualizar la configuración?" → re-ejecutar wizard.
- **Connection refused**: "No puedo conectar con {url}. ¿Verificás la URL? ¿Querés actualizarla?"

## Error Handling Unificado (v2.1)

| HTTP Status | Contexto | Acción |
|-------------|----------|--------|
| 401 | Cualquier API | Re-auth (1 retry, pide password de nuevo). Si falla → ofrecer actualizar config |
| 403 | Cualquier API | "Sin permisos. Verificá el rol de tu usuario en BIZUIT." |
| 404 | Search | "Proceso '{name}' no encontrado. Verificá el nombre." |
| 500 | Persist | **NO retry automático**. BPMN guardado local (FR68). "Persist falló. Verificá en BIZUIT si se guardó parcialmente. Podés reintentar con 'retry persist'." |
| 500 | Otros | "Error del servidor BIZUIT. Intentá de nuevo en unos minutos." |
| Timeout (15s) | Cualquier API | "API no responde en 15s. Verificá la URL en .bizuit-config.yaml." A los 5s: "Tardando más de lo esperado..." (NFR13) |
| Connection refused | Cualquier API | "No puedo conectar con {url}. ¿Querés verificar/actualizar la configuración?" |

## Flujo

1. `GET $BIZUIT_API_URL/login` con header `Authorization: Basic {base64(BIZUIT_USERNAME:BIZUIT_PASSWORD)}`
2. Extraer token: `.token`. Si null → AUTH_FAILED.
3. **1 login, 1 token, 2 APIs** — el mismo token funciona en ambas con diferentes headers:
   - **Dashboard API lectura**: `Authorization: Basic {token}`
   - **Dashboard API publish**: `BZ-AUTH-TOKEN: {token}`
   - **BPMN API (todo)**: `Authorization: Bearer {token}`
4. Si 401 en cualquier call → re-auth 1 vez. Si sigue 401 → AUTH_FAILED definitivo.

Token en memoria (no disco, NFR9). Se reutiliza en la sesión.

## 2 APIs

### Dashboard API (`BIZUIT_API_URL`)

Gestiona el runtime: events (procesos publicados), VDW download/upload.

| Método | Endpoint | Auth | Descripción |
|--------|----------|------|-------------|
| GET | `/login` | `Basic {base64(user:pass)}` | Login → token |
| GET | `/eventmanager/events` | `Basic {token}` | Lista todos los eventos/procesos |
| GET | `/eventmanager/events/download?eventName=X&version=` | `Basic {token}` | Download VDW como Base64 |
| POST | `/eventmanager/publish/xaml` | `BZ-AUTH-TOKEN: {token}` | Publicar VDW (Base64) |

### BPMN API (`BIZUIT_BPMN_API_URL`)

Gestiona la persistencia: guardar/buscar/obtener BPMN XML.

| Método | Endpoint | Auth | Descripción |
|--------|----------|------|-------------|
| GET | `/bpmn/process-names` | `Bearer {token}` | Lista procesos con logicalProcessId |
| GET | `/bpmn/search?name=X&scope=all` | `Bearer {token}` | Busca por nombre |
| POST | `/bpmn/persist` | `Bearer {token}` | Guarda BPMN XML |
| GET | `/bpmn/process/{versionId}` | `Bearer {token}` | Obtiene proceso con XML |
| POST | `/bpmn/publish` | `Bearer {token}` | Publica VDW al Dashboard API |

## Error Codes (solo auth-related)

| Código | Cuándo | Mensaje | Acción |
|---|---|---|---|
| AUTH_FAILED | Login falla | "Credenciales inválidas para '{user}'" | Verificar env vars |
| AUTH_EXPIRED | 401 mid-session | "Token expirado, re-autenticando..." | Auto re-auth (1 retry) |
| API_FORBIDDEN | 403 | "Sin permisos" | NO re-auth (403 ≠ token) |
| API_NOT_FOUND | 404 | "Proceso no encontrado" | Verificar nombre |
| API_ERROR | 500 | "Error del servidor" | Retry manual |
| API_TIMEOUT | 15s sin respuesta | "API no responde" | Verificar URL |

> Códigos no auth-related → Error Catalog en `rules/README.md`.

## Drift-check auth (Story 5.1)

El drift check usa BPMN API search (`GET /bpmn/search?name={processName}&scope=all`, Bearer token). Es de lectura — no modifica nada. Timeout: 15s (default). Si falla, el edit continúa sin check (no bloqueante).

## Persist-specific auth (Story 4.4)

El persist usa BPMN API (`Authorization: Bearer {token}`). Consideraciones adicionales:

- **Timeout extendido**: 30 segundos para persist (vs 15s default) — BPMN puede ser >500KB
- **Producción check (FR69)**: Si `BIZUIT_ENVIRONMENT="production"` o usuario confirmó → advertir antes de persist. Una vez por sesión.
- **Retry en persist**: Si 401 → re-auth + retry 1 vez. Si 500 → NO retry automático (podría crear duplicados). Informar al usuario.
- **saveAction**: `"newVersion"` para create, `"update"`/`"updateVersion"` para edit

## Gotchas

- 403 ≠ 401: NO re-auth en 403
- Dashboard API: header lectura (`Authorization: Basic`) ≠ header escritura (`BZ-AUTH-TOKEN`)
- BPMN API: siempre `Authorization: Bearer`
- `version=` en download es requerido pero puede ser vacío
- `eventName` en Dashboard API = `x:Name` del root element del VDW
- `saveAction` en persist: `"newVersion"`, `"update"`, `"updateVersion"` — NO `"new"`
- Token está URL-encoded (contiene `%2f`, `%2b`) — usar tal cual
- Mensaje "tardando más de lo esperado" a los 5 seg (NFR13)
