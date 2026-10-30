---
name: workflow-design
description: Marca y design system de la app de campo de Workflow (base en tinta y piedra con el color de cada empresa como acento, IBM Plex empaquetada, estados punto + texto, medidas para guantes y sol, conexión siempre visible). Cargala ANTES de crear o tocar cualquier UI de esta app Flutter — una pantalla de lib/features/*, un widget de lib/shared/widgets, el tema de lib/shared/theme, los tokens de lib/shared/constants, textos de botones/estados/vacíos/errores, colores, tipografía o medidas — y antes de maquetar una pantalla en un artifact. Trae las reglas duras, los widgets a usar y el checklist de verificación.
---

# Workflow design · app de campo

La app se usa con guantes, al sol y muchas veces sin señal. Es la misma marca que la web (`workflow-frontend/docs/brand/`, sobre todo `05-app-campo.md`) con otra densidad: una tarea por pantalla, botones grandes, el botón principal fijo abajo.

Referencia visual (privada de la cuenta, leela con la herramienta Artifact, acción `read`): https://claude.ai/artifact/QqL3N9xZnCt4hkqUXskeoa — página «App de campo» (`project/App*.dc.html`, `App.dc.html`, `MobileNav.dc.html`, `MobileStatus.dc.html`; 390 × 844 con medidas exactas). **Toda pantalla nueva copia el canvas; lo que no está en el canvas sale de los widgets de `lib/shared/widgets/`.**

## Dónde está cada cosa

| Qué | Dónde |
|---|---|
| Colores | `lib/shared/constants/app_colors.dart` (`AppColors`) |
| Medidas | `lib/shared/constants/app_sizes.dart` (`AppSizes`) |
| Fuentes | `lib/shared/constants/app_fonts.dart` (`AppFonts.sans`, `AppFonts.mono`, `AppFonts.monoStyle`), archivos en `assets/fonts/` |
| Color de la empresa | `lib/shared/theme/tenant_brand.dart` (`TenantBrand.from(hex)` → `fill`, `on`, `ink`; `context.brand`) |
| Tema | `lib/shared/theme/app_theme.dart` `buildAppTheme(brand)`: siempre claro; `lib/app.dart` lo arma con el `brandColor` de la sesión |
| Pantalla de campo | `FieldScaffold` + `FieldFooter` (`shared/widgets/field_scaffold.dart`) |
| Conexión | `ConnectionFrame` / `ConnectionStrip` (`shared/widgets/connection_strip.dart`), montado en `app.dart` |
| Barra inferior | `AppShell` (`shared/navigation/app_shell.dart`) |
| Piezas | `common.dart`: `StatusChip`, `StatusDot`, `Chapa`, `RuledList`, `RowLink`, `ChoiceGrid`, `FieldLabel`, `FieldNotice`, `ProgressHeader`, `SectionTitle`, `EmptyState`, `LocalSaveHint`; `AppButton`, `AppTextField`, `PhotoStrip`, `TenantMark` |
| Color de cada estado | `assetStatusColor` (`common.dart`), `remitoStatusColor`, `incidentStatusColor`, `requirementStatusColor`, `reviewStatusColor` (`shared/labels.dart`) |

## Reglas duras

1. **El color de la empresa es el acento.** Sale de `brandColor` de `/auth/me` (`Profile.tenantBrandColor`, `#RRGGBB`); sin color, el petróleo de Workflow `#0E6E85`. `TenantBrand` deriva, con la misma cuenta que la web (`brandColor.ts` → `deriveBrand`): `fill` = el color tal cual (rellenos), `on` = tinta o blanco, el que dé más contraste contra `fill` (texto encima del relleno), `ink` = el color oscurecido hasta 4,5:1 contra la piedra (bordes, foco, cursor, texto o marcas finas sobre el fondo). En pantalla se lee con `context.brand`; el tema se rearma solo al ingresar o cambiar de empresa.
   - **Usan el acento:** el botón principal (`fill` + `on`), el botón Escanear de la barra, lo elegido (`ChoiceGrid`, `ChoiceChip`, `SegmentedButton`, `Checkbox`, `Switch`: `fill` + `on`), la pestaña activa de la barra inferior (`ink`), el foco y el cursor de los campos (`ink`), los botones secundarios (`OutlinedButton`, borde y texto `ink`), las barras de avance (`ink`), la tarjeta «Arriba en la mina» (`fill` + `on`) y la marca `TenantMark`.
   - **Siguen fijos:** el texto en tinta, los estados con punto + texto, la chapa con borde de tinta, los avisos, la franja «Sin conexión» en tinta y el fondo piedra. Nunca pintes un estado ni un aviso con el color de la empresa.
   - No uses `AppColors.ink` ni `AppColors.primary` para una acción o algo elegido: usá el tema o `context.brand`.
2. **Una acción principal por pantalla**, con `AppButton` lleno (o `FilledButton` del tema), fija abajo en un `FieldFooter` cuando la pantalla es un formulario o una tarea. Lo secundario con `isOutlined: true` o `TextButton` subrayado.
3. **Estados = punto + texto** con `StatusChip(label, color: …)`. Nunca pastillas, fondos teñidos (`color.withValues(alpha: …)` de fondo) ni íconos de color como único indicador. Colores fijos: bien `statusSuccess` `#2C7A47`, atención `statusWarning` `#97570A`, problema `statusError` `#B8321C`, **en tránsito** `statusMove` `#2B59C3` (solo para eso), neutro `statusNeutral` `#6B6E6A`.
4. **Avisos = `FieldNotice`**: fondo `selected` opaco, texto en tinta, el color del significado solo en el ícono. Snackbars en tinta (los da el tema).
5. **La conexión siempre se ve.** No agregues indicadores de sync propios ni escondas la franja: `ConnectionFrame` la pone arriba de todas las pantallas con sesión («Sin conexión · N guardados sin enviar» en tinta; «Con conexión · Todo enviado» en piedra) y abre `/sync`. Solo el escáner la esconde (`fullScreenDepth`). La key `syncIndicator` está en la franja.
6. **Sin cajas para estructurar.** Listas con `RuledList` (regla de tinta arriba, línea entre filas) y filas de 64 con `RowLink`. Nada de `Card` dentro de `Card`, ni sombras salvo lo que flota (botón Escanear de la barra).
7. **Medidas de campo**: botones y campos 56 (`AppSizes.buttonHeight`, `inputHeight`), filas 64 (`rowHeight`), toques ≥ 48 (`tapTarget`), radio 14 (`radiusMd`; 10, 12, 16 y 22 para lo chico y lo grande), texto 16–17 (nunca menos de 13 para ayudas). Bordes de campo 1,5 px `lineStrong`; foco en el `ink` de la empresa.
8. **Etiquetas arriba del campo** (`FieldLabel`, `AppTextField`), no flotantes. Tocar afuera cierra el teclado (ya lo hacen `FieldScaffold` y `AppTextField`).
9. **Tipografía**: IBM Plex Sans para palabras, **IBM Plex Mono para códigos, cantidades, fechas y horas** (`AppFonts.monoStyle`). Título de pantalla 26–28/600, sección 18/600 (`SectionTitle(strong: true)`) o 15/500 gris. Las fuentes van empaquetadas: **no uses `google_fonts`** (las baja en tiempo de ejecución y la app tiene que andar sin señal).
10. **Códigos en chapa** (`Chapa`): ítems, remitos, contenedores.
11. **Siempre claro.** No hay tema oscuro: al sol se lee mejor. No agregues `darkTheme` ni colores `*Dark`.
12. **Textos en `lib/l10n/app_es.arb` y `app_en.arb`**, nunca sueltos en el código. Español rioplatense con voseo, en oración. Botón = verbo + objeto («Confirmar recepción», «Registrar subida»). Ayuda bajo el botón principal: qué pasa con lo que se guarda («Se guarda en el teléfono y se envía cuando haya señal.»). Vacío = qué falta + qué hacer. Error = qué pasó + cómo se arregla.
13. **Sin señal es lo normal.** Toda acción se guarda en la cola y se dice así; nada de spinners que esperan la red para guardar.
14. **Keys de los tests no se tocan**: `scanButton`, `addPhoto`, `action-*`, `currentProject`, `onSiteStatus`, `confirmCheckIn`, `syncIndicator` y las demás `Key('…')` que ya existan.

Si una pantalla "necesita" romper una regla, el problema está en la pantalla, no en la regla. Si falta un widget, armalo en `lib/shared/widgets/` y usalo desde la pantalla.

## Skills de diseño

Instaladas a nivel usuario (`~/.claude/skills/`): `impeccable` en modo **operar** (`critique`/`audit` para revisar una pantalla, `clarify` para textos, `harden` para errores y bordes, `polish` para la pasada final) dentro de este sistema; `emil-design-eng` solo para movimiento puntual. Si alguna sugiere otra paleta, otra tipografía o tarjetas con sombra, gana este sistema.

## Checklist antes de dar por terminado

- [ ] Una acción principal en el color de la empresa, fija abajo si es una tarea; estados, avisos y texto sin el color de la empresa.
- [ ] Estados con `StatusChip` (el azul solo para en tránsito), avisos con `FieldNotice`, sin fondos teñidos.
- [ ] Estilos con estado en el tema: el color del texto como `WidgetStateColor` dentro de un `TextStyle` (los chips no resuelven un `WidgetStateTextStyle` y el texto queda sin color).
- [ ] `FieldScaffold`, listas con `RuledList`/`RowLink`, opciones con `ChoiceGrid`, códigos en `Chapa`, números en mono.
- [ ] Medidas de campo (56 / 64 / 48, radio 14, texto 16–17).
- [ ] Textos nuevos en `app_es.arb` y `app_en.arb`, en oración y voseo.
- [ ] `/Users/pabloromero/development/flutter/bin/flutter analyze` sin issues y `flutter test` en verde.
- [ ] Mirada en el simulador de iOS (390 × 844) comparada con el canvas, **con y sin señal** (interruptor «Trabajar sin conexión» de Sincronización) y con dos colores de empresa: uno claro (Arqytop `#54B548`, texto en tinta) y sin color (petróleo, texto blanco).
- [ ] Si cambiaste un token o un widget compartido: actualizá esta skill en el mismo commit.
