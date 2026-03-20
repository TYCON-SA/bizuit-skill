# Naming Conventions

| Elemento | Convención | Ejemplo |
|----------|-----------|---------|
| Parámetro de negocio | p + PascalCase | pMontoTotal |
| Parámetro de sistema | PascalCase | InstanceId |
| Variable interna | PascalCase | LoggedUser |
| ID de actividad (create) | Type_SlugifiedName | UserTask_CrearSolicitud |
| ID de actividad (edit) | **Preservar original** | handleActivity1 |
| Nombre de actividad | Español descriptivo | Crear Solicitud de Compra |
| Directorio de proceso | slugified lowercase | aprobacion-compras |
| Directorio de organización | BIZUIT_ORG_ID | rdaff |

**En edit**: los IDs se preservan del VDW original (frontmatter `originalIds`). NO se re-generan.
