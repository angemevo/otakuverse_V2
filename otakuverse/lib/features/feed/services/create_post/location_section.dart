import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';

class LocationSection extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback          onLocationChanged;

  const LocationSection({
    super.key,
    required this.controller,
    required this.onLocationChanged,
  });

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  static const _suggestions = [
    'Cocody, Abidjan',
    'Abidjan',
    'Angré 9ème',
    'Plateau, Abidjan',
    'Yopougon',
  ];

  void _showLocationPicker() {
    showModalBottomSheet(
      context:         context,
      backgroundColor: AppColors.darkGray,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (ctx) => _LocationPickerSheet(
        controller:       widget.controller,
        suggestions:      _suggestions,
        onLocationPicked: (loc) {
          widget.controller.text = loc;
          widget.onLocationChanged();
          Navigator.pop(ctx);
        },
        onClear: () {
          widget.controller.clear();
          widget.onLocationChanged();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        widget.controller.text.trim().isNotEmpty;

    return Container(
      color: AppColors.deepBlack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─ Row lieu ────────────────────────────────────────
          ListTile(
            tileColor: AppColors.deepBlack,
            leading:   Icon(
              Icons.location_on_outlined,
              color: hasLocation
                  ? AppColors.crimsonRed
                  : AppColors.pureWhite,
              size: 22,
            ),
            title: Text(
              hasLocation
                  ? widget.controller.text
                  : 'Ajouter un lieu',
              style: GoogleFonts.inter(
                color: hasLocation
                    ? AppColors.pureWhite
                    : AppColors.pureWhite,
                fontSize:   15,
                fontWeight: hasLocation
                    ? FontWeight.w500
                    : FontWeight.w400,
              ),
            ),
            trailing: hasLocation
                ? GestureDetector(
                    onTap: () {
                      widget.controller.clear();
                      widget.onLocationChanged();
                    },
                    child: const Icon(Icons.close,
                        color: AppColors.mediumGray,
                        size:  20),
                  )
                : const Icon(Icons.chevron_right,
                    color: AppColors.mediumGray, size: 22),
            onTap: _showLocationPicker,
          ),

          // ─ Suggestions chips ─────────────────────────────
          Padding(
            padding: const EdgeInsets.only(
                left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _suggestions
                        .map((loc) => _LocationChip(
                              label: loc,
                              isSelected:
                                  widget.controller.text ==
                                  loc,
                              onTap: () {
                                widget.controller.text = loc;
                                widget.onLocationChanged();
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                        color:    AppColors.mediumGray,
                        fontSize: 11),
                    children: const [
                      TextSpan(
                          text:
                              'Les profils avec lesquels tu partages ce contenu '
                              'peuvent voir le lieu identifié. '),
                      TextSpan(
                        text: 'En savoir plus',
                        style: TextStyle(
                          decoration:      TextDecoration.underline,
                          decorationColor: AppColors.mediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOCATION PICKER SHEET ───────────────────────────────────────────
class _LocationPickerSheet extends StatefulWidget {
  final TextEditingController controller;
  final List<String>          suggestions;
  final ValueChanged<String>  onLocationPicked;
  final VoidCallback          onClear;

  const _LocationPickerSheet({
    required this.controller,
    required this.suggestions,
    required this.onLocationPicked,
    required this.onClear,
  });

  @override
  State<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState
    extends State<_LocationPickerSheet> {
  late final TextEditingController _search;
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _search   = TextEditingController(
        text: widget.controller.text);
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
              .where((s) => s.toLowerCase()
                  .contains(query.toLowerCase()))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ─ Champ de recherche ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color:        AppColors.deepBlack,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _search,
                autofocus:  true,
                style: GoogleFonts.inter(
                    color: AppColors.pureWhite),
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText:  'Chercher un lieu...',
                  hintStyle: GoogleFonts.inter(
                      color: AppColors.mediumGray),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.mediumGray,
                  ),
                  border:         InputBorder.none,
                  contentPadding: const EdgeInsets
                      .symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─ Liste suggestions ───────────────────────────
          ..._filtered.map((loc) => ListTile(
                tileColor: AppColors.darkGray,
                leading: const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.crimsonRed,
                    size:  20),
                title: Text(loc,
                    style: GoogleFonts.inter(
                        color:    AppColors.pureWhite,
                        fontSize: 14)),
                onTap: () =>
                    widget.onLocationPicked(loc),
              )),

          // ─ Effacer ─────────────────────────────────────
          if (widget.controller.text.isNotEmpty)
            ListTile(
              tileColor: AppColors.darkGray,
              leading: const Icon(Icons.close,
                  color: AppColors.mediumGray, size: 20),
              title: Text('Effacer la localisation',
                  style: GoogleFonts.inter(
                      color:    AppColors.mediumGray,
                      fontSize: 14)),
              onTap: widget.onClear,
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── LOCATION CHIP ───────────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  final String     label;
  final bool       isSelected;
  final VoidCallback onTap;

  const _LocationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.crimsonRed.withValues(alpha: 0.15)
            : AppColors.darkGray,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.crimsonRed
              : AppColors.mediumGray.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            color: isSelected
                ? AppColors.crimsonRed
                : AppColors.pureWhite,
            fontSize:   13,
            fontWeight: FontWeight.w500,
          )),
    ),
  );
}