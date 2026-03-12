# Origami Companion Visual Evolution Specification

Документ — исполняемая спецификация. Все координаты относительные (в диапазоне -1..1 по X/Y, Z — доля от базового размера).

## Входные параметры

- Energy (0–100)
- Mood (0–100)
- Damage (0–100)
- Complexity (0–100)

## Стадии: детальные требования

### Stage 1 — Flat Diamond (Complexity 0–19)

A. Геометрия
- Базовый ромб: 4 угла + центральная складка.
- Вершины формируются из diamond-grid с шагом 1 (5 вершин: 4 угла + центр).
- Faces: 2 треугольника, центральная линия crease визуализируется отдельно.

B. Высота
- Z: 0–2% от базового размера (bulge=0.02).

C. Элементы
- Две треугольные плоскости.
- Лёгкий хребет по диагонали.

D. Эффекты
- Тонкая тень, слабый градиент вдоль crease.

E. Анимация
- Breathing по Y: 0.5–1.5 px, период 4–6 s.
- Интерполяция complexity 0→19: linear lift центра (0→h1).

### Stage 2 — Folded Pyramid (Complexity 20–39)

A. Геометрия
- Ромб → неглубокая пирамида.
- Diamond-grid шаг 2 (13 вершин), центральная вершина (bulge=0.14).
- 4 треугольные грани + внутренние диагонали.

B. Высота
- 5–18% (Z максимум ~0.14).

C. Элементы
- Поднятые края, центральная вершина, радиальные складки.

D. Эффекты
- Контрастные альбедо различия между гранями.
- Тень сильнее, чем в Stage1.

E. Анимация
- Folding pulse 700–900 ms при переходе.
- Fold sharpness = base * (0.6 + 0.4 * energy/100).

### Stage 3 — Primitive Origami Form (Complexity 40–59)

A. Геометрия
- Diamond-grid шаг 3 (25 вершин) + крылья + спина.
- Faces: 8–12 плоскостей + дополнительные треугольники.
- Вершин 20–28.

B. Высота
- 20–35% (bulge=0.24 + выступы).

C. Элементы
- «Голова/спина/хвост» в виде дополнительных сегментов.
- Крылья из треугольников.

D. Эффекты
- Пересечения плоскостей, легкий AO в стыках.

E. Анимация
- Медленное вращение 0–8° от energy.
- При low mood — асимметрия (см. раздел Mood).

### Stage 4 — Advanced Origami Sculpture (Complexity 60–79)

A. Геометрия
- Diamond-grid шаг 4 (41 вершина) + 3 слоя + «балконы» + шпиль.
- Faces 20+.
- Вершин 40+.

B. Высота
- 35–60% (bulge=0.36 + верхние слои).

C. Элементы
- Внутренние слои, вторичные гребни, «балконы».

D. Эффекты
- Глубокие тени, лёгкие блики по граням.
- Тонкое зерно бумаги.

E. Анимация
- Occasional fold adjustments (8–15 s).
- Micro tremor при low energy.

### Stage 5 — Origami Architecture (Complexity 80–100)

A. Геометрия
- Diamond-grid шаг 6 (85 вершин) + 4 слоя + консоли + шпили.
- Faces 40+.
- Вершин 80+.

B. Высота
- 60–120% (bulge=0.62 + шпили).

C. Элементы
- Консоли, нависания, внутренние полости, «проёмы».

D. Эффекты
- Сложные тени, тонкая золотая кромка (очень экономно).

E. Анимация
- Slow elegant breathing.
- Occasional settle (1200 ms) при апгрейде стадии.
- Damage>70 → частичный коллапс сегментов.

## Интерполяция между стадиями

1. Определить текущую стадию по complexity.
2. Внутри диапазона стадии вычислить `w = (complexity - stageMin) / (stageMax - stageMin)`.
3. Сгладить: `w_smooth = easeInOutCubic(w)`.
4. Морфинг:
   - Привести вершины StageN к числу вершин StageN+1 методом сопоставления по полярному углу + seed jitter.
   - `V = lerp(V_stageN, V_stageN+1, w_smooth)`.

## Применение Energy / Mood / Damage

Energy
- `idle_amp = base_idle_amp * (energy/100)^0.8`
- `fold_sharpness = base_angle * (0.6 + 0.4*(energy/100))`

Mood
- Симметрия: `V_final = lerp(V_original, V_mirrored, mood/100)`
- При mood < 30 добавляется Perlin/noise смещение: amplitude = (30-mood)/30 * max_offset

Damage
- `damage_map = smoothstep(damage/100)`
- >20: wrinkles (normal perturbation)
- >50: рваные края, вершины уезжают внутрь/вниз
- >80: часть face отключается (collapse)

## Рендеринг (Flutter)

Компоненты:

- `OrigamiController` — нормализация входа и расчёт mesh
- `OrigamiMeshGenerator` — построение стадий, морфинг, energy/mood/damage
- `OrigamiMeshPainter` — 2.5D рендер: полигоны, shadows, AO, edges
- `FoldAnimator` — тайминги (fold/settle/pulse)

LOD
- Low-end: использовать только Stage1/Stage3/Stage5
- Средний: пропускать мелкие слои
- Высокий: полный mesh

## Mesh tables (исполняемые таблицы)

Вершинные таблицы, face indices и normals находятся в:

- docs/origami_mesh/stage1_mid.json
- docs/origami_mesh/stage2_mid.json
- docs/origami_mesh/stage3_mid.json
- docs/origami_mesh/stage4_mid.json
- docs/origami_mesh/stage5_mid.json

Damaged варианты:

- docs/origami_mesh/stage1_damaged.json
- docs/origami_mesh/stage2_damaged.json
- docs/origami_mesh/stage3_damaged.json
- docs/origami_mesh/stage4_damaged.json
- docs/origami_mesh/stage5_damaged.json

SVG эскизы:

- docs/origami_mesh/stage1_mid.svg
- docs/origami_mesh/stage2_mid.svg
- docs/origami_mesh/stage3_mid.svg
- docs/origami_mesh/stage4_mid.svg
- docs/origami_mesh/stage5_mid.svg
- docs/origami_mesh/stage1_damaged.svg
- docs/origami_mesh/stage2_damaged.svg
- docs/origami_mesh/stage3_damaged.svg
- docs/origami_mesh/stage4_damaged.svg
- docs/origami_mesh/stage5_damaged.svg

## Примеры входных состояний

1) {complexity: 10, energy: 80, mood: 90, damage: 0}
- Stage1
- Плоская форма, симметрия максимальная, lively micro motion.

2) {complexity: 30, energy: 40, mood: 80, damage: 10}
- Stage2
- Небольшая пирамида, мягкие тени.

3) {complexity: 50, energy: 70, mood: 50, damage: 30}
- Stage3
- Primitive form, заметная асимметрия.

4) {complexity: 70, energy: 20, mood: 30, damage: 60}
- Stage4
- Глубокие деформации, micro tremor.

5) {complexity: 90, energy: 90, mood: 95, damage: 5}
- Stage5
- Архитектурный павильон, чистая симметрия.

## Псевдокод (Flutter)

```dart
final mesh = generator.buildMesh(
  complexity: state.structureComplexity,
  energy: state.energy,
  mood: state.mood,
  damage: state.damage,
  seed: stateSeed,
);

CustomPaint(
  painter: OrigamiMeshPainter(
    mesh: mesh,
    energy: state.energy / 100,
    damage: state.damage / 100,
    light: idleValue,
  ),
);
```

## Stage1 → Stage2 morph (пример)

```dart
final t = easeInOutCubic((complexity - 20) / 19);
final meshA = baseMesh(stage1);
final meshB = baseMesh(stage2);
final mesh = morph(meshA, meshB, t, seed);
```

## Интеграция с API

```dart
final response = await client.get('/v1/pet');
final pet = PetState.fromJson(response);

OrigamiCompanion(state: pet);
```
