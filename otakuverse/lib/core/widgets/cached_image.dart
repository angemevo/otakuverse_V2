import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class CachedImage extends StatelessWidget {
  final String?    url;
  final double?    width;
  final double?    height;
  final BoxFit     fit;
  final Widget?    placeholder;
  final Widget?    errorWidget;
  final BorderRadius? borderRadius;

  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit          = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ URL null ou vide → errorWidget directement
    if (url == null || url!.isEmpty) {
      return _buildError();
    }

    Widget image = CachedNetworkImage(
      imageUrl:   url!,
      width:      width,
      height:     height,
      fit:        fit,
      // ✅ Placeholder pendant le chargement
      placeholder: (_, _) => placeholder ?? _buildPlaceholder(),
      // ✅ Widget si erreur
      errorWidget: (_, _, _) => errorWidget ?? _buildError(),
      // ✅ Durée de cache — 7 jours
      cacheKey: url,
    );

    // ✅ Arrondir si borderRadius fourni
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    return image;
  }

  Widget _buildPlaceholder() {
    return Container(
      width:  width,
      height: height,
      color:  AppColors.bgCard,
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color:       AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width:  width,
      height: height,
      color:  AppColors.bgCard,
      child: const Center(
        child: Icon(
          HeroiconsOutline.photo,
          color: AppColors.textMuted,
          size:  32,
        ),
      ),
    );
  }
}

// ─── AVATAR CACHED ───────────────────────────────────────────────────
// ✅ Variante spécifique pour les avatars circulaires
class CachedAvatar extends StatelessWidget {
  final String?  url;
  final double   radius;
  final String?  fallbackLetter;

  const CachedAvatar({
    super.key,
    required this.url,
    this.radius         = 20,
    this.fallbackLetter,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Pas d'URL → initiale
    if (url == null || url!.isEmpty) {
      return _buildFallback();
    }

    return CircleAvatar(
      radius:          radius,
      backgroundColor: AppColors.bgCard,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl:    url!,
          width:       radius * 2,
          height:      radius * 2,
          fit:         BoxFit.cover,
          placeholder: (_, _) => _buildFallback(),
          errorWidget: (_, _, _) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return CircleAvatar(
      radius:          radius,
      backgroundColor: AppColors.bgCard,
      child: fallbackLetter != null
          ? Text(
              fallbackLetter![0].toUpperCase(),
              style: TextStyle(
                color:      AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize:   radius * 0.7,
              ),
            )
          : Icon(
              Icons.person,
              color: AppColors.textPrimary,
              size:  radius,
            ),
    );
  }
}