import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:otakuverse/core/constants/app_colors.dart';
import 'package:otakuverse/features/feed/screens/create_post_screen.dart';
import 'package:otakuverse/features/feed/screens/create_short_screen.dart';
import 'package:otakuverse/features/stories/screens/create_story/create_story_screen.dart';
import 'widgets/media_gallery_grid.dart';
import 'widgets/media_type_tabs.dart';

class MediaPickerScreen extends StatefulWidget {
  const MediaPickerScreen({super.key});

  @override
  State<MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<MediaPickerScreen> {
  String            _type           = 'post';
  List<AssetEntity> _assets         = [];
  bool              _loadingGallery = true;
  AssetEntity?      _previewAsset;
  Uint8List?        _previewBytes;
  List<AssetEntity> _selectedAssets = [];
  bool              _multiSelect    = false;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  // ─── Galerie ─────────────────────────────────────────────────────

  Future<void> _loadGallery() async {
    final perm = await PhotoManager.requestPermissionExtend();
    if (!perm.isAuth) {
      if (mounted) setState(() => _loadingGallery = false);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      type:         RequestType.image,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(
          sizeConstraint:
              SizeConstraint(minWidth: 1, minHeight: 1)),
      ),
    );
    if (albums.isEmpty) {
      if (mounted) setState(() => _loadingGallery = false);
      return;
    }
    final assets = await albums.first
        .getAssetListRange(start: 0, end: 100);
    if (!mounted) return;
    setState(() {
      _assets         = assets;
      _loadingGallery = false;
    });
    if (assets.isNotEmpty) _setPreview(assets.first);
  }

  Future<void> _setPreview(AssetEntity asset) async {
    final bytes = await asset.thumbnailDataWithSize(
        const ThumbnailSize(800, 800));
    if (mounted) setState(() { _previewAsset = asset; _previewBytes = bytes; });
  }

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

  void _toggleMultiSelect() {
    HapticFeedback.mediumImpact();
    setState(() {
      _multiSelect    = !_multiSelect;
      _selectedAssets = _previewAsset != null ? [_previewAsset!] : [];
    });
  }

  // ─── Navigation suivant ──────────────────────────────────────────

  Future<void> _onNext() async {
    if (_previewAsset == null) return;
    HapticFeedback.mediumImpact();

    final toExport = _multiSelect && _selectedAssets.isNotEmpty
        ? _selectedAssets
        : [_previewAsset!];

    final files = <XFile>[];
    for (final a in toExport) {
      final f = await a.file;
      if (f != null) files.add(XFile(f.path));
    }
    if (files.isEmpty || !mounted) return;

    Widget dest;
    switch (_type) {
      case 'story':
        dest = CreateStoryScreen(preselectedFile: files.first);
        break;
      case 'short':
        Get.snackbar(
          'Bientôt disponible 🚧',
          'Les Shorts arrivent prochainement',
          backgroundColor: AppColors.bgCard,
          colorText:       AppColors.textPrimary,
          snackPosition:   SnackPosition.BOTTOM,
          margin:          const EdgeInsets.all(16),
          borderRadius:    12,
        );
        return;
      default:
        dest = CreatePostScreen(preselectedFiles: files);
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => dest));
  }

  // ─── Onglets → navigation externe ────────────────────────────────

  void _onTypeChanged(String type) {
    if (type == 'story') {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreateStoryScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 200),
      ));
      return;
    }
    if (type == 'short') {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreateShortScreen(),
        transitionsBuilder: (_, a, __, c) =>
            FadeTransition(opacity: a, child: c),
        transitionDuration: const Duration(milliseconds: 200),
      ));
      return;
    }
    setState(() => _type = type);
  }

  String get _typeLabel {
    switch (_type) {
      case 'story': return 'Nouvelle story';
      case 'short': return 'Nouveau short';
      default:      return 'Nouvelle publication';
    }
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(children: [
        _buildAppBar(),
        _buildPreview(),
        MediaGalleryToolbar(
          multiSelect:         _multiSelect,
          onToggleMultiSelect: _toggleMultiSelect,
        ),
        Expanded(
          child: MediaGalleryGrid(
            assets:         _assets,
            loading:        _loadingGallery,
            multiSelect:    _multiSelect,
            previewAsset:   _previewAsset,
            selectedAssets: _selectedAssets,
            onTap:          _selectAsset,
          ),
        ),
        MediaTypeTabs(
          currentType:   _type,
          onTypeChanged: _onTypeChanged,
        ),
      ]),
    );
  }

  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.close,
                color: Colors.white, size: 26),
          ),
          const Spacer(),
          Text(_typeLabel,
              style: GoogleFonts.poppins(
                color:      Colors.white,
                fontWeight: FontWeight.w700,
                fontSize:   16,
              )),
          const Spacer(),
          GestureDetector(
            onTap:  _previewAsset != null ? _onNext : null,
            child: Text('Suivant',
                style: GoogleFonts.inter(
                  color: _previewAsset != null
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize:   15,
                )),
          ),
        ]),
      ),
    );
  }

  Widget _buildPreview() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: const Color(0xFF111111),
        child: _previewBytes != null
            ? Image.memory(_previewBytes!,
                fit:    BoxFit.cover,
                width:  double.infinity,
                height: double.infinity)
            : _loadingGallery
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primary))
                : Center(
                    child: Text('Aucune image',
                        style: GoogleFonts.inter(
                            color: AppColors.textMuted))),
      ),
    );
  }
}