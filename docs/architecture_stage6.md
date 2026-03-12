# Stage 6 Origami Companion Logic and Animation

## Architecture Explanation

Stage 6 introduces the origami companion logic and its animation system. The companion state is derived deterministically from current habit activity, producing a PetState that drives the visuals. The presentation layer renders the companion using a CustomPainter backed by deliberate, slow animations. Breathing motion, shadow drift, and fold intensity are tied to the PetState so that habit completions visibly reshape the sculpture.

Key decisions:

1. Deterministic pet logic
PetState is derived from habit completion ratio and streak totals. This keeps visuals in sync across devices once data sync is active.

2. CustomPainter for sculptural control
A bespoke painter builds layered origami panels with subtle gradients, shadows, and crease lines that simulate studio lighting.

3. Slow, intentional motion
Animation uses long durations to keep the companion calm. Fold intensity and damage respond to habit state changes.

4. Presentation isolation
OrigamiCompanion is a self contained widget that receives PetState and handles all motion internally.

## Directory Structure

- mobile/
  - lib/
    - features/
      - pet/
        - domain/
          - pet_state.dart
        - presentation/
          - pet_controller.dart
          - origami_companion.dart
      - home/
        - presentation/
          - home_screen.dart

## Code Examples

Pet state provider:

```dart
final petStateProvider = Provider<PetState>((ref) {
  final habits = ref.watch(habitsProvider);
  return _computePetState(habits);
});
```

Origami companion widget:

```dart
OrigamiCompanion(state: petState)
```

## API Contracts

No changes in Stage 6. The REST contracts from Stage 1 to Stage 3 remain unchanged.

## Database Schemas

No changes in Stage 6. The SQLite and PostgreSQL schemas from Stage 2 remain unchanged.
