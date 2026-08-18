import 'package:flutter/material.dart';

import '../../../adoption_centers/presentation/widgets/adoption_centers_list_view.dart';
import '../../../vets/presentation/widgets/vets_list_view.dart';

enum _AliadoCategory { todos, veterinarias, adopcion }

/// Pestaña "Aliados": unifica veterinarias cercanas (Google Places) y casas
/// de adopción (lista propia) bajo un solo lugar con chips de categoría, en
/// vez de dos pantallas sueltas — ver VetsListView/AdoptionCentersListView,
/// que ya no tienen Scaffold propio para poder combinarse acá.
class AliadosScreen extends StatefulWidget {
  const AliadosScreen({super.key});

  @override
  State<AliadosScreen> createState() => _AliadosScreenState();
}

class _AliadosScreenState extends State<AliadosScreen> {
  _AliadoCategory _category = _AliadoCategory.todos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aliados')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _category == _AliadoCategory.todos,
                    onSelected: (_) => setState(() => _category = _AliadoCategory.todos),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.local_hospital_outlined, size: 16),
                    label: const Text('Veterinarias'),
                    selected: _category == _AliadoCategory.veterinarias,
                    onSelected: (_) => setState(() => _category = _AliadoCategory.veterinarias),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    avatar: const Icon(Icons.volunteer_activism_outlined, size: 16),
                    label: const Text('Adopción'),
                    selected: _category == _AliadoCategory.adopcion,
                    onSelected: (_) => setState(() => _category = _AliadoCategory.adopcion),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_category) {
      case _AliadoCategory.veterinarias:
        return const VetsListView();
      case _AliadoCategory.adopcion:
        return const AdoptionCentersListView();
      case _AliadoCategory.todos:
        return const CustomScrollView(
          slivers: [
            _SectionHeader('Veterinarias cercanas'),
            SliverToBoxAdapter(child: SizedBox(height: 320, child: VetsListView())),
            _SectionHeader('Casas de adopción'),
            SliverToBoxAdapter(child: SizedBox(height: 420, child: AdoptionCentersListView())),
            SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
