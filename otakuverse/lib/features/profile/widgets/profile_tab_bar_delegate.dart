import 'package:flutter/material.dart';
import 'package:otakuverse/core/constants/app_colors.dart';

class ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const ProfileTabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset,
          bool overlapsContent) =>
      Container(color: AppColors.bgPrimary, child: tabBar);

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate _) => false;
}