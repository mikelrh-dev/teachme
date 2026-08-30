---
tags:
  - learning
  - teachme
  - changelog
created: 2026-08-28
---

# 🔧 Auditoría y mejoras — teachme (2026-08-28)

Esta sesión auditó `teachme` contra el original `learn-source` (sistema
para *pi*), corrigió **7 defectos** de la adaptación a Freebuff y añadió
**3 mejoras** nativas (Estado, Fuentes, Flashcards). El agente activo
(`~/.agents/teachme.ts`) quedó sincronizado con la referencia
(`.agents/teachme.md`), verificado sintácticamente (`node --check`).

> [!warning] Acción requerida
> Los agentes se cargan al arrancar sesión: abre una **sesión nueva** de
> Freebuff para que surta efecto todo lo de esta página.

## Camino rápido

1. Abre Freebuff aquí (`teachme`) en sesión nueva.
2. Pide una lección corta de humo: `@teachme enséñame qué es un hash`.
3. Verifica con el [checklist](#checklist-de-verificación) de abajo.

## Detalles

### Bugs corregidos

| # | Defecto | Fix |
|---|---------|-----|
| B1 | **La correcta siempre primera.** El quiz original baraja opciones por código; `ask_user` de Freebuff no baraja, y la regla "escribe primero la correcta" filtraba la respuesta por posición. | Regla **"Baraja la posición al emitir"**: el orden de redacción no es el de emisión; posición al azar, rebaraja si ambas preguntas coinciden. |
| B2 | **"Other" ≡ "no lo sé"** perdía respuestas sustantivas, y faltaba el "I don't know" explícito del original (nunca contado como ✗). | Opción literal **"No lo sé"** en cada pregunta (laguna genuina, se revela la correcta sin ✗) + el texto libre se gradúa si es un intento real. |
| B3 | **Log "en vivo" inviable:** `ask_user` bloquea el turno, así que el quiz nunca podía escribirse "antes" de la respuesta. | **Secuencia obligatoria por bloque:** prosa → bloque quiz al log (sin la correcta) → `ask_user` → veredictos + Estado. |
| B4 | **Detección de modo ambigua:** un repo con su propio log se clasificaba como VAULT. | Señales de código **primero**; repo con log = MODO REPO reanudado. |
| B5 | **Menores:** "quiz" ya no es tool (obsoleto "nunca quiz"); nodo vs bloque; pasos socráticos graduables; plantilla sin fence en el `.ts`; `<tema>` vs `<tema-kebab>`; tip del README desactualizado. | Terminología unificada ("formato quiz vía `ask_user`"), nodo = UN bloque, regla socrático-graduable, plantilla re-encajada (`~~~~markdown`), kebab único, README corregido. |
| B6 | **Colisión de visuals:** `write_file` sobreescribe; `<tema>.mmd` se pisaba entre bloques del mismo tema (el original usaba nombres únicos con timestamp). | Nombres únicos por bloque: `<tema-kebab>-b<n>.mmd` (+ `<tema-kebab>-plan.mmd`). |
| B7 | **Riesgo de corrupción del log:** la reescritura completa con `write_file` (primera opción hasta entonces) puede truncar/alterar bloques previos en logs largos. | `str_replace` anclado al final como vía principal; `write_file` completo solo para CREAR el archivo. |

### Mejoras añadidas (adaptadas a Freebuff)

| # | Mejora | Qué aporta |
|---|--------|-----------|
| B | **`## Estado actual`** en el log (sección viva: modo, tema, objetivo, bordes, nodos firmes/refuerzo, siguiente bloque) + retoma leyendo Índice + Estado primero. | El coste de retomar sesión ya no crece con el log (resume O(1)); la memoria entre sesiones vive solo en el log. |
| C | **`**Fuentes:**`** por bloque (URLs consultadas para verificar). | Trazabilidad estilo `researcher`: hoy la verificación web no dejaba rastro en el log. |
| D | **Flashcards** `pregunta :: respuesta` bajo `**Tarjetas** #flashcards`, una por pregunta del quiz (también con "No lo sé"). | Repaso espaciado con el plugin *Spaced Repetition* de Obsidian; cierra el ciclo aprender → recordar. |
| E | **`### Nivel del estudiante`** — puntuación 1–5 POR TEMA en `## Estado actual`, derivada de evidencia contable (ventana de ~6 veredictos de quiz: 5=100% ✓, 4=≥85%, 3=60–84%, 2=<60% o misconcepción activa, 1=sin suelo). Tendencia (subiendo/estable/bajando) comparando con la ventana anterior. Recalculada tras cada bloque. | El agente calibra el andamiaje/vocabulario/ritmo de las explicaciones al nivel real, y el nivel sobrevive entre sesiones (O(1) al retomar). |
| F | **Regla de escalada (2 bloques limpios)** — si los 2 últimos bloques cierran todo ✓ y nivel 4+, el agente PROPONE con `ask_user`: (a) nodo extra fuera del plan que extienda lo aprendido, o (b) contenido más denso en el siguiente tema. Rechazo → no se repite en la sesión. | Cierra el ciclo probe→teach→re-evaluate: la subida de nivel se detecta sola y se traduce en más profundidad, sin romper la compuerta de aprobación del plan. |

#### Diseño de E/F — qué se descartó y por qué

- **Puntuación global multi-tema:** engañosa — el grafo de dependencias es por
  tema; un número único aplanaría justo lo que el sistema enseña.
- **Reescritura automática del currículum según nivel:** rompería la compuerta
  del plan (Fase 2); sugerir+aprobar > adaptar solo.
- **Rúbricas complejas** (ponderar misconcepciones, velocidad…): todo aquí son
  instrucciones, no mecánica — una regla contable simple sobrevive; una matriz
  de 6 factores no.
- La puntuación es **orientativa para el agente, no una nota del estudiante**;
  si pregunta, se describe como "mapa de progreso".

### Descartadas por ahora (apuntadas)

- **A — Skill `teach` auto-trigger:** versión condensada de la filosofía en
  `.agents/skills/` para que el agente principal enseñe con el método en
  explicaciones rápidas sin `@teachme`. Recuperaría el comportamiento del
  original ("even a quick explanation").
- **E — Subagents FREE:** probar si Freebuff permite spawn con
  `z-ai/glm-5.3-flash`; si sí, resucitar el `researcher` aislado sin coste.

## Riesgos residuales conocidos

1. **Barajado y secuencia del log son instrucciones, no mecánica.** El
   `quiz.ts` original los garantizaba por código; aquí dependen del modelo
   seguir reglas (las reglas ya son inequívocas, pero no hay garantía dura).
2. **Doble mantenimiento** `.md` ↔ `.ts` — mitigado con el banner "NO ACTIVO"
   del `.md`; cada cambio toca dos archivos.
3. **LaTeX en opciones del quiz:** si la UI de `ask_user` no renderiza `$...$`,
   saldrá crudo — decidir en la lección de humo (regla condicional: opciones en
   texto plano, LaTeX solo en chat y log).
4. **Feedback diferido:** el veredicto llega en el mensaje siguiente, no dentro
   del popup como el `quiz` original. Inherente a la plataforma.

## Checklist de verificación

Lección de humo (sesión nueva de Freebuff):

- [ ] `@teachme` se autocompleta y carga (sesión nueva tras los cambios).
- [ ] En los quizzes, la correcta **no** cae siempre en la misma posición.
- [ ] Cada pregunta muestra la opción **"No lo sé"** y el "Other" libre.
- [ ] El quiz aparece en `LEARNING_LOG.md` **antes** de responder, sin la correcta.
- [ ] Tras responder: veredictos ✓/✗ (o laguna), **Tarjetas** y **Fuentes** en el log.
- [ ] `## Estado actual` queda actualizado al cierre.
- [ ] `### Nivel del estudiante` aparece en `## Estado actual` con `nivel: n/5 — tendencia · evidencia x/y ✓`.
- [ ] La línea `**Nivel:**` aparece al final de cada bloque en el log.
- [ ] Tras 2 bloques seguidos todo ✓ con nivel 4+, el agente propone nodo extra / más denso vía `ask_user`.
- [ ] Un visual (si lo hay) usa nombre único `<tema>-b<n>.mmd` y renderiza en Obsidian.
- [ ] Comprobar cómo se ve el LaTeX en las opciones del quiz (riesgo 3).

## Siguiente paso

Ejecutar la lección de humo con el checklist de arriba; si algo falla, ajustar
`~/.agents/teachme.ts` **y** `.agents/teachme.md` a la vez, y
reabrir sesión.

## Mejora posterior — control de calidad de artefactos (2026-08-28)

La generación del vault de hashes reveló un fallo operativo: se crearon notas sin la extensión `.md`, por lo que Obsidian no las mostraba; además, el diagnóstico inicial atribuyó incorrectamente un archivo vacío a Obsidian antes de comprobar la causa. El vault se corrigió renombrando las notas, flashcards y README, eliminando el duplicado vacío y haciendo explícitos los enlaces con `notas/`.

### Cambios aplicados al agente

- Añadida una checklist obligatoria de calidad en `.agents/teachme.md` y `~/.agents/teachme.ts`.
- Las notas futuras deben crearse siempre con `.md`; las fuentes Mermaid con `.mmd`.
- Antes de declarar terminado se deben comprobar estructura, extensiones, tamaños, archivos vacíos, duplicados, enlaces, flashcards y bloques Mermaid embebidos.
- El diagnóstico de visibilidad debe verificar primero la ruta absoluta, el árbol y el contenido real; no debe especular sobre el origen de archivos creados por Obsidian.
- El agente activo fue validado con `node --check` después del cambio.
