# Error Catalog

Cuando cualquier operación falla, usar estos códigos:

| Código | Contexto | Acción |
|--------|----------|--------|
| AUTH_FAILED | Login | Verificar BIZUIT_USERNAME/PASSWORD |
| AUTH_EXPIRED | Token mid-session | Re-auth automático (1 retry) |
| API_FORBIDDEN | 403 | NO re-auth — verificar permisos |
| API_NOT_FOUND | 404 | Verificar nombre de proceso |
| API_ERROR | 500 | Informar, sugerir retry manual |
| API_TIMEOUT | 15s | Verificar URL |
| VDW_EMPTY | Download vacío | Verificar que el proceso existe en BIZUIT |
| VDW_PARSE_FAIL | Tipo desconocido | Marcar actividad como ⚠️ No parseada |
| SPEC_CORRUPT | YAML inválido | Ofrecer reparar/nueva/abortar |
| SPEC_DRIFT | Version mismatch | Advertir y ofrecer merge |
| BPMN_INVALID | Violación de rules | Listar violaciones, NO persistir |
| PERSIST_FAIL | API error | Informar, sugerir retry |
| DIR_FAIL | Sin permisos | Verificar permisos de filesystem |
| NAME_EXISTS | Nombre duplicado | Sugerir nombre alternativo |

**Regla general**: nunca fallar silenciosamente. Siempre informar al usuario qué pasó y qué puede hacer.
