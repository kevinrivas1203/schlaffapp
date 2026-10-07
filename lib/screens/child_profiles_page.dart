import 'package:flutter/material.dart';

import '../data/sleep_data.dart';
import 'home_page.dart';

class ChildProfilesPage extends StatefulWidget {
  const ChildProfilesPage({super.key});

  @override
  State<ChildProfilesPage> createState() => _ChildProfilesPageState();
}

class _ChildProfilesPageState extends State<ChildProfilesPage> {
  List<ChildProfile> _profiles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final data = await SleepDataStore.loadAll();
    if (!mounted) return;
    setState(() {
      _profiles = data.profiles;
      _loading = false;
    });
  }

  Future<void> _createProfile() async {
    var enteredName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear perfil'),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre del niño o niña',
          ),
          onChanged: (value) => enteredName = value,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, enteredName.trim()),
            child: const Text('Crear perfil'),
          ),
        ],
      ),
    );
    if (!mounted || name == null || name.trim().isEmpty) return;

    final profile = ChildProfile(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
    );
    final profiles = [..._profiles, profile];
    final data = await SleepDataStore.loadAll();
    await SleepDataStore.save(profiles, data.days);
    if (!mounted) return;
    setState(() => _profiles = profiles);
  }

  Future<void> _openProfile(ChildProfile profile) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ChildProfilePage(profile: profile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfiles infantiles')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.child_care, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'Crea un perfil para empezar el registro del sueño.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _createProfile,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Crear perfil'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      '¿De quién quieres consultar el registro?',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._profiles.map(
                      (profile) => Card(
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.child_care),
                          ),
                          title: Text(profile.name),
                          subtitle: const Text('Abrir registro y cuestionario'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openProfile(profile),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _createProfile,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Crear otro perfil'),
                    ),
                  ],
                ),
    );
  }
}
