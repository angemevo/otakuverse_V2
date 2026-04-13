import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/core/services/audio_manager.dart';
import 'package:otakuverse/features/feed/models/post_model.dart';

class PostCardMusicPlayer extends StatefulWidget {
  final PostModel post;

  const PostCardMusicPlayer({
    super.key,
    required this.post,
  });

  @override
  State<PostCardMusicPlayer> createState() =>
      _PostCardMusicPlayerState();
}

class _PostCardMusicPlayerState
    extends State<PostCardMusicPlayer>
    with SingleTickerProviderStateMixin {

  late final AudioPlayer         _player;
  late final AnimationController _barsController;

  StreamSubscription? _positionSub;
  StreamSubscription? _playerStateSub;

  // ✅ Source unique de vérité — dérivé du player
  bool     _isPlaying  = false;
  bool     _isLoading  = false;
  bool     _hasError   = false;
  bool     _isLoaded   = false; // ✅ Track chargé
  Duration _position   = Duration.zero;
  Duration _duration   = Duration.zero;

  bool _userPaused = false;  
  static const double _visibilityThreshold = 0.75;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _barsController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _setupListeners();
  }

  @override
  void dispose() {
    // ✅ Stopper proprement avant dispose
    if (_isPlaying) {
      AudioManager.instance.stop(widget.post.id);
    }
    _positionSub?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    _barsController.dispose();
    super.dispose();
  }

  // ─── SETUP LISTENERS ─────────────────────────────────────────────
  void _setupListeners() {
    // ✅ Position
    _positionSub = _player.positionStream
        .listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    // ✅ UN SEUL listener — playerStateStream
    // gère TOUT : loading, playing, paused, completed
    _playerStateSub =
        _player.playerStateStream.listen((state) {
      if (!mounted) return;

      final isActuallyPlaying =
          state.playing &&
          state.processingState !=
              ProcessingState.completed &&
          state.processingState !=
              ProcessingState.idle;

      final isBuffering =
          state.processingState ==
              ProcessingState.loading ||
          state.processingState ==
              ProcessingState.buffering;

      final isCompleted =
          state.processingState ==
              ProcessingState.completed;

      setState(() {
        _isPlaying = isActuallyPlaying;
        _isLoading = isBuffering && !isActuallyPlaying;
      });

      // ✅ Barres animées
      if (isActuallyPlaying) {
        if (!_barsController.isAnimating) {
          _barsController.repeat(reverse: true);
        }
      } else {
        _barsController.stop();
        if (isCompleted) {
          _barsController.reset();
          setState(() => _position = Duration.zero);
        }
      }

      // ✅ Mettre à jour la durée dès qu'elle est dispo
      if (_player.duration != null &&
          _player.duration! > Duration.zero) {
        setState(() {
          _duration = _player.duration!;
          _isLoaded = true;
        });
      }
    });
  }

  // ─── CHARGER LE TRACK ────────────────────────────────────────────
  Future<void> _loadTrack() async {
    if (widget.post.musicPreviewUrl == null) return;
    if (_isLoaded) return; // ✅ Déjà chargé

    setState(() {
      _isLoading = true;
      _hasError  = false;
    });

    try {
      await _player.setUrl(
          widget.post.musicPreviewUrl!);
      _duration = _player.duration ?? Duration.zero;

      if (mounted) {
        setState(() {
          _isLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError  = true;
          _isLoaded  = false;
        });
        debugPrint('❌ Load error: $e');
      }
    }
  }

  // ─── TOGGLE PLAY/PAUSE ───────────────────────────────────────────
  // ✅ Simple et direct — pas de logique complexe
  Future<void> _togglePlay() async {
    if (widget.post.musicPreviewUrl == null) return;

    if (_isPlaying) {
      // ✅ L'utilisateur pause manuellement
      // → bloquer l'autoplay jusqu'au prochain appui
      _userPaused = true;
      await _player.pause();
      AudioManager.instance.stop(widget.post.id);
    } else {
      // ✅ L'utilisateur relance manuellement
      // → réactiver l'autoplay
      _userPaused = false;

      if (!_isLoaded) {
        await _loadTrack();
        if (!_isLoaded) return;
      }

      await AudioManager.instance.play(
        postId:     widget.post.id,
        previewUrl: widget.post.musicPreviewUrl!,
        player:     _player,
      );
    }
  }

  // ─── AUTOPLAY VISIBILITÉ ─────────────────────────────────────────
  Future<void> _onVisibilityChanged(
    VisibilityInfo info) async {
    if (widget.post.musicPreviewUrl == null) return;

    final isVisible =
        info.visibleFraction >= _visibilityThreshold;

    if (isVisible && !_isPlaying && !_isLoading) {
      // ✅ Ne pas relancer si l'utilisateur
      // a pausé manuellement
      if (_userPaused) return;

      if (!_isLoaded) await _loadTrack();
      if (!mounted || !_isLoaded) return;

      await AudioManager.instance.play(
        postId:     widget.post.id,
        previewUrl: widget.post.musicPreviewUrl!,
        player:     _player,
      );
    } else if (!isVisible && _isPlaying) {
      // ✅ Post hors écran → pause automatique
      // et réinitialiser _userPaused pour
      // relancer au prochain scroll
      _userPaused = false;
      await _player.pause();
      AudioManager.instance.stop(widget.post.id);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60)
        .toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60)
        .toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.post.musicTitle == null) {
      return const SizedBox.shrink();
    }

    return VisibilityDetector(
      key: Key('music_${widget.post.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color:        AppColors.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isPlaying
                  ? AppColors.primary
                      .withValues(alpha: 0.6)
                  : AppColors.primary
                      .withValues(alpha: 0.2),
              width: _isPlaying ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              // ─ Pochette ────────────────────────────
              if (widget.post.musicImageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(
                      right: 10),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl:
                          widget.post.musicImageUrl!,
                      width:  44, height: 44,
                      fit:    BoxFit.cover,
                      placeholder: (_, __) => Container(
                        width: 44, height: 44,
                        color: AppColors.bgPrimary,
                      ),
                      errorWidget: (_, __, ___) =>
                          Container(
                        width: 44, height: 44,
                        color: AppColors.bgPrimary,
                        child: const Icon(
                          Icons.music_note,
                          color: AppColors.textMuted,
                          size:  20,
                        ),
                      ),
                    ),
                  ),
                ),

              // ─ Bouton play/pause ─────────────────
              GestureDetector(
                onTap: _togglePlay,
                child: AnimatedContainer(
                  duration: const Duration(
                      milliseconds: 150),
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? AppColors.primary
                        : AppColors.primary
                            .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width:  16, height: 16,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  AppColors.primary,
                            ),
                          )
                        // ✅ AnimatedSwitcher pour
                        // transition fluide play↔pause
                        : AnimatedSwitcher(
                            duration: const Duration(
                                milliseconds: 150),
                            transitionBuilder:
                                (child, anim) =>
                                    ScaleTransition(
                              scale: anim,
                              child: child,
                            ),
                            child: Icon(
                              _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              // ✅ Key obligatoire
                              // pour AnimatedSwitcher
                              key: ValueKey<bool>(
                                  _isPlaying),
                              color: _isPlaying
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 22,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ─ Infos ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ─ Titre + barres ─────────────
                    Row(children: [
                      if (_isPlaying)
                        Padding(
                          padding:
                              const EdgeInsets.only(
                                  right: 6),
                          child: _AnimatedBars(
                            controller:
                                _barsController,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          widget.post.musicTitle!,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize:   13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines:  1,
                          overflow:
                              TextOverflow.ellipsis,
                        ),
                      ),
                    ]),

                    // ─ Artiste ────────────────────
                    if (widget.post.musicArtist !=
                        null)
                      Text(
                        widget.post.musicArtist!,
                        style: GoogleFonts.inter(
                          color:    AppColors.textMuted,
                          fontSize: 11,
                        ),
                        maxLines:  1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),

                    // ─ Progress bar ───────────────
                    if (_duration.inSeconds > 0)
                      Padding(
                        padding:
                            const EdgeInsets.only(
                                top: 6),
                        child: Column(
                          children: [
                            // ─ Barre ──────────────
                            ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(2),
                              child:
                                  LinearProgressIndicator(
                                value: (_position
                                            .inMilliseconds /
                                        _duration
                                            .inMilliseconds)
                                    .clamp(0.0, 1.0),
                                backgroundColor:
                                    AppColors.textMuted
                                        .withValues(
                                            alpha: 0.2),
                                valueColor:
                                    const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                                minHeight: 3,
                              ),
                            ),
                            const SizedBox(height: 3),

                            // ─ Temps + badge ──────
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                              children: [
                                Text(_fmt(_position),
                                    style: GoogleFonts
                                        .inter(
                                      color: AppColors
                                          .textMuted,
                                      fontSize: 9,
                                    )),
                                // ✅ Badge Deezer
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 5,
                                    vertical:   1,
                                  ),
                                  decoration:
                                      BoxDecoration(
                                    color: const Color(
                                            0xFF00C7F2)
                                        .withValues(
                                            alpha: 0.15),
                                    borderRadius:
                                        BorderRadius
                                            .circular(4),
                                  ),
                                  child: Text(
                                    '30s · Deezer',
                                    style:
                                        GoogleFonts.inter(
                                      color: const Color(
                                          0xFF00C7F2),
                                      fontSize:   8,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(_fmt(_duration),
                                    style: GoogleFonts
                                        .inter(
                                      color: AppColors
                                          .textMuted,
                                      fontSize: 9,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ─ Erreur → réessayer ────────────────
              if (_hasError)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _hasError = false;
                      _isLoaded = false;
                    });
                    _togglePlay();
                  },
                  child: const Padding(
                    padding:
                        EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.refresh,
                      color: AppColors.error,
                      size:  20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── BARRES ANIMÉES ──────────────────────────────────────────────────
class _AnimatedBars extends StatelessWidget {
  final AnimationController controller;
  const _AnimatedBars({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Row(
        mainAxisSize:       MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [1.0, 0.6, 0.8, 0.4].map((ratio) {
          final height =
              4.0 + (8.0 * controller.value * ratio);
          return Container(
            width:  2,
            height: height,
            margin: const EdgeInsets.only(right: 1.5),
            decoration: BoxDecoration(
              color:        AppColors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }).toList(),
      ),
    );
  }
}