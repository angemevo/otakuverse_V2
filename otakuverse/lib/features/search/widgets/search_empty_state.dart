import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

/// Affiché quand la recherche ne retourne aucun résultat.
class SearchEmptyState extends StatelessWidget {
  final String query;

  const SearchEmptyState({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(HeroiconsOutline.userGroup,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            'Aucun résultat',
            style: GoogleFonts.poppins(
              color:      AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize:   16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aucun utilisateur trouvé pour "$query"',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// En-tête de la section suggestions (titre "Suggestions").
class SearchSuggestionsHeader extends StatelessWidget {
  const SearchSuggestionsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Suggestions',
        style: GoogleFonts.poppins(
          color:      AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize:   16,
        ),
      ),
    );
  }
}
