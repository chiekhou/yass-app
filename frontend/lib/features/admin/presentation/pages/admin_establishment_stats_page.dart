import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/admin_stats_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/admin_drawer.dart';

class AdminEstablishmentStatsPage extends StatefulWidget {
  const AdminEstablishmentStatsPage({super.key});

  @override
  State<AdminEstablishmentStatsPage> createState() =>
      _AdminEstablishmentStatsPageState();
}

class _AdminEstablishmentStatsPageState
    extends State<AdminEstablishmentStatsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _repo = AdminRepository();

  String _statusFilter = 'all';
  EstablishmentStatsData? _data;
  bool _isLoading = true;
  String? _error;

  static const _chartColors = [
    Color(0xFF002FA7),
    Color(0xFF00B074),
    Color(0xFFFF6530),
    Color(0xFF9B59B6),
    Color(0xFFF39C12),
    Color(0xFFBDBDBD),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repo.getEstablishmentStats(status: _statusFilter);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      drawer: AdminDrawer(currentRoute: AppRoutes.adminEstablishmentStats),
      appBar: AppBar(
        title: const Text('Stats des établissements',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.scaffoldBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentOrange,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Par catégorie'),
            Tab(text: "Plus d'avis"),
            Tab(text: 'Meilleures notes'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGreen),
                  )
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildCategoryTab(),
                          _buildTopReviewedTab(),
                          _buildTopRatedTab(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  // ── Filter chips ──────────────────────────────────────────
  Widget _buildFilterBar() {
    final filters = [
      ('all', 'Tous'),
      ('active', 'Actifs'),
      ('pending', 'En attente'),
    ];
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Iconsax.filter, size: 16, color: AppColors.grey600),
          const SizedBox(width: 8),
          ...filters.map((f) {
            final selected = _statusFilter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (!selected) {
                    setState(() => _statusFilter = f.$1);
                    _loadStats();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.scaffoldBackground
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.scaffoldBackground
                          : AppColors.grey300,
                    ),
                  ),
                  child: Text(
                    f.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.grey700,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Tab 1 : Par catégorie ─────────────────────────────────
  Widget _buildCategoryTab() {
    final cats = _data!.byCategory;
    if (cats.isEmpty) return _buildEmpty('Aucune donnée par catégorie');

    final total = cats.fold(0, (s, e) => s + e.count);
    final top5 = cats.take(5).toList();
    final othersCount = cats.skip(5).fold(0, (s, e) => s + e.count);

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < top5.length; i++) {
      final pct = total > 0 ? top5[i].count / total * 100 : 0;
      sections.add(PieChartSectionData(
        color: _chartColors[i % _chartColors.length],
        value: top5[i].count.toDouble(),
        title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
        radius: 58,
      ));
    }
    if (othersCount > 0) {
      sections.add(PieChartSectionData(
        color: _chartColors[5],
        value: othersCount.toDouble(),
        title: '',
        radius: 58,
      ));
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primaryGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Donut chart ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 230,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(PieChartData(
                          sections: sections,
                          centerSpaceRadius: 62,
                          sectionsSpace: 3,
                          startDegreeOffset: -90,
                        )),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.scaffoldBackground),
                            ),
                            const Text('établissements',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.grey500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Légende top 5
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < top5.length; i++)
                        _legendItem(
                            _chartColors[i % _chartColors.length],
                            top5[i].categoryName,
                            top5[i].count),
                      if (othersCount > 0)
                        _legendItem(_chartColors[5], 'Autres', othersCount),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            // ── Liste complète ──
            const Text('Toutes les catégories',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: cats.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  final pct = total > 0 ? cat.count / total : 0.0;
                  final barColor =
                      _chartColors[i % (_chartColors.length - 1)];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(cat.categoryName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.grey800)),
                            ),
                            Text('${cat.count}',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.scaffoldBackground)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LayoutBuilder(builder: (ctx, box) {
                          return Stack(children: [
                            Container(
                                height: 6,
                                width: box.maxWidth,
                                decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius:
                                        BorderRadius.circular(3))),
                            Container(
                                height: 6,
                                width: box.maxWidth * pct,
                                decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius:
                                        BorderRadius.circular(3))),
                          ]);
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ($count)',
            style: const TextStyle(fontSize: 11, color: AppColors.grey700)),
      ],
    );
  }

  // ── Tab 2 : Plus d'avis ───────────────────────────────────
  Widget _buildTopReviewedTab() {
    final items = _data!.topReviewed;
    if (items.isEmpty) return _buildEmpty('Aucun avis enregistré');
    final maxReviews = items.first.totalReviews;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.paddingM),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildRankCard(
          rank: i + 1,
          item: items[i],
          barValue:
              maxReviews > 0 ? items[i].totalReviews / maxReviews : 0,
          barColor: AppColors.primaryBlue,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.message_text, size: 14,
                  color: AppColors.primaryBlue),
              const SizedBox(width: 4),
              Text('${items[i].totalReviews}',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryBlue)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3 : Meilleures notes ──────────────────────────────
  Widget _buildTopRatedTab() {
    final items = _data!.topRated;
    if (items.isEmpty) return _buildEmpty('Aucune note enregistrée');

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppDimens.paddingM),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _buildRankCard(
          rank: i + 1,
          item: items[i],
          barValue: items[i].averageRating / 5,
          barColor: AppColors.accentOrange,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, size: 16,
                  color: AppColors.accentOrange),
              const SizedBox(width: 2),
              Text(items[i].averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentOrange)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard({
    required int rank,
    required EstablishmentRankItem item,
    required double barValue,
    required Color barColor,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Rank badge
            SizedBox(
              width: 36,
              child: rank <= 3
                  ? Text(
                      rank == 1
                          ? '🥇'
                          : rank == 2
                              ? '🥈'
                              : '🥉',
                      style: const TextStyle(fontSize: 24),
                      textAlign: TextAlign.center,
                    )
                  : Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey600),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Name + category + bar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.categoryName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.categoryName,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.grey500),
                    ),
                  ],
                  const SizedBox(height: 6),
                  LayoutBuilder(builder: (ctx, box) {
                    return Stack(children: [
                      Container(
                          height: 4,
                          width: box.maxWidth,
                          decoration: BoxDecoration(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(2))),
                      Container(
                          height: 4,
                          width: box.maxWidth * barValue.clamp(0.0, 1.0),
                          decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(2))),
                    ]);
                  }),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          const Text('Erreur de chargement',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.grey800)),
          const SizedBox(height: 8),
          TextButton(
              onPressed: _loadStats,
              child: const Text('Réessayer',
                  style: TextStyle(color: AppColors.primaryGreen))),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Iconsax.chart_2, size: 48, color: AppColors.grey300),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: AppColors.grey500, fontSize: 14)),
        ],
      ),
    );
  }
}
