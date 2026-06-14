/// Назначение: единый справочник поддерживаемых стран (код → название).
///
/// Слой: core/constants
/// Зависимости: нет.
/// Ключевые типы: kSupportedCountries.
library;

/// Поддерживаемые страны (код → название). v1: СНГ.
const Map<String, String> kSupportedCountries = {
  'BY': 'Беларусь',
  'RU': 'Россия',
  'KZ': 'Казахстан',
};

/// Человекочитаемое название страны по коду (или сам код, если не найдено).
String countryName(String? code) =>
    code == null ? '—' : (kSupportedCountries[code] ?? code);
