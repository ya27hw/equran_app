# eQuran

<p align="center">
  <a href="https://github.com/ya27hw/equran_app/blob/main/pubspec.yaml">
    <img alt="App version" src="https://img.shields.io/badge/dynamic/yaml?url=https%3A%2F%2Fraw.githubusercontent.com%2Fya27hw%2Fequran_app%2Fmain%2Fpubspec.yaml&query=%24.version&label=app%20version&style=for-the-badge">
  </a>
  <a href="https://github.com/ya27hw/equran_app/releases">
    <img alt="Latest release" src="https://img.shields.io/github/v/release/ya27hw/equran_app?sort=semver&style=for-the-badge">
  </a>
  <a href="https://github.com/ya27hw/equran_app/commits/main">
    <img alt="Last commit" src="https://img.shields.io/github/last-commit/ya27hw/equran_app?style=for-the-badge">
  </a>
  <a href="https://github.com/ya27hw/equran_app/stargazers">
    <img alt="GitHub stars" src="https://img.shields.io/github/stars/ya27hw/equran_app?style=for-the-badge">
  </a>
  <a href="https://github.com/ya27hw/equran_app/network/members">
    <img alt="GitHub forks" src="https://img.shields.io/github/forks/ya27hw/equran_app?style=for-the-badge">
  </a>
  <a href="https://github.com/ya27hw/equran_app/actions/workflows/deploy.yml">
    <img alt="Release build" src="https://img.shields.io/github/actions/workflow/status/ya27hw/equran_app/deploy.yml?branch=main&label=release%20build&style=for-the-badge">
  </a>
  <a href="LICENSE">
    <img alt="License" src="https://img.shields.io/github/license/ya27hw/equran_app?style=for-the-badge">
  </a>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-%E2%89%A53.41.7-02569B?logo=flutter&logoColor=white&style=flat-square">
  <img alt="Dart" src="https://img.shields.io/badge/Dart-%E2%89%A53.11.5-0175C2?logo=dart&logoColor=white&style=flat-square">
  <img alt="Release targets" src="https://img.shields.io/badge/targets-Android%20%7C%20Linux%20%7C%20Windows-0f766e?style=flat-square">
</p>

<p align="center">
  <a href="https://f-droid.org/en/packages/com.app.equran/">
    <img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="72">
  </a>
</p>

eQuran is a focused Quran companion built with Flutter. It brings reading, listening, favourites, tafsir, transliteration, prayer times, Qibla direction, and offline audio downloads into one calm Material 3 experience.

The goal is simple: keep the interface quiet, keep the text central, and make the daily act of reading or listening feel easy to return to.

## Screenshots

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/1.png" alt="eQuran home screen" width="180">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/2.png" alt="Quran reading screen" width="180">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/3.png" alt="Surah list screen" width="180">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/4.png" alt="Audio player screen" width="180">
</p>

<p align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/5.png" alt="Downloads screen" width="180">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/6.png" alt="Favourites screen" width="180">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/7.png" alt="Prayer times screen" width="180">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/8.png" alt="Settings screen" width="180">
</p>

## 💖 Support the Project

If this project helps you, consider supporting its development! You can donate using any of the cryptocurrency addresses below:

| Cryptocurrency | Badge | Wallet Address |
| :--- | :--- | :--- |
| **Bitcoin (BTC)** | ![Bitcoin](https://img.shields.io/badge/Bitcoin-F7931A?style=for-the-badge&logo=bitcoin&logoColor=white) | `bc1qs7jfrkxvpdh96qmfu9srtla38fe30gvdvc22av` |
| **Ethereum (ETH)** | ![Ethereum](https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=ethereum&logoColor=white) | `0x9d60158D5315Fa46241FC47Bf76eEE6cF7abcAa9` |
| **Solana (SOL)** | ![Solana](https://img.shields.io/badge/Solana-242424?style=for-the-badge&logo=solana&logoColor=A81507) | `Gyy1Ar1Lu5zbyW9WEcisKkcGxBb4GPuUQEJvcQ4oV9va` |
| **USDC (ERC-20)** | ![USDC](https://img.shields.io/badge/USDC-2775CA?style=for-the-badge&logo=usd-coin&logoColor=white) | `0x9d60158D5315Fa46241FC47Bf76eEE6cF7abcAa9` |
| **Litecoin (LTC)** | ![Litecoin](https://img.shields.io/badge/Litecoin-0096FF?style=for-the-badge&logo=bitcoin&logoColor=white) | `LZW5Jh52Lnni6Zr3FQhimGGkyZPywSAaDX` |

## ☕ Dev Tools

[OpenCode Go](https://opencode.ai/go?ref=APMP0ZVD7S) — open-source AI coding agent for the terminal. New users: sign up through this link and we both get **$5 usage credit**!

## What It Does

- Read the Quran by Surah or Juz.
- Resume from your last-read ayah.
- Listen to full surahs or individual ayahs.
- Download Quran audio for offline playback.
- Choose from multiple reciters.
- Save favourite ayahs with optional notes.
- View translation, transliteration, and tafsir where available.
- Use prayer times, reminders, location settings, and Qibla tools.
- Share ayahs as generated images.
- Use responsive layouts across mobile, tablet, and desktop-sized screens.

## Supported Devices

| Platform | Status | Notes |
| --- | --- | --- |
| Android phones and tablets | Supported | Primary mobile target. Release APKs are built in CI. |
| Linux desktop | Supported | Release bundle is built in CI. |
| Windows desktop | Supported | Release bundle is built in CI. |
| iOS | Project files included | Can be run from Flutter with Apple tooling; not part of the current release workflow. |
| macOS | Project files included | Can be run from Flutter with Apple tooling; not part of the current release workflow. |
| Web | Project files included | Useful for development checks; not part of the current release workflow. |

## Requirements

Install the Flutter stable SDK and the platform tooling for the device you want to run:

| Target | Tooling |
| --- | --- |
| Android | Android Studio, Android SDK, and an emulator or physical device |
| Linux | `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`, and GStreamer development packages |
| Windows | Visual Studio with Desktop development with C++ |
| iOS/macOS | Xcode on macOS |
| Web | Chrome or another Flutter-supported browser |

This project currently expects:

```text
Flutter >=3.41.7
Dart >=3.11.5 <4.0.0
```

## Run The App

Clone the repository:

```bash
git clone https://github.com/ya27hw/equran_app.git
cd equran_app
```

Install dependencies:

```bash
flutter pub get
```

Run on the connected device or selected desktop target:

```bash
flutter run
```

You can also choose a specific target:

```bash
flutter run -d android
flutter run -d linux
flutter run -d windows
flutter run -d chrome
```

## Build Releases

Android split APKs:

```bash
flutter build apk --release --split-per-abi
```

Linux:

```bash
flutter config --enable-linux-desktop
flutter build linux --release
```

Windows:

```bash
flutter config --enable-windows-desktop
flutter build windows --release
```

Build outputs are written under `build/`.

## Project Shape

```text
lib/
  backend/      Data, downloads, audio, persistence, settings, and services
  home/         Main screens, reading views, player, library, and settings
  prayer/       Prayer times, reminders, location, timezone, and Qibla tools
  utils/        Theme, layout, formatting, and shared helpers
  widgets/      Reusable interface components

assets/
  fonts/        Hafs Quran font
  content/      Daily hadith and dua content
  tafsir/       Tafsir JSON assets
  transliteration/

metadata/       Store listing metadata and app icon
```

## Release Flow

The GitHub Actions release workflow lives in [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml).

On pushes to `main` or manual workflow dispatch, it reads the version from `pubspec.yaml`, builds Android split APKs plus Linux and Windows bundles, then publishes a GitHub Release when the version tag is new.

## Notes For Maintainers

Prayer times are calculated locally with `adhan_dart`. Prayer reminders use `flutter_local_notifications` and Android scheduled notifications. Android 13 and newer require notification permission, which the app requests when reminders are enabled.

The prayer location picker uses `flutter_map` with OpenStreetMap-compatible tiles. If the app grows beyond light usage, use a tile provider that fits the project’s traffic and terms.

## Contributing

Contributions are welcome when they keep the app focused, respectful, and easy to use.

Before opening a pull request:

1. Keep the change scoped.
2. Run `dart format .`.
3. Run `flutter analyze`.
4. Test the feature path you touched.
5. Update documentation when setup, behavior, or release steps change.

## License

eQuran is released under the [MIT License](LICENSE).
