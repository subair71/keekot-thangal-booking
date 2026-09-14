#!/usr/bin/env bash
set -euo pipefail
export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
cd "$(dirname "$0")/.."
booking_environment="${1:-development}"
case "$booking_environment" in development|staging|production) ;; *) echo 'Use development, staging, or production.'; exit 1;; esac
booking_config="config/${booking_environment}.json"
if command -v py >/dev/null 2>&1; then
  py tool/configure_web.py "$booking_config"
elif command -v python3 >/dev/null 2>&1; then
  python3 tool/configure_web.py "$booking_config"
else
  python tool/configure_web.py "$booking_config"
fi
flutter pub get --enforce-lockfile
dart run build_runner build
flutter analyze
flutter test
flutter build web --release --dart-define-from-file="$booking_config"
