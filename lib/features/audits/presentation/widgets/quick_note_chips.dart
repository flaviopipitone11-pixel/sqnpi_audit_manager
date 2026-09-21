import 'package:flutter/material.dart';
import '../../application/checklist_note_presets.dart';

/// Selettore compatto e moderno per formule standard SQNPI.
/// Mostra un pulsante leggero che apre un Dialog centrato su PC/Tablet
/// o un BottomSheet elegante su Smartphone.
class QuickNoteChips extends StatelessWidget {
  final List<String> presets;
  final TextEditingController controller;
  final VoidCallback? onApplied;
  final String label;

  const QuickNoteChips({
    super.key,
    required this.presets,
    required this.controller,
    this.onApplied,
    this.label = 'Formule standard',
  });

  void _openPresetsModal(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 640;

    final content = _PresetsModalContent(
      title: label,
      presets: presets,
      controller: controller,
      onApplied: onApplied,
    );

    if (isDesktopOrTablet) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 32,
          ),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 680),
            child: content,
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: content,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _openPresetsModal(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.format_list_bulleted_rounded,
              size: 15,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                '$label (${presets.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetsModalContent extends StatefulWidget {
  final String title;
  final List<String> presets;
  final TextEditingController controller;
  final VoidCallback? onApplied;

  const _PresetsModalContent({
    required this.title,
    required this.presets,
    required this.controller,
    this.onApplied,
  });

  @override
  State<_PresetsModalContent> createState() => _PresetsModalContentState();
}

class _PresetsModalContentState extends State<_PresetsModalContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = '';
  String _selectedCategory = 'Tutte';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  NotePresetItem? _findPresetItem(String text) {
    for (final item in ChecklistNotePresets.koRilievoItems) {
      if (item.text == text) return item;
    }
    for (final item in ChecklistNotePresets.koAzioneItems) {
      if (item.text == text) return item;
    }
    for (final item in ChecklistNotePresets.naItems) {
      if (item.text == text) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mappatura elementi con metadati
    final itemsWithMeta = widget.presets.map((text) {
      final found = _findPresetItem(text);
      return found ??
          NotePresetItem(
            text: text,
            category: 'Generale',
            icon: Icons.checklist_rtl_rounded,
          );
    }).toList();

    // Raccoglie categorie uniche
    final categories = <String>{'Tutte'};
    for (final it in itemsWithMeta) {
      categories.add(it.category);
    }

    // Filtra per ricerca e per categoria
    final filtered = itemsWithMeta.where((item) {
      final matchesSearch =
          _filter.isEmpty ||
          item.text.toLowerCase().contains(_filter.toLowerCase()) ||
          item.category.toLowerCase().contains(_filter.toLowerCase());
      final matchesCategory =
          _selectedCategory == 'Tutte' || item.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con Icona, Titolo, Badge e Tasto Chiudi
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.presets.length} opzioni',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tocca una formula per inserirla direttamente nel verbale.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Chiudi',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Barra di ricerca rapida
            TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _filter = val),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _filter = '');
                        },
                      )
                    : null,
                hintText:
                    'Cerca per parola chiave (es. irroratrice, trattamenti, fatture)...',
                hintStyle: const TextStyle(fontSize: 12.5),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Filtro Categorie (se presenti più categorie)
            if (categories.length > 2) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                          }
                        },
                        visualDensity: VisualDensity.compact,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Lista Formule
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 36,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nessuna formula corrispondente ai filtri.',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final currentText = widget.controller.text
                            .trim()
                            .toLowerCase();
                        final isAlreadyPresent = currentText.contains(
                          item.text.toLowerCase(),
                        );

                        return Material(
                          color: isAlreadyPresent
                              ? Colors.green.shade50.withValues(alpha: 0.7)
                              : theme.colorScheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isAlreadyPresent
                                  ? Colors.green.shade300
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.6,
                                    ),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              ChecklistNotePresets.applyPreset(
                                widget.controller,
                                item.text,
                              );
                              widget.onApplied?.call();
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('Formula inserita nel campo!'),
                                    ],
                                  ),
                                  duration: const Duration(milliseconds: 1400),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icona tematica
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isAlreadyPresent
                                          ? Colors.green.shade100
                                          : theme.colorScheme.primaryContainer
                                                .withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isAlreadyPresent
                                          ? Icons.check_rounded
                                          : item.icon,
                                      size: 16,
                                      color: isAlreadyPresent
                                          ? Colors.green.shade800
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Testo + Tag Categoria
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 1.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isAlreadyPresent
                                                ? Colors.green.shade100
                                                      .withValues(alpha: 0.6)
                                                : theme
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            item.category.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.3,
                                              color: isAlreadyPresent
                                                  ? Colors.green.shade900
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.text,
                                          style: TextStyle(
                                            fontSize: 13,
                                            height: 1.3,
                                            fontWeight: isAlreadyPresent
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Badge / Tasto Inserisci
                                  if (isAlreadyPresent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Inserita',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade800,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.colorScheme.primary
                                              .withValues(alpha: 0.25),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.add_rounded,
                                            size: 13,
                                            color: theme.colorScheme.primary,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            'Inserisci',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
