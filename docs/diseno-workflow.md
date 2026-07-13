# Workflow — Documento de diseño

> **📌 DOCUMENTO FUENTE DE VERDAD — v1 (definiciones iniciales).**
> Este es el documento canónico de diseño de Workflow: producto, modelo de datos y arquitectura.
> Abarca los tres repos: `workflow-api` (NestJS), `workflow-frontend` (React) y
> `work-flow-flutter` (mobile). Ante cualquier contradicción con el código actual o con otros
> documentos, **manda este**. El código hoy corre con mocks y un modelo desalineado (ver
> `integracion-api.md`); este documento describe el **modelo objetivo**.
>
> Estado: diseño acordado, v1. Fecha: 2026-07-10.
> El esquema se diseña completo acá; la construcción va por fases (§13). Las decisiones y sus
> alternativas descartadas están en §14.
>
> **Cómo evoluciona esta documentación**: este documento fija las *definiciones*. Cada fase de
> construcción (§13) tendrá su propio documento/spec de implementación (`docs/fase-XX-*.md`) que
> baja estas definiciones a esquema SQL concreto, contratos de endpoint y tareas — sin
> re-discutir el modelo. Si una fase necesita cambiar una definición, se actualiza **acá primero**
> y se registra en §14. Índice de toda la documentación en `docs/README.md`.

---

## Índice

1. [Qué es Workflow y qué problema resuelve](#1)
2. [Qué NO hace (límites del alcance)](#2)
3. [Actores, roles y el día típico](#3)
4. [Los principios de diseño (leer antes del modelo)](#4)
5. [El modelo en tres capas](#5)
6. [Capa 1 — Referencia / catálogo](#6)
7. [Capa 2 — Hechos / eventos](#7)
8. [Capa 3 — Proyecciones / estado](#8)
9. [Módulo comercial: licitación → presupuesto → obra → certificación](#9)
10. [Módulo de compras: requerimiento → orden → recepción](#10)
11. [Sincronización offline-first](#11)
12. [Permisos con alcance](#12)
13. [Arquitectura técnica y plan de construcción por fases](#13)
14. [Decisiones tomadas y alternativas descartadas](#14)
15. [Glosario](#15)

---

<a name="1"></a>
## 1. Qué es Workflow y qué problema resuelve

**Workflow** es un SaaS B2B para empresas que proveen **servicios y personal** a operaciones
mineras. El cliente ancla y arquetipo es **Arq&Top**: provee topógrafos, arquitectos,
vehículos y herramientas a minas en distintas provincias de Argentina (Sales de Jujuy, POSCO,
Río Tinto, Río Grande, La Lucinda, Tolar Grande, Monte Quemado, entre otras).

### El dolor real (validado con datos)

Hoy Arq&Top opera con **Excel + muchos grupos de WhatsApp**. El Excel real que usan
(`SEGUIMIENTO DE VEHICULOS 2025-2026.xlsx`) es, tabla por tabla, una versión manual del modelo
de este documento: por cada vehículo llevan a mano un encabezado de datos fijos, un **log de
movimientos** (`fecha | ubicación | personal a cargo | novedades`) y un **log de mantenimiento**
(`fecha | km | trabajo | taller | monto | n° factura`). Llegaron solos a un modelo de eventos
porque es la forma natural de trackear un activo caro en el tiempo.

El sistema resuelve cuatro problemas concretos, en orden de dolor:

1. **Vencimientos que dejan gente y equipos afuera de la mina.** A una mina no se entra sin los
   papeles al día: apto psicofísico de altura, inducción minera, matrícula profesional, ART del
   lado de las personas; seguro, RTO/revisión técnica, matafuegos, homologación por mina, VTV
   del lado de vehículos; **calibración de instrumentos** (una estación total de topografía sin
   calibración vigente produce mediciones que el cliente rechaza). Hoy esto se controla con
   Excel y falla: el profesional viaja cientos de kilómetros y lo rebotan en la garita.
   **Workflow avisa con anticipación qué se vence y quién/qué no va a poder subir.**

2. **Trazabilidad de activos caros: dónde está, quién lo tiene, en qué estado.** Herramientas e
   instrumentos de miles de dólares que rotan entre base y obras. El sistema responde en
   cualquier momento *dónde está*, *quién es responsable* y *cuál es su historia* (movimientos,
   custodias, servicios, fotos) — la "Hoja de Vida" del activo.

3. **Captura de campo desde el teléfono, sin señal.** El operario en la mina carga movimientos,
   estados, novedades, fotos y auditorías **offline**, y sincroniza al recuperar cobertura.
   Reemplaza los grupos de WhatsApp y la transcripción manual.

4. **Control comercial: presupuestado vs real.** Cotizar servicios a la minera y, cuando la obra
   se ejecuta, comparar en vivo lo presupuestado contra el costo real (horas de personal,
   activos asignados, materiales consumidos, servicios de mantenimiento).

### Multi-tenant

Cada empresa cliente de Workflow (Arq&Top y futuras) es un **tenant** aislado. Todo dato de
negocio cuelga de un `tenant_id`. Arq&Top es el primer tenant; el producto se diseña genérico.

---

<a name="2"></a>
## 2. Qué NO hace (límites del alcance)

Declarar los límites es parte del diseño: evita el "y si también..." que convierte un producto
en un motor de reglas genérico que no sirve a nadie.

- **No emite factura fiscal.** No hay integración con ARCA/AFIP, ni CAE, ni tipos de
  comprobante. Workflow llega hasta la **certificación** (lo ejecutado y cobrable); la factura
  la emite el sistema contable del cliente. El modelo deja el lugar para agregarlo (§9).
- **No es contabilidad.** No hay cuentas por pagar/cobrar, conciliación bancaria, pagos,
  retenciones. Registra qué se compró y qué se recibió; no cuánto se debe ni cuándo se paga.
- **No es un motor de reglas configurable.** El cliente **configura** (elige entre opciones
  cerradas: prende flags, elige uno de cuatro modelos de precio, define sus puestos), no
  **customiza** (no escribe fórmulas ni workflows arbitrarios).
- **No hace liquidación de sueldos.** Registra horas y asistencia; la liquidación es externa.
- **No es un GIS.** Guarda coordenadas de eventos, no hace ruteo ni mapas de calor.

---

<a name="3"></a>
## 3. Actores, roles y el día típico

Todos los actores usan la **app mobile**; la oficina usa además la **web**. Arq&Top tiene ~80
empleados y ~6 obras simultáneas.

| Rol | Dónde opera | Día típico |
|---|---|---|
| **Operario / técnico de campo** (topógrafo, arquitecto) | Mobile, en la mina, frecuentemente **sin señal** | Marca subida/bajada de obra; registra movimientos de los activos que lleva; carga bitácora diaria, fotos de estado, auditorías de herramientas; reporta incidentes. Todo se sincroniza al bajar. |
| **Supervisor de obra** | Mobile + web | Ve su obra: personal presente, activos en sitio, vencimientos próximos de su gente. Aprueba/revisa evidencia de su obra (permiso con **alcance de obra**). |
| **Encargado de pañol / logística** | Web + mobile en base | Gestiona almacenes, transferencias, custodia de activos, recepción de compras, órdenes de servicio (mantenimiento). |
| **Oficina / administración** | Web | Controla vencimientos de todo el tenant, arma presupuestos, gestiona compras, certifica obras, ve dashboards. |
| **RRHH / analista** | Web | Alta de empleados, carga y renovación de habilitaciones (apto, inducción, matrícula), reportes. |
| **Admin del tenant** | Web | Usuarios, roles, catálogos, configuración de la empresa. |
| **Super admin** (Workflow) | Web | Gestión de tenants. Transversal a todo el sistema. |

**Relación Usuario ↔ Empleado**: la mayoría de los empleados tiene un `Usuario` para entrar a la
app. Algunos usuarios (admin de oficina puro) pueden no ser `Empleado`. Son entidades separadas
vinculadas por `empleado.usuario_id` (nullable). Ver §6.

---

<a name="4"></a>
## 4. Los principios de diseño (leer antes del modelo)

Cinco principios gobiernan todo el modelo. Si algo del esquema parece raro, casi siempre se
explica por uno de estos.

### P1 — Tres tipos de datos, tres tratamientos

No todo el sistema es igual. Cada tabla es una de tres cosas, y se trata distinto:

- **Referencia / catálogo** → CRUD mutable clásico. Se corrige con `UPDATE`, sin historial.
  Es ~la mitad de las tablas (§6). Los ABMs viven acá.
- **Hechos / eventos** → **append-only**. Registran que algo pasó en un momento. Nunca se
  editan; se corrigen con otro hecho (contra-asiento), igual que la contabilidad (§7).
- **Proyecciones / estado** → **caché derivada**. Las escribe el sistema como consecuencia de un
  hecho, nunca un usuario. Se pueden borrar y reconstruir enteras desde los hechos (§8).

La mayor fuente de errores en sistemas así es creer que "append-only" aplica a las tres. Aplica
solo a los hechos.

### P2 — Estado actual = proyección de un log de hechos

`activo.ubicacion_actual` no es la verdad: es un **resumen** de la verdad, que vive en el log de
movimientos. La oficina la consulta con un `SELECT` normal (no se reconstruye nada al leer),
pero se escribe solo desde eventos. Esto es lo que hace posible offline (P3) y trazabilidad.
No es event sourcing puro: hay tablas de estado reales, consultables en SQL; el log solo es la
autoridad.

### P3 — Offline-first, y por eso hechos inmutables con ID de cliente

La app de campo escribe sin señal. Dos operarios pueden tocar el mismo activo sin verse. Con
estado mutable eso es un conflicto de escritura sin solución correcta. Con **hechos inmutables**
no hay conflicto: entran los dos eventos, se ordenan por cuándo ocurrieron, la proyección se
recalcula. Consecuencias transversales, obligatorias en todas las tablas de hechos:

- **IDs UUIDv7 generados por el cliente** (ordenables por tiempo). Las escrituras son
  `PUT /recurso/:id` **idempotentes**, no `POST`. Reintentar la sync no duplica.
- **Bitemporalidad**: cada hecho lleva `ocurrido_en` (reloj del teléfono, *cuándo pasó*) y
  `recibido_en` (reloj del servidor, *cuándo el sistema se enteró*). La lógica de negocio ordena
  por `ocurrido_en`; la auditoría usa `recibido_en`. El estado puede cambiar **retroactivamente**
  cuando llega un evento viejo, y la UI debe poder explicarlo ("cambió por un evento del 10:04
  sincronizado a las 20:30"). El reloj del cliente no se confía para nada sensible: si la
  diferencia entre ambos tiempos es absurda, se marca para revisión.

### P4 — Configuración cerrada, no customización abierta

Cada punto de flexibilidad es un `enum` chico y cerrado que diseñamos y entendemos, no un campo
libre de lógica. Modelos de precio: cuatro. Tipos de documento: catálogo por tenant. Estados:
enumerados. Agregar un caso el año que viene es una fila; sacar generalidad de un esquema con
datos de veinte clientes es imposible.

### P5 — Cada fricción de campo se paga con datos falsos

Si el sistema le exige al operario 30 taps para mover una caja de herramientas, va a mover la
caja y no registrar los contenidos, y a los tres meses el inventario miente. Por eso las
operaciones compuestas (mover una caja mueve su contenido; recibir una compra crea los activos)
son **un gesto** que genera múltiples hechos por debajo, agrupados con un `correlation_id`.

---

<a name="5"></a>
## 5. El modelo en tres capas

Vista de pájaro. El detalle de cada tabla en §6–§10.

```
┌─ CAPA 1 · REFERENCIA (mutable, CRUD) ─────────────────────────────────────┐
│  Tenant · Usuario · Rol · AsignacionDeRol                                  │
│  Empleado · Puesto · PatronDeRotacion                                       │
│  Cliente · Sitio                                                            │
│  Proveedor · Almacen                                                        │
│  Marca · ModeloDeActivo · CondicionDeActivo · TipoDeDocumento              │
│  ServicioPlantilla                                                          │
└────────────────────────────────────────────────────────────────────────────┘
        │ definen el vocabulario; los hechos los referencian
        ▼
┌─ CAPA 2 · HECHOS (append-only, con ocurrido_en/recibido_en, id de cliente)─┐
│  Activos:   MovimientoDeActivo · EventoDeCustodia · OrdenDeServicio         │
│  Stock:     AsientoDeStock                                                  │
│  Personal:  Marcacion · Asignacion(*) · ParteDeHoras                        │
│  Campo:     Submission (bitácora/incidente/auditoría/informe) · Adjunto     │
│  Docs:      Documento(**)                                                   │
│  Comercial: Certificacion · Recepcion                                       │
└────────────────────────────────────────────────────────────────────────────┘
        │ el sistema recalcula
        ▼
┌─ CAPA 3 · PROYECCIONES (caché derivada, reconstruible) ───────────────────┐
│  Activo.{ubicacion, custodio, condicion, km}_actual                        │
│  SaldoDeStock(modelo, ubicacion) = Σ delta                                 │
│  Empleado.{en_obra, obra_actual, estado_habilitaciones}                    │
│  VencimientosProximos (vista sobre Documento)                              │
└────────────────────────────────────────────────────────────────────────────┘

Comercial (mayormente mutable, con hechos donde corresponde):
  Licitacion · Presupuesto · LineaDePresupuesto · Obra · LineaDeContrato
  Requerimiento · OrdenDeCompra · LineaDeOrdenDeCompra
```

(*) `Asignacion` es un plan con período (mutable-ish); la `Marcacion` es el hecho. Ver §7.4.
(**) `Documento` es un caso mixto: se comporta como referencia pero se **renueva** creando filas
nuevas, conservando historia. Ver §6 y §8.

**Convención de importes (P4)**: todo importe es un par **`(monto: decimal, moneda: enum)`**.
Nunca un número suelto. Cuando se consolida o compara entre monedas, se guarda además la
`cotizacion_referencia` y su fecha.

**Convención de identidad y tiempo (P3)**: toda entidad hereda `id: uuid` (v7),
`tenant_id`, `created_at`, `updated_at`, `deleted_at` (soft-delete). Las tablas de **hecho**
agregan `ocurrido_en`, `recibido_en`, `registrado_por` (usuario), y opcional `correlation_id`,
`anulado_en`/`anulado_por`/`motivo_anulacion`.

---

<a name="6"></a>
## 6. Capa 1 — Referencia / catálogo

Todo CRUD mutable, tenant-scoped, soft-delete.

### Organización y acceso

| Entidad | Campos clave | Notas |
|---|---|---|
| **Tenant** | razón social, cuit, logo, config | La empresa cliente de Workflow. `tenants.*` es exclusivo de super admin. |
| **Usuario** | email, nombre, apellido, hash, activo | Credencial de acceso. Único por `(tenant, email)`. |
| **Rol** | nombre, permisos `string[]` | Datos, no código. Convención `modulo.accion` + wildcards. Puede ser custom por tenant. |
| **AsignacionDeRol** | usuario, rol, **alcance** (`GLOBAL`\|`OBRA`), alcance_id | **Clave para permisos con scope (§12).** Un usuario puede ser admin global y a la vez supervisor de la obra X. |

### Personal

| Entidad | Campos clave | Notas |
|---|---|---|
| **Empleado** | legajo, nombre, apellido, dni, cuil, puesto_id, usuario_id?, fecha_ingreso, contacto, emergencia | `usuario_id` nullable (no todo empleado entra a la app; no todo usuario es empleado). |
| **Puesto** | nombre, descripción | Topógrafo, arquitecto, oficial electricista… Se referencia desde presupuestos (precio por puesto). |
| **PatronDeRotacion** | nombre, días_trabajo, días_descanso | 14x7, 7x7… Habilita derivar `en_descanso` y planificar dotación (§7.4). |

Las **habilitaciones** del empleado (apto psicofísico, inducción, matrícula, ART) **no** son
campos del empleado: son `Documento` (ver abajo), porque tienen vencimiento y renovación.

### Comercial (referencia)

| Entidad | Campos clave | Notas |
|---|---|---|
| **Cliente** | razón social, cuit, contacto | La minera contratante. Reemplaza el `varchar clientCompany` actual. |
| **Sitio** | cliente_id, nombre, ubicación, geo | El yacimiento/mina. Un cliente tiene varios sitios. Las "empresas/obras" del Excel (POSCO, Río Tinto…) son sitios. |
| **Proveedor** | razón social, cuit, rubro, contacto | Talleres (Pussetto, Sagle, Lalo Frenos…), aseguradoras, vendedores. Origen de compras y servicios. |

### Inventario (catálogo)

| Entidad | Campos clave | Notas |
|---|---|---|
| **Almacen** | nombre, tipo (`CENTRAL`\|`EN_OBRA`), sitio_id?, dirección | Depósito. Puede estar en base o en una obra. |
| **Marca** | nombre | Ford, Iveco, Metz, Biassoni… |
| **ModeloDeActivo** | marca_id, nombre, categoría, **flags de comportamiento** | Ver flags abajo. "Hilux 4x4", "Estación Total Leica TS16". |
| **CondicionDeActivo** | nombre, orden | **Tabla editable** (no enum): Bueno, Regular, Malo, Fuera de servicio… configurable por tenant. |

**Categorías de activo** (`enum`, ya existe y ampliable con `ALTER TYPE`): `VEHICULO`,
`HERRAMIENTA`, `CAJA_HERRAMIENTAS`, `INSTRUMENTO` (estación total, nivel…), `EPP`,
`CABLE_ACCESORIO`, `CONSUMIBLE`, `EQUIPO` (grupo electrógeno, moto, cuatriciclo, motosierra).

**Flags de comportamiento del modelo** (P4 — configuran el flujo sin cambiar el esquema):
`requiere_numero_serie`, `requiere_custodia`, `requiere_auditoria_diaria`,
`es_vehiculo` (habilita campos patente/chasis/km y documentos vehiculares),
`tracking` (`INDIVIDUAL` = una fila por unidad física con identidad; `BULK` = saldo por cantidad).
La empresa que no quiere trackear algo pone el flag en `false` — el esquema no cambia, el trabajo
del operario sí.

### Documentos y plantillas

| Entidad | Campos clave | Notas |
|---|---|---|
| **TipoDeDocumento** | nombre, aplica_a (`EMPLEADO`\|`ACTIVO`\|`OBRA`\|`TENANT`), requiere_vencimiento, días_preaviso | Catálogo configurable por tenant: Apto psicofísico, Inducción minera, Matrícula, ART, Seguro, RTO, Matafuegos, Homologación, Calibración, VTV… |
| **ServicioPlantilla** | nombre, líneas precargadas | Plantilla reutilizable de líneas de presupuesto ("Montaje eléctrico tipo" = 6 líneas). Un "servicio a medida" parte de acá y se edita. |

**Documento** (entidad central del dolor #1) — dueño polimórfico, con vencimiento:

| Campo | Descripción |
|---|---|
| `dueño_tipo`, `dueño_id` | Polimórfico: apunta a Empleado, Activo, Obra o Tenant. |
| `tipo_documento_id` | FK a TipoDeDocumento. |
| `numero` | Póliza, matrícula, N° de certificado… |
| `emisor` | Aseguradora, organismo, taller de calibración… |
| `emitido_en`, `vence_en` | Fechas. `vence_en` es el corazón de las alertas. |
| `archivo_adjunto` | Vía `Adjunto` (§7.5). |
| `estado` | Derivado (§8): `VIGENTE` / `POR_VENCER` / `VENCIDO`. |

**Renovación**: renovar = crear un `Documento` nuevo del mismo `(dueño, tipo)`; el anterior queda
como historia (vencido). La consulta "documento vigente de X" toma el de mayor `vence_en`. Del
Excel: un vehículo puede tener **dos matafuegos** (1kg y 5kg) con vencimientos distintos → son
dos `Documento` del mismo tipo, sin problema.

---

<a name="7"></a>
## 7. Capa 2 — Hechos / eventos

Todas append-only. Cada fila lleva `ocurrido_en`, `recibido_en`, `registrado_por`, y soporta
anulación (marcado, nunca borrado — ver "ventana de gracia" abajo).

### 7.1 MovimientoDeActivo

El log de "dónde estuvo cada activo". El `activo.ubicacion_actual` (§8) es su proyección.

| Campo | Descripción |
|---|---|
| `activo_id` | Qué se movió. |
| `desde_ref_tipo`, `desde_ref_id` | Origen. Nullable = alta inicial. |
| `hasta_ref_tipo`, `hasta_ref_id` | Destino. **Puntero polimórfico**: `ALMACEN`\|`OBRA`\|`ACTIVO`\|`GPS`\|`LIBRE`. |
| `lat`, `lng`, `nota_ubicacion` | Para destino GPS/LIBRE. |
| `custodio_empleado_id` | Quién queda a cargo tras el movimiento (si el modelo `requiere_custodia`). |
| `evidencia` | Checklist/fotos del estado en el movimiento (vía Submission/Adjunto). |
| `correlation_id` | Agrupa movimientos disparados por un mismo gesto (P5). |

**La caja de herramientas como ubicación** (resuelve los sub-ítems del Excel, `S/N ATH-100-xxxx`):
una llave serializada es un `Activo` cuyo `hasta_ref_tipo = ACTIVO` (la caja). Mover la caja a una
obra genera, en un gesto, el movimiento de la caja **y** el de sus contenidos, con el mismo
`correlation_id`. Una herramienta puede salir sola de la caja: es un movimiento normal.

### 7.2 EventoDeCustodia

Custodia es un eje **independiente** de ubicación (una herramienta puede estar en la obra X bajo
responsabilidad de Juan). Se activa solo si `modelo.requiere_custodia` (respuesta "mixto según
el activo"). Del Excel: "PERSONAL A CARGO", "RECIBE SANDRO", "RETIRA PATRICIO".

| Campo | Descripción |
|---|---|
| `activo_id` | Qué. |
| `de_empleado_id` | Quién lo tenía (nullable = primera entrega). |
| `a_empleado_id` | Quién lo recibe. |
| `evidencia` | Firma/foto opcional. |

`activo.custodio_actual` es el `a_empleado_id` del último evento (§8).

### 7.3 OrdenDeServicio (mantenimiento)

Del Excel ("HOJA DE VIDA": fecha, km, trabajo, taller, monto, n° orden/factura). Historial de
mantenimiento del activo — para equipos caros, es medio negocio.

| Campo | Descripción |
|---|---|
| `activo_id` | Qué se reparó/mantuvo. |
| `proveedor_id` | El taller. |
| `fecha`, `km` | Cuándo y con qué kilometraje. |
| `descripcion` | "Servicio 40.000km, filtros y aceite". |
| `numero_orden_factura` | Referencia del taller. |
| `costo` | `(monto, moneda)`. Alimenta el costo real de la obra si el activo estaba asignado. |
| `estado` | `PENDIENTE` / `EN_TALLER` / `COMPLETADO`. |

> Futuro (diseñado, no v1): `PlanDeMantenimiento` preventivo — servicios recurrentes por km o
> tiempo, y los "arranques periódicos de control" del Excel ("poner en marcha 15 min"). Se
> modela como plantilla que genera `OrdenDeServicio` pendientes.

### 7.4 Personal: plan vs realidad

Tres conceptos donde el API hoy tiene uno mal nombrado (`ProjectAssignment`).

- **Asignacion** (el *plan*): `empleado, obra, desde, hasta, puesto, patron_rotacion`. Es lo que
  dibuja el **Gantt de personal**. Semi-mutable: se puede reprogramar (es planificación).
- **Marcacion** (el *hecho*): `empleado, obra, tipo (SUBE|BAJA), ocurrido_en, registrado_por`.
  Append-only. Es lo que hoy es `ProjectAssignment.movementType`.
- **ParteDeHoras** (el *hecho de tiempo*, **diseñado, no v1**): `empleado, obra, fecha, horas,
  tarea/linea_contrato, estado_aprobacion`. Base de la facturación por hora (§9).

`empleado.en_obra` = última marcación es `SUBE`. `en_descanso` = el patrón de rotación indica
descanso hoy. (Hoy el API hardcodea `en_descanso: false` por falta de este modelo.)

**Simetría deliberada**: empleado y activo son las dos cosas que "salen de la base, van a una
obra y vuelven". Ambos tienen asignación (plan), movimiento/marcación (hecho), y generan
evidencia. Comparten estructura conceptual.

### 7.5 Evidencia de campo: Submission + Adjunto

Unifica cuatro conceptos hoy solapados (Report, Incident, AssetAudit, Bitácora del mobile) y
tres tablas de adjuntos duplicadas. Un solo flujo de revisión, un solo endpoint de upload, un
solo cursor de sincronización.

**Submission** (base, append-only):

| Campo | Descripción |
|---|---|
| `tipo` | `BITACORA_DIARIA` \| `INCIDENTE` \| `AUDITORIA_ACTIVO` \| `INFORME` \| `CHECKLIST_MOVIMIENTO`. |
| `obra_id`, `autor_id` | Contexto. |
| `ocurrido_en`, `recibido_en` | Bitemporal. |
| `estado_revision` | `PENDIENTE` \| `APROBADO` \| `OBSERVADO`. Revisor + fecha. |
| `payload` | `jsonb` flexible según tipo (tareas, severidad, notas…). |
| `lat`, `lng` | Geo del reporte. |

Tablas satélite **solo donde hace falta FK/índice real**:
- `incidente_detalle`: severidad (`BAJA`\|`MEDIA`\|`ALTA`\|`CRITICA`), estado
  (`ABIERTO`\|`EN_INVESTIGACION`\|`RESUELTO`\|`CERRADO`).
- `auditoria_detalle`: activo_id, condición reportada, resultado de aprobación.

**Adjunto** (polimórfico, una sola tabla para todo archivo):

| Campo | Descripción |
|---|---|
| `dueño_tipo`, `dueño_id` | Submission, Documento, Activo, OrdenDeServicio… |
| `object_key`, `url` | Cloudflare R2. |
| `estado_subida` | `PENDIENTE` \| `SUBIDO`. Clave para offline: la foto vive local hasta sincronizar. |
| `orden`, `tipo_mime` | Presentación. |

> Sobre "Rechazar" auditoría: se distingue **observar la foto** (mala toma → `estado_revision =
> OBSERVADO`, el operario re-sube) de **marcar el activo como problemático** (→ genera novedad de
> condición sobre el activo). Son cosas distintas; el enum lo separa.

### 7.6 Corrección de hechos: la ventana de gracia

Los hechos no se editan. Pero para no castigar la carga errónea:

- **Dentro de ~15 min de creado, y solo por su autor**: "deshacer" → marca `anulado_en/por` con
  motivo. En la UI se siente como un undo; el hecho no aparece en ningún reporte. Sigue existiendo
  en la tabla (append-only intacto).
- **Pasada la ventana, o por otra persona**: corrección formal con motivo obligatorio
  (contra-asiento). El hecho erróneo queda visible, tachado, junto a su anulación.

Esto es lo que hace del registro una **evidencia** válida ante el cliente, el seguro o el
empleado. Un historial que se puede reescribir en silencio no es un historial.

---

<a name="8"></a>
## 8. Capa 3 — Proyecciones / estado

Caché derivada de los hechos. Las escribe **el sistema** en la misma transacción que el hecho
(§13), nunca un usuario. Se pueden **reconstruir enteras** desde la Capa 2.

| Proyección | Se deriva de | Uso en UI |
|---|---|---|
| `activo.ubicacion_actual` | último `MovimientoDeActivo` por `ocurrido_en` | Lista de inventario, "¿dónde está?" |
| `activo.custodio_actual` | último `EventoDeCustodia` | "¿quién lo tiene?" |
| `activo.condicion_actual` | última auditoría/checklist | Badge de condición |
| `activo.km_actual` | última `OrdenDeServicio`/movimiento con km | Vehículos |
| **`SaldoDeStock(modelo, ubicacion)`** | `Σ AsientoDeStock.delta` | Stock de consumibles/EPP por ubicación |
| `empleado.en_obra`, `obra_actual` | últimas `Marcacion` + `Asignacion` | Gantt, dashboard |
| `empleado.estado_habilitaciones` | `Documento` del empleado vs hoy | "¿puede subir?" |
| **`VencimientosProximos`** | vista sobre `Documento` (`vence_en` ≤ hoy + preaviso) | **Alertas del dashboard — el producto** |

**AsientoDeStock** (Capa 2, referenciado acá) — el libro mayor de consumibles a granel, que
resuelve el problema de "100 guantes, 60 en central y 40 en obra":
`modelo_id, ubicacion_ref, delta (±), motivo, ocurrido_en`. El saldo actual es `SUM(delta)`.
Dos entregas offline generan dos asientos que suman bien, sin conflicto de escritura.

**El script de reconstrucción** (se escribe temprano, §13): borra las proyecciones, las recalcula
desde los hechos, y compara. Es la red de seguridad ante un bug de proyección y corre
periódicamente en prod (comparando sin escribir) para detectar desincronización.

**Mantenimiento de la proyección**: misma transacción de Postgres (insert del hecho + update del
estado). A la escala de Arq&Top (~80 empleados, decenas de miles de eventos) sobra; no hacen
falta workers ni colas. Se revisa si un tenant crece 100×.

---

<a name="9"></a>
## 9. Módulo comercial: licitación → presupuesto → obra → certificación

Cadena: **Licitación** (opcional) → **Presupuesto** → si se gana, **Obra** → ejecución →
**Certificación**. Cotización directa = presupuesto con `licitacion_id` null.

| Entidad | Campos clave | Notas |
|---|---|---|
| **Licitacion** | cliente_id, sitio_id?, fecha, estado | Origen opcional. |
| **Presupuesto** | cliente_id, licitacion_id?, moneda, validez, estado (`BORRADOR`\|`ENVIADO`\|`GANADO`\|`PERDIDO`), condiciones | Cabecera. |
| **LineaDePresupuesto** | presupuesto_id, ref (`PUESTO`\|`ARTICULO`\|`EQUIPO`\|`LIBRE`), ref_id?, cantidad, unidad, **precio_unitario**, **costo_unitario**, **tipo_precio** | Ambos importes son `(monto,moneda)`. |
| **Obra** (Project) | cliente_id, sitio_id, presupuesto_id?, nombre, estado, **fechas plan/real** | Ver estados y fechas abajo. |
| **LineaDeContrato** | obra_id, linea_presupuesto_id?, tipo_precio | Contra qué se certifica y se mide real. |
| **Certificacion** | obra_id, periodo, líneas, monto | Lo ejecutado y cobrable. Hecho append-only. |

**`tipo_precio`** por línea (P4 — los cuatro modos que usa Arq&Top: "a veces horas, a veces
servicios, a veces alquiler"):

| Tipo | Se factura contra | Fuente del "real" |
|---|---|---|
| `PRECIO_CERRADO` (lump sum) | nada (monto fijo) | — |
| `POR_UNIDAD` | cantidad certificada | Certificación |
| `POR_HORA` (T&M) | horas reportadas | `ParteDeHoras` |
| `POR_DIA_ALQUILER` | días de asignación del activo | `Asignacion`/`MovimientoDeActivo` |

**Estados de obra** (el front ya los tenía bien, el API tiene solo 2): `PLANIFICACION`,
`EN_CURSO`, `PAUSADO`, `FINALIZADO`. **Fechas**: `inicio_plan`, `fin_plan`, `inicio_real`,
`fin_real` — planificado vs real es lo que dibuja el **Gantt del dashboard** (hoy sin datos).

**Presupuestado vs real** (la funcionalidad más valiosa): como la línea guarda `costo_unitario`
**y** `precio_unitario`, y los hechos operativos (horas, movimientos de activos, consumos,
órdenes de servicio) se imputan a `linea_contrato`, se puede mostrar en vivo, por línea:
cotizado vs costo real vs margen. Todo el trackeo de campo existe, en última instancia, para
alimentar esta comparación.

**Certificación vs factura**: la certificación (Workflow) es lo acordado como ejecutado y
cobrable. La factura fiscal (externa, §2) cuelga de la certificación cuando exista. Separarlas
deja el lugar para ARCA sin rediseñar.

**Registro de horas**: `ParteDeHoras` está **diseñado** (§7.4) pero **no se construye en v1**.
Cuando Arq&Top facture por hora, se activa sin tocar el esquema.

---

<a name="10"></a>
## 10. Módulo de compras: requerimiento → orden → recepción

Unifica "pedir desde una obra" y "comprar a un proveedor" en un solo origen: el capataz emite
una **necesidad**; la oficina la resuelve con stock propio (transferencia) o con compra.

| Entidad | Campos clave | Notas |
|---|---|---|
| **Requerimiento** | obra_id/solicitante, items, fecha_necesidad, estado | Una sola bandeja de entrada. El capataz sigue su pedido sin saber cómo se resuelve. |
| **OrdenDeCompra** | proveedor_id, moneda, estado, líneas | Cuando no hay stock. |
| **LineaDeOrdenDeCompra** | modelo/artículo, cantidad, precio_unitario | `(monto,moneda)`. |
| **Recepcion** | orden_compra_id, fecha | **Recibir crea los activos o los `AsientoDeStock`** (P5: un gesto). El activo nace con costo, fecha, proveedor y garantía. |

**Estados del requerimiento**: `PENDIENTE` → `EN_COMPRA` / `EN_TRANSFERENCIA` → `ENTREGADO`.
Si se satisface con stock, dispara una **transferencia interna** (movimiento de activo o asiento
de stock entre ubicaciones). Frontera con contabilidad (§2): se guarda `numero_factura` como
texto y se exporta; no hay cuentas por pagar.

---

<a name="11"></a>
## 11. Sincronización offline-first

Materializa P3. Aplica a la app mobile; la web asume conexión (pero consume las mismas APIs
idempotentes).

**Modelo de escritura**:
- El cliente **genera el UUIDv7** de cada entidad de hecho.
- Escribe con `PUT /recurso/:id` **idempotente**: reenviar la misma operación (por reintento de
  sync) no duplica ni falla.
- Cada hecho lleva `ocurrido_en` (reloj local) + el servidor sella `recibido_en`.

**Cola local y sync**:
- El mobile mantiene una **cola de operaciones pendientes** (ya tiene base local sqlite/drift).
- Al recuperar señal, drena la cola en orden. Las fotos son `Adjunto` con `estado_subida =
  PENDIENTE`: primero se pide `presign` a R2, se sube el binario, luego se confirma.
- **Lectura**: el mobile baja un delta desde un **cursor** (`recibido_en > último_visto`). Un
  solo cursor sirve para todos los hechos gracias a `Submission`/`Adjunto` unificados.

**Conflictos**: no existen a nivel escritura (hechos inmutables con id propio). El "conflicto" de
negocio (evento retroactivo que cambia el estado actual) se resuelve reordenando por
`ocurrido_en` y recalculando la proyección. La UI de oficina **muestra** cuando un estado cambió
por un evento retroactivo.

**Anti-abuso del reloj**: si `|recibido_en − ocurrido_en|` supera un umbral (p. ej. reloj del
teléfono adelantado días), el hecho se acepta pero se marca para revisión. Nada sensible confía
ciegamente en el reloj del cliente.

---

<a name="12"></a>
## 12. Permisos con alcance

Hoy el permiso es global al tenant: un supervisor con `audits.approve` puede aprobar auditorías
de **cualquier** obra. Para minería eso es un agujero. Solución: el permiso se evalúa **con
alcance**.

- **Autoridad real**: `usuario.permisos: string[]` con convención `modulo.accion` y wildcards
  (`modulo.*`, `*`). `role` es solo etiqueta de display. (Ya es así en los tres clientes.)
- **Alcance**: `AsignacionDeRol(usuario, rol, alcance: GLOBAL|OBRA, alcance_id)` (§6). Un usuario
  puede tener rol admin `GLOBAL` **y** supervisor de la `OBRA X`.
- **Evaluación** (guard del API): permitir si el usuario tiene el permiso **y** (el alcance es
  `GLOBAL` **o** el `alcance_id` coincide con la obra del recurso). El campo `scope` que
  `GET /auth/me` ya devuelve (hoy sin uso) es exactamente esto.
- **Frontend/mobile**: gating de UX (ocultar/deshabilitar acciones). La autoridad es siempre el
  guard del API.

Seed de roles base (mismo en API, web y mobile — mantener en sync): `SUPER_ADMIN` (`*`), `ADMIN`,
`LOGISTICA`, `ANALYST`, `STOCK_MANAGER`, `WAREHOUSE_KEEPER`, más los roles de campo del mobile
(`empleado`, `supervisor`, `fotografo`) que se seedearán como filas reales. **Pendiente**:
resolver el `tenant_id: null` de `SUPER_ADMIN` (hoy ve listas vacías porque los services filtran
por tenant) — decisión: bypass de tenant en los services para scope `*`, no asignarle un tenant.

---

<a name="13"></a>
## 13. Arquitectura técnica y plan de construcción por fases

### Stack (ya existente, se mantiene)

- **API**: NestJS 11 + TypeORM + PostgreSQL. Multi-tenant, JWT, guards globales, soft-delete,
  Swagger. Prefijo `/api/v1`. Respuesta `{ data }` / `{ data, meta }`.
- **Web**: React 19 + Vite + TS + React Query + Zustand + Tailwind. Arquitectura de conexión
  detallada en `integracion-api.md` (repository → mapper → hook → componente; SOLID).
- **Mobile**: Flutter, clean architecture (data/domain/presentation), base local offline.
- **Storage**: Cloudflare R2 (S3-compatible) con presigned URLs.

### Reglas transversales de implementación

- **IDs UUIDv7 de cliente** para hechos; `PUT` idempotente en todos los endpoints de escritura de
  campo. (Cambio respecto del `@PrimaryGeneratedColumn('uuid')` actual — barato ahora, caro
  después de tener datos.)
- **Proyecciones en la misma transacción** que el hecho. Nunca escribir proyección desde un
  endpoint de usuario.
- **Script de reconstrucción de proyecciones** desde el día uno; se corre en CI y en prod (modo
  comparación).
- **Bitemporalidad** (`ocurrido_en` + `recibido_en`) en toda tabla de hecho.
- **`(monto, moneda)`** en todo importe; `cotizacion_referencia` al consolidar.
- **Migrations reales** antes de producción (hoy el API usa `synchronize` en dev; sirve para la
  fase de captura, no para prod).

### Fases de construcción

> El **esquema completo** (todas las tablas de §6–§10) se diseña y migra desde el inicio. Las
> fases ordenan **qué se construye** (endpoints + UI + flujo mobile), no qué se modela.

| Fase | Qué se construye | Por qué primero |
|---|---|---|
| **F0 · Cimientos** | Auth con tenant real (resolver por CUIT), permisos con alcance, deploy de la API hosteada, esquema completo migrado, storage R2, script de reconstrucción. | Desbloquea todo. Resuelve los 4 bloqueantes de auth de `integracion-api.md`. |
| **F1 · Núcleo — Activos + Hoja de Vida** | Catálogo (marca/modelo/condición), Activo, MovimientoDeActivo, EventoDeCustodia, OrdenDeServicio, cajas con contenido. Pantalla "Hoja de Vida". Carga mobile offline. | Es lo que hoy es el Excel de vehículos. Trazabilidad + custodia. |
| **F2 · Núcleo — Vencimientos** | TipoDeDocumento, Documento, alertas `VencimientosProximos`, habilitaciones de empleado. Dashboard de vencimientos. | **El dolor #1 de Arq&Top.** Reemplaza el Excel + WhatsApp de control. |
| **F3 · Núcleo — Campo + Personal** | Submission (bitácora/incidente/auditoría/checklist) + Adjunto, sync offline completa, Marcacion, Asignacion, Gantt de personal. | Cierra la captura de campo y el "quién está dónde". |
| **F4 · Stock a granel** | AsientoDeStock, SaldoDeStock por ubicación, transferencias internas, Almacenes. | Consumibles/EPP (guantes, cables) con saldo por ubicación. |
| **F5 · Comercial** | Cliente/Sitio, Licitación, Presupuesto con costo/precio, Obra desde presupuesto, Certificación, presupuestado-vs-real. | Excel aún lo aguanta; alto valor pero no es el dolor inmediato. |
| **F6 · Compras** | Proveedor, Requerimiento, OrdenDeCompra, Recepción (que crea activos/stock). | Cierra el ciclo de origen de los activos. |
| **F7 · Diferidos** | ParteDeHoras (facturación por hora), PlanDeMantenimiento preventivo, factura fiscal (ARCA), reportes avanzados. | Esquema ya listo; se activan cuando el negocio lo pida. |

---

<a name="14"></a>
## 14. Decisiones tomadas y alternativas descartadas

| # | Decisión | Alternativa descartada | Por qué |
|---|---|---|---|
| D1 | **Núcleo append-only** para hechos; catálogo mutable; estado como proyección. | CRUD mutable + tabla de auditoría por triggers. | La auditoría por triggers no reconstruye estado, se desincroniza, y **no resuelve offline** (los conflictos de escritura siguen). |
| D2 | UUIDv7 **de cliente** + `PUT` idempotente. | IDs de servidor + `POST`. | Sin id de cliente no hay sync offline sin duplicados. Irreversible con datos cargados. |
| D3 | **Bitemporal** (`ocurrido_en` ≠ `recibido_en`). | Un solo timestamp. | El evento de campo llega tarde; el orden de negocio es por cuándo pasó, no por cuándo llegó. |
| D4 | **Proyecciones en misma transacción**. | Workers async / outbox. | A la escala de Arq&Top sobra; async agrega consistencia eventual y complejidad operativa sin beneficio. |
| D5 | **Custodia como eje independiente** de ubicación, activada por flag del modelo. | Custodia siempre / nunca. | "Mixto según el activo": herramientas caras sí, consumibles no. |
| D6 | **Caja de herramientas = ubicación**; contenidos son activos. | Tabla `asset_sub_items` con reglas propias (como el mobile). | Reutiliza el mecanismo de movimiento; los sub-ítems del Excel ya tienen serial propio (todo trackeado). |
| D7 | **Documento polimórfico con vencimiento** para habilitaciones, seguros, RTO, matafuegos, calibración. | Campos fijos en cada entidad (como `Asset.vtvExpiresAt`). | Un solo modelo, N por dueño (dos matafuegos), un solo motor de alertas. Elimina la duplicación actual. |
| D8 | **Submission + Adjunto unificados**. | Report/Incident/Audit/Bitácora con 3 tablas de adjuntos (estado actual). | Un flujo de revisión, un endpoint de upload, un cursor de sync. |
| D9 | **`tipo_precio` por línea** (4 modos) + `(monto,moneda)` siempre. | Precio como número; modelo de facturación fijo. | Cubre "a veces horas, a veces servicios, a veces alquiler" sin motor de reglas. Moneda es irreversible de agregar tarde. |
| D10 | **Requerimiento unificado** (stock propio o compra). | Módulos separados de peticiones y compras. | El capataz sigue una sola bandeja; se preserva el vínculo necesidad→resolución. |
| D11 | **Certificación separada de factura fiscal**. | Facturar en Workflow desde ya. | Deja el lugar para ARCA sin construir integración fiscal ahora. |
| D12 | **Permisos con alcance** (GLOBAL/OBRA). | Permisos globales al tenant (estado actual). | Un supervisor no debe aprobar auditorías de otra obra. `scope` de `/auth/me` ya lo anticipa. |
| D13 | Front **alinea IDs a UUID string** y **enums al API**; español solo en `*_LABELS`. | Mantener `id: number` + enums propios + mappers. | Los UUID no caben en `number`; ver `integracion-api.md` §7. |
| D14 | **Esquema completo desde el inicio, construcción por fases.** | Construir solo lo del dolor y ampliar el esquema después. | El esquema es lo irreversible; los errores de modelo son los caros. Construir es incremental. |

---

<a name="15"></a>
## 15. Glosario

- **Activo**: unidad física con identidad (vehículo, herramienta serializada, instrumento, caja).
- **Asiento de stock**: movimiento con signo de un consumible a granel en una ubicación.
- **Bitemporal**: dos ejes de tiempo — `ocurrido_en` (mundo real) y `recibido_en` (el sistema se
  enteró).
- **Certificación**: lo ejecutado de una obra que se puede cobrar. No es factura fiscal.
- **Custodia**: responsabilidad de una persona sobre un activo. Eje independiente de la ubicación.
- **Hecho / evento**: registro append-only de algo que pasó. Se corrige con otro hecho.
- **Hoja de Vida**: línea de tiempo de un activo (movimientos + custodias + servicios +
  vencimientos + fotos).
- **Obra**: contrato de servicio en un sitio de un cliente, con fechas plan/real. (Antes "Project".)
- **Proyección**: caché derivada de los hechos, reconstruible (estado actual).
- **Sitio**: yacimiento/mina de un cliente (POSCO, Río Tinto…).
- **Submission**: unidad de evidencia de campo (bitácora, incidente, auditoría, informe, checklist).
- **Tenant**: empresa cliente de Workflow (Arq&Top y futuras), aislada.
