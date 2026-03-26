import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/services/music_service.dart';
import 'package:otakuverse/features/feed/widgets/create_post/spotify_picker_sheet.dart';

class MusicSection extends StatelessWidget {
  final SpotifyTrack?               selectedTrack;
  final ValueChanged<SpotifyTrack?> onTrackSelected;

  const MusicSection({
    super.key,
    required this.selectedTrack,
    required this.onTrackSelected,
  });

  Future<void> _openPicker(BuildContext context) async {
    await showModalBottomSheet(
      context:            context,
      backgroundColor:    AppColors.darkGray,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => SpotifyPickerSheet(
        selectedTrack:   selectedTrack,
        onTrackSelected: (track) {
          onTrackSelected(track);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.deepBlack,
      child: ListTile(
        tileColor: AppColors.deepBlack,

        // ─ Pochette ou icône ──────────────────────────
        leading: selectedTrack?.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: selectedTrack!.imageUrl!,
                  width:    40, height: 40,
                  fit:      BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 40, height: 40,
                    color: AppColors.darkGray,
                  ),
                ),
              )
            : Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color:        AppColors.darkGray,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.music_note_outlined,
                  color: AppColors.pureWhite,
                  size:  20,
                ),
              ),

        // ─ Titre ──────────────────────────────────────
        title: Text(
          selectedTrack != null
              ? selectedTrack!.title
              : 'Ajouter de la musique',
          style: GoogleFonts.inter(
            color:    AppColors.pureWhite,
            fontSize: 15,
            fontWeight: selectedTrack != null
                ? FontWeight.w500
                : FontWeight.w400,
          ),
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
        ),

        // ─ Artiste + durée ────────────────────────────
        subtitle: selectedTrack != null
            ? Text(
                '${selectedTrack!.artist} · '
                '${selectedTrack!.durationFormatted}',
                style: GoogleFonts.inter(
                    color:    AppColors.crimsonRed,
                    fontSize: 12),
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
              )
            : Text('Recherche sur Spotify',
                style: GoogleFonts.inter(
                    color:    AppColors.mediumGray,
                    fontSize: 12)),

        // ─ Retirer ou flèche ──────────────────────────
        trailing: selectedTrack != null
            ? GestureDetector(
                onTap: () => onTrackSelected(null),
                child: const Icon(Icons.close,
                    color: AppColors.mediumGray,
                    size:  20),
              )
            : const Icon(Icons.chevron_right,
                color: AppColors.mediumGray, size: 22),

        onTap: () => _openPicker(context),
      ),
    );
  }
}