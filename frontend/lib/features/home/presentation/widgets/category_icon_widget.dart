import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// ── Données d'une icône de catégorie ──────────────────────────────────────────
class _CatIcon {
  final IconData main;
  final IconData accent;

  const _CatIcon(this.main, this.accent);
}

// ── Mapping slug → icônes ─────────────────────────────────────────────────────
const Map<String, _CatIcon> _iconMap = {
  // Existantes
  'restaurants':               _CatIcon(Iconsax.coffee,       Icons.restaurant_rounded),
  'beaute-bien-etre':          _CatIcon(Iconsax.lovely,       Icons.face_retouching_natural),
  'sante':                     _CatIcon(Iconsax.health,       Icons.add_rounded),
  'automobile':                _CatIcon(Iconsax.car,          Icons.settings_rounded),
  'hebergement':               _CatIcon(Iconsax.building_4,   Icons.bed_rounded),
  'activites-loisirs':         _CatIcon(Iconsax.game,         Icons.sports_rounded),
  'maison-services':           _CatIcon(Iconsax.home_2,       Icons.build_rounded),
  'commerces':                 _CatIcon(Iconsax.shop,         Icons.shopping_cart_rounded),
  'education':                 _CatIcon(Iconsax.book_1,       Icons.school_rounded),
  'services-professionnels':   _CatIcon(Iconsax.briefcase,    Icons.work_rounded),
  'voyage-tourisme':           _CatIcon(Iconsax.airplane,     Icons.luggage_rounded),
  'evenements':                _CatIcon(Iconsax.calendar_1,   Icons.celebration_rounded),
  // Nouvelles
  'vie-nocturne':                      _CatIcon(Iconsax.moon,           Icons.local_bar_rounded),
  'shopping':                          _CatIcon(Iconsax.bag_2,          Icons.shopping_bag_rounded),
  'alimentation':                      _CatIcon(Iconsax.cup,            Icons.eco_rounded),
  'salons-beaute-spas':                _CatIcon(Iconsax.scissor,        Icons.spa_rounded),
  'maison-travaux':                    _CatIcon(Iconsax.home_2,         Icons.construction_rounded),
  'services-locaux':                   _CatIcon(Iconsax.people,         Icons.handyman_rounded),
  'organisation-evenements':           _CatIcon(Iconsax.calendar_2,     Icons.celebration_rounded),
  'art-loisirs':                       _CatIcon(Iconsax.brush_1,        Icons.palette_rounded),
  'sports-activites-loisirs':          _CatIcon(Iconsax.weight,         Icons.sports_soccer_rounded),
  'services-destines-professionnels':  _CatIcon(Iconsax.briefcase,      Icons.business_center_rounded),
  'hotels-sejours':                    _CatIcon(Iconsax.building_4,     Icons.hotel_rounded),
  'formation-enseignement':            _CatIcon(Iconsax.book,           Icons.school_rounded),
  'animaux-compagnie':                 _CatIcon(Iconsax.pet,            Icons.pets_rounded),
  'services-financiers':               _CatIcon(Iconsax.money_2,        Icons.account_balance_rounded),
  'couleur-locale':                    _CatIcon(Iconsax.location,       Icons.flag_rounded),
  'services-publics-gouvernementaux':  _CatIcon(Iconsax.buildings,      Icons.account_balance_rounded),
  'media':                             _CatIcon(Iconsax.video_play,     Icons.newspaper_rounded),
  'organisation-religieuse':           _CatIcon(Iconsax.star_1,         Icons.church_rounded),
  'sante-medical':                     _CatIcon(Iconsax.hospital,       Icons.emergency_rounded),
};

// ── Widget principal ──────────────────────────────────────────────────────────
class CategoryIconWidget extends StatelessWidget {
  final String slug;
  final String name;
  final Color color;

  /// Taille du conteneur (adapte l'icône principale automatiquement).
  final double size;

  const CategoryIconWidget({
    super.key,
    required this.slug,
    required this.name,
    required this.color,
    this.size = 52,
  });

  _CatIcon _resolve() {
    if (_iconMap.containsKey(slug)) return _iconMap[slug]!;

    // Fallback par nom
    final n = name.toLowerCase();
    if (n.contains('restaurant') || n.contains('cuisine') || n.contains('café')) {
      return const _CatIcon(Iconsax.coffee,    Icons.restaurant_rounded);
    }
    if (n.contains('beauté') || n.contains('spa') || n.contains('coiffure')) {
      return const _CatIcon(Iconsax.lovely,    Icons.face_retouching_natural);
    }
    if (n.contains('santé') || n.contains('médical') || n.contains('médecin')) {
      return const _CatIcon(Iconsax.health,    Icons.add_rounded);
    }
    if (n.contains('auto') || n.contains('voiture')) {
      return const _CatIcon(Iconsax.car,       Icons.settings_rounded);
    }
    if (n.contains('hôtel') || n.contains('hébergement') || n.contains('séjour')) {
      return const _CatIcon(Iconsax.building_4, Icons.bed_rounded);
    }
    if (n.contains('sport') || n.contains('activité') || n.contains('loisir')) {
      return const _CatIcon(Iconsax.weight,    Icons.sports_rounded);
    }
    if (n.contains('maison') || n.contains('travaux')) {
      return const _CatIcon(Iconsax.home_2,    Icons.build_rounded);
    }
    if (n.contains('shopping') || n.contains('commerce')) {
      return const _CatIcon(Iconsax.shop,      Icons.shopping_cart_rounded);
    }
    if (n.contains('éducation') || n.contains('formation')) {
      return const _CatIcon(Iconsax.book_1,    Icons.school_rounded);
    }
    if (n.contains('professionnel') || n.contains('service')) {
      return const _CatIcon(Iconsax.briefcase, Icons.work_rounded);
    }
    if (n.contains('voyage') || n.contains('tourisme')) {
      return const _CatIcon(Iconsax.airplane,  Icons.luggage_rounded);
    }
    if (n.contains('événement') || n.contains('fête')) {
      return const _CatIcon(Iconsax.calendar_1, Icons.celebration_rounded);
    }
    if (n.contains('alimentation') || n.contains('épicerie')) {
      return const _CatIcon(Iconsax.cup,       Icons.eco_rounded);
    }
    if (n.contains('nocturne') || n.contains('nuit')) {
      return const _CatIcon(Iconsax.moon,      Icons.local_bar_rounded);
    }
    if (n.contains('animal') || n.contains('pet')) {
      return const _CatIcon(Iconsax.pet,       Icons.pets_rounded);
    }
    if (n.contains('financier') || n.contains('banque')) {
      return const _CatIcon(Iconsax.money_2,   Icons.account_balance_rounded);
    }
    if (n.contains('art') || n.contains('culture')) {
      return const _CatIcon(Iconsax.brush_1,   Icons.palette_rounded);
    }
    if (n.contains('religieu') || n.contains('mosquée') || n.contains('église')) {
      return const _CatIcon(Iconsax.star_1,    Icons.church_rounded);
    }
    if (n.contains('media') || n.contains('presse')) {
      return const _CatIcon(Iconsax.video_play, Icons.newspaper_rounded);
    }

    return const _CatIcon(Iconsax.category, Icons.star_rounded);
  }

  @override
  Widget build(BuildContext context) {
    final icons = _resolve();
    final mainSize  = size * 0.52;
    final badgeSize = size * 0.38;
    final iconInBadge = badgeSize * 0.52;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fond coloré dégradé subtil
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
          ),

          // Icône principale (sombre, centrée légèrement en haut-gauche)
          Positioned(
            top: size * 0.15,
            left: size * 0.12,
            child: Icon(icons.main, size: mainSize, color: const Color(0xFF1A1A1A)),
          ),

          // Badge accent (couleur catégorie, coin bas-droit)
          Positioned(
            bottom: -(badgeSize * 0.18),
            right: -(badgeSize * 0.18),
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icons.accent, size: iconInBadge, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
