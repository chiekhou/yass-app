import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:win_app/core/l10n/l10n_extensions.dart';

class PhotoCategory {
  final String key;
  final String label;
  final IconData icon;

  const PhotoCategory({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Toutes les catégories disponibles (hors "Tout" qui est un filtre, pas une vraie catégorie)
const List<PhotoCategory> kPhotoCategories = [
  PhotoCategory(key: 'plats',      label: 'Plats',       icon: Iconsax.coffee),
  PhotoCategory(key: 'boissons',   label: 'Boissons',    icon: Iconsax.cup),
  PhotoCategory(key: 'desserts',   label: 'Desserts',    icon: Iconsax.cake),
  PhotoCategory(key: 'menu',       label: 'Menu',        icon: Iconsax.document_text),
  PhotoCategory(key: 'interieur',  label: 'Intérieur',   icon: Iconsax.home_2),
  PhotoCategory(key: 'exterieur',  label: 'Extérieur',   icon: Iconsax.sun_1),
  PhotoCategory(key: 'terrasse',   label: 'Terrasse',    icon: Iconsax.tree),
  PhotoCategory(key: 'ambiance',   label: 'Ambiance',    icon: Iconsax.music),
  PhotoCategory(key: 'bar',        label: 'Bar',         icon: Iconsax.glass),
  PhotoCategory(key: 'salle',      label: 'Salle',       icon: Iconsax.people),
  PhotoCategory(key: 'entree',     label: 'Façade',      icon: Iconsax.building),
  PhotoCategory(key: 'cuisine',    label: 'Cuisine',     icon: Iconsax.flash),
  PhotoCategory(key: 'parking',    label: 'Parking',     icon: Iconsax.car),
  PhotoCategory(key: 'evenements', label: 'Événements',  icon: Iconsax.calendar),
  PhotoCategory(key: 'promotions', label: 'Promos',      icon: Iconsax.medal_star),
  PhotoCategory(key: 'produits',   label: 'Produits',    icon: Iconsax.box),
  PhotoCategory(key: 'autres',     label: 'Autres',      icon: Iconsax.more_circle),
];

/// Retrouve le label d'une clé (fallback = "Autres") — sans contexte, utilisé dans le modèle
String photoCategoryLabel(String? key) {
  if (key == null) return 'Autres';
  return kPhotoCategories
      .firstWhere((c) => c.key == key,
          orElse: () => const PhotoCategory(
              key: 'autres', label: 'Autres', icon: Iconsax.more_circle))
      .label;
}

/// Version traduite pour l'UI (nécessite un BuildContext)
String photoCategoryL10nLabel(BuildContext context, String? key) {
  switch (key) {
    case 'plats':      return context.l10n.photoCategoryPlats;
    case 'boissons':   return context.l10n.photoCategoryBoissons;
    case 'desserts':   return context.l10n.photoCategoryDesserts;
    case 'menu':       return context.l10n.photoCategoryMenu;
    case 'interieur':  return context.l10n.photoCategoryInterieur;
    case 'exterieur':  return context.l10n.photoCategoryExterieur;
    case 'terrasse':   return context.l10n.photoCategoryTerrasse;
    case 'ambiance':   return context.l10n.photoCategoryAmbiance;
    case 'bar':        return context.l10n.photoCategoryBar;
    case 'salle':      return context.l10n.photoCategorySalle;
    case 'entree':     return context.l10n.photoCategoryEntree;
    case 'cuisine':    return context.l10n.photoCategoryCuisine;
    case 'parking':    return context.l10n.photoCategoryParking;
    case 'evenements': return context.l10n.photoCategoryEvenements;
    case 'promotions': return context.l10n.photoCategoryPromotions;
    case 'produits':   return context.l10n.photoCategoryProduits;
    default:           return context.l10n.photoCategoryOthers;
  }
}
