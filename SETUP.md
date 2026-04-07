# Polymarket Swipe — Setup

## Требования
- Flutter SDK (>=3.0.0) — https://flutter.dev
- Android Studio (для Android SDK)
- Android-телефон с включённой USB-отладкой

## Первый запуск

```bash
# 1. Клонируй репо
git clone <repo-url>
cd polymarket_swipe

# 2. Создай нативную обвязку Flutter (только один раз!)
flutter create . --project-name polymarket_swipe --org com.polyswipe

# 3. Добавь интернет-разрешение в android/app/src/main/AndroidManifest.xml
# Найди строку <manifest ...> и добавь сразу после неё:
# <uses-permission android:name="android.permission.INTERNET"/>

# 4. Установи зависимости
flutter pub get

# 5. Подключи телефон по USB и запускай
flutter run
```

## Hot Reload
После запуска `flutter run`:
- `r` — Hot Reload (мгновенное обновление UI)
- `R` — Hot Restart (полный перезапуск)
- `q` — выход

## Структура проекта
```
lib/
  main.dart                    — точка входа
  models/market.dart           — модель рынка Polymarket
  services/polymarket_service.dart — Gamma API
  widgets/market_card.dart     — карточка рынка
  screens/feed_screen.dart     — лента со свайпами
```
