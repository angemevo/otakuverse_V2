import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

// ─── MODÈLE SONG ─────────────────────────────────────────────────────
class SongModel {
  final String path;
  final String title;
  final String artist;
  final int?   duration;

  const SongModel({
    required this.path,
    required this.title,
    required this.artist,
    this.duration,
  });
}

// ─── MUSIC SECTION ───────────────────────────────────────────────────
class MusicSection extends StatefulWidget {
  final SongModel?               selectedSong;
  final ValueChanged<SongModel?> onSongSelected;

  const MusicSection({
    super.key,
    required this.selectedSong,
    required this.onSongSelected,
  });

  @override
  State<MusicSection> createState() => _MusicSectionState();
}

class _MusicSectionState extends State<MusicSection> {

  Future<void> _openPicker() async {
    await showModalBottomSheet(
      context:            context,
      backgroundColor:    AppColors.darkGray,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) => _MusicPickerSheet(
        selectedSong:   widget.selectedSong,
        onSongSelected: (song) {
          widget.onSongSelected(song);
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
        leading: const Icon(
            Icons.music_note_outlined,
            color: AppColors.pureWhite, size: 22),
        title: Text(
          widget.selectedSong != null
              ? widget.selectedSong!.title
              : 'Ajouter de la musique',
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color:    AppColors.pureWhite,
            fontSize: 15,
            fontWeight: widget.selectedSong != null
                ? FontWeight.w500
                : FontWeight.w400,
          ),
        ),
        subtitle: widget.selectedSong != null
            ? Text(
                widget.selectedSong!.artist,
                style: GoogleFonts.inter(
                    color:    AppColors.crimsonRed,
                    fontSize: 12),
              )
            : null,
        trailing: widget.selectedSong != null
            ? GestureDetector(
                onTap: () => widget.onSongSelected(null),
                child: const Icon(Icons.close,
                    color: AppColors.mediumGray, size: 20),
              )
            : const Icon(Icons.chevron_right,
                color: AppColors.mediumGray, size: 22),
        onTap: _openPicker,
      ),
    );
  }
}

// ─── MUSIC PICKER SHEET ──────────────────────────────────────────────
class _MusicPickerSheet extends StatefulWidget {
  final SongModel?               selectedSong;
  final ValueChanged<SongModel?> onSongSelected;

  const _MusicPickerSheet({
    required this.selectedSong,
    required this.onSongSelected,
  });

  @override
  State<_MusicPickerSheet> createState() =>
      _MusicPickerSheetState();
}

class _MusicPickerSheetState
    extends State<_MusicPickerSheet> {
  final _player     = AudioPlayer();
  final _searchCtrl = TextEditingController();

  List<SongModel> _allSongs      = [];
  List<SongModel> _filteredSongs = [];
  SongModel?      _previewSong;
  bool            _loading       = false;
  bool            _isPlaying     = false;

  @override
  void initState() {
    super.initState();
    // ✅ Écouter la fin de la lecture
    _player.playerStateStream.listen((state) {
      if (state.processingState ==
          ProcessingState.completed) {
        if (mounted) setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── SÉLECTIONNER DES FICHIERS AUDIO ─────────────────────────────
  Future<void> _pickAudioFiles() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type:          FileType.audio,
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final songs = result.files
          .where((f) => f.path != null)
          .map((f) {
            // ✅ Extraire le titre depuis le nom de fichier
            final name = f.name;
            final title = name.contains('.')
                ? name.substring(0, name.lastIndexOf('.'))
                : name;

            // ✅ Essayer d'extraire artiste - titre
            String artist = 'Artiste inconnu';
            String songTitle = title;
            if (title.contains(' - ')) {
              final parts = title.split(' - ');
              artist    = parts.first.trim();
              songTitle = parts.sublist(1).join(' - ').trim();
            }

            return SongModel(
              path:     f.path!,
              title:    songTitle,
              artist:   artist,
              duration: f.size,
            );
          })
          .toList();

      if (mounted) {
        setState(() {
          _allSongs = [..._allSongs, ...songs]
              .fold<List<SongModel>>([], (list, s) {
            if (!list.any((e) => e.path == s.path)) {
              list.add(s);
            }
            return list;
          });
          _filteredSongs = _allSongs;
          _loading       = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── FILTRER ─────────────────────────────────────────────────────
  void _search(String query) {
    setState(() {
      _filteredSongs = query.isEmpty
          ? _allSongs
          : _allSongs.where((s) {
              final q = query.toLowerCase();
              return s.title.toLowerCase().contains(q) ||
                  s.artist.toLowerCase().contains(q);
            }).toList();
    });
  }

  // ─── APERÇU ──────────────────────────────────────────────────────
  Future<void> _togglePreview(SongModel song) async {
    HapticFeedback.lightImpact();

    if (_previewSong?.path == song.path && _isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _previewSong = song;
      _isPlaying   = true;
    });

    try {
      await _player.setFilePath(song.path);
      await _player.play();

      // ✅ Stop après 30 secondes
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _isPlaying &&
            _previewSong?.path == song.path) {
          _player.pause();
          if (mounted) setState(() => _isPlaying = false);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ─ Handle ───────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ─ Header ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16),
            child: Row(
              children: [
                Text('Ma musique',
                    style: GoogleFonts.poppins(
                      color:      AppColors.pureWhite,
                      fontWeight: FontWeight.w700,
                      fontSize:   17,
                    )),
                const Spacer(),
                // ✅ Bouton parcourir les fichiers
                GestureDetector(
                  onTap: _pickAudioFiles,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:        AppColors.crimsonRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text('Parcourir',
                            style: GoogleFonts.inter(
                              color:      Colors.white,
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─ Barre recherche ──────────────────────────────
          if (_allSongs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color:        AppColors.deepBlack,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged:  _search,
                  style: GoogleFonts.inter(
                      color: AppColors.pureWhite,
                      fontSize: 14),
                  decoration: InputDecoration(
                    hintText:  'Rechercher...',
                    hintStyle: GoogleFonts.inter(
                        color:    AppColors.mediumGray,
                        fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.mediumGray,
                        size:  18),
                    border:         InputBorder.none,
                    contentPadding: const EdgeInsets
                        .symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),

          // ─ Contenu ──────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.crimsonRed))
                : _allSongs.isEmpty
                    ? _buildEmptyState()
                    : _filteredSongs.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun résultat',
                              style: GoogleFonts.inter(
                                  color: AppColors
                                      .mediumGray),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            itemCount:
                                _filteredSongs.length,
                            itemBuilder: (_, i) {
                              final song =
                                  _filteredSongs[i];
                              final isSelected =
                                  widget.selectedSong
                                      ?.path ==
                                  song.path;
                              final isPreviewing =
                                  _previewSong?.path ==
                                  song.path;

                              return _SongTile(
                                song:         song,
                                isSelected:   isSelected,
                                isPreviewing: isPreviewing
                                    && _isPlaying,
                                onTap: () => widget
                                    .onSongSelected(song),
                                onPreview: () =>
                                    _togglePreview(song),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:  AppColors.darkGray,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_outlined,
              color: AppColors.mediumGray,
              size:  48,
            ),
          ),
          const SizedBox(height: 16),
          Text('Aucune musique chargée',
              style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize:   16,
              )),
          const SizedBox(height: 8),
          Text(
            'Appuie sur "Parcourir" pour\nsélectionner des fichiers audio',
            style: GoogleFonts.inter(
                color:    AppColors.mediumGray,
                fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickAudioFiles,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color:        AppColors.crimsonRed,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open_outlined,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Parcourir la galerie',
                      style: GoogleFonts.inter(
                        color:      Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize:   14,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SONG TILE ───────────────────────────────────────────────────────
class _SongTile extends StatelessWidget {
  final SongModel    song;
  final bool         isSelected;
  final bool         isPreviewing;
  final VoidCallback onTap;
  final VoidCallback onPreview;

  const _SongTile({
    required this.song,
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
          ? AppColors.crimsonRed.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        // ─ Bouton play/pause ───────────────────────────
        leading: GestureDetector(
          onTap: onPreview,
          child: Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isPreviewing
                  ? AppColors.crimsonRed
                      .withValues(alpha: 0.15)
                  : AppColors.deepBlack,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected || isPreviewing
                    ? AppColors.crimsonRed
                    : AppColors.mediumGray
                        .withValues(alpha: 0.2),
                width: isSelected || isPreviewing ? 1.5 : 1,
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isPreviewing
                    ? Icons.pause
                    : Icons.play_arrow,
                key:   ValueKey(isPreviewing),
                color: isPreviewing
                    ? AppColors.crimsonRed
                    : AppColors.mediumGray,
                size:  22,
              ),
            ),
          ),
        ),

        // ─ Titre + Artiste ──────────────────────────────
        title: Text(
          song.title,
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color:      AppColors.pureWhite,
            fontWeight: isSelected
                ? FontWeight.w600
                : FontWeight.w400,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          song.artist,
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: isSelected
                ? AppColors.crimsonRed
                : AppColors.mediumGray,
            fontSize: 12,
          ),
        ),

        // ─ Check sélectionné ────────────────────────────
        trailing: isSelected
            ? const Icon(Icons.check_circle,
                color: AppColors.crimsonRed, size: 22)
            : null,

        onTap: onTap,
      ),
    );
  }
}