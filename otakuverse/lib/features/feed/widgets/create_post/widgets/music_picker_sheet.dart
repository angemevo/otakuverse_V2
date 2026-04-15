import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/music_service.dart';

/// Sheet de recherche et sélection de musique via Deezer.
/// Utilise [MusicService.search] et [MusicService.getSuggestions].
class MusicPickerSheet {
  static Future<void> show(
    BuildContext context, {
    required MusicTrack?               selectedSong,
    required ValueChanged<MusicTrack?> onSongSelected,
  }) {
    return showModalBottomSheet(
      context:            context,
      backgroundColor:    AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _MusicPickerContent(
        selectedSong:   selectedSong,
        onSongSelected: (song) {
          onSongSelected(song);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _MusicPickerContent extends StatefulWidget {
  final MusicTrack?               selectedSong;
  final ValueChanged<MusicTrack?> onSongSelected;

  const _MusicPickerContent({
    required this.selectedSong,
    required this.onSongSelected,
  });

  @override
  State<_MusicPickerContent> createState() => _MusicPickerContentState();
}

class _MusicPickerContentState extends State<_MusicPickerContent> {
  final _searchCtrl  = TextEditingController();
  final _audioPlayer = AudioPlayer();

  List<MusicTrack> _results       = [];
  bool             _loading       = false;
  bool             _hasSearched   = false;

  // Preview audio state
  String? _previewingId;
  bool    _previewLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();

    // Reset preview state when track finishes
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) {
        setState(() { _previewingId = null; });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ─── Suggestions initiales ────────────────────────────────────────

  Future<void> _loadSuggestions() async {
    setState(() => _loading = true);
    final results = await MusicService.getSuggestions();
    if (mounted) setState(() {
      _results = results;
      _loading = false;
    });
  }

  // ─── Recherche ────────────────────────────────────────────────────

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().isEmpty) {
      _stopPreview();
      _loadSuggestions();
      return;
    }
    setState(() { _loading = true; _hasSearched = true; });
    final results = await MusicService.search(query);
    if (mounted) setState(() {
      _results = results;
      _loading = false;
    });
  }

  // ─── Preview audio ────────────────────────────────────────────────

  Future<void> _togglePreview(MusicTrack track) async {
    if (track.previewUrl == null) return;

    HapticFeedback.lightImpact();

    // Même track → toggle play/pause
    if (_previewingId == track.id) {
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
      return;
    }

    // Autre track → charger et jouer
    setState(() {
      _previewingId   = track.id;
      _previewLoading = true;
    });

    try {
      await _audioPlayer.setUrl(track.previewUrl!);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('❌ Preview error: $e');
      if (mounted) setState(() { _previewingId = null; });
    } finally {
      if (mounted) setState(() => _previewLoading = false);
    }
  }

  Future<void> _stopPreview() async {
    await _audioPlayer.stop();
    if (mounted) setState(() { _previewingId = null; });
  }

  // ─── Build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, sc) => Column(children: [
        const SizedBox(height: 8),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color:        AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),

        // ─ Header ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Text('Ajouter de la musique',
                style: GoogleFonts.poppins(
                  color:      AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize:   17,
                )),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text('Deezer',
                  style: GoogleFonts.inter(
                    color:      AppColors.primary,
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ─ Champ de recherche ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color:        AppColors.bgPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged:  _onSearchChanged,
              style: GoogleFonts.inter(
                  color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText:  'Rechercher un titre, artiste...',
                hintStyle: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textMuted, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _stopPreview();
                          _loadSuggestions();
                        },
                        child: const Icon(Icons.close,
                            color: AppColors.textMuted, size: 16),
                      )
                    : null,
                border:         InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ─ Contenu ──────────────────────────────────────────────
        Expanded(child: _buildContent(sc)),
      ]),
    );
  }

  Widget _buildContent(ScrollController sc) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_results.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.music_off_outlined,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text(
            _hasSearched
                ? 'Aucun résultat pour "${_searchCtrl.text}"'
                : 'Aucune suggestion disponible',
            style: GoogleFonts.inter(
                color: AppColors.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ]),
      );
    }

    return ListView.builder(
      controller: sc,
      itemCount:  _results.length,
      itemBuilder: (_, i) {
        final track      = _results[i];
        final isSelected = widget.selectedSong?.id == track.id;
        final isPreviewing = _previewingId == track.id;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: ListTile(
            leading: _buildAlbumArt(track, isSelected),
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color:      AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize:   14,
              ),
            ),
            subtitle: Row(children: [
              Text(
                track.artist,
                style: GoogleFonts.inter(
                  color:    isSelected ? AppColors.primary : AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${track.durationFormatted}',
                style: GoogleFonts.inter(
                    color: AppColors.textMuted, fontSize: 11),
              ),
            ]),
            // ─ Trailing : preview + sélection ─────────────────────
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton preview (seulement si URL disponible)
                if (track.previewUrl != null)
                  GestureDetector(
                    onTap: () => _togglePreview(track),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(
                        color: isPreviewing
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.bgPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPreviewing
                              ? AppColors.primary
                              : AppColors.textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: (_previewLoading && isPreviewing)
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary),
                              )
                            : StreamBuilder<PlayerState>(
                                stream: _audioPlayer.playerStateStream,
                                builder: (_, snap) {
                                  final playing = snap.data?.playing == true
                                      && isPreviewing;
                                  return Icon(
                                    playing
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: isPreviewing
                                        ? AppColors.primary
                                        : AppColors.textMuted,
                                    size: 18,
                                  );
                                },
                              ),
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Bouton sélection
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 22)
                else
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _stopPreview();
                      widget.onSongSelected(track);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:        AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text('Choisir',
                          style: GoogleFonts.inter(
                            color:      AppColors.primary,
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
              ],
            ),
            onTap: isSelected
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    _stopPreview();
                    widget.onSongSelected(track);
                  },
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(MusicTrack track, bool isSelected) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color:        AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.textMuted.withValues(alpha: 0.2),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: track.imageUrl != null
          ? Image.network(track.imageUrl!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.music_note, color: AppColors.textMuted, size: 20))
          : const Icon(Icons.music_note,
              color: AppColors.textMuted, size: 20),
    );
  }
}
