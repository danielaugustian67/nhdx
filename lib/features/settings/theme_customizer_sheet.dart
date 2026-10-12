import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_palette.dart';
import 'settings_providers.dart';

/// Modal bottom sheet allowing users to customize theme palette,
/// custom accent color, and pure black (AMOLED) mode.
class ThemeCustomizerSheet extends ConsumerStatefulWidget {
  const ThemeCustomizerSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const ThemeCustomizerSheet(),
      );

  @override
  ConsumerState<ThemeCustomizerSheet> createState() => _ThemeCustomizerSheetState();
}

class _ThemeCustomizerSheetState extends ConsumerState<ThemeCustomizerSheet> {
  final _hexController = TextEditingController();

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _selectPalette(ThemePalette palette) {
    saveSetting(ref, ThemePalette.settingKey, palette.id);
  }

  void _selectCustomColor(Color color) {
    saveSetting(ref, ThemePalette.settingKey, ThemePalette.custom.id);
    saveSetting(ref, ThemePalette.customColorKey, '${color.toARGB32()}');
  }

  void _togglePureBlack(bool enabled) {
    saveSetting(ref, ThemePalette.pureBlackKey, enabled ? 'true' : 'false');
  }

  void _showHexDialog(int? currentColor) {
    _hexController.text = currentColor != null
        ? Color(currentColor).toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()
        : 'E11D48';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Input Kode Warna Hex'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan kode warna 6 karakter (RRGGBB):',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpace.m),
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                prefixText: '# ',
                hintText: 'Misal: 3B82F6',
              ),
              maxLength: 6,
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final raw = _hexController.text.trim().replaceAll('#', '');
              final val = int.tryParse('FF$raw', radix: 16);
              if (val != null) {
                _selectCustomColor(Color(val));
                Navigator.of(dialogCtx).pop();
              }
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final look = ref.watch(appearanceProvider).value ?? defaultAppearance;
    final isCustom = look.palette == ThemePalette.custom;
    final activeCustomColor = look.customColor != null ? Color(look.customColor!) : const Color(0xFFC2406F);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.s, AppSpace.screen, AppSpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpace.m),
                  decoration: BoxDecoration(
                    color: c.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Text(
                'Warna & Nuansa Tema',
                style: AppText.title1.copyWith(color: c.ink),
              ),
              const SizedBox(height: 2),
              Text(
                'Sesuaikan palet warna aplikasi sesuai dengan seleramu.',
                style: AppText.bodySmall.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AppSpace.l),

              // Live Preview Card
              _LivePreviewCard(look: look, colors: c),
              const SizedBox(height: AppSpace.xl),

              // Section: Presets
              Text(
                'Tema Pilihan',
                style: AppText.title2.copyWith(color: c.ink, fontSize: 16),
              ),
              const SizedBox(height: AppSpace.m),

              // Preset options
              for (final p in ThemePalette.values)
                _PaletteTile(
                  palette: p,
                  isSelected: look.palette == p,
                  customColor: isCustom ? activeCustomColor : null,
                  onTap: () => _selectPalette(p),
                ),

              // Custom Color Section (if custom palette chosen)
              if (isCustom) ...[
                const SizedBox(height: AppSpace.l),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pilih Warna Aksen',
                      style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                    ),
                    TextButton.icon(
                      onPressed: () => _showHexDialog(look.customColor),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Input Hex'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final color in CustomThemeSwatches.list)
                      GestureDetector(
                        onTap: () => _selectCustomColor(color),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: look.customColor == color.toARGB32()
                                  ? c.ink
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: look.customColor == color.toARGB32()
                              ? const Icon(Icons.check, color: Colors.white, size: 22)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpace.xl),
              const Divider(),
              const SizedBox(height: AppSpace.s),

              // Pure Black switch
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Latar Hitam Pekat (AMOLED)',
                  style: AppText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Menggunakan warna hitam murni (#000000) pada mode gelap untuk hemat baterai dan kontras tinggi.',
                  style: AppText.bodySmall.copyWith(color: c.inkMuted),
                ),
                value: look.pureBlack,
                onChanged: _togglePureBlack,
              ),

              const SizedBox(height: AppSpace.m),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.isSelected,
    required this.customColor,
    required this.onTap,
  });

  final ThemePalette palette;
  final bool isSelected;
  final Color? customColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final displayColor = customColor ?? palette.seedColor ?? c.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.s),
      child: Material(
        color: isSelected ? c.surfaceHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.m, vertical: AppSpace.m),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(
                color: isSelected ? c.primaryText : c.line,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Color swatch circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: displayColor.withValues(alpha: 0.35),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: AppSpace.m),
                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        palette.name,
                        style: AppText.body.copyWith(
                          color: c.ink,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      Text(
                        palette.description,
                        style: AppText.bodySmall.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.radio_button_checked, color: c.primaryText, size: 20)
                else
                  Icon(Icons.radio_button_off, color: c.inkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({required this.look, required this.colors});

  final Appearance look;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.l),
      decoration: BoxDecoration(
        color: colors.surfaceHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PREVIEW TAMPILAN',
                style: AppText.label.copyWith(
                  color: colors.primaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.s, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.jlptBg(3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'JLPT N3',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colors.jlptFg(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.m),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '桜',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.ink,
                ),
              ),
              const SizedBox(width: AppSpace.s),
              Text(
                'さくら · sakura',
                style: AppText.body.copyWith(color: colors.primaryText),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Bunga sakura khas Jepang yang mekar di musim semi.',
            style: AppText.bodySmall.copyWith(color: colors.inkMuted),
          ),
          const SizedBox(height: AppSpace.l),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                  ),
                  child: const Text('Tombol Utama'),
                ),
              ),
              const SizedBox(width: AppSpace.s),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.primaryText,
                  side: BorderSide(color: colors.primaryText),
                ),
                child: const Text('Detail'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
