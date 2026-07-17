# BeautyHub — customer MVP (Flutter)

Multi-vendor salon/barber marketplace ("Uber for beauty"). Android + iOS,
tested on an Android emulator.

## Commands

- `flutter run` — run on the connected emulator/device
- `flutter analyze` — must stay at zero issues
- `flutter test` — unit + widget tests in `test/`

## Architecture rules

- Dependency rule: `features/* (presentation) → domain ← data`. `domain/` is
  pure Dart — no Flutter imports there.
- All data access goes through the abstract repositories in
  `domain/repositories/`. Bindings live in `lib/core/di/providers.dart`
  (currently in-memory mocks with simulated latency). To add a real backend,
  implement the contracts in `data/repositories/` and swap the binding —
  do not call data sources from widgets.
- State management is Riverpod **without codegen** (`flutter_riverpod` 2.x);
  navigation is `go_router` (`lib/core/router/app_router.dart`). Bottom tabs
  use `StatefulShellRoute`; full-screen flows (salon details, booking) go on
  the root navigator.
- Theme/palette in `lib/core/theme/app_theme.dart`; currency & date
  formatting only via `lib/core/utils/formatters.dart` (single place to
  change currency/locale).
- Vendor photos don't exist yet: covers are gradients keyed by
  `Salon.coverSeed` (see `AppColors.coverGradients` and `SalonCover`).

## Conventions

- One class per file, feature-first folders: `features/<name>/presentation/`
  with `providers/` and `widgets/` subfolders.
- Booking selection flows via route params: salon details pushes
  `/salon/:id/book?services=<comma-separated ids>`.
- After mutating bookings, `ref.invalidate(bookingsProvider)`.
