# Application architecture

## Overview

The package is `koto_blue_sharks`, a Flutter application organized around GetX. It uses feature-oriented presentation directories with a practical Screen -> Controller -> Provider -> Model flow rather than strict Clean Architecture.

## Layer map

- `lib/main.dart`: initializes Hive adapters, analytics, shared preferences, FCM, localization, and `GetMaterialApp`.
- `lib/presentation/`: feature screens and their GetX controllers.
- `lib/infrastructure/navigation/`: route constants, `GetPage` registrations, and controller bindings.
- `lib/app/providers/`: API access through `GetConnect`, grouped by auth, gallery, info, match, media, member, and OTP.
- `lib/app/data/models/`: Freezed and JSON-serializable API and persistence models.
- `lib/app/services/`: authentication token storage, analytics, and notification services.
- `lib/app/views/views/`: reusable UI components.
- `lib/utils/`: constants, colors, formatting, preferences, FCM, notifications, and general helpers.
- `lib/generated/`: generated localization data.
- `assets/`: fonts, images, SVG vectors, and Lottie animations.

## Main features

- `splash`: version checks through Firebase Remote Config and initial navigation.
- `main`: application shell, toolbar, notifications, and five-tab bottom navigation.
- `home`: home content.
- `menu/info`: news and topics.
- `menu/match`: match list and details.
- `menu/player`: player list and details.
- `menu/gallery`: gallery list and details.
- `profile`: my page, password editing, and account deletion.
- `register`: email registration, OTP, fan-club registration, login, and password recovery.
- `notification`: notification list and details.
- `wallpaper`: wallpaper and selected-player wallpaper flows.
- `stadium`: stadium information and fullscreen images.
- `calendar`: calendar view.
- `webview`: team pages and privacy policy.

## Main navigation

`MainScreen` contains five tabs:

1. Home
2. Menu and news
3. My page
4. Stadium
5. Calendar

GetX route names live in `lib/infrastructure/navigation/routes.dart`. Page factories and bindings live in `lib/infrastructure/navigation/navigation.dart` and `lib/infrastructure/navigation/bindings/controllers/`.

## State and data

- GetX reactive values (`.obs`) and `Obx` drive screen state.
- Controllers coordinate user actions, navigation, services, and providers.
- Providers use `GetConnect` for HTTP requests.
- Models use Freezed and `json_serializable`; generated files end in `.freezed.dart` and `.g.dart`.
- Hive caches member, category, media, and related application data.
- SharedPreferences stores lightweight flags such as first-open state.
- FlutterSecureStorage stores the access token.
- Firebase Messaging and Awesome Notifications handle notifications.
- Firebase Remote Config controls version checks.
- Firebase Analytics records usage.

## Startup flow

1. Resolve the initial route as `/splash`.
2. Initialize Hive and register model adapters.
3. Initialize analytics, preferences, and FCM.
4. Start `GetMaterialApp` with Japanese localization and GetX pages.
5. In the splash controller, fetch Remote Config and compare app versions.
6. Route first-time users to wallpaper selection and returning users to `MainScreen`.

## Environment and UI defaults

- `lib/config.dart` selects local, dev, QAS, or production settings; the checked-in selection is local.
- ScreenUtil uses a `375 x 812` design size.
- The app forces a text scale factor of `1.0` and uses the Inter font.
- The supported and fallback locale is `ja_JP`.

## Known structural risks to recheck

- `Routes.FORGOT_PASSWORD` is registered more than once in the current navigation table.
- `Routes.RESET_PASSWORD` shares the `/forgot-password` path.
- `WidgetsFlutterBinding.ensureInitialized()` currently appears after Hive initialization.
- Retrofit is declared, while the inspected providers primarily use GetConnect.
- Test coverage is minimal and includes the default-style widget test.

Confirm these against the working tree before relying on them because the repository may evolve.
