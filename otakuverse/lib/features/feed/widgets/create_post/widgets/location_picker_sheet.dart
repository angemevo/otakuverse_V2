import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

/// Sheet de sélection de lieu avec champ de recherche.
/// Utilisée via [LocationPickerSheet.show].
class LocationPickerSheet {
  static Future<void> show(
    BuildContext context, {
    required String            currentValue,
    required List<String>      suggestions,
    required ValueChanged<String> onPicked,
    required VoidCallback      onClear,
  }) {
    return showModalBottomSheet(
      context:            context,
      backgroundColor:    AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _LocationPickerContent(
        currentValue: currentValue,
        suggestions:  suggestions,
        onPicked:     onPicked,
        onClear:      onClear,
      ),
    );
  }
}

class _LocationPickerContent extends StatefulWidget {
  final String           currentValue;
  final List<String>     suggestions;
  final ValueChanged<String> onPicked;
  final VoidCallback     onClear;

  const _LocationPickerContent({
    required this.currentValue,
    required this.suggestions,
    required this.onPicked,
    required this.onClear,
  });

  @override
  State<_LocationPickerContent> createState() =>
      _LocationPickerContentState();
}

class _LocationPickerContentState
    extends State<_LocationPickerContent> {
  late final TextEditingController _search;
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _search   = TextEditingController(text: widget.currentValue);
    _filtered = widget.suggestions;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? widget.suggestions
          : widget.suggestions
              .where((s) =>
                  s.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color:        AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _search,
                autofocus:  true,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary),
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText:  'Chercher un lieu...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textMuted),
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._filtered.map((loc) => ListTile(
                tileColor: AppColors.bgCard,
                leading: const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 20),
                title: Text(loc,
                    style: GoogleFonts.inter(
                        color:    AppColors.textPrimary,
                        fontSize: 14)),
                onTap: () {
                  widget.onPicked(loc);
                  Navigator.pop(context);
                },
              )),
          if (widget.currentValue.isNotEmpty)
            ListTile(
              tileColor: AppColors.bgCard,
              leading: const Icon(Icons.close,
                  color: AppColors.textMuted, size: 20),
              title: Text('Effacer la localisation',
                  style: GoogleFonts.inter(
                      color:    AppColors.textMuted,
                      fontSize: 14)),
              onTap: () {
                widget.onClear();
                Navigator.pop(context);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}