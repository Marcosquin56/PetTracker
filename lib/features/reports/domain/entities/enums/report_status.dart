/// Estado de un reporte a lo largo de su ciclo de vida.
enum ReportStatus {
  /// El dueño perdió a su mascota y la está buscando.
  lost('lost', 'Perdido'),

  /// Animal callejero avistado, sin dueño identificado (aún).
  stray('stray', 'Avistado en la calle'),

  /// El animal fue encontrado / está en custodia de alguien.
  found('found', 'Encontrado / En custodia');

  const ReportStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static ReportStatus fromApiValue(String value) {
    return ReportStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => throw ArgumentError('ReportStatus desconocido: $value'),
    );
  }
}
