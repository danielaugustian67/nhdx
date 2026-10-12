import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_palette.dart';
import '../../l10n/app_localizations.dart';
import 'settings_providers.dart';

/// Name of [p] as shown to the user.
String paletteName(AppLocalizations l10n, ThemePalette p) => p == ThemePalette.custom ? l10n.paletteCustom : p.name;

String _paletteNote(AppLocalizations l10n, ThemePalette p) => switch (p) {
  ThemePalette.sakura => l10n.paletteSakuraNote,
  ThemePalette.matcha => l10n.paletteMatchaNote,
  ThemePalette.aoi => l10n.paletteAoiNote,
  ThemePalette.mikan => l10n.paletteMikanNote,
  ThemePalette.murasaki => l10n.paletteMurasakiNote,
  ThemePalette.kuro => l10n.paletteKuroNote,
  ThemePalette.custom => l10n.paletteCustomNote,
};

/// Accent used by the custom palette before one is picked.
const _defaultCustom = Color(0xFFC2406F);

String _hex(Color color) => color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

/// The whole look in one sheet: dark/light, palette (or a custom accent) and
/// pure black. Every change is saved at once and the app recolours behind it.
class ThemeSheet extends ConsumerWidget {
  const ThemeSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    // Above the tab bar, not inside the tab.
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const ThemeSheet(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final look = ref.watch(appearanceProvider).value ?? defaultAppearance;
    final custom = look.customColor == null ? _defaultCustom : Color(look.customColor!);
    final dark = Theme.of(context).brightness == Brightness.dark;

    void selectCustom(Color color) {
      saveSetting(ref, ThemePalette.customColorKey, '${color.toARGB32()}');
      saveSetting(ref, ThemePalette.settingKey, ThemePalette.custom.id);
    }

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: AppSpace.l, bottom: AppSpace.s),
      child: Semantics(
        header: true,
        child: Text(title, style: AppText.label.copyWith(color: c.inkMuted)),
      ),
    );

    String modeName(ThemeChoice t) => switch (t) {
      ThemeChoice.dark => l10n.themeDark,
      ThemeChoice.light => l10n.themeLight,
      ThemeChoice.system => l10n.followSystem,
    };

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.theme, style: AppText.title2.copyWith(color: c.ink)),
            const SizedBox(height: AppSpace.xs),
            Text(l10n.themeNote, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
            const SizedBox(height: AppSpace.m),
            const _Preview(),
            section(l10n.themeMode),
            SegmentedButton<ThemeChoice>(
              showSelectedIcon: false,
              segments: [for (final t in ThemeChoice.values) ButtonSegment(value: t, label: Text(modeName(t)))],
              selected: {look.theme},
              onSelectionChanged: (s) => saveSetting(ref, ThemeChoice.settingKey, s.single.name),
            ),
            section(l10n.themeColor),
            for (final p in ThemePalette.values)
              _PaletteTile(
                name: paletteName(l10n, p),
                note: _paletteNote(l10n, p),
                color: p.seedColor ?? custom,
                selected: look.palette == p,
                onTap: () =>
                    p == ThemePalette.custom ? selectCustom(custom) : saveSetting(ref, ThemePalette.settingKey, p.id),
              ),
            if (look.palette == ThemePalette.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(l10n.themeAccent, style: AppText.body.copyWith(color: c.ink)),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final color = await _HexDialog.show(context, custom);
                      if (color != null) selectCustom(color);
                    },
                    icon: const Icon(Icons.tag_rounded, size: 18),
                    label: Text('${l10n.themeHex} · ${_hex(custom)}'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s),
              Wrap(
                spacing: AppSpace.s,
                runSpacing: AppSpace.s,
                children: [
                  for (final color in CustomThemeSwatches.list)
                    _Swatch(
                      color: color,
                      selected: color.toARGB32() == custom.toARGB32(),
                      onTap: () => selectCustom(color),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.m),
            Divider(color: c.line, height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.themePureBlack, style: AppText.body.copyWith(color: c.ink)),
              subtitle: Text(
                dark ? l10n.themePureBlackNote : '${l10n.themePureBlackNote} ${l10n.themePureBlackLight}',
                style: AppText.bodySmall.copyWith(color: c.inkMuted),
              ),
              value: look.pureBlack,
              onChanged: (on) => saveSetting(ref, ThemePalette.pureBlackKey, on ? 'true' : 'false'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A word card and the two button styles in the current colours.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(AppSpace.m),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.themePreview, style: AppText.label.copyWith(color: c.inkMuted)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.s, vertical: 2),
                  decoration: BoxDecoration(color: c.jlptBg(5), borderRadius: BorderRadius.circular(4)),
                  child: Text('N5', style: AppText.label.copyWith(color: c.jlptFg(5))),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.s),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '桜',
                  locale: const Locale('ja'),
                  style: AppText.displayCard.copyWith(fontSize: 32, color: c.ink),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: Text('さくら · ${l10n.themePreviewMeaning}', style: AppText.body.copyWith(color: c.primaryText)),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.m),
            // Buttons fill their share: the app's buttons are as wide as they
            // can be, so they need a bounded width.
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: () {}, child: Text(l10n.themePreviewMain)),
                ),
                const SizedBox(width: AppSpace.s),
                Expanded(
                  child: OutlinedButton(onPressed: () {}, child: Text(l10n.themePreviewOther)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.name,
    required this.note,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String note;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      side: BorderSide(color: selected ? c.primaryText : c.line, width: selected ? 1.5 : 1),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s),
      child: Material(
        color: selected ? c.surfaceHigh : Colors.transparent,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.m),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color,
                    child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                  ),
                  const SizedBox(width: AppSpace.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppText.body.copyWith(
                            color: c.ink,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        Text(note, style: AppText.bodySmall.copyWith(color: c.inkMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.selected, required this.onTap});
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '#${_hex(color)}',
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? context.colors.ink : Colors.transparent, width: 3),
        ),
        child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 22) : null,
      ),
    ),
  );
}

/// Asks for an RRGGBB code; returns the colour, or null when cancelled.
class _HexDialog extends StatefulWidget {
  const _HexDialog({required this.initial});
  final Color initial;

  static Future<Color?> show(BuildContext context, Color initial) => showDialog<Color>(
    context: context,
    builder: (_) => _HexDialog(initial: initial),
  );

  @override
  State<_HexDialog> createState() => _HexDialogState();
}

class _HexDialogState extends State<_HexDialog> {
  late final _controller = TextEditingController(text: _hex(widget.initial));
  static final _valid = RegExp(r'^[0-9a-fA-F]{6}$');
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final raw = _controller.text.trim().replaceAll('#', '');
    if (!_valid.hasMatch(raw)) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(Color(int.parse('FF$raw', radix: 16)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.themeHex),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[0-9a-fA-F]'))],
        decoration: InputDecoration(
          prefixText: '# ',
          helperText: l10n.themeHexHint,
          errorText: _showError ? l10n.themeHexInvalid : null,
        ),
        onChanged: (_) {
          if (_showError) setState(() => _showError = false);
        },
        onSubmitted: (_) => _apply(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(onPressed: _apply, child: Text(l10n.themeApply)),
      ],
    );
  }
}
