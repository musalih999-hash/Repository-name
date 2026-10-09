#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="${FLUTTER_HOME:-$HOME/flutter}/bin:${PATH}"
export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-21-openjdk-amd64}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$ANDROID_HOME}"
cd "$ROOT"
flutter doctor -v
flutter clean
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug --no-pub
printf '\nAPK: %s\n' "$ROOT/build/app/outputs/flutter-apk/app-debug.apk"
