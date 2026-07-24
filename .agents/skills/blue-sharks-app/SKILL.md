---
name: blue-sharks-app
description: Investigate, explain, review, and safely modify the koto_blue_sharks Flutter application. Use for questions or implementation work involving this repository's GetX screens and controllers, navigation and bindings, GetConnect providers, Freezed models, local storage, Firebase integrations, startup flow, or feature placement.
---

# Blue Sharks App

Work from repository evidence. Read [references/architecture.md](references/architecture.md) before explaining the app structure, deciding where a change belongs, or tracing a feature across layers.

## Investigate

1. Read `pubspec.yaml`, `lib/main.dart`, and the files directly related to the requested feature.
2. Trace behavior in this order when applicable: Screen -> GetX Controller -> Provider or Service -> Model or storage.
3. Check `lib/infrastructure/navigation/routes.dart`, `navigation.dart`, and the relevant binding for routed screens.
4. Use `rg` to confirm call sites and dependencies. Do not infer current behavior from filenames alone.
5. Treat generated `*.freezed.dart`, `*.g.dart`, and `lib/generated/` files as generated outputs; edit their source definitions instead.

## Change

1. Keep features in their existing layer and feature directory unless the task explicitly requires restructuring.
2. Put reusable widgets under `lib/app/views/views/`; keep screen-specific UI beside its screen.
3. Keep reactive screen state in the relevant GetX controller and API calls in providers.
4. Preserve the existing Japanese locale, ScreenUtil design size, authentication storage, and environment selection unless the request changes them.
5. Regenerate Freezed and JSON code when model annotations change.

## Verify

Run the smallest relevant checks first:

```sh
dart format --output=none --set-exit-if-changed <changed-dart-files>
flutter analyze
flutter test
```

If repository-wide analysis already contains unrelated findings, distinguish them from regressions caused by the change. For startup, navigation, Firebase, native permission, or platform-specific changes, also perform the relevant Android or iOS build/run check when feasible.

## Report

Explain the result in Japanese when the user asks in Japanese. Cite concrete repository paths, separate verified facts from inferences, and mention focused verification performed. Call out existing structural risks only when they affect the request.
