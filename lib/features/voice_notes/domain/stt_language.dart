/// لغة مستقلة عن المزوّد. كل datasource بيترجمها لكود المزوّد.
enum SttLanguage {
  arabic('عربي (سوري)'),
  english('English'),
  auto('تلقائي (عربي + إنجليزي)');

  const SttLanguage(this.label);
  final String label;
}
