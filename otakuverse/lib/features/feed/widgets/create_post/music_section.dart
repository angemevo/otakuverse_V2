import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/music_service.dart';
import 'widgets/music_picker_sheet.dart';

/// Widget d'ajout de musique (Deezer) dans la création de post.
/// Utilise [MusicTrack] depuis [MusicService].
class MusicSection extends StatelessWidget {
  final MusicTrack?               selectedSong;
  final ValueChanged<MusicTrack?> onSongSelected;

  const MusicSection({
    super.key,
    required this.selectedSong,
    required this.onSongSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgPrimary,
      child: ListTile(
        tileColor: AppColors.bgPrimary,
        leading:   const Icon(Icons.music_note_outlined,
            color: AppColors.textPrimary, size: 22),
        title: Text(
          selectedSong?.title ?? 'Ajouter de la musique',
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color:      AppColors.textPrimary,
            fontSize:   15,
            fontWeight: selectedSong != null
                ? FontWeight.w500
                : FontWeight.w400,
          ),
        ),
        subtitle: selectedSong != null
            ? Text(
                selectedSong!.artist,
                style: GoogleFonts.inter(
                    color: AppColors.primary, fontSize: 12),
              )
            : null,
        trailing: selectedSong != null
            ? GestureDetector(
                onTap: () => onSongSelected(null),
                child: const Icon(Icons.close,
                    color: AppColors.textMuted, size: 20),
              )
            : const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 22),
        onTap: () => MusicPickerSheet.show(
          context,
          selectedSong:   selectedSong,
          onSongSelected: onSongSelected,
        ),
      ),
    );
  }
}