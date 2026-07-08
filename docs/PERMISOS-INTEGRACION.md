# Integración de permisos con el backend real

Este documento es para vos (equipo de `work-flow-flutter`). Resume qué cambió en
`arqytop-api` en el sistema de roles/permisos, qué tenés que ajustar en la app, y qué
**no** hace falta tocar porque tu diseño ya era el correcto.

---

## Por qué este cambio

Estábamos por integrar 3 sistemas (tu app mobile, el admin web, el API) que ya
compartían la misma idea de fondo — **el rol es una etiqueta, los permisos gatean** —
pero con dos convenciones de strings distintas:

- Vos ya usabas `modulo.accion` con wildcards (`obras.read`, `herramientas.*`, `*`),
  documentado en `user_permissions.dart`: *"evaluar siempre `permissions`, nunca
  `role`"*. Es exactamente el patrón correcto — nivel industria (mismo enfoque que
  Casbin, Spatie, etc.), y es lo que permite roles custom por tenant sin tocar código.
- El API usaba `CAN_VIEW_X` / `CAN_MANAGE_X` — más pobre (2 verbos, sin wildcards).

Se migró **el API a tu convención**, no al revés — era la más expresiva y la que menos
cambios te iba a pedir a vos. Este doc es la contraparte de esa migración: alinear tu
mock (y el cableado real cuando toque) al catálogo final.

**Nada de tu arquitectura de permisos cambia.** `UserPermissions`, el matcher
`canRead`/`canWrite`/`canDelete`, `scope`, `estado_actual` — todo eso queda igual. Lo
que cambia son los **strings de los permisos** y el **shape exacto** de las respuestas
del API real.

---

## 1. Catálogo canónico de permisos (fuente de verdad)

Formato: `modulo.accion`, minúsculas. Verbos: `read`, `write`, `delete` (+ verbos
puntuales donde el dominio lo pedía: `audits.approve`, `reports.review`). Wildcards:
`modulo.*` y `*` (`SUPER_ADMIN`).

| Módulo API | Antes (tu mock, en español) |
|---|---|
| `users` | — (no existía en tu catálogo) |
| `roles` | — |
| `projects` | `obras` |
| `employees` | `empleados` |
| `inventory` | `herramientas` |
| `warehouses` | — (nuevo) |
| `transfers` | — (nuevo) |
| `audits` | — (relacionado con `bitacora`, ver más abajo) |
| `reports` | `reportes` |
| `incidents` | — (nuevo) |
| `tenants` | `configuracion` (aprox.) |
| `bitacora` | `bitacora` — **no tiene módulo backend todavía**, ver nota abajo |
| `vehiculos` | **retirado** — ver nota abajo |

**Notas importantes:**

- **`vehiculos.*` no existe como módulo real.** En el seed viejo del API existían
  `CAN_VIEW_VEHICLES`/`CAN_MANAGE_VEHICLES` pero ningún guard los usaba — los documentos
  de vehículo (`vehicle-documents`) están gateados por `inventory.read`/`inventory.write`.
  Se sacaron del seed nuevo por vestigiales. Tu rol `logistica` debería usar
  `inventory.*` en vez de `vehiculos.*`.
- **`bitacora.*` no tiene módulo en el API todavía.** Es 100% tuyo/mobile por ahora. No
  hay `CAN_VIEW_BITACORA` ni nada parecido en el backend — si en algún momento el admin
  o el API necesitan ver bitácoras, alguien va a tener que crear ese módulo. Hasta
  entonces, dejá esos permisos en tu mock tal cual están (no rompen nada, simplemente el
  backend real nunca los va a devolver para ningún usuario — filtralo del lado mobile
  como corresponda, o tratalo como feature local).
- **`audits`** sí es un módulo real y bastante fino: `audits.read`, `audits.write`
  (crear auditoría), `audits.approve` (aprobar/rechazar). Tu rol `fotografo` (que crea
  auditorías fotográficas) mapea naturalmente a `audits.write` — es probablemente un
  mejor fit que meterlo dentro de `bitacora`.
- **`tenants.read`/`tenants.write` son exclusivos de `SUPER_ADMIN`** (`['*']`). El
  `TenantsService` del API no filtra por tenant — un usuario con ese permiso podría
  editar la empresa de otro cliente. No se lo des a ningún rol de campo.

---

## 2. Roles del API vs. tus roles de campo — no es un conflicto

El API hoy solo tiene seedeados roles de **oficina**: `SUPER_ADMIN`, `ADMIN`,
`ANALYST`, `STOCK_MANAGER`, `WAREHOUSE_KEEPER`. Tus roles de **campo**
(`empleado`, `empleado_supervisor`, `fotografo`, `rrhh`, `logistica`, `admin`) **no
existen todavía como filas en la tabla `roles`** — nadie los creó.

Esto es esperado, no un bug: los roles son datos (`Role.permissions: string[]`, por
tenant), no código. Cuando haga falta login real desde la app, alguien (vos, o quien
gestione el backend) tiene que darlos de alta vía `POST /roles` (requiere
`roles.write`), usando el catálogo de arriba. Abajo te dejo una propuesta de traducción
de tus permisos actuales a la convención final, lista para pegar como referencia el día
que se seedeen esos roles.

| Tu rol | Permisos sugeridos (traducidos) | Qué se cae (sin equivalente backend aún) |
|---|---|---|
| `admin` | igual que `ADMIN` del API (ver seed) | — |
| `rrhh` | `projects.*`, `employees.*`, `inventory.read`, `reports.read` | `vehiculos.*`, `bitacora.*` |
| `logistica` | `inventory.*`, `warehouses.*`, `transfers.*`, `projects.read` | `bitacora.read`, `vehiculos.read` (→ ya cubierto por `inventory.*`) |
| `empleado_supervisor` | `projects.read`, `projects.write`, `inventory.read`, `employees.read` | `bitacora.*`, `vehiculos.read` (→ `inventory.read`) |
| `fotografo` | `projects.read`, `audits.write`, `audits.read` | `bitacora.*` |
| `empleado` | `projects.read`, `inventory.read`, `employees.read` | `bitacora.*` |

---

## 3. Qué tenés que cambiar vos

### 3.1 `lib/config/mock_permissions_config.dart`
Reemplazar los strings en español por los del catálogo de la sección 1 (usando la tabla
de la sección 2 como referencia). Es un cambio mecánico — la estructura del archivo no
cambia, solo los strings.

### 3.2 `lib/shared/enums/app_user_role.dart` (`AppUserRole.fromApi`)
Revisar que los slugs cubran lo que el API realmente manda. Hoy el login real (`POST
/auth/login`) devuelve `user.role` en **mayúsculas** tal cual está en la DB (ej.
`"ADMIN"`, `"STOCK_MANAGER"`) — tu `fromApi` ya lowercasea antes de comparar, así que
`"ADMIN"` matchea bien contra `_adminSlugs`. Pero `"stock_manager"`, `"analyst"`,
`"warehouse_keeper"` **no matchean ningún slug tuyo** hoy (caen al fallback
`empleado`) — son roles de oficina que probablemente nunca logueen desde la app mobile,
así que puede no importarte, pero si algún día sí, hay que sumarlos.

`GET /auth/me` (ver 3.3) devuelve `usuario.rol` ya en **minúsculas** (`"admin"`,
`"stock_manager"`) — dato menor, tu normalización ya lo cubre en ambos casos.

### 3.3 Contrato de login — 3 diferencias concretas con lo que tu código espera hoy

**a) Las respuestas vienen envueltas en `{ "data": ... }`.** Tu `ApiHttpClient` (Dio)
devuelve `response.data` crudo, sin desenvolver. Ejemplo real de `POST /auth/login`:

```json
{
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "24a75c5f-9ef0-4289-ba63-095bcad7ec9b",
      "email": "admin@minerademo.com",
      "firstName": "Laura",
      "lastName": "García",
      "role": "ADMIN",
      "permissions": ["users.read", "users.write", "projects.read", "..."]
    }
  }
}
```

Tu `auth_remote_datasource.dart` hoy lee `response['user']`, `response['token']`,
`response['refresh_token']` — necesita leer `response['data']['user']`, etc.

**b) Los nombres de los tokens son camelCase, no lo que esperás.** El API devuelve
`accessToken` / `refreshToken` (no `token` / `refresh_token`). Ajustar:
```dart
// antes
final token = response['token'] as String;
final refreshToken = response['refresh_token'] as String;
// después
final token = response['data']['accessToken'] as String;
final refreshToken = response['data']['refreshToken'] as String;
```

**c) Falta el header `x-tenant-id` en el login.** El API lo requiere (`BadRequestException`
si no viene) — es multi-tenant. El endpoint público `GET /tenants/resolve?cuit=...`
devuelve el `id` del tenant a partir del CUIT de la empresa; hace falta un paso previo
(pantalla o selector) para resolverlo antes de loguear, algo que tu app no tiene hoy.

### 3.4 `GET /auth/me` — el login solo no alcanza para permisos completos

Acá hay un punto de diseño importante: **`POST /auth/login` no devuelve `scope` ni
`estado_actual`** (son específicos de la app de campo, no tienen sentido en el login
genérico que también usa el admin web). Para tener el shape completo que vos necesitás,
el flujo correcto es:

1. `POST /auth/login` → conseguís el `accessToken`.
2. Con ese token, `GET /auth/me` (autenticado) → acá sí vienen `permisos`, `scope`,
   `estado_actual` completos.

Ejemplo real de `GET /auth/me`:
```json
{
  "data": {
    "usuario": { "id": "24a75c5f-...", "nombre": "Laura García", "rol": "admin" },
    "permisos": ["users.read", "users.write", "..."],
    "scope": { "tipo": "global", "obraId": null },
    "estadoActual": { "enObra": false, "enDescanso": false }
  }
}
```

**Ojo con el casing**: es `estadoActual` / `enObra` / `enDescanso` / `obraId`
(camelCase), **no** `estado_actual` / `en_obra` / `en_descanso` / `obra_id`
(snake_case) que es lo que tu `UserModel.fromJson` espera hoy:

```dart
// tu código actual (lib/features/auth/data/models/user_model.dart) espera:
'en_obra': json['estado_actual']?['en_obra'],
'en_descanso': json['estado_actual']?['en_descanso'],
// y PermissionScope.fromJson espera json['obra_id']

// tenés que leer en su lugar:
'en_obra': json['estadoActual']?['enObra'],
'en_descanso': json['estadoActual']?['enDescanso'],
// y obraId (no obra_id) para el scope
```

Recomendación concreta: en `AuthRemoteDataSourceImpl.login()`, después de conseguir el
token, encadenar un segundo call a `GET /auth/me` y mergear ese resultado en el
`UserModel` (en vez de esperar que `POST /auth/login` traiga todo en un solo shot, como
asume el mock hoy).

### 3.5 Cómo derivamos `scope`/`estado_actual` del lado del API (por si te sirve)

No hicimos ningún endpoint nuevo para esto — reusamos el dominio que ya existía:
`Employee.userId` te vincula con tu usuario de login, y `ProjectAssignment`
(`movementType: UP_TO_MINE | DOWN_TO_BASE`) es el log de movimientos que ya se llena
desde `POST /projects/:projectId/assignments`. `GET /auth/me` mira tu último movimiento:
`UP_TO_MINE` → `scope.tipo:'obra'` + `enObra:true`; `DOWN_TO_BASE` → `enObra:false`.
Si tu usuario no tiene un `Employee` vinculado (roles de oficina) → `scope` es global.

**`en_descanso` siempre viene `false` hoy** — el dominio del API no modela
turnos/rotación todavía, no hay de dónde derivarlo. Es una deuda explícita, no un bug.

---

## 4. Qué NO tenés que cambiar

- Tu arquitectura de `UserPermissions` (scope, estado, evaluadores `canRead`/`canWrite`/
  `canDelete`/`has`) — está bien diseñada, es el patrón que se adoptó como estándar para
  los 3 sistemas.
- `PermissionScope` (`global`/`obra` + `obraId`) — el shape conceptual es correcto, solo
  cambia el casing del JSON que lo alimenta (ver 3.4).
- Los evaluadores de UI (`showInventoryTab`, `showBitacoraTab`, etc.) — no dependen de
  los strings específicos, siguen funcionando igual una vez actualizados los permisos
  base.

---

## 5. Checklist

- [ ] Actualizar `mock_permissions_config.dart` con los strings del catálogo (sección 1
      y 2).
- [ ] Revisar `AppUserRole.fromApi` — confirmar que cubre los roles que vas a usar.
- [ ] Cuando se active el login real: ajustar `auth_remote_datasource.dart` para leer
      la respuesta envuelta en `data`, y los campos `accessToken`/`refreshToken`
      (camelCase).
- [ ] Resolver de dónde sale el `x-tenant-id` antes de loguear (`GET
      /tenants/resolve?cuit=...`).
- [ ] Encadenar `GET /auth/me` después del login para obtener `permisos`/`scope`/
      `estadoActual` completos.
- [ ] Ajustar `UserModel.fromJson` (o el parser que uses para `/auth/me`) a las keys
      camelCase (`estadoActual`, `enObra`, `enDescanso`, `obraId`).
- [ ] Coordinar con el equipo backend el alta de tus 5 roles de campo
      (`empleado`, `empleado_supervisor`, `fotografo`, `rrhh`, `logistica`) como filas
      reales en `roles` — hoy no existen en el seed. Usar la tabla de la sección 2 como
      punto de partida.
- [ ] `bitacora.*` y `vehiculos.*`: no hay módulo backend — coordinar si/cuándo hace
      falta uno, o dejarlo como feature 100% local por ahora.
