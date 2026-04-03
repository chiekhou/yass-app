import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Win'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In fr, this message translates to:
  /// **'Trouvez tout près de chez vous'**
  String get appTagline;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @resetPassword.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser le mot de passe'**
  String get resetPassword;

  /// No description provided for @firstName.
  ///
  /// In fr, this message translates to:
  /// **'Prénom'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @hasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get hasAccount;

  /// No description provided for @registerAsPartner.
  ///
  /// In fr, this message translates to:
  /// **'Inscription partenaire'**
  String get registerAsPartner;

  /// No description provided for @companyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'entreprise'**
  String get companyName;

  /// No description provided for @home.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get home;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @favorites.
  ///
  /// In fr, this message translates to:
  /// **'Favoris'**
  String get favorites;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @nearMe.
  ///
  /// In fr, this message translates to:
  /// **'Près de moi'**
  String get nearMe;

  /// No description provided for @featured.
  ///
  /// In fr, this message translates to:
  /// **'À la une'**
  String get featured;

  /// No description provided for @popular.
  ///
  /// In fr, this message translates to:
  /// **'Populaires'**
  String get popular;

  /// No description provided for @recent.
  ///
  /// In fr, this message translates to:
  /// **'Récents'**
  String get recent;

  /// No description provided for @seeAll.
  ///
  /// In fr, this message translates to:
  /// **'Voir tout'**
  String get seeAll;

  /// No description provided for @searchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un établissement...'**
  String get searchHint;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À propos'**
  String get about;

  /// No description provided for @openingHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires'**
  String get openingHours;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @location.
  ///
  /// In fr, this message translates to:
  /// **'Localisation'**
  String get location;

  /// No description provided for @reviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis'**
  String get reviews;

  /// No description provided for @services.
  ///
  /// In fr, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @amenities.
  ///
  /// In fr, this message translates to:
  /// **'Équipements'**
  String get amenities;

  /// No description provided for @photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @call.
  ///
  /// In fr, this message translates to:
  /// **'Appeler'**
  String get call;

  /// No description provided for @whatsapp.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get whatsapp;

  /// No description provided for @directions.
  ///
  /// In fr, this message translates to:
  /// **'Itinéraire'**
  String get directions;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @report.
  ///
  /// In fr, this message translates to:
  /// **'Signaler'**
  String get report;

  /// No description provided for @addToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter aux favoris'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retirer des favoris'**
  String get removeFromFavorites;

  /// No description provided for @writeReview.
  ///
  /// In fr, this message translates to:
  /// **'Écrire un avis'**
  String get writeReview;

  /// No description provided for @closed.
  ///
  /// In fr, this message translates to:
  /// **'Fermé'**
  String get closed;

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert'**
  String get open;

  /// No description provided for @openNow.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert maintenant'**
  String get openNow;

  /// No description provided for @closedNow.
  ///
  /// In fr, this message translates to:
  /// **'Fermé maintenant'**
  String get closedNow;

  /// No description provided for @rating.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get rating;

  /// No description provided for @yourReview.
  ///
  /// In fr, this message translates to:
  /// **'Votre avis'**
  String get yourReview;

  /// No description provided for @reviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Partagez votre expérience...'**
  String get reviewHint;

  /// No description provided for @submitReview.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'avis'**
  String get submitReview;

  /// No description provided for @helpful.
  ///
  /// In fr, this message translates to:
  /// **'Utile'**
  String get helpful;

  /// No description provided for @pros.
  ///
  /// In fr, this message translates to:
  /// **'Points positifs'**
  String get pros;

  /// No description provided for @cons.
  ///
  /// In fr, this message translates to:
  /// **'Points négatifs'**
  String get cons;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @myFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Mes Favoris'**
  String get myFavorites;

  /// No description provided for @myReviews.
  ///
  /// In fr, this message translates to:
  /// **'Mes avis'**
  String get myReviews;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Mes Notifications'**
  String get notifications;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @privacyPolicy.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsOfService;

  /// No description provided for @contactUs.
  ///
  /// In fr, this message translates to:
  /// **'Nous contacter'**
  String get contactUs;

  /// No description provided for @rateApp.
  ///
  /// In fr, this message translates to:
  /// **'Noter l\'application'**
  String get rateApp;

  /// No description provided for @partnerSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace partenaire'**
  String get partnerSpace;

  /// No description provided for @myEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Mes établissements'**
  String get myEstablishments;

  /// No description provided for @addEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un établissement'**
  String get addEstablishment;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @views.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get views;

  /// No description provided for @calls.
  ///
  /// In fr, this message translates to:
  /// **'Appels'**
  String get calls;

  /// No description provided for @clicks.
  ///
  /// In fr, this message translates to:
  /// **'Clics'**
  String get clicks;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @done.
  ///
  /// In fr, this message translates to:
  /// **'Terminé'**
  String get done;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @skip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skip;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @noResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get noResults;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @somethingWentWrong.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get somethingWentWrong;

  /// No description provided for @noInternet.
  ///
  /// In fr, this message translates to:
  /// **'Pas de connexion internet'**
  String get noInternet;

  /// No description provided for @pullToRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Tirer pour actualiser'**
  String get pullToRefresh;

  /// No description provided for @filters.
  ///
  /// In fr, this message translates to:
  /// **'Filtres'**
  String get filters;

  /// No description provided for @sortBy.
  ///
  /// In fr, this message translates to:
  /// **'Trier par'**
  String get sortBy;

  /// No description provided for @distance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @priceRange.
  ///
  /// In fr, this message translates to:
  /// **'Gamme de prix'**
  String get priceRange;

  /// No description provided for @verified.
  ///
  /// In fr, this message translates to:
  /// **'Vérifié'**
  String get verified;

  /// No description provided for @applyFilters.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearFilters;

  /// No description provided for @monday.
  ///
  /// In fr, this message translates to:
  /// **'Lundi'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In fr, this message translates to:
  /// **'Mardi'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In fr, this message translates to:
  /// **'Mercredi'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In fr, this message translates to:
  /// **'Jeudi'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In fr, this message translates to:
  /// **'Vendredi'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In fr, this message translates to:
  /// **'Samedi'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In fr, this message translates to:
  /// **'Dimanche'**
  String get sunday;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get myAccount;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @byEmail.
  ///
  /// In fr, this message translates to:
  /// **'Par email'**
  String get byEmail;

  /// No description provided for @byPhone.
  ///
  /// In fr, this message translates to:
  /// **'Par téléphone'**
  String get byPhone;

  /// No description provided for @adminSpace.
  ///
  /// In fr, this message translates to:
  /// **'Espace administration'**
  String get adminSpace;

  /// No description provided for @usersManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion utilisateurs'**
  String get usersManagement;

  /// No description provided for @partnersManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion partenaires'**
  String get partnersManagement;

  /// No description provided for @reviewsManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des avis'**
  String get reviewsManagement;

  /// No description provided for @pageNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Page non trouvée'**
  String get pageNotFound;

  /// No description provided for @backToHome.
  ///
  /// In fr, this message translates to:
  /// **'Retour à l\'accueil'**
  String get backToHome;

  /// No description provided for @statusPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get statusPending;

  /// No description provided for @statusActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get statusActive;

  /// No description provided for @statusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get statusRejected;

  /// No description provided for @statusSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendu'**
  String get statusSuspended;

  /// No description provided for @statusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get statusDraft;

  /// No description provided for @statusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get statusApproved;

  /// No description provided for @statusReported.
  ///
  /// In fr, this message translates to:
  /// **'Signalé'**
  String get statusReported;

  /// No description provided for @welcomeTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur Win !'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder à toutes les fonctionnalités'**
  String get welcomeSubtitle;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement'**
  String get loadingError;

  /// No description provided for @noReviews.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis pour le moment'**
  String get noReviews;

  /// No description provided for @beFirstReview.
  ///
  /// In fr, this message translates to:
  /// **'Soyez le premier à donner votre avis !'**
  String get beFirstReview;

  /// No description provided for @ownerResponse.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du propriétaire'**
  String get ownerResponse;

  /// No description provided for @reportReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Signaler cet avis'**
  String get reportReviewTitle;

  /// No description provided for @reportReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Raison du signalement (min. 10 caractères)'**
  String get reportReasonHint;

  /// No description provided for @reportSent.
  ///
  /// In fr, this message translates to:
  /// **'Signalement envoyé'**
  String get reportSent;

  /// No description provided for @reportError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du signalement'**
  String get reportError;

  /// No description provided for @loginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get loginRequired;

  /// No description provided for @loginToAction.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour effectuer cette action.'**
  String get loginToAction;

  /// No description provided for @loginToReview.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour écrire un avis.'**
  String get loginToReview;

  /// No description provided for @loginToFavoriteMsg.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour ajouter cet établissement à vos favoris.'**
  String get loginToFavoriteMsg;

  /// No description provided for @loginToReportReview.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour signaler un avis.'**
  String get loginToReportReview;

  /// No description provided for @anonymous.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get anonymous;

  /// No description provided for @markAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout lire'**
  String get markAllRead;

  /// No description provided for @noNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification'**
  String get noNotifications;

  /// No description provided for @loginToSeeNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour voir vos notifications'**
  String get loginToSeeNotifications;

  /// No description provided for @searchEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Recherchez un établissement'**
  String get searchEstablishment;

  /// No description provided for @searchPlaceholder.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant, hôtel, pharmacie...'**
  String get searchPlaceholder;

  /// No description provided for @noResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé'**
  String get noResultsFound;

  /// No description provided for @tryOtherTerms.
  ///
  /// In fr, this message translates to:
  /// **'Essayez avec d\'autres termes ou filtres'**
  String get tryOtherTerms;

  /// No description provided for @categoryFilter.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get categoryFilter;

  /// No description provided for @wilayaFilter.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get wilayaFilter;

  /// No description provided for @priceFilter.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get priceFilter;

  /// No description provided for @sortBestRated.
  ///
  /// In fr, this message translates to:
  /// **'Mieux noté'**
  String get sortBestRated;

  /// No description provided for @sortAlphabetical.
  ///
  /// In fr, this message translates to:
  /// **'A → Z'**
  String get sortAlphabetical;

  /// No description provided for @reviewsCount.
  ///
  /// In fr, this message translates to:
  /// **'({count} avis)'**
  String reviewsCount(int count);

  /// No description provided for @searchFor.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher \"{term}\"'**
  String searchFor(String term);

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @connect.
  ///
  /// In fr, this message translates to:
  /// **'Connexion requise'**
  String get connect;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'es',
        'fr',
        'it',
        'nl'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
