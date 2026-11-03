# Трекер привычек — дизайн-кит MVP

Дизайн-концепт первого продукта Sukhanov labs: офлайн-трекер привычек для Android (Flutter),
публикация в RuStore. Базовый экран — **360 × 800 dp**, светлая тема, русский интерфейс.
Рабочее название в макетах — «Привычки»; финальное имя подставляет маркетинг (SUK-6).

Скоуп синхронизирован с брифом SUK-3: ежедневное или выборочное расписание, эмодзи (16) и
цвет (6), без онбординга, статистика без графиков.

## Как открыть

Откройте `index.html` в браузере — это обзорный хаб со всеми экранами и материалами.
Сборка не нужна: макеты — статические HTML + CSS, иконки — SVG, экспорт — PNG.

```
index.html                     обзор: экраны, палитра, иконка, скриншоты
mockups/01…09*.html            экраны 360 × 800; 01* — онбординг P2, вне MVP
mockups/10-components.html     все компоненты и состояния
assets/app-icon*.svg           иконка: основной концепт + 2 альтернативы
assets/app-icon-512.png        иконка для карточки RuStore
assets/app-icon-1024.png       иконка для Google Play
assets/icon-preview.html       проверка иконки на 128…32 px
store/screenshot-1…4.html      композиции скриншотов 1080 × 1920
store/app/*.png               кадры реального UI 1080 × 2400 (SUK-10)
store/store-1…4-*.png          готовые PNG для RuStore
tokens/design-tokens.json      токены (цвет, шрифт, отступы, радиусы, motion)
tokens/theme.dart              эталонная тема Flutter
exports/*.png                  PNG-экспорт экранов 1080 × 2400
tools/render.mjs               аудит вёрстки и пересборка PNG
tools/render-icons.mjs         иконка 512/1024 и Android mipmap
../tool/suk10_screenshots_test.dart  рендер экранов приложения
```

## Пересобрать PNG

Нужны Node 22+ и Google Chrome. Скрипт запускает headless Chrome, проверяет, что контент не
выходит за пределы экрана, и сохраняет PNG.

```bash
node tools/render.mjs audit     # проверка переполнений и рендера иконок
node tools/render.mjs screens   # exports/*.png, 1080 × 2400 (3x)
node tools/render.mjs store     # store/store-*.png, 1080 × 1920
node tools/render-icons.mjs     # assets/app-icon-*.png + android mipmap
```

Если Chrome установлен не в `C:\Program Files\Google\Chrome\Application\chrome.exe`,
задайте `CHROME_PATH`.

## Шрифт

В макетах используется **Inter** (лицензия SIL OFL), подключённый локально из `assets/`.
Для Flutter шрифт нужно **встроить в APK** (не `google_fonts` — приложение офлайн): положить
static `.ttf` в `assets/fonts/` и объявить в `pubspec.yaml`. Кириллица обязательна.

## Рамки MVP

В дизайне только то, что входит в первую версию: список привычек, отметка, серии, ежедневные
напоминания, простая статистика, базовые настройки. Тёмная тема, гибкое расписание, экспорт
данных, аккаунты и синхронизация — во второй версии.

## Источник правды

- Спецификация для разработчика — документ `design` в задаче SUK-4.
- Цвета, типографика, размеры — `tokens/design-tokens.json`.
- Визуальные состояния — макеты и `mockups/10-components.html`.
