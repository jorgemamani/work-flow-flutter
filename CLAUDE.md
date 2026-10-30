# CLAUDE.md — work-flow-flutter-mvp

App de campo de Workflow (Flutter, offline-first).

## Docu de Workflow (MCP `workflow-docs`)

Antes de integrar un endpoint o tocar un flujo de negocio (sync, cola de hechos, fotos, remitos, marcaciones), consultá el MCP `workflow-docs` (`search_docs`, `get_endpoint`, `get_rule`) para el contrato, el permiso y las reglas. Si el código y la docu difieren, manda el código: avisá la diferencia para corregirla en el repo `../workflow-docs`.

Para UI, cargá la skill `workflow-design` (`.claude/skills/workflow-design/`).
