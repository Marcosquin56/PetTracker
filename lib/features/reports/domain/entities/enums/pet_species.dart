/// Especie del animal reportado. PetTracker solo cubre gatos y perros.
enum PetSpecies {
  cat('cat', 'Gato'),
  dog('dog', 'Perro');

  const PetSpecies(this.apiValue, this.label);

  /// Valor estable enviado/recibido en el JSON de la API, independiente del
  /// nombre del enum en Dart.
  final String apiValue;
  final String label;

  static PetSpecies fromApiValue(String value) {
    return PetSpecies.values.firstWhere(
      (species) => species.apiValue == value,
      orElse: () => throw ArgumentError('PetSpecies desconocida: $value'),
    );
  }
}
