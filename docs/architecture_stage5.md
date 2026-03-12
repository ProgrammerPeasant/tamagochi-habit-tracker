# Stage 5 Habit Tracking UI

## Architecture Explanation

Stage 5 focuses on the habit tracking UI. The presentation layer now renders a sculptural home screen with a focused habit list and a dedicated Habits screen for full management. State is managed through Riverpod using a lightweight in memory controller to keep UI flows interactive while backend wiring remains pending. The UI is built on the established design system so that color, typography, and elevation are consistent with the minimalist avant garde aesthetic.

Key decisions:

1. Feature scoped state
Habit state lives in a HabitsController, exposed via Riverpod providers to both Home and Habits screens.

2. Layered surfaces
Cards and panels use soft dark surfaces with subtle shadowing to create a physical installation feel.

3. Quiet interactions
Buttons and toggles use subtle brightness shifts and minimal motion while keeping completion actions clear.

4. Modular presentation widgets
Habit cards and form sheets are isolated for reuse and visual consistency.

## Directory Structure

- mobile/
  - lib/
    - features/
      - habits/
        - domain/
          - habit.dart
        - presentation/
          - habits_controller.dart
          - habits_screen.dart
          - widgets/
            - habit_card.dart
            - habit_form_sheet.dart
      - home/
        - presentation/
          - home_screen.dart

## Code Examples

Riverpod controller:

```dart
final habitsProvider = StateNotifierProvider<HabitsController, List<HabitEntity>>(
  (ref) => HabitsController(),
);
```

Habit card widget:

```dart
class HabitCard extends StatelessWidget {
  final HabitEntity habit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(child: Text(habit.title)),
          IconButton(icon: Icon(habit.completedToday ? Icons.check_circle : Icons.circle_outlined)),
        ],
      ),
    );
  }
}
```

## API Contracts

No changes in Stage 5. The REST contracts from Stage 1 to Stage 3 remain unchanged.

## Database Schemas

No changes in Stage 5. The SQLite and PostgreSQL schemas from Stage 2 remain unchanged.
