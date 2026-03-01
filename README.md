# SmartTrip AI

Final year BCA project: AI-powered travel itinerary planner.

## Module Architecture

The app is organized by modules under `lib/modules/`.

```
lib/
├── modules/
│   ├── user/
│   ├── admin/
│   ├── ai_generation/
│   │   ├── common/
│   │   ├── models/
│   │   ├── viewmodels/
│   │   ├── widgets/
│   │   └── screens/
│   ├── database_management/
│   └── external_api/
```

## Current Status

Implemented module:
- `ai_generation`

Implemented screens:
- `step1.dart`
- `step2.dart`
- `step3.dart`
- `step4.dart`
- `step5.dart`

## Refactor Rule

When adding or updating itinerary generation features:
- Place feature code inside `lib/modules/ai_generation/`.
- Keep UI in `screens/` and `widgets/`.
- Keep state/logic in `viewmodels/`.
- Keep enums/entities in `models/`.
- Keep shared module constants/utilities in `common/`.

Other modules (`user`, `admin`, `database_management`, `external_api`) will be populated as development progresses.
