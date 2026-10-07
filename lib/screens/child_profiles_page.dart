import 'package:flutter/material.dart';

import '../data/sleep_data.dart';
import '../localization.dart';
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
        title: Text(appText(context, 'Crear perfil')),
        content: TextField(
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: appText(context, 'Nombre del niño o niña'),
          ),
          onChanged: (value) => enteredName = value,
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appText(context, 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, enteredName.trim()),
            child: Text(appText(context, 'Crear perfil')),
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

  Future<void> _deleteProfile() async {
    if (_profiles.isEmpty) return;

    final profile = await showDialog<ChildProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appText(context, 'Borrar perfil')),
        content: SizedBox(
          width: double.maxFinite,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: ListView(
              shrinkWrap: true,
              children: _profiles
                  .map(
                    (profile) => ListTile(
                      leading: const Icon(Icons.child_care),
                      title: Text(profile.name),
                      onTap: () => Navigator.pop(context, profile),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appText(context, 'Cancelar')),
          ),
        ],
      ),
    );
    if (!mounted || profile == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appText(context, 'Confirmar borrado')),
        content: Text(
          appText(context, '¿Estás segura de que quieres borrar el perfil "{name}"?', {
            'name': profile.name,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appText(context, 'Cancelar')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appText(context, 'Borrar perfil')),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final data = await SleepDataStore.loadAll();
    final profiles = data.profiles
        .where((savedProfile) => savedProfile.id != profile.id)
        .toList();
    final days = Map<String, List<SleepDay>>.from(data.days)
      ..remove(profile.id);
    await SleepDataStore.save(profiles, days);
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
      appBar: AppBar(
        title: Text(appText(context, 'Perfiles infantiles')),
        actions: [
          PopupMenuButton<AppLanguage>(
            tooltip: appText(context, 'Idioma'),
            initialValue: AppLanguageScope.of(context),
            onSelected: (language) =>
                AppLanguageScope.controllerOf(context).setLanguage(language),
            itemBuilder: (context) => AppLanguage.values
                .map(
                  (language) => PopupMenuItem(
                    value: language,
                    child: Row(
                      children: [
                        Text(language.flag),
                        const SizedBox(width: 10),
                        Text(language.name),
                        if (language == AppLanguageScope.of(context)) ...[
                          const Spacer(),
                          const Icon(Icons.check, size: 18),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(AppLanguageScope.of(context).flag),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
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
                          appText(
                            context,
                            'Crea un perfil para empezar el registro del sueño.',
                          ),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _createProfile,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: Text(appText(context, 'Crear perfil')),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _profiles.isEmpty ? null : _deleteProfile,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(appText(context, 'Borrar perfil')),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      appText(context, '¿De quién quieres consultar el registro?'),
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
                          subtitle: Text(
                            appText(context, 'Abrir registro y cuestionario'),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _openProfile(profile),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _createProfile,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: Text(appText(context, 'Crear otro perfil')),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _deleteProfile,
                      icon: const Icon(Icons.delete_outline),
                      label: Text(appText(context, 'Borrar perfil')),
                    ),
                  ],
                ),
    );
  }
}
