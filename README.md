# Win Display Flip

One-click Windows monitor rotation tool. No external software required.

## What is this?

A lightweight batch script generator that creates custom rotation scripts for your monitors. Perfect for:
- Switching between landscape and portrait mode with one click
- Vertical monitor setups for coding/reading
- Multi-monitor configurations with individual settings
- Quick screen orientation toggle via hotkey or shortcut

## Features

- **Zero dependencies** - Pure Windows batch + PowerShell, no installation needed
- **Auto-detect monitors** - Scans and shows all connected displays with resolution and current orientation
- **Multi-monitor support** - Configure multiple monitors at once (comma separated: `1, 2, 3`)
- **Custom rotation scripts** - Generate personalized .bat files for your specific setup
- **Toggle mode** - Switch back and forth between orientations with single click
- **One-time mode** - Just set orientation once without toggling
- **All orientations supported** - Landscape, Portrait, Landscape flipped, Portrait flipped

## Quick Start

1. Run `Setup.bat` as Administrator
2. Select monitors (comma separated, e.g. `1, 2` or just `1`)
3. For each monitor:
   - Choose target orientation (0-3)
   - Choose swap mode (Y/N)
4. Enter filename for your script
5. Done! Run the generated .bat file to rotate your screens

## Orientation Values

| Value | Orientation | Description |
|-------|-------------|-------------|
| 0 | Landscape | Normal horizontal (default) |
| 1 | Portrait | Rotated 90° clockwise |
| 2 | Landscape flipped | Upside down (180°) |
| 3 | Portrait flipped | Rotated 270° (or 90° counter-clockwise) |

## Requirements

- Windows 10/11
- Administrator privileges (requested automatically)

## Pro Tips

- Create a desktop shortcut to your rotation script
- Assign a keyboard hotkey to the shortcut for instant rotation
- Pin to taskbar for quick access

---

# Win Display Flip (Русский)

Поворот монитора Windows одним кликом. Без сторонних программ.

## Что это?

Легковесный генератор batch-скриптов для создания персональных скриптов поворота мониторов. Идеально для:
- Переключения между альбомной и книжной ориентацией одним кликом
- Вертикальных мониторов для кодинга/чтения
- Мульти-мониторных конфигураций с индивидуальными настройками
- Быстрого переключения ориентации через горячую клавишу

## Возможности

- **Без зависимостей** - Чистый Windows batch + PowerShell, установка не нужна
- **Автоопределение мониторов** - Сканирует и показывает все подключенные дисплеи с разрешением и текущей ориентацией
- **Мульти-монитор** - Настройка нескольких мониторов сразу (через запятую: `1, 2, 3`)
- **Кастомные скрипты** - Генерирует персонализированные .bat файлы под вашу конфигурацию
- **Режим переключения** - Переключение туда-обратно между ориентациями одним кликом
- **Однократный режим** - Просто установить ориентацию один раз без переключения
- **Все ориентации** - Альбомная, Книжная, Альбомная перевернутая, Книжная перевернутая

## Быстрый старт

1. Запустите `Setup.bat` от имени Администратора
2. Выберите мониторы (через запятую, например `1, 2` или просто `1`)
3. Для каждого монитора:
   - Выберите целевую ориентацию (0-3)
   - Выберите режим swap (Y/N)
4. Введите имя файла для скрипта
5. Готово! Запускайте созданный .bat файл для поворота экранов

## Значения ориентации

| Значение | Ориентация | Описание |
|----------|------------|----------|
| 0 | Альбомная | Обычная горизонтальная (по умолчанию) |
| 1 | Книжная | Поворот на 90° по часовой |
| 2 | Альбомная перевернутая | Вверх ногами (180°) |
| 3 | Книжная перевернутая | Поворот на 270° (или 90° против часовой) |

## Требования

- Windows 10/11
- Права администратора (запрашиваются автоматически)

## Советы

- Создайте ярлык на рабочем столе для скрипта поворота
- Назначьте горячую клавишу на ярлык для мгновенного поворота
- Закрепите на панели задач для быстрого доступа

---

## Keywords / Ключевые слова

windows monitor rotation, screen orientation, display flip, rotate screen windows, portrait mode windows, landscape to portrait, monitor toggle, screen rotation script, batch screen rotate, powershell display rotation, windows display settings, multi monitor rotation, vertical monitor setup, rotate display windows 10, rotate display windows 11, one click screen rotation, hotkey screen rotate, автоповорот экрана windows, поворот монитора windows, ориентация экрана, переключение экрана, книжная ориентация windows, альбомная книжная, скрипт поворота экрана, вертикальный монитор, настройка дисплея windows, мульти монитор поворот, горячая клавиша поворот экрана, bat файл поворот монитора
