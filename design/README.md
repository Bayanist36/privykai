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
tokens/tokens-v1.2-proposed.json  предложение по токенам (не источник истины)
exports/*.png                  PNG-экспорт экранов 1080 × 2400
exports/v12-*.png              концепты v1.2 (статистика, тихие часы, цель, онбординг)
mockups/v12-*.html             концепты v1.2; вне MVP 1.1
widgets/widget-2x1.html        виджет 2×1: 3 варианта, 4 состояния, 2 темы
widgets/widget-4x2.html        виджет 4×2: то же
widgets/exports/*.png          обзоры @2x и точные PNG @3x
UI_AUDIT_v1.0.md               UI-аудит 1.1: дефекты и приоритеты
TOKENS_AUDIT_v1.0.md           контраст, типографика, сетка, тёмная тема
V1_2_CONCEPTS.md               описание концептов и открытые решения
WIDGET_SPEC_v1.0.md            спецификация виджета для разработчика
tools/render.mjs               аудит вёрстки и пересборка PNG
tools/render-v12.mjs           рендер концептов и виджетов
tools/round-widget-corners.py  прозрачные скругления PNG виджетов
tools/contrast.mjs             расчёт контраста WCAG по токенам
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
node tools/render-v12.mjs all   # exports/v12-*.png + widgets/exports/*.png
python tools/round-widget-corners.py  # прозрачные углы точных PNG виджетов
node tools/contrast.mjs         # таблица контраста WCAG по токенам
```

`render-v12.mjs all` пересобирает оба вида: экраны 360 × 800 @3x и виджеты
(точные 2×1 456 × 216 и 4×2 984 × 480 @3x, обзоры @2x).

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
