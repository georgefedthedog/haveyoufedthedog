import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/chores/chore_actions.dart';
import '../../core/subjects/character.dart';
import '../../core/subjects/character_artwork.dart';
import '../../core/subjects/characters.dart';
import '../../core/subjects/subject_actions.dart';
import '../../router/routes.dart';
import '../../widgets/build_label.dart';
import '../subjects/character_picker.dart';
import 'onboarding_preset.dart';

/// First-time onboarding — a two-step PageView that lets a user pick a
/// character + name and an opening chore preset in one go, instead of
/// dropping them into the bare edit-subject + edit-chore screens.
///
/// On finish: creates the subject, then the chore, then pops back to home.
/// On skip: pops back to home; the user will see the EmptyState with its
/// "Add a subject" CTA.
class OnboardingWelcomeScreen extends ConsumerStatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  ConsumerState<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState
    extends ConsumerState<OnboardingWelcomeScreen> {
  final _pageCtrl = PageController();
  final _nameCtrl = TextEditingController();
  Character _character = CharacterRegistry.dog;
  OnboardingPreset? _preset;
  int _step = 0;
  bool _busy = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      if (_nameCtrl.text.trim().isEmpty) return;
      setState(() => _step = 1);
      _pageCtrl.animateToPage(
        1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step == 1) {
      setState(() => _step = 0);
      _pageCtrl.animateToPage(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _finish() async {
    if (_preset == null) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      final name = _nameCtrl.text.trim();
      final subject = await ref
          .read(subjectActionsProvider)
          .createSubject(name: name, icon: _character.id);
      await ref.read(choreActionsProvider).createChore(
            subjectId: subject.id,
            name: '${_preset!.choreName} $name',
            scheduleType: _preset!.scheduleType,
            hour: _preset!.hour,
            minute: _preset!.minute,
            weekdayMask: _preset!.weekdayMask,
          );
      router.go(Routes.home);
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        showCloseIcon: true,
        content: Text('Could not finish setup: $e'),
      ));
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(_step == 0 ? Icons.close : Icons.arrow_back),
          onPressed: _busy ? null : _back,
          tooltip: _step == 0 ? 'Skip' : 'Back',
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => context.go(Routes.home),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LinearProgressIndicator(
                value: _step == 0 ? 0.5 : 1.0,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1(
                    character: _character,
                    nameCtrl: _nameCtrl,
                    onCharacter: (c) => setState(() => _character = c),
                    onChanged: () => setState(() {}),
                  ),
                  _Step2(
                    character: _character,
                    selected: _preset,
                    onSelect: (p) => setState(() => _preset = p),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: theme.textTheme.titleMedium,
                ),
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(_step == 0 ? Icons.arrow_forward : Icons.check),
                label: Text(_step == 0 ? 'Next' : "Let's go!"),
                onPressed: _busy ||
                        (_step == 0
                            ? _nameCtrl.text.trim().isEmpty
                            : _preset == null)
                    ? null
                    : _next,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const SafeArea(child: BuildLabel()),
    );
  }
}

class _Step1 extends StatelessWidget {
  final Character character;
  final TextEditingController nameCtrl;
  final ValueChanged<Character> onCharacter;
  final VoidCallback onChanged;

  const _Step1({
    required this.character,
    required this.nameCtrl,
    required this.onCharacter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'What are we tracking?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a character and give them a name.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: ClipOval(
                child: CharacterArtwork(
                  character: character,
                  stage: true,
                  iconSize: 72,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Kiko, Plant, Wheelie',
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 24),
          Text('Character', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          CharacterPicker(
            selected: character.id,
            onChanged: (id) => onCharacter(CharacterRegistry.lookup(id)),
          ),
        ],
      ),
    );
  }
}

class _Step2 extends StatelessWidget {
  final Character character;
  final OnboardingPreset? selected;
  final ValueChanged<OnboardingPreset> onSelect;

  const _Step2({
    required this.character,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'When does it need doing?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "We'll set up a first chore for you — you can tweak it later.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 96,
              height: 96,
              child: ClipOval(
                child: CharacterArtwork(
                  character: character,
                  stage: true,
                  iconSize: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...OnboardingPreset.all.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PresetTile(
                preset: p,
                isSelected: selected == p,
                onTap: () => onSelect(p),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  final OnboardingPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  preset.label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
