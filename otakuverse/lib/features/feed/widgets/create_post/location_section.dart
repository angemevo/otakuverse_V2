import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'widgets/location_picker_sheet.dart';

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

  void _openPicker() {
    LocationPickerSheet.show(
      context,
      currentValue: widget.controller.text,
      suggestions:  _suggestions,
      onPicked: (loc) {
        widget.controller.text = loc;
        widget.onLocationChanged();
      },
      onClear: () {
        widget.controller.clear();
        widget.onLocationChanged();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.controller.text.trim().isNotEmpty;

    return Container(
      color: AppColors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            tileColor: AppColors.bgPrimary,
            leading: Icon(
              Icons.location_on_outlined,
              color: hasLocation
                  ? AppColors.primary
                  : AppColors.textPrimary,
              size: 22,
            ),
            title: Text(
              hasLocation
                  ? widget.controller.text
                  : 'Ajouter un lieu',
              style: GoogleFonts.inter(
                color:      AppColors.textPrimary,
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
                        color: AppColors.textMuted, size: 20),
                  )
                : const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 22),
            onTap: _openPicker,
          ),
          Padding(
            padding: const EdgeInsets.only(
                left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _suggestions
                        .map((loc) => _LocationChip(
                              label:      loc,
                              isSelected: widget.controller.text == loc,
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
                        color:    AppColors.textMuted,
                        fontSize: 11),
                    children: const [
                      TextSpan(
                        text: 'Les profils avec lesquels tu partages ce '
                            'contenu peuvent voir le lieu identifié. ',
                      ),
                      TextSpan(
                        text: 'En savoir plus',
                        style: TextStyle(
                          decoration:      TextDecoration.underline,
                          decorationColor: AppColors.textMuted,
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

// ─── Chip lieu ────────────────────────────────────────────────────────

class _LocationChip extends StatelessWidget {
  final String       label;
  final bool         isSelected;
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
      margin:   const EdgeInsets.only(right: 8),
      padding:  const EdgeInsets.symmetric(
          horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.textMuted.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
            color: isSelected
                ? AppColors.primary
                : AppColors.textPrimary,
            fontSize:   13,
            fontWeight: FontWeight.w500,
          )),
    ),
  );
}