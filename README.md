# BeautyHub

A multi-vendor marketplace for salons, barbers and spas — "Uber for beauty".
This repository contains the **customer-facing MVP** built with Flutter for
Android and iOS.

## Features (MVP)

- **Explore** — search salons by name or service, filter by category
  (haircut, barber, nails, spa, makeup, skincare), featured carousel and a
  nearest-first list.
- **Salon details** — services with prices and durations, team, reviews,
  opening hours. Select one or more services and see a running total.
- **Booking flow** — pick a professional (or "any"), a date and an available
  time slot, review the summary and confirm.
- **My bookings** — upcoming and history tabs, cancellation with
  confirmation.
- **Profile** — placeholder account area ready for auth, payments and
  favourites.

## Architecture

Pragmatic clean architecture with a strict dependency rule
(`presentation → domain ← data`):

```
lib/
├── main.dart                  # entry point (ProviderScope)
├── app.dart                   # MaterialApp.router
├── core/                      # cross-cutting concerns
│   ├── di/providers.dart      # composition root (repository bindings)
│   ├── router/app_router.dart # go_router config (shell + full-screen routes)
│   ├── theme/app_theme.dart   # Material 3 theme + brand palette
│   ├── utils/formatters.dart  # currency / date / duration formatting
│   └── widgets/               # shared presentation widgets
├── domain/                    # pure Dart, no Flutter imports
│   ├── entities/              # Salon, SalonService, StaffMember, Booking…
│   └── repositories/          # abstract contracts
├── data/
│   ├── mock/                  # seed catalogue
│   └── repositories/          # in-memory implementations of the contracts
└── features/                  # one folder per feature, presentation layer
    ├── home/
    ├── salon/
    ├── booking/
    ├── bookings/
    ├── profile/
    └── shell/                 # bottom-navigation scaffold
```

- **State management:** Riverpod (`flutter_riverpod`), no code generation.
- **Navigation:** `go_router` with a `StatefulShellRoute` for the bottom
  tabs; salon details and booking are full-screen routes on the root
  navigator.
- **Data:** the app talks only to the abstract `SalonRepository` /
  `BookingRepository`. The MVP binds in-memory mocks (with simulated
  latency) in `core/di/providers.dart`; swapping in a REST/GraphQL backend
  is a one-file change.
- **Vendor imagery:** deterministic gradient covers (`Salon.coverSeed`)
  stand in for photos until a real media pipeline exists.

## Getting started

```sh
flutter pub get
flutter run            # with an Android emulator (or iOS simulator) running
```

Run checks:

```sh
flutter analyze
flutter test
```

## Post-MVP roadmap

- Authentication (customer accounts) and persisted bookings
- Real backend + media storage for vendor photos
- Payments at checkout
- Geolocation for true "near you" distances
- Vendor-side app (calendar, service management)
- Push notifications for booking reminders
