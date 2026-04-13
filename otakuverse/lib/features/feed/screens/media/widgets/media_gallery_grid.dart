import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

/// Barre d'outils au-dessus de la grille (album + sélection multiple).
class MediaGalleryToolbar extends StatelessWidget {
  final bool         multiSelect;
  final VoidCallback onToggleMultiSelect;

  const MediaGalleryToolbar({
    super.key,
    required this.multiSelect,
    required this.onToggleMultiSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
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
          onTap: onToggleMultiSelect,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: multiSelect
                  ? AppColors.primary
                  : const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Icon(
                multiSelect ? Icons.check_circle : Icons.copy_outlined,
                color: Colors.white, size: 16,
              ),
              const SizedBox(width: 6),
              Text('Sélection multiple',
                  style: GoogleFonts.inter(
                    color:      Colors.white,
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                  )),
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Grille de médias avec support de sélection multiple.
class MediaGalleryGrid extends StatelessWidget {
  final List<AssetEntity> assets;
  final bool              loading;
  final bool              multiSelect;
  final AssetEntity?      previewAsset;
  final List<AssetEntity> selectedAssets;
  final void Function(AssetEntity) onTap;

  const MediaGalleryGrid({
    super.key,
    required this.assets,
    required this.loading,
    required this.multiSelect,
    required this.previewAsset,
    required this.selectedAssets,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (assets.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.photo_library_outlined,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('Aucun média disponible',
              style: GoogleFonts.inter(color: AppColors.textMuted)),
        ]),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
      ),
      itemCount: assets.length,
      itemBuilder: (_, i) {
        final asset      = assets[i];
        final isPreview  = previewAsset == asset;
        final selIndex   = selectedAssets.indexOf(asset);
        final isSelected = selIndex != -1;

        return GestureDetector(
          onTap: () => onTap(asset),
          child: Stack(fit: StackFit.expand, children: [
            AssetThumbnail(asset: asset),
            if (isPreview && !multiSelect)
              Container(color: Colors.white.withValues(alpha: 0.15)),
            if (multiSelect && !isSelected)
              Container(color: Colors.black.withValues(alpha: 0.35)),
            if (multiSelect)
              Positioned(
                top: 6, right: 6,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    shape:  BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
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
          ]),
        );
      },
    );
  }
}

// ─── Thumbnail individuel ─────────────────────────────────────────────

class AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;
  const AssetThumbnail({super.key, required this.asset});

  @override
  State<AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<AssetThumbnail> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
        const ThumbnailSize(200, 200));
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) return Container(color: const Color(0xFF1A1A1A));
    return Image.memory(_bytes!, fit: BoxFit.cover);
  }
}