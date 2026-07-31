#!/usr/bin/env bash
set -e
flutter create community_health_app
cp -R lib community_health_app/
cp -R test community_health_app/
cp pubspec.yaml analysis_options.yaml community_health_app/
cd community_health_app
flutter pub get
flutter run -d chrome
