import 'package:flutter/material.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../app_router.dart';
import '../../../establishment/data/models/establishment_model.dart';
import '../../../reviews/data/models/review_model.dart';
import '../../data/repositories/partner_repository.dart';

class PartnerEstablishmentDetailsPage extends StatefulWidget {
  final String establishmentId;
  final String? paymentResult; // 'featured_success' | 'featured_failed' | null

  const PartnerEstablishmentDetailsPage({
    super.key,
    required this.establishmentId,
    this.paymentResult,
  });

  @override
  State<PartnerEstablishmentDetailsPage> createState() =>
      _PartnerEstablishmentDetailsPageState();
}

class _PartnerEstablishmentDetailsPageState
    extends State<PartnerEstablishmentDetailsPage> {
  final _repository = PartnerRepository();
  bool _isLoading = true;
  String? _errorMessage;
  Establishment? _establishment;
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  bool _paymentSubmitted = false;
  bool _eliteOnly = false;
  int? _ratingFilter;

  @override
  void initState() {
    super.initState();
    _loadEstablishment();
    if (widget.paymentResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.paymentResult == 'featured_success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.featuredActivated),
              backgroundColor: Colors.green,
            ),
          );
        } else if (widget.paymentResult == 'featured_failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.paymentFailed),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  Future<void> _loadEstablishment() async {
    try {
      final establishment =
          await _repository.getEstablishmentById(widget.establishmentId);
      setState(() {
        _establishment = establishment;
        _isLoading = false;
      });
      _loadReviews();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isLoadingReviews = true);
    try {
      final data = await _repository.getEstablishmentReviews(
        widget.establishmentId,
        eliteOnly: _eliteOnly,
        rating: _ratingFilter,
      );
      setState(() {
        _reviews = data.reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      setState(() => _isLoadingReviews = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.warning_2, size: 64, color: AppColors.error),
            const SizedBox(height: AppDimens.paddingM),
            Text(
              context.l10n.loadingError,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimens.paddingL),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadEstablishment();
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final establishment = _establishment!;

    return CustomScrollView(
      slivers: [
        // App Bar with Cover Image
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.scaffoldBackground,
          foregroundColor: AppColors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (establishment.coverImage != null)
                  Image.network(
                    establishment.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
                      child: const Icon(
                        Iconsax.building,
                        size: 64,
                        color: AppColors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    child: const Icon(
                      Iconsax.building,
                      size: 64,
                      color: AppColors.white,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Iconsax.edit),
              onPressed: () => context.push(
                AppRoutes.partnerEstablishmentEdit
                    .replaceFirst(':id', establishment.id),
              ),
            ),
          ],
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Stats Card
              _buildStatsCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Featured Card
              _buildFeaturedCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Status Card
              _buildStatusCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Description Card
              if (establishment.description != null &&
                  establishment.description!.isNotEmpty)
                _buildDescriptionCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Contact Card
              _buildContactCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Location Card
              _buildLocationCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Social Media Card
              if (_hasSocialMedia(establishment))
                _buildSocialMediaCard(establishment),

              const SizedBox(height: AppDimens.paddingM),

              // Reviews Card
              _buildReviewsCard(),

              const SizedBox(height: AppDimens.paddingXL),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.all(AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.radiusM),
              color: AppColors.grey100,
              image: establishment.logo != null
                  ? DecorationImage(
                      image: NetworkImage(establishment.logo!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: establishment.logo == null
                ? const Icon(Iconsax.building,
                    color: AppColors.grey400, size: 32)
                : null,
          ),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        establishment.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.scaffoldBackground),
                      ),
                    ),
                    if (establishment.isVerified)
                      const Icon(
                        Iconsax.verify5,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                  ],
                ),
                if (establishment.category != null) ...[
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    establishment.category!.localizedName(
                        Localizations.localeOf(context).languageCode),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                ],
                if (establishment.priceRange != null) ...[
                  const SizedBox(height: AppDimens.paddingXS),
                  Text(
                    establishment.priceRangeDisplay,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mise à la une ──────────────────────────────────────────────────────────

  static const _featuredPlans = [
    {'key': 'featured_7',  'days': '7',  'price': '500 DZD'},
    {'key': 'featured_15', 'days': '15', 'price': '800 DZD'},
    {'key': 'featured_30', 'days': '30', 'price': '1 400 DZD'},
  ];

  Widget _buildFeaturedCard(Establishment establishment) {
    final isActive = establishment.isFeatured;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFFFFF8E1), const Color(0xFFFFF3CD)]
              : [AppColors.white, AppColors.white],
        ),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: isActive ? const Color(0xFFFFCA28) : AppColors.grey200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.star5, color: Color(0xFFFFCA28), size: 20),
                const SizedBox(width: 8),
                Text(
                  context.l10n.featuredTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.scaffoldBackground,
                      ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isActive ? const Color(0xFFFFCA28) : AppColors.grey200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? context.l10n.activeLabel : context.l10n.inactiveLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.brown[800] : AppColors.grey600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.paddingS),
            Text(
              isActive
                  ? context.l10n.featuredActiveDesc
                  : context.l10n.featuredInactiveDesc,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.grey600, height: 1.4),
            ),
            if (!isActive) ...[
              const SizedBox(height: AppDimens.paddingM),
              if (establishment.partnerSubscriptionPlan != 'gold')
                // Bloqué — réservé au plan Gold
                GestureDetector(
                  onTap: () => context.push(AppRoutes.partnerSubscription),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                          color:
                              const Color(0xFFFFCA28).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_rounded,
                            size: 15, color: Color(0xFFFFCA28)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.reservedForGold,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF795548),
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          context.l10n.upgradeToGold,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF795548),
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_paymentSubmitted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Iconsax.clock, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.paymentPendingAdmin,
                          style: const TextStyle(fontSize: 13, color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                )
              /* else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showFeaturedPaymentSheet(establishment),
                    icon: const Icon(Iconsax.star, size: 16),
                    label: Text(context.l10n.featuredTitle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCA28),
                      foregroundColor: Colors.brown[900],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      ),
                    ),
                  ),
                ), */
            ],
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showFeaturedPaymentSheet(Establishment establishment) {
    String selectedPlan = 'featured_7';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: AppDimens.paddingL,
            right: AppDimens.paddingL,
            top: AppDimens.paddingL,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDimens.paddingXL,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.paddingM),
              Row(
                children: [
                  const Icon(Iconsax.star5, color: Color(0xFFFFCA28), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.featuredTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.paddingS),
              Text(
                context.l10n.chooseDuration,
                style: const TextStyle(fontSize: 13, color: AppColors.grey500),
              ),
              const SizedBox(height: AppDimens.paddingM),
              // Plan selector
              ...(_featuredPlans.map((p) {
                final isSelected = selectedPlan == p['key'];
                return GestureDetector(
                  onTap: () => setSheetState(() => selectedPlan = p['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.08)
                          : AppColors.grey50,
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.grey200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? AppColors.primaryGreen
                              : AppColors.grey400,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l10n.featuredDaysLabel(int.parse(p['days']!)),
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          p['price']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? AppColors.primaryGreen
                                : AppColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              })),
              const SizedBox(height: AppDimens.paddingM),
              const Divider(),
              const SizedBox(height: AppDimens.paddingM),
              // Paiement en ligne
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _payFeaturedOnline(ctx, establishment.id, selectedPlan),
                  icon: const Icon(Iconsax.card, size: 18),
                  label: Text(context.l10n.payOnline),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.paddingS),
              // Virement bancaire
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _payFeaturedManual(ctx, establishment.id, selectedPlan),
                  icon: const Icon(Iconsax.bank, size: 18),
                  label: Text(context.l10n.bankTransfer),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: const BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.paddingS),
              // Paiement en espèces
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      _payFeaturedCash(ctx, establishment.id, selectedPlan),
                  icon: const Icon(Iconsax.money, size: 18),
                  label: Text(context.l10n.cashPayment),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.grey700,
                    side: const BorderSide(color: AppColors.grey400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusM),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _payFeaturedOnline(
      BuildContext sheetCtx, String establishmentId, String plan) async {
    Navigator.pop(sheetCtx);
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.partnerFeaturedCheckout(establishmentId),
        data: {'plan': plan},
      );
      final url = response.data['data']['checkout_url'] as String?;
      if (url != null && mounted) {
        setState(() => _paymentSubmitted = true);
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _payFeaturedManual(
      BuildContext sheetCtx, String establishmentId, String plan) async {
    Navigator.pop(sheetCtx);
    try {
      final response = await ApiClient.instance.post(
        ApiConfig.partnerFeaturedManual(establishmentId),
        data: {'plan': plan, 'payment_method': 'manual'},
      );
      final bankDetails = response.data['data']['bank_details'];
      if (mounted) {
        setState(() => _paymentSubmitted = true);
        _showBankDetailsDialog(bankDetails);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _payFeaturedCash(
      BuildContext sheetCtx, String establishmentId, String plan) async {
    Navigator.pop(sheetCtx);
    try {
      await ApiClient.instance.post(
        ApiConfig.partnerFeaturedManual(establishmentId),
        data: {'plan': plan, 'payment_method': 'cash'},
      );
      if (mounted) {
        setState(() => _paymentSubmitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cashRequestRegistered),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showBankDetailsDialog(dynamic bankDetails) {
    final ccp = bankDetails?['ccp'] ?? '';
    final rib = bankDetails?['rib'] ?? '';
    final name = bankDetails?['accountName'] ?? '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.radiusL)),
        title: Row(
          children: [
            const Icon(Iconsax.bank, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(context.l10n.bankDetailsTitle),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.bankTransferInstruction,
              style: const TextStyle(fontSize: 13, color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimens.paddingM),
            _bankRow('CCP', ccp),
            _bankRow('RIB', rib),
            _bankRow(context.l10n.accountHolder, name),
            const SizedBox(height: AppDimens.paddingS),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.info_circle, size: 14, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.l10n.featuredActivationPending,
                      style: const TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label : ',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.grey700)),
          Expanded(
              child: Text(value,
                  style: const TextStyle(color: AppColors.grey800))),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Iconsax.eye,
            value: establishment.totalViews.toString(),
            label: context.l10n.views,
          ),
          _buildStatItem(
            icon: Iconsax.heart,
            value: establishment.totalFavorites.toString(),
            label: context.l10n.favorites,
          ),
          _buildStatItem(
            icon: Iconsax.star,
            value: establishment.displayRating,
            label: '(${establishment.totalReviews})',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryGreen, size: 24),
        const SizedBox(height: AppDimens.paddingXS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.scaffoldBackground,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.scaffoldBackground,
              ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(Establishment establishment) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (establishment.status) {
      case 'active':
        statusColor = AppColors.success;
        statusLabel = context.l10n.statusActive;
        statusIcon = Iconsax.tick_circle;
        break;
      case 'pending':
        statusColor = AppColors.warning;
        statusLabel = context.l10n.pendingValidation;
        statusIcon = Iconsax.clock;
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = context.l10n.statusRejected;
        statusIcon = Iconsax.close_circle;
        break;
      case 'inactive':
        statusColor = AppColors.grey500;
        statusLabel = context.l10n.statusInactive;
        statusIcon = Iconsax.minus_cirlce;
        break;
      default:
        statusColor = AppColors.grey500;
        statusLabel = establishment.status;
        statusIcon = Iconsax.info_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: AppDimens.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.statusLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.grey600,
                      ),
                ),
                Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.descriptionLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.scaffoldBackground,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            establishment.description!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.contact,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.scaffoldBackground,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          _buildContactRow(Iconsax.call, context.l10n.phone, establishment.phone),
          if (establishment.phoneSecondary != null &&
              establishment.phoneSecondary!.isNotEmpty)
            _buildContactRow(
                Iconsax.call, context.l10n.phoneSecondary, establishment.phoneSecondary!),
          if (establishment.whatsapp != null &&
              establishment.whatsapp!.isNotEmpty)
            _buildContactRow(
                Iconsax.message, context.l10n.whatsapp, establishment.whatsapp!),
          if (establishment.email != null && establishment.email!.isNotEmpty)
            _buildContactRow(Iconsax.sms, context.l10n.email, establishment.email!),
          if (establishment.website != null &&
              establishment.website!.isNotEmpty)
            _buildContactRow(
                Iconsax.global, context.l10n.websiteLabel, establishment.website!),
          ...[
            const SizedBox(height: AppDimens.paddingM),
            Text(
              context.l10n.interlocutor,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey700,
                  ),
            ),
            const SizedBox(height: AppDimens.paddingS),
            _buildContactRow(
              Iconsax.user,
              context.l10n.firstName,
              establishment.contactFirstName ?? context.l10n.notProvided,
            ),
            _buildContactRow(
              Iconsax.user,
              context.l10n.lastName,
              establishment.contactLastName ?? context.l10n.notProvided,
            ),
            _buildContactRow(
              Iconsax.briefcase,
              context.l10n.positionLabel,
              establishment.contactPosition ?? context.l10n.notProvided,
            ),
            _buildContactRow(
              Iconsax.call,
              context.l10n.phone,
              establishment.contactPhone ?? context.l10n.notProvided,
            ),
            _buildContactRow(
              Iconsax.sms,
              context.l10n.email,
              establishment.contactEmail ?? context.l10n.notProvided,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimens.paddingS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey500, size: 18),
          const SizedBox(width: AppDimens.paddingS),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey500,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.location,
                  color: AppColors.scaffoldBackground, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.location,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.scaffoldBackground,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          Text(
            establishment.address,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey700,
                ),
          ),
          if (establishment.wilaya != null ||
              establishment.commune != null) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              [
                if (establishment.commune != null) establishment.commune!.name,
                if (establishment.wilaya != null) establishment.wilaya!.name,
              ].join(', '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ],
          if (establishment.hasCoordinates) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              '${context.l10n.coordinates}: ${establishment.latitude}, ${establishment.longitude}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey500,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  bool _hasSocialMedia(Establishment establishment) {
    return (establishment.facebook != null &&
            establishment.facebook!.isNotEmpty) ||
        (establishment.instagram != null &&
            establishment.instagram!.isNotEmpty) ||
        (establishment.tiktok != null && establishment.tiktok!.isNotEmpty);
  }

  Widget _ratingChip(int? value, String label) {
    final isSelected = _ratingFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _ratingFilter = value);
        _loadReviews();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryGreen : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.grey600,
          ),
        ),
      ),
    );
  }

  Widget _buildReviewsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.message_text,
                  color: AppColors.scaffoldBackground, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.customerReviewsCount(_reviews.length),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.scaffoldBackground,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingS),
          const Divider(height: 1),
          const SizedBox(height: AppDimens.paddingS),
          // Elite filter
          GestureDetector(
            onTap: () {
              setState(() => _eliteOnly = !_eliteOnly);
              _loadReviews();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _eliteOnly ? const Color(0xFFFFD700) : AppColors.grey100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      _eliteOnly ? const Color(0xFFFFD700) : AppColors.grey300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Iconsax.medal_star,
                      size: 14,
                      color: _eliteOnly ? Colors.white : AppColors.grey500),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.eliteOnly,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _eliteOnly ? Colors.white : AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.paddingS),
          // Rating filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ratingChip(null, context.l10n.allFilter),
                const SizedBox(width: 6),
                for (int r = 5; r >= 1; r--) ...[
                  _ratingChip(r, '$r ★'),
                  if (r > 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimens.paddingM),
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimens.paddingL),
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
            )
          else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimens.paddingL),
                child: Column(
                  children: [
                    const Icon(Iconsax.message_text,
                        size: 40, color: AppColors.grey300),
                    const SizedBox(height: AppDimens.paddingS),
                    Text(
                      context.l10n.noReviews,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.grey500,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
              _reviews.length > 5 ? 5 : _reviews.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  bottom:
                      index < (_reviews.length > 5 ? 4 : _reviews.length - 1)
                          ? AppDimens.paddingM
                          : 0,
                ),
                child: _buildPartnerReviewCard(_reviews[index]),
              ),
            ),
          if (_reviews.length > 5) ...[
            const SizedBox(height: AppDimens.paddingM),
            Center(
              child: TextButton(
                onPressed: () {
                  context.push(
                    '/establishment/${widget.establishmentId}/reviews',
                    extra: {
                      'establishmentName': _establishment?.name,
                    },
                  );
                },
                child: Text(
                  context.l10n.seeAllReviewsCount(_reviews.length),
                  style: const TextStyle(color: AppColors.primaryGreen),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartnerReviewCard(Review review) {
    final userName = review.user != null
        ? '${review.user!.firstName} ${review.user!.lastName}'
        : context.l10n.anonymous;
    final initials =
        review.user != null ? review.user!.firstName[0].toUpperCase() : 'U';
    final timeAgo = _formatTimeAgo(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.greenSurface,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppDimens.paddingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Iconsax.star5 : Iconsax.star,
                            size: 12,
                            color: i < review.rating
                                ? const Color(0xFFFFCA28)
                                : AppColors.grey300,
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingXS),
                        Text(
                          timeAgo,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.grey500, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Comment
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: AppDimens.paddingS),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey700,
                    height: 1.4,
                  ),
            ),
          ],
          // Partner reply
          if (review.hasPartnerReply) ...[
            const SizedBox(height: AppDimens.paddingS),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.greenSurface,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.message_text_1,
                      size: 14, color: AppColors.primaryGreen),
                  const SizedBox(width: AppDimens.paddingXS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.yourReplyLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.partnerReply!,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.grey700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Reply button
            const SizedBox(height: AppDimens.paddingS),
            SizedBox(
              height: 30,
              child: OutlinedButton.icon(
                onPressed: () => _showReplyDialog(review),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(color: AppColors.primaryGreen),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                icon: const Icon(Iconsax.message, size: 14),
                label: Text(context.l10n.replyButton),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(Review review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusL),
        ),
        title: Text(context.l10n.replyReviewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show the review
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingS),
              decoration: BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.circular(AppDimens.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < review.rating ? Iconsax.star5 : Iconsax.star,
                        size: 12,
                        color: i < review.rating
                            ? const Color(0xFFFFCA28)
                            : AppColors.grey300,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.grey600,
                        ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.paddingM),
            TextField(
              controller: controller,
              maxLines: 4,
              maxLength: 1000,
              decoration: InputDecoration(
                hintText: context.l10n.responseHintLong,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().length >= 10) {
                Navigator.pop(ctx);
                try {
                  await _repository.replyToReview(
                    review.id,
                    controller.text.trim(),
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.replySent),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    _loadReviews();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(e.toString()),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: Text(context.l10n.send),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return context.l10n.timeAgoYears(difference.inDays ~/ 365);
    } else if (difference.inDays > 30) {
      return context.l10n.timeAgoMonths(difference.inDays ~/ 30);
    } else if (difference.inDays > 0) {
      return context.l10n.timeAgoDays(difference.inDays);
    } else if (difference.inHours > 0) {
      return context.l10n.timeAgoHours(difference.inHours);
    } else {
      return context.l10n.timeAgoNow;
    }
  }

  Widget _buildSocialMediaCard(Establishment establishment) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimens.paddingM),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.link, color: AppColors.grey600, size: 20),
              const SizedBox(width: AppDimens.paddingS),
              Text(
                context.l10n.socialNetworks,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.paddingM),
          if (establishment.facebook != null &&
              establishment.facebook!.isNotEmpty)
            _buildContactRow(Iconsax.link, 'Facebook', establishment.facebook!),
          if (establishment.instagram != null &&
              establishment.instagram!.isNotEmpty)
            _buildContactRow(
                Iconsax.instagram, 'Instagram', establishment.instagram!),
          if (establishment.tiktok != null && establishment.tiktok!.isNotEmpty)
            _buildContactRow(Iconsax.video, 'TikTok', establishment.tiktok!),
        ],
      ),
    );
  }
}
