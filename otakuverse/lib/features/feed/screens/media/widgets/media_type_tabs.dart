import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Onglets de type de contenu en bas du MediaPickerScreen.
/// Gère la navigation vers CreateStoryScreen / CreateShortScreen.
class MediaTypeTabs extends StatelessWidget {
  final String   currentType;
  final void Function(String type) onTypeChanged;

  const MediaTypeTabs({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  static const _tabs = [
    ('post',  'PUBLIER'),
    ('story', 'STORY'),
    ('short', 'SHORT'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _tabs.map((t) => _buildTab(t.$1, t.$2)).toList(),
      ),
    );
  }

  Widget _buildTab(String type, String label) {
    final selected = currentType == type;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTypeChanged(type);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: selected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              fontWeight:      selected ? FontWeight.w700 : FontWeight.w500,
              fontSize:        14,
              letterSpacing:   0.5,
              decoration:      TextDecoration.none,
              decorationColor: Colors.transparent,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width:  selected ? 24 : 0,
            height: 2,
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}
