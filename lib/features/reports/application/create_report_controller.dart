import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/geo_location.dart';
import '../domain/entities/create_report_input.dart';
import '../domain/entities/enums/health_condition.dart';
import '../domain/entities/enums/pet_species.dart';
import '../domain/entities/enums/report_status.dart';
import '../domain/entities/pet_report_entity.dart';
import 'reports_providers.dart';

class CreateReportFormState {
  const CreateReportFormState({
    this.species = PetSpecies.dog,
    this.status = ReportStatus.stray,
    this.healthConditions = const {},
    this.photos = const [],
    this.location,
    this.petName,
    this.breed,
    this.color,
    this.description,
    this.contactPhone,
    this.isResolvingLocation = true,
    this.isSubmitting = false,
  });

  final PetSpecies species;
  final ReportStatus status;
  final Set<HealthCondition> healthConditions;
  final List<XFile> photos;
  final GeoLocation? location;
  final String? petName;
  final String? breed;
  final String? color;
  final String? description;
  final String? contactPhone;
  final bool isResolvingLocation;
  final bool isSubmitting;

  bool get canSubmit => location != null && !isSubmitting;

  CreateReportFormState copyWith({
    PetSpecies? species,
    ReportStatus? status,
    Set<HealthCondition>? healthConditions,
    List<XFile>? photos,
    GeoLocation? location,
    String? petName,
    String? breed,
    String? color,
    String? description,
    String? contactPhone,
    bool? isResolvingLocation,
    bool? isSubmitting,
  }) {
    return CreateReportFormState(
      species: species ?? this.species,
      status: status ?? this.status,
      healthConditions: healthConditions ?? this.healthConditions,
      photos: photos ?? this.photos,
      location: location ?? this.location,
      petName: petName ?? this.petName,
      breed: breed ?? this.breed,
      color: color ?? this.color,
      description: description ?? this.description,
      contactPhone: contactPhone ?? this.contactPhone,
      isResolvingLocation: isResolvingLocation ?? this.isResolvingLocation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final createReportControllerProvider =
    AutoDisposeNotifierProvider<CreateReportController, CreateReportFormState>(
  CreateReportController.new,
);

class CreateReportController extends AutoDisposeNotifier<CreateReportFormState> {
  final _imagePicker = ImagePicker();

  @override
  CreateReportFormState build() {
    _resolveLocation();
    return const CreateReportFormState();
  }

  Future<void> _resolveLocation() async {
    final location = await ref.read(locationServiceProvider).getCurrentLocation();
    state = state.copyWith(location: location, isResolvingLocation: false);
  }

  void setSpecies(PetSpecies species) => state = state.copyWith(species: species);

  void setStatus(ReportStatus status) => state = state.copyWith(status: status);

  void toggleHealthCondition(HealthCondition condition) {
    final updated = Set<HealthCondition>.from(state.healthConditions);
    if (!updated.remove(condition)) updated.add(condition);
    state = state.copyWith(healthConditions: updated);
  }

  void setPetName(String value) => state = state.copyWith(petName: value);

  void setBreed(String value) => state = state.copyWith(breed: value);

  void setColor(String value) => state = state.copyWith(color: value);

  void setDescription(String value) => state = state.copyWith(description: value);

  void setContactPhone(String value) => state = state.copyWith(contactPhone: value);

  void setAddress(String address) {
    final current = state.location;
    if (current == null) return;
    state = state.copyWith(location: current.copyWith(address: address));
  }

  Future<void> addPhotoFromCamera() => _addPhoto(ImageSource.camera);

  Future<void> addPhotoFromGallery() => _addPhoto(ImageSource.gallery);

  Future<void> _addPhoto(ImageSource source) async {
    final photo = await _imagePicker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (photo == null) return;
    state = state.copyWith(photos: [...state.photos, photo]);
  }

  void removePhoto(XFile photo) {
    state = state.copyWith(photos: state.photos.where((p) => p.path != photo.path).toList());
  }

  /// `null` si no hay ubicación resuelta todavía. Sube las fotos después de
  /// crear el reporte porque el backend necesita el `id` del reporte primero.
  Future<PetReportEntity?> submit() async {
    final location = state.location;
    if (location == null) return null;

    state = state.copyWith(isSubmitting: true);
    try {
      final repository = ref.read(reportRepositoryProvider);
      var report = await repository.create(
        CreateReportInput(
          species: state.species,
          status: state.status,
          location: location,
          healthConditions: state.healthConditions.toList(),
          petName: state.petName,
          breed: state.breed,
          color: state.color,
          description: state.description,
          contactPhone: state.contactPhone,
        ),
      );

      for (final photo in state.photos) {
        report = await repository.addPhoto(report.id, photo);
      }

      return report;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
