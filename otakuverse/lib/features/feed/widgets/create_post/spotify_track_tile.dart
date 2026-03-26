import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/services/music_service.dart';

class SpotifyTrackTile extends StatelessWidget {
  final SpotifyTrack track;
  final bool         isSelected;
  final bool         isPreviewing;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const SpotifyTrackTile({
    super.key,
    required this.track,
    required this.isSelected,
    required this.isPreviewing,
    required this.onTap,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: isSelected
          ? const Color(0xFF1DB954)
              .withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        // ─ Pochette + overlay play ─────────────────────
        leading: GestureDetector(
          onTap: onPreview,
          child: Stack(
            children: [
              // ─ Pochette ───────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: track.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: track.imageUrl!,
                        width:    46, height: 46,
                        fit:      BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 46, height: 46,
                          color: AppColors.deepBlack,
                        ),
                      )
                    : Container(
                        width:  46, height: 46,
                        color:  AppColors.deepBlack,
                        child:  const Icon(
                          Icons.music_note,
                          color: AppColors.mediumGray,
                          size:  22,
                        ),
                      ),
              ),

              // ─ Overlay pause ──────────────────────────
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isPreviewing
                        ? Colors.black
                            .withValues(alpha: 0.55)
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                  child: isPreviewing
                      ? const Icon(Icons.pause,
                          color: Colors.white, size: 20)
                      : null,
                ),
              ),
            ],
          ),
        ),

        // ─ Titre ──────────────────────────────────────
        title: Text(
          track.title,
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color:      AppColors.pureWhite,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.w400,
            fontSize:   14,
          ),
        ),

        // ─ Artiste + durée + badge no preview ─────────
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                '${track.artist} · '
                '${track.durationFormatted}',
                maxLines:  1,
                overflow:  TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: isSelected
                      ? const Color(0xFF1DB954)
                      : AppColors.mediumGray,
                  fontSize: 12,
                ),
              ),
            ),
            // ✅ Badge si pas d'aperçu disponible
            if (track.previewUrl == null)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color:        AppColors.darkGray,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('No preview',
                    style: GoogleFonts.inter(
                      color:    AppColors.mediumGray,
                      fontSize: 9,
                    )),
              ),
          ],
        ),

        // ─ Check sélectionné ──────────────────────────
        trailing: isSelected
            ? const Icon(Icons.check_circle,
                color: Color(0xFF1DB954), size: 22)
            : null,

        onTap: onTap,
      ),
    );
  }
}