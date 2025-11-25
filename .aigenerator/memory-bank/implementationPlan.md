# implementation Plan

**[2025-11-25 12:33:27]**
# PDFConverter_4 Implementation Plan

## Основные требования
- Создать приложение по аналогии с PDFScanner_1
- 5 экранов: Convert, Edit, Scan, Sign, Settings
- Кастомный таб бар с SVG иконками из Figma
- Цвета из Figma дизайна
- Логику во вью модели
- Использовать PDFConverterStorage (аналог PDFStorage)
- Кастомный тулбар везде

## Этапы реализации

### 1. Обновление цветовой схемы из Figma
- Добавить цвета в Assets.xcassets/Colors
- Обновить Color+Ext.swift с новыми цветами

### 2. Обновление таб бара
- Экспорт SVG иконок из Figma
- Добавление в Assets.xcassets/Icons
- Обновление MainFlow с новыми иконками

### 3. Доработка Convert экрана
- Улучшить CustomHorizontalPicker согласно дизайну
- Добавить DocumentPickerView
- Улучшить конвертацию и превью

### 4. Реализация Edit экрана
- Создать EditViewModel
- Добавить функционал выбора файлов
- Реализовать редактирование PDF/Image/Text

### 5. Интеграция сканнера из PDFScanner_1
- Скопировать Vision сканнер
- Адаптировать под новую архитектуру
- Интеграция с PDFConverterStorage

### 6. Реализация Sign экрана
- Создать SignViewModel
- Добавить функционал подписи документов
- Интеграция подписи в PDF

### 7. Реализация Settings экрана
- Share App, Rate App, Contact Us
- App Version, Privacy/Terms

### 8. Финальная доработка
- Тестирование всех функций
- Проверка дизайна соответствию Figma