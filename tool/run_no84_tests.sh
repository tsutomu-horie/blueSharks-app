#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
flutter test --no-pub test/training_game/no84_current_settings_test.dart
