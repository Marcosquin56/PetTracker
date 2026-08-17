/// Condición física/de salud observada en el animal.
///
/// Un reporte puede tener varias a la vez (p. ej. `injured` + `hasCollar`),
/// por eso [PetReportEntity] la modela como `List<HealthCondition>` en vez
/// de un único valor.
enum HealthCondition {
  healthy('healthy', 'En buen estado'),
  injured('injured', 'Herido'),
  hungry('hungry', 'Hambriento / desnutrido'),
  sick('sick', 'Enfermo'),
  hasCollar('has_collar', 'Con collar'),
  pregnant('pregnant', 'Preñada'),
  aggressive('aggressive', 'Agresivo / asustadizo'),
  other('other', 'Otro');

  const HealthCondition(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static HealthCondition fromApiValue(String value) {
    return HealthCondition.values.firstWhere(
      (condition) => condition.apiValue == value,
      orElse: () => throw ArgumentError('HealthCondition desconocida: $value'),
    );
  }
}
