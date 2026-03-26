import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/core/services/music_service.dart';
import 'package:otakuverse/features/feed/widgets/create_post/spotify_track_tile.dart';

class SpotifyPickerSheet extends StatefulWidget {
  final SpotifyTrack?               selectedTrack;
  final ValueChanged<SpotifyTrack?> onTrackSelected;

  const SpotifyPickerSheet({
    super.key,
    required this.selectedTrack,
    required this.onTrackSelected,
  });

  @override
  State<SpotifyPickerSheet> createState() =>
      _SpotifyPickerSheetState();
}

class _SpotifyPickerSheetState
    extends State<SpotifyPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _player     = AudioPlayer();

  List<SpotifyTrack> _tracks      = [];
  bool               _loading     = false;
  bool               _loadingSugg = true;
  SpotifyTrack?      _previewTrack;
  bool               _isPlaying   = false;
  Timer?             _debounce;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _player.playerStateStream.listen((state) {
      if (state.processingState ==
          ProcessingState.completed) {
        if (mounted) setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _player.dispose();
    super.dispose();
  }

  // ─── SUGGESTIONS ─────────────────────────────────────────────────
  Future<void> _loadSuggestions() async {
    setState(() => _loadingSugg = true);
    try {
      final tracks =
          await SpotifyService.getSuggestions();
      if (mounted) {
        setState(() {
          _tracks      = tracks;
          _loadingSugg = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSugg = false);
    }
  }

  // ─── RECHERCHE DEBOUNCE ──────────────────────────────────────────
  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      _loadSuggestions();
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final tracks = await SpotifyService.search(query);
      if (mounted) {
        setState(() {
          _tracks  = tracks;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── APERÇU 30s ──────────────────────────────────────────────────
  Future<void> _togglePreview(SpotifyTrack track) async {
    HapticFeedback.lightImpact();

    if (track.previewUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pas d\'aperçu disponible pour ce titre',
            style: GoogleFonts.inter(
                color: AppColors.pureWhite),
          ),
          backgroundColor: AppColors.darkGray,
          behavior:        SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ),
      );
      return;
    }

    if (_previewTrack?.id == track.id && _isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _previewTrack = track;
      _isPlaying    = false;
    });

    try {
      await _player.setUrl(track.previewUrl!);
      await _player.play();
      if (mounted) setState(() => _isPlaying = true);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, scrollCtrl) => Column(
        children: [
          // ─ Handle ──────────────────────────────────────
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color:        AppColors.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // ─ Header ──────────────────────────────────────
          _buildHeader(),
          const SizedBox(height: 12),

          // ─ Recherche ───────────────────────────────────
          _buildSearchBar(),
          const SizedBox(height: 4),

          // ─ Label ───────────────────────────────────────
          _buildSectionLabel(),

          // ─ Liste ───────────────────────────────────────
          Expanded(child: _buildList(scrollCtrl)),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16),
      child: Row(
        children: [
          // ─ Badge Deezer ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              // ✅ Couleur Deezer
              color:        const Color(0xFF00C7F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('Deezer',
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize:   12,
                    )),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text('Musique',
              style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w700,
                fontSize:   17,
              )),
          const Spacer(),
          if (widget.selectedTrack != null)
            GestureDetector(
              onTap: () => widget.onTrackSelected(null),
              child: Text('Retirer',
                  style: GoogleFonts.inter(
                    color:      AppColors.crimsonRed,
                    fontSize:   13,
                    fontWeight: FontWeight.w600,
                  )),
            ),
        ],
      ),
    );
  }

  // ─── BARRE RECHERCHE ─────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color:        AppColors.deepBlack,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged:  _onSearch,
          style: GoogleFonts.inter(
              color: AppColors.pureWhite,
              fontSize: 14),
          decoration: InputDecoration(
            hintText:  'Artiste, titre, album...',
            hintStyle: GoogleFonts.inter(
                color:    AppColors.mediumGray,
                fontSize: 14),
            prefixIcon: const Icon(Icons.search,
                color: AppColors.mediumGray, size: 18),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      _loadSuggestions();
                      setState(() {});
                    },
                    child: const Icon(Icons.close,
                        color: AppColors.mediumGray,
                        size:  16),
                  )
                : null,
            border:         InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 12),
          ),
        ),
      ),
    );
  }

  // ─── LABEL SECTION ───────────────────────────────────────────────
  Widget _buildSectionLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _searchCtrl.text.isEmpty
              ? 'Suggestions anime'
              : '${_tracks.length} résultats',
          style: GoogleFonts.inter(
            color:      AppColors.mediumGray,
            fontSize:   12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ─── LISTE ───────────────────────────────────────────────────────
  Widget _buildList(ScrollController scrollCtrl) {
    if (_loading || _loadingSugg) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFF1DB954)),
      );
    }

    if (_tracks.isEmpty) {
      return _buildEmpty();
    }

    return ListView.builder(
      controller: scrollCtrl,
      itemCount:  _tracks.length,
      itemBuilder: (_, i) {
        final track      = _tracks[i];
        final isSelected =
            widget.selectedTrack?.id == track.id;
        final isPreviewing =
            _previewTrack?.id == track.id && _isPlaying;

        return SpotifyTrackTile(
          track:        track,
          isSelected:   isSelected,
          isPreviewing: isPreviewing,
          onTap:        () => widget
              .onTrackSelected(track),
          onPreview:    () => _togglePreview(track),
        );
      },
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off,
              color: AppColors.mediumGray, size: 48),
          const SizedBox(height: 12),
          Text('Aucun résultat',
              style: GoogleFonts.poppins(
                color:      AppColors.pureWhite,
                fontWeight: FontWeight.w600,
                fontSize:   16,
              )),
          const SizedBox(height: 6),
          Text('Essaie un autre titre ou artiste',
              style: GoogleFonts.inter(
                  color:    AppColors.mediumGray,
                  fontSize: 13)),
        ],
      ),
    );
  }
}