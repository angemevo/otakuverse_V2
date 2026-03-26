import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:otakuverse/features/stories/screens/create_story/create_story_screen.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:otakuverse/core/constants/colors.dart';
import 'package:otakuverse/features/feed/screens/create_post_screen.dart';
import 'package:otakuverse/features/feed/screens/create_short_screen.dart';

class MediaPickerScreen extends StatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  // ─── Type ────────────────────────────────────────────────────────
  String _type = 'post';

  // ─── Galerie ─────────────────────────────────────────────────────
  List<AssetEntity> _assets        = [];
  bool              _loadingGallery = true;

  // ─── Preview ─────────────────────────────────────────────────────
  AssetEntity?  _previewAsset;
  Uint8List?    _previewBytes;

  // ─── Sélection multiple ──────────────────────────────────────────
  List<AssetEntity> _selectedAssets = [];
  bool              _multiSelect    = false;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  // ─── CHARGER LA GALERIE ──────────────────────────────────────────
  Future<void> _loadGallery() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      if (mounted) setState(() => _loadingGallery = false);
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type:           RequestType.image,
      filterOption:   FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint: SizeConstraint(minWidth: 1, minHeight: 1),
        ),
      ),
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _loadingGallery = false);
      return;
    }

    final assets = await albums.first.getAssetListRange(
      start: 0, end: 100,
    );

    if (mounted) {
      setState(() {
        _assets        = assets;
        _loadingGallery = false;
      });
      if (assets.isNotEmpty) _setPreview(assets.first);
    }
  }

  // ─── DÉFINIR LA PREVIEW ──────────────────────────────────────────
  Future<void> _setPreview(AssetEntity asset) async {
    final bytes = await asset.thumbnailDataWithSize(
      const ThumbnailSize(800, 800),
    );
    if (mounted) {
      setState(() {
        _previewAsset = asset;
        _previewBytes = bytes;
      });
    }
  }

  // ─── SÉLECTIONNER UN ASSET ───────────────────────────────────────
  void _selectAsset(AssetEntity asset) {
    HapticFeedback.selectionClick();
    if (_multiSelect) {
      setState(() {
        if (_selectedAssets.contains(asset)) {
          _selectedAssets.remove(asset);
        } else if (_selectedAssets.length < 10) {
          _selectedAssets.add(asset);
        }
      });
    }
    _setPreview(asset);
  }

  // ─── TOGGLE MULTI-SELECT ─────────────────────────────────────────
  void _toggleMultiSelect() {
    HapticFeedback.mediumImpact();
    setState(() {
      _multiSelect = !_multiSelect;
      _selectedAssets = _previewAsset != null
          ? [_previewAsset!]
          : [];
    });
  }

  // ─── SUIVANT ─────────────────────────────────────────────────────
  Future<void> _onNext() async {
    if (_previewAsset == null) return;
    HapticFeedback.mediumImpact();

    final assetsToExport = _multiSelect && _selectedAssets.isNotEmpty
        ? _selectedAssets
        : [_previewAsset!];

    // ✅ Convertir AssetEntity → XFile
    final files = <XFile>[];
    for (final asset in assetsToExport) {
      final file = await asset.file;
      if (file != null) files.add(XFile(file.path));
    }
    if (files.isEmpty) return;

    if (!mounted) return;

    switch (_type) {
      case 'post':
        Navigator.pushReplacement(context,
          MaterialPageRoute(
            builder: (_) => CreatePostScreen(preselectedFiles: files),
          ),
        );
        break;
      case 'story':
        Navigator.pushReplacement(context,
          MaterialPageRoute(
            builder: (_) => CreateStoryScreen(
                preselectedFile: files.first),
          ),
        );
        break;
      case 'short':
        Get.snackbar(
          'Bientôt disponible 🚧',
          'Les Shorts arrivent prochainement',
          backgroundColor: AppColors.darkGray,
          colorText:       AppColors.pureWhite,
          snackPosition:   SnackPosition.BOTTOM,
          margin:          const EdgeInsets.all(16),
          borderRadius:    12,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // ─ AppBar ───────────────────────────────────────────────
          _buildAppBar(),

          // ─ Preview ──────────────────────────────────────────────
          _buildPreview(),

          // ─ Toolbar galerie ──────────────────────────────────────
          _buildGalleryToolbar(),

          // ─ Grille galerie ───────────────────────────────────────
          Expanded(child: _buildGalleryGrid()),

          // ─ Onglets type ─────────────────────────────────────────
          _buildTypeTabs(),
        ],
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 26),
            ),
            const Spacer(),
            Text(
              _typeLabel,
              style: GoogleFonts.poppins(
                color:      Colors.white,
                fontWeight: FontWeight.w700,
                fontSize:   16,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap:  _previewAsset != null ? _onNext : null,
              child: Text(
                'Suivant',
                style: GoogleFonts.inter(
                  color: _previewAsset != null
                      ? AppColors.crimsonRed
                      : AppColors.mediumGray,
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PREVIEW ─────────────────────────────────────────────────────
  Widget _buildPreview() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: const Color(0xFF111111),
        child: _previewBytes != null
            ? Image.memory(
                _previewBytes!,
                fit: BoxFit.cover,
                width:  double.infinity,
                height: double.infinity,
              )
            : _loadingGallery
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.crimsonRed))
                : Center(
                    child: Text('Aucune image',
                        style: GoogleFonts.inter(
                            color: AppColors.mediumGray)),
                  ),
      ),
    );
  }

  // ─── TOOLBAR GALERIE ─────────────────────────────────────────────
  Widget _buildGalleryToolbar() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Row(children: [
            Text('Récent',
                style: GoogleFonts.inter(
                  color:      Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize:   15,
                )),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down,
                color: Colors.white, size: 20),
          ]),
          const Spacer(),
          GestureDetector(
            onTap: _toggleMultiSelect,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _multiSelect
                    ? AppColors.crimsonRed
                    : const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _multiSelect
                        ? Icons.check_circle
                        : Icons.copy_outlined,
                    color: Colors.white,
                    size:  16,
                  ),
                  const SizedBox(width: 6),
                  Text('Sélection multiple',
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
    );
  }

  // ─── GRILLE GALERIE ──────────────────────────────────────────────
  Widget _buildGalleryGrid() {
    if (_loadingGallery) {
      return const Center(
        child: CircularProgressIndicator(
            color: AppColors.crimsonRed),
      );
    }
    if (_assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.photo_library_outlined,
                color: AppColors.mediumGray, size: 48),
            const SizedBox(height: 12),
            Text('Aucun média disponible',
                style: GoogleFonts.inter(
                    color: AppColors.mediumGray)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding:     EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        crossAxisSpacing: 2,
        mainAxisSpacing:  2,
      ),
      itemCount: _assets.length,
      itemBuilder: (_, index) {
        final asset      = _assets[index];
        final isPreview  = _previewAsset == asset;
        final selIndex   = _selectedAssets.indexOf(asset);
        final isSelected = selIndex != -1;

        return GestureDetector(
          onTap: () => _selectAsset(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─ Thumbnail ─────────────────────────────────────
              _AssetThumbnail(asset: asset),

              // ─ Overlay preview ───────────────────────────────
              if (isPreview && !_multiSelect)
                Container(
                  color: Colors.white.withValues(alpha: 0.15),
                ),

              // ─ Overlay sombre non sélectionné ────────────────
              if (_multiSelect && !isSelected)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),

              // ─ Badge numéro sélection ─────────────────────────
              if (_multiSelect)
                Positioned(
                  top: 6, right: 6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width:  24, height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.crimsonRed
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                    ),
                    child: isSelected
                        ? Center(
                            child: Text(
                              '${selIndex + 1}',
                              style: const TextStyle(
                                color:      Colors.white,
                                fontSize:   11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── ONGLETS TYPE ────────────────────────────────────────────────
  Widget _buildTypeTabs() {
    const types = [
      ('post',  'PUBLIER'),
      ('story', 'STORY'),
      ('short', 'SHORT'),
    ];

    return Container(
      color: Colors.black,
      padding: EdgeInsets.only(
        top:    12,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: types.map((t) {
          final selected = _type == t.$1;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();

              // ✅ STORY → naviguer vers CreateStoryScreen
              if (t.$1 == 'story') {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        const CreateStoryScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration:
                        const Duration(milliseconds: 200),
                  ),
                );
                return;
              }

              // ✅ SHORT → naviguer vers CreateShortScreen
              if (t.$1 == 'short') {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) =>
                        const CreateShortScreen(),
                    transitionsBuilder: (_, anim, __, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration:
                        const Duration(milliseconds: 200),
                  ),
                );
                return;
              }

              // ✅ PUBLIER → rester sur cette page
              setState(() => _type = t.$1);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.$2,
                  style: GoogleFonts.inter(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
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
        }).toList(),
      ),
    );
  }

  String get _typeLabel {
    switch (_type) {
      case 'story': return 'Nouvelle story';
      case 'short': return 'Nouveau short';
      default:      return 'Nouvelle publication';
    }
  }
}

// ─── THUMBNAIL WIDGET ────────────────────────────────────────────────
class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  const _AssetThumbnail({required this.asset});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(200, 200),
    );
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return Container(color: const Color(0xFF1A1A1A));
    }
    return Image.memory(_bytes!, fit: BoxFit.cover);
  }
}