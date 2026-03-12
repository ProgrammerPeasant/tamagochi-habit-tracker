# Stage 4 Flutter Project Structure

## Architecture Explanation

Stage 4 establishes the Flutter application skeleton with clean architecture boundaries and the design system foundations. The app is structured into core modules and feature modules, where each feature contains data, domain, and presentation layers. State management is wired with Riverpod to keep UI reactive and isolate business logic. The visual system is encoded as a theme with a monochrome palette, deliberate elevation, and calm typography to support the sculptural mood.

Key decisions:

1. Clean feature boundaries
Each feature owns its data, domain, and presentation layers. The home screen is a composition layer that assembles the pet and habits UI.

2. Design system as code
Color palette, typography, and elevation are centralized in core theme files for consistent visuals across screens.

3. Minimal navigation shell
A root scaffold controls bottom navigation to Home, Habits, Stats, and Profile without introducing complex routing yet.

4. Riverpod-first setup
ProviderScope is configured at app root. This makes it easy to add state controllers in later stages.

## Directory Structure

- mobile/
  - lib/
    - app/
      - app.dart
      - root_shell.dart
    - core/
      - theme/
        - app_colors.dart
        - app_theme.dart
        - app_typography.dart
    - features/
      - habits/
        - data/
        - domain/
        - presentation/
      - home/
        - presentation/
      - notifications/
        - data/
        - domain/
        - presentation/
      - pet/
        - data/
        - domain/
        - presentation/
      - profile/
        - data/
        - domain/
        - presentation/
      - stats/
        - data/
        - domain/
        - presentation/

## Code Examples

App entrypoint:

```dart
void main() {
  runApp(const ProviderScope(child: OrigamitApp()));
}
```

Theme definition:

```dart
final ThemeData theme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.primaryBackground,
  textTheme: AppTypography.textTheme,
);
```

## API Contracts

No changes in Stage 4. The REST contracts from Stage 1 to Stage 3 remain unchanged.

## Database Schemas

No changes in Stage 4. The SQLite and PostgreSQL schemas from Stage 2 remain unchanged.
