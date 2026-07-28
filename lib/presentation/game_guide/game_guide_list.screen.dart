import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:koto_blue_sharks/app/data/models/game_guide/game_guide_post.dart';
import 'package:koto_blue_sharks/infrastructure/navigation/routes.dart';
import 'package:koto_blue_sharks/presentation/game_guide/controllers/game_guide.controller.dart';
import 'package:koto_blue_sharks/utils/app_color.dart';

class GameGuideListScreen extends StatelessWidget {
  const GameGuideListScreen({super.key});

  GameGuideController _controller() {
    if (Get.isRegistered<GameGuideController>()) {
      return Get.find<GameGuideController>();
    }
    return Get.put(GameGuideController());
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: BrandColor.hover,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(
          'ホームゲームの楽しみ方',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              tooltip: '記事一覧の端末保存',
              onPressed: () => _showStorageSettings(context, controller),
              icon: Icon(
                controller.saveArticlesEnabled.value
                    ? Icons.offline_pin
                    : Icons.offline_pin_outlined,
              ),
            ),
          ),
          IconButton(
            tooltip: '絞り込み',
            onPressed: () => _showFilters(context, controller),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Obx(
        () => _buildBody(context, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    GameGuideController controller,
  ) {
    if (controller.isLoading.value && controller.guides.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage.value != null && controller.guides.isEmpty) {
      return _ErrorState(
        message: controller.errorMessage.value!,
        onRetry: controller.loadInitial,
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refreshGuides,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          _GuideIntroduction(
            hasActiveFilters: controller.hasActiveFilters,
            onFilterTap: () => _showFilters(context, controller),
          ),
          if (controller.showingCachedData.value)
            _CachedDataBanner(cachedAt: controller.cachedAt.value),
          if (controller.errorMessage.value != null &&
              controller.guides.isNotEmpty)
            _InlineError(
              message: controller.errorMessage.value!,
              onRetry: controller.refreshGuides,
            ),
          if (controller.visibleGuides.isEmpty)
            _EmptyState(
              isFiltered: controller.hasActiveFilters,
              onClearFilters: controller.clearFilters,
            )
          else
            ...controller.visibleGuides.map(
              (post) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: _GameGuideCard(
                  post: post,
                  isOpening: controller.openingGuideId.value == post.id,
                  onTap: () => _openGuide(controller, post),
                ),
              ),
            ),
          if (controller.visibleGuides.isNotEmpty && controller.hasMore.value)
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: OutlinedButton(
                onPressed:
                    controller.isLoadingMore.value ? null : controller.loadMore,
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.fromHeight(48.h),
                  foregroundColor: BrandColor.main,
                ),
                child: controller.isLoadingMore.value
                    ? SizedBox(
                        width: 20.w,
                        height: 20.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('もっと見る'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openGuide(
    GameGuideController controller,
    GameGuidePost post,
  ) async {
    if (controller.openingGuideId.value != null) return;

    controller.openingGuideId.value = post.id;
    try {
      await Get.toNamed(
        Routes.GAME_GUIDE_DETAIL,
        arguments: post,
      );
    } finally {
      controller.openingGuideId.value = null;
    }
  }

  Future<void> _showStorageSettings(
    BuildContext context,
    GameGuideController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 24.h),
            child: Obx(
              () => SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  '記事一覧を端末に保存',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'ONの場合のみ、最後に表示した記事一覧を保存します。',
                ),
                value: controller.saveArticlesEnabled.value,
                onChanged: controller.setSaveArticlesEnabled,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFilters(
    BuildContext context,
    GameGuideController controller,
  ) async {
    var season = controller.selectedSeason.value;
    var location = controller.selectedLocation.value;
    var status = controller.selectedStatus.value;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20.w,
                  0,
                  20.w,
                  MediaQuery.of(context).viewInsets.bottom + 24.h,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '記事を絞り込む',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '絞り込み軸は仮実装です。WordPressの項目が設定されている場合に選択できます。',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: TextColor.secondary,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _FilterDropdown(
                      label: 'シーズン',
                      value: season,
                      options: controller.seasons,
                      onChanged: (value) => setState(() => season = value),
                    ),
                    SizedBox(height: 12.h),
                    _FilterDropdown(
                      label: '開催地',
                      value: location,
                      options: controller.locations,
                      onChanged: (value) => setState(() => location = value),
                    ),
                    SizedBox(height: 12.h),
                    _FilterDropdown(
                      label: '開催状態',
                      value: status,
                      options: controller.statuses,
                      onChanged: (value) => setState(() => status = value),
                    ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.applyFilters(
                            season: season,
                            location: location,
                            status: status,
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColor.hover,
                          foregroundColor: Colors.white,
                          minimumSize: Size.fromHeight(48.h),
                        ),
                        child: const Text('この条件で表示'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          controller.clearFilters();
                          Navigator.of(context).pop();
                        },
                        child: const Text('条件をクリア'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _GuideIntroduction extends StatelessWidget {
  const _GuideIntroduction({
    required this.hasActiveFilters,
    required this.onFilterTap,
  });

  final bool hasActiveFilters;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '観戦前に知りたいこと',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: TextColor.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '記事を選ぶとアプリ内で詳細を確認できます。',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: TextColor.secondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onFilterTap,
            icon: Icon(
              Icons.tune,
              size: 18.w,
            ),
            label: Text(hasActiveFilters ? '条件あり' : '絞り込み'),
          ),
        ],
      ),
    );
  }
}

class _GameGuideCard extends StatelessWidget {
  const _GameGuideCard({
    required this.post,
    required this.isOpening,
    required this.onTap,
  });

  final GameGuidePost post;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: isOpening ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: BorderColor.primary),
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 104.w,
                  height: 78.h,
                  child: post.thumbnailUrl == null
                      ? _thumbnailPlaceholder()
                      : CachedNetworkImage(
                          imageUrl: post.thumbnailUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _thumbnailPlaceholder(),
                          errorWidget: (_, __, ___) => _thumbnailPlaceholder(),
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: TextColor.primary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _formatDate(post.publishedAt),
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: TextColor.secondary,
                      ),
                    ),
                    if (isOpening) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          SizedBox(
                            width: 14.w,
                            height: 14.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '記事を開いています',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: BrandColor.hover,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: TextColor.disabled,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return ColoredBox(
      color: BrandColor.surface,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: TextColor.disabled,
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '未定';
    return DateFormat('yyyy/MM/dd HH:mm:ss').format(value.toLocal());
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      value: options.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        helperText: options.isEmpty ? 'WordPressフィールド未設定' : null,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('すべて'),
        ),
        ...options.map(
          (option) => DropdownMenuItem<String?>(
            value: option,
            child: Text(option),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _CachedDataBanner extends StatelessWidget {
  const _CachedDataBanner({required this.cachedAt});

  final DateTime? cachedAt;

  @override
  Widget build(BuildContext context) {
    final timestamp = cachedAt == null
        ? ''
        : '（${DateFormat('yyyy/MM/dd HH:mm').format(cachedAt!.toLocal())}）';
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: WarningColor.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: WarningColor.border),
      ),
      child: Text(
        'オフライン：保存済みの記事一覧を表示しています$timestamp',
        style: TextStyle(
          fontSize: 12.sp,
          color: WarningColor.hover,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: DangerColor.surface,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: DangerColor.main,
                fontSize: 12.sp,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('再読み込み'),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isFiltered,
    required this.onClearFilters,
  });

  final bool isFiltered;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 80.h),
      child: Column(
        children: [
          Icon(
            Icons.article_outlined,
            size: 48.w,
            color: TextColor.disabled,
          ),
          SizedBox(height: 16.h),
          Text(
            isFiltered ? '条件に一致する記事がありません' : '現在公開記事がありません',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (isFiltered)
            TextButton(
              onPressed: onClearFilters,
              child: const Text('条件をクリア'),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.w,
              color: DangerColor.main,
            ),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('再読み込み'),
            ),
          ],
        ),
      ),
    );
  }
}
