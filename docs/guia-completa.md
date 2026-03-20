# bizuit-sdd — Guía Completa

> Para analistas y usuarios de negocio que quieren entender y usar el skill.

---

## 1. ¿Qué es bizuit-sdd?

Pensá en bizuit-sdd como un **libro de instrucciones para Claude**. Cuando ponés el skill en la "estantería" de Claude (una carpeta especial de tu computadora), Claude aprende a trabajar con BIZUIT: puede crear procesos nuevos, documentar los existentes, y hacer cambios — todo conversando con vos.

No necesitás saber programar. Solo necesitás saber qué proceso querés crear o documentar.

---

## 2. ¿Qué puedo hacer con el skill?

| Flujo | ¿Qué hace? | Ejemplo |
|---|---|---|
| **Crear** | Genera un proceso BIZUIT desde cero, conversando | "Crear proceso de aprobación de compras" |
| **Documentar** | Analiza un proceso existente en BIZUIT y genera documentación | "Documentar el proceso de onboarding" |
| **Editar** | Modifica un proceso ya documentado | "Agregar validación de documentos al proceso de compras" |
| **Consultar** | Responde preguntas sobre un proceso | "¿Qué pasa si el monto supera $10.000?" |
| **Validar** | Verifica que una spec esté completa y correcta | "Validar la spec del proceso de compras" |
| **Generar Forms** | Genera componentes React (.tsx) para los formularios del proceso | "Generá forms para el proceso de compras" |
| **Visualizar** | Muestra el flujo del proceso como diagrama | "Mostrá el flujo del proceso de compras" |
| **Graph** | Construye/consulta relaciones entre procesos | "Graph build" / "Graph query tabla X" |
| **Vistas** | Genera vistas para stakeholders (ejecutiva, QA) | "Vista ejecutiva del proceso de compras" |
| **Exportar** | HTML self-contained offline | "Exportar proceso de compras" |

---

## 3. Instalación

La instalación la hace IT o un compañero técnico. Si ya está instalado, **saltá a la sección 4**.

### ¿Qué necesitás?

- Una computadora con **Claude Code** instalado (o una cuenta de claude.ai)
- Las **credenciales de BIZUIT** de tu organización (preguntale a IT)
- **Git** instalado (preguntale a IT si no sabés)

### Pasos

1. IT clona el repositorio del skill en tu máquina
2. IT ejecuta el script de instalación (`install-skill.sh` o `install-skill.ps1`)
3. El script pregunta las credenciales de BIZUIT — IT las ingresa
4. Listo — abrí Claude Code y decí "hola"

### ¿Qué pedirle a IT?

Decile:

> "Necesito que instales el skill bizuit-sdd en mi máquina. Es un `git clone` + correr un script. Las instrucciones están en la guia-rapida.md del repo. Necesito las credenciales de BIZUIT: URL de Dashboard API, URL de BPMN API, usuario, password, y organization ID."

---

## 4. Mi primera spec

> **Si ya está instalado, empezá acá.**

### Paso 1: Abrir Claude Code

Abrí la terminal y escribí `claude` (o abrí Claude Code desde VS Code).

### Paso 2: Decir qué proceso querés

Ejemplo:

> "Crear proceso de aprobación de vacaciones"

### Paso 3: Responder las preguntas

Claude te va a hacer preguntas para entender el proceso:
- ¿Quién participa? (jefe, RRHH, empleado)
- ¿Qué pasos tiene? (solicitud → aprobación → registro)
- ¿Qué pasa si no se aprueba?
- ¿Hay límites de tiempo?

**No te preocupes si no sabés alguna respuesta.** Podés decir "no sé" y Claude marca esa parte como pendiente. Después la completás cuando tengas la información.

### Paso 4: Revisar el resultado

Claude genera una **spec** (especificación) del proceso con:
- Objetivo
- Actores
- Caminos (happy path + errores)
- Integraciones técnicas
- Casos especiales

La spec se guarda automáticamente en tu máquina.

---

## 4b. Generar formularios React

> **Prerequisitos:** una spec completa (creada o documentada) + el SDK `@tyconsa/bizuit-form-sdk` instalado en tu proyecto React.

### Paso 1: Tener una spec completa

Primero creá o documentá el proceso (sección 4). Los forms se generan a partir de la spec.

### Paso 2: Pedir los forms

> "Generá forms para el proceso de aprobación de compras"

### Paso 3: Revisar el resultado

Claude genera en `processes/{org}/{slug}/forms/`:
- **hooks.ts** — lógica compartida (carga de datos, submit, lock management)
- **types.ts** — constantes del proceso (PROCESS_NAME, ACTIVITIES, EVENTS)
- **{ActivityName}.tsx** — 1 componente por UserTask (el primero es START, los demás CONTINUE)
- **index.ts** — barrel export de todos los forms

**Ejemplo con Pedido de Soporte (4 UserTasks):**
```
forms/pedido-de-soporte/
├── hooks.ts
├── types.ts
├── RegistrarSolicitud.tsx          ← START (inicia el proceso)
├── ClasificarTicket.tsx            ← CONTINUE (acciones: Clasificar)
├── ResolverProblema.tsx            ← CONTINUE (acciones: Resolver)
├── ConfirmarResolucion.tsx         ← CONTINUE (acciones: Confirmar, Rechazar)
└── index.ts
```

### Paso 4: Configurar el proyecto React

Los forms requieren el provider stack de BIZUIT en un layout padre:

```tsx
import { BizuitSDKProvider } from '@tyconsa/bizuit-form-sdk'
import { BizuitThemeProvider, BizuitAuthProvider } from '@tyconsa/bizuit-ui-components'

// En tu layout:
<BizuitThemeProvider>
  <BizuitAuthProvider>
    <BizuitSDKProvider config={{ apiUrl: '...' }}>
      {children}
    </BizuitSDKProvider>
  </BizuitAuthProvider>
</BizuitThemeProvider>
```

### Nota: Regenerar

Si ejecutás "generá forms" de nuevo, el skill hace un backup automático antes de sobreescribir. Los archivos que hayas customizado se preservan en `.backup-{fecha}/`.

---

## 5. Preguntas frecuentes

**¿Puedo usarlo sin credenciales de BIZUIT?**
Sí. El skill funciona en modo degradado — podés crear specs y validarlas sin conectar a BIZUIT. Solo necesitás credenciales para publicar el proceso o documentar uno existente.

**¿Qué pasa si me equivoco?**
Podés corregir en cualquier momento. Decile a Claude "cambiar el aprobador a RRHH" o "agregar un paso de validación".

**¿Puedo interrumpir y retomar después?**
Sí. El progreso se guarda en disco. La próxima vez que abras Claude Code, decí "editar proceso de vacaciones" y retomás donde quedaste.

**¿Cómo actualizo el skill?**
Decile a IT que ejecute `git pull` en la carpeta del skill. O hacelo vos si tenés acceso a la terminal:
```
cd ~/.claude/skills/bizuit-sdd && git pull
```

---

## 6. Seguridad y privacidad

El contenido de los procesos se envía a **Claude (Anthropic)** para su procesamiento. Esto incluye nombres de actividades, queries SQL, y estructura del proceso.

**Si tu organización tiene requisitos de data residency, consultá con tu equipo legal antes de usar el skill con procesos que contengan datos sensibles.**

El skill:
- **NO almacena credenciales** en sus archivos — están en las variables de entorno de tu máquina
- **Enmascara passwords** automáticamente si aparecen en un proceso (las reemplaza por `***`)
- **Separa datos por organización** — cada tenant tiene su propia carpeta

---

## 7. Cómo pedir ayuda a IT

Si algo no funciona, decile a IT:

> "El skill bizuit-sdd me da este error: [copiar el error]. ¿Podés correr `./scripts/install-skill.sh --check` en la carpeta del skill para ver qué pasa?"

El health check (`--check`) verifica que todo esté en su lugar y reporta qué falta.

También podés decirle a Claude: **"diagnóstico"** — el skill hace un health check desde adentro.

---

## 8. BizuitForms — Forms Automáticos

### ¿Qué son los forms BizuitForms?

Los forms BizuitForms son los formularios que los usuarios llenan cuando interactúan con un proceso. Son pantallas con campos (nombre, fecha, monto), botones (enviar, cancelar), y datos que se cargan del proceso.

Antes, estos forms se creaban manualmente en el editor visual de BizuitForms. Ahora, el skill los genera automáticamente como parte del BPMN.

### ¿Cómo funciona?

Cuando creás un proceso con el skill, el BPMN generado ya incluye los forms embebidos. Cada StartEvent con inicio humano y cada UserTask recibe un form con:

- **Campos** pre-configurados según lo que documentaste en la spec (nombre, tipo, validaciones)
- **Bindings** a los parámetros del proceso (la conexión entre el campo y el dato)
- **DataSources** para combos y listas (si documentaste las queries en el detalle técnico)
- **Botones** de acción (Enviar + Cancelar por default)

### ¿Qué tengo que hacer yo?

**Nada extra.** Los forms se generan automáticamente al crear o editar un proceso. Después podés:

1. **Abrir el form en el editor** de BizuitForms para ajustar el diseño visual (colores, posiciones, estilos)
2. **Agregar lógica custom** como eventos JavaScript o formateo condicional
3. **Configurar DataSources** que el skill no pudo generar (por falta de info en la spec)

### ¿Qué controles se generan?

El skill mapea 23 tipos de control según el tipo de dato: campos de texto, combos, checkboxes, date pickers, archivos adjuntos, firma digital, geolocalización, tablas editables, y más.

### Ejemplo

Si documentaste un UserTask "Registrar Solicitud" con campos:
- pNombreSolicitante (texto, obligatorio)
- pMonto (número)
- pFechaSolicitud (fecha)

El form generado tiene:
- Un InputTextbox "Nombre del Solicitante" (obligatorio)
- Un InputTextbox "Monto" (dataType: Integer)
- Un DatePicker "Fecha de Solicitud"
- Botones "Enviar" y "Cancelar"
- Primary DataSource con los 3 parámetros bindeados

### Referencia técnica

Para detalles completos sobre los 23 controles, el schema JSON, y la integración con procesos, consultá las rules de referencia:
- `rules/bizuit/forms/bizuit-forms-controls.md` — Controles y mapeo
- `rules/bizuit/forms/bizuit-forms-json-schema.md` — Schema JSON y encoding
- `rules/bizuit/forms/bizuit-forms-process-integration.md` — Integración BPMN/VDW

---

## 9. Visual Output — Diagrama del proceso (v1.3)

### ¿Qué es?

Cuando documentás, creás o editás un proceso, el skill genera automáticamente una representación visual del flujo como texto indentado. No necesitás pedirlo — aparece al final del output.

### Ejemplo

```
📊 Flujo del Proceso: PedidoSoporte v3

→ Inicio (startEvent)
  → RegistrarSolicitud (userTask) [Solicitante] [form: 5 controles]
  → ClasificarTicket (userTask) [Soporte]
  → ¿esCritico? (exclusiveGateway)
    → [Sí] EscalarAJefe (serviceTask/Email)
    → [No] ResolverProblema (userTask) [Técnico]
  → ConfirmarResolucion (userTask) [Solicitante]
→ Fin (endEvent)

📋 Test Paths (3):
  1. Happy path [happy]: Inicio → Registrar → Clasificar → No crítico → Resolver → Confirmar → Fin
  2. Escalado [alternative]: Inicio → Registrar → Clasificar → Crítico → Escalar → Fin
  3. Rechazo [error]: Inicio → Registrar → Clasificar → Resolver → Confirmar(Rechazar) → Fin

📈 Resumen: 6 actividades, 1 gateway, 3 actores, 3 test paths, 0 anomalías
```

### Formatos disponibles

| Comando | Formato | Cuándo usarlo |
|---|---|---|
| (automático) | Diagrama Mermaid | Default — diagrama gráfico en Claude App y VS Code |
| `--visual text` | Texto indentado | Para CLI o si preferís texto plano |
| `--no-visual` | Sin visual | Si solo querés la spec sin diagrama |
| `--expand-all` | Texto expandido | Para procesos grandes donde se colapsaron secciones |

### Procesos grandes (>20 actividades)

El skill colapsa automáticamente secciones con muchas actividades para que el diagrama sea legible:
```
→ [+12 actividades en BloqueProcesamiento]
```

Usá `--expand-all` para ver todo expandido.

### En edición (diff visual)

Cuando editás un proceso, el visual muestra los cambios con colores:
- **Verde**: actividades agregadas
- **Rojo**: actividades eliminadas
- **Amarillo**: actividades modificadas

---

## 10. Knowledge Graph — Relaciones entre procesos (v1.3)

### ¿Qué es?

El knowledge graph es un mapa de conexiones entre tus procesos documentados. Te dice qué tablas SQL comparten, qué APIs usan en común, y qué pasa si cambiás algo.

### Comandos

| Comando | Qué hace |
|---|---|
| `"graph build"` | Construye/actualiza el graph a partir de todas las specs en `processes/` |
| `"graph query tabla Clientes"` | Busca qué procesos usan la tabla Clientes |
| `"graph validate"` | Detecta inconsistencias (tablas huérfanas, integraciones rotas) |
| `"graph status"` | Muestra estado del graph: nodos, aristas, health |

### Blast radius

La feature más útil: cuando vas a cambiar algo, el graph te dice qué se puede romper.

> "¿Qué procesos se ven afectados si cambio la tabla Facturas?"

El skill analiza el graph y lista todos los procesos que usan esa tabla, con qué operaciones (SELECT, INSERT, UPDATE, DELETE).

### Health status

Cada nodo del graph tiene un semáforo:
- **Verde**: todo OK
- **Amarillo**: warnings (ej: tabla usada solo en modo lectura)
- **Rojo**: problemas detectados (ej: referencia a tabla/SP que no existe en ningún otro proceso)

---

## 11. Vistas para Stakeholders (v1.3)

### Vista ejecutiva

Resumen de 1 página para directivos y managers. Solo lo esencial:

> "Vista ejecutiva del proceso de compras"

Incluye: objetivo, actores, camino crítico, riesgos, y métricas clave. Sin detalles técnicos.

### Vista QA

Para el equipo de testing. Incluye:

> "Vista QA del proceso de compras"

- Test paths completos con datos de prueba sugeridos
- Condiciones de cada gateway
- Edge cases y escenarios de error
- Checklist de validación

### Form preview

Vista estructural HTML de los formularios del proceso:

> "Form preview del proceso de compras"

Muestra un preview con grid de 6 columnas, controles posicionados, y legend de tipos. No es el form real — es una representación para revisar layout y campos sin abrir el editor.

### Export HTML

Genera un archivo HTML self-contained (<50KB) que funciona offline:

> "Exportar proceso de compras"

El archivo incluye el flujo como SVG inline, sin dependencias externas. Útil para compartir con personas que no tienen acceso al skill.
