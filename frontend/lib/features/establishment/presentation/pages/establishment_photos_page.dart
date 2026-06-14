import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/establishment_model.dart';
import '../../data/models/photo_category.dart';

class EstablishmentPhotosPage extends StatefulWidget {
  final String establishmentName;
  final List<PhotoItem> photos;

  const EstablishmentPhotosPage({
    super.key,
    required this.establishmentName,
    required this.photos,
  });

  @override
  State<EstablishmentPhotosPage> createState() =>
      _EstablishmentPhotosPageState();
}

class _EstablishmentPhotosPageState extends State<EstablishmentPhotosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // "tout" = tab synthétique regroupant tout
  static const _allKey = 'tout';

  late List<String> _activeTabs; // clés de catégories présentes

  @override
  void initState() {
    super.initState();
    _buildTabs();
  }

  void _buildTabs() {
    // Catégories effectivement présentes dans les photos
    final usedKeys = widget.photos.map((p) => p.category).toSet();

    // Ordre : "tout" en premier, puis l'ordre déclaré dans kPhotoCategories
    _activeTabs = [
      _allKey,
      ...kPhotoCategories
          .map((c) => c.key)
          .where((k) => usedKeys.contains(k)),
    ];

    _tabController = TabController(length: _activeTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PhotoItem> _photosForTab(String key) {
    if (key == _allKey) return widget.photos;
    return widget.photos.where((p) => p.category == key).toList();
  }

  String _tabLabel(String key) {
    if (key == _allKey) return 'Tout (${widget.photos.length})';
    final cat = kPhotoCategories.firstWhere(
      (c) => c.key == key,
      orElse: () =>
          const PhotoCategory(key: 'autres', label: 'Autres', icon: Iconsax.more_circle),
    );
    final count = widget.photos.where((p) => p.category == key).length;
    return '${cat.label} ($count)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kleinBlue,
      appBar: AppBar(
        backgroundColor: AppColors.kleinBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              widget.establishmentName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        bottom: widget.photos.isEmpty
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.accentGreen,
                    unselectedLabelColor: Colors.white60,
                    indicatorColor: AppColors.accentGreen,
                    indicatorWeight: 2.5,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    unselectedLabelStyle:
                        const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                    tabs: _activeTabs
                        .map((key) => Tab(text: _tabLabel(key)))
                        .toList(),
                  ),
                ),
              ),
      ),
      body: widget.photos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.gallery_slash,
                      size: 64, color: AppColors.white),
                  SizedBox(height: 16),
                  Text(
                    'Aucune photo disponible',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: _activeTabs.map((key) {
                final photos = _photosForTab(key);
                return _PhotoGrid(
                  photos: photos,
                  onTap: (index) => _openFullScreen(photos, index),
                );
              }).toList(),
            ),
    );
  }

  void _openFullScreen(List<PhotoItem> photos, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, _) => _FullScreenGallery(
          photos: photos,
          initialIndex: index,
          establishmentName: widget.establishmentName,
        ),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

// ==================== GRILLE ====================

class _PhotoGrid extends StatelessWidget {
  final List<PhotoItem> photos;
  final void Function(int index) onTap;

  const _PhotoGrid({required this.photos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1.0,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final item = photos[index];
        return GestureDetector(
          onTap: () => onTap(index),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.isVideo)
                Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Iconsax.play_circle,
                        color: Colors.white, size: 40),
                  ),
                )
              else
                Image.network(
                  item.url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.grey200,
                    child: const Icon(Iconsax.image,
                        color: AppColors.grey400, size: 32),
                  ),
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: AppColors.grey100,
                      child: const Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.accentGreen),
                      ),
                    );
                  },
                ),
              // Badge catégorie en haut à droite
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    item.categoryLabel,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Icône vidéo en bas à gauche
              if (item.isVideo)
                const Positioned(
                  bottom: 6,
                  left: 6,
                  child: Icon(Iconsax.video, color: Colors.white70, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==================== VISIONNEUSE PLEIN ÉCRAN ====================

class _FullScreenGallery extends StatefulWidget {
  final List<PhotoItem> photos;
  final int initialIndex;
  final String establishmentName;

  const _FullScreenGallery({
    required this.photos,
    required this.initialIndex,
    required this.establishmentName,
  });

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

// ==================== LECTEUR VIDÉO ====================

class _VideoPlayerItem extends StatefulWidget {
  final String url;
  const _VideoPlayerItem({required this.url});

  @override
  State<_VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<_VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              if (!_controller.value.isPlaying)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 48),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== VISIONNEUSE PLEIN ÉCRAN ====================

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.photos[_currentIndex];
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_currentIndex + 1} / ${widget.photos.length}',
              style:
                  const TextStyle(color: Colors.white, fontSize: 15),
            ),
            Text(
              current.categoryLabel,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final item = widget.photos[index];
          if (item.isVideo) {
            return _VideoPlayerItem(url: item.url);
          }
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                item.url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Iconsax.image,
                    color: Colors.white54,
                    size: 64),
              ),
            ),
          );
        },
      ),
    );
  }
}
