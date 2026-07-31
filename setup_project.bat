@echo off
flutter create community_health_app
xcopy /E /I /Y lib community_health_app\lib
xcopy /E /I /Y test community_health_app\test
copy /Y pubspec.yaml community_health_app\pubspec.yaml
copy /Y analysis_options.yaml community_health_app\analysis_options.yaml
cd community_health_app
flutter pub get
flutter run -d chrome
