# Workflow · app de campo

App Flutter para el personal en las minas. Funciona hasta 14 días sin señal: lee de una base local que copia la API y guarda lo que se registra en una cola que se envía sola al volver la conexión.

- Contrato con la API: `workflow-api/docs/contrato-mvp.md` y `workflow-api/openapi.json`.
- Producto: `Workflow-Vision-y-Alcance-v4.md` (v4.1), sobre todo §9 (remitos) y §11 (modo offline).

## Correr

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3103
```

Sin `API_BASE_URL` usa la de `.env.dev` (Render). El simulador de iOS llega a `localhost` de la Mac.

Credenciales de la empresa demo (seed de la API): CUIT `30-12345678-9`, DNI `30111222`, PIN `1234`. Oficina: `admin@minerademo.com` / `Admin1234!`.

## Tests

```bash
flutter analyze
flutter test
```

`test/integration/` corre el flujo completo contra una API real y se saltea si no se define `API_BASE_URL`:

```bash
API_BASE_URL=http://localhost:3103 flutter test test/integration
```

Necesita un remito en tránsito hacia el proyecto del usuario de campo.

## Cómo funciona el modo offline

```
lib/core/
├── db/          SQLite: records (copia de /sync/changes), outbox (cola), kv (cursor, perfil)
├── sync/        SyncApplier (upsert/deleted/cursor), SyncEngine (paginado), SyncCoordinator
├── outbox/      OutboxStore (cola persistente), OutboxProcessor (drenado en orden)
├── auth/        SessionManager (login, refresh rotativo), Profile (/auth/me guardado)
├── data/        FieldRepository (lecturas locales), FieldActions (hechos → cola)
├── network/     ApiClient (Dio), AuthInterceptor, OfflineGuardInterceptor, conectividad
└── photos/      PhotoService (comprime, guarda y cachea fotos vigentes)
```

- **Lectura**: `GET /sync/changes` con cursor, paginando mientras `hasMore`. Cada fila se guarda por `source` + `id` (upsert) y se borran los `deleted`. Todas las pantallas leen de la base local.
- **Escritura**: cada acción es un hecho con id UUIDv7 y `occurredAt` del teléfono. Se encola junto con sus fotos y aplica un cambio optimista en la base local, que se vuelve a aplicar después de cada sync mientras siga pendiente.
- **Drenado** (contrato §4): primero refresca la sesión y después manda en orden. `2xx` sale de la cola (`created` true o false). `4xx` queda como fallido visible (las fotos de ese hecho fallan con él). `5xx` o sin red corta el drenado y reintenta después con el mismo id. Ante un `401`, refresca y reintenta una vez.
- **Fotos** (contrato §5): se comprimen a JPEG (1600 px, calidad 70) y se suben después del hecho que las declara: `PUT /attachments/:id` → `PUT` a la URL firmada de R2 → `confirm`.
- **Sesión** (RN-28): el access token dura 15 min y el refresh 30 días, y rota en cada uso. Sin señal la sesión no se cierra; solo se pide ingresar de nuevo si la API rechaza el refresh, y la cola se conserva.
- **Modo sin conexión**: en Sincronización se puede activar "Trabajar sin conexión" para cortar la red desde la app.
