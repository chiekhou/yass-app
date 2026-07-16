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

  /// No description provided for @acceptTermsError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez accepter les conditions d\'utilisation'**
  String get acceptTermsError;

  /// No description provided for @selectWilaya.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner votre wilaya'**
  String get selectWilaya;

  /// No description provided for @becomePartner.
  ///
  /// In fr, this message translates to:
  /// **'Devenir partenaire'**
  String get becomePartner;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe réinitialisé avec succès !'**
  String get passwordResetSuccess;

  /// No description provided for @verifyCode.
  ///
  /// In fr, this message translates to:
  /// **'Vérifier le code'**
  String get verifyCode;

  /// No description provided for @resendCode.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer le code'**
  String get resendCode;

  /// No description provided for @verifying.
  ///
  /// In fr, this message translates to:
  /// **'Vérification en cours...'**
  String get verifying;

  /// No description provided for @backToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get backToLogin;

  /// No description provided for @resendEmail.
  ///
  /// In fr, this message translates to:
  /// **'Renvoyer l\'email'**
  String get resendEmail;

  /// No description provided for @codeSentSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Code renvoyé avec succès'**
  String get codeSentSuccess;

  /// No description provided for @noFeatured.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement à la une'**
  String get noFeatured;

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie disponible'**
  String get noCategoriesAvailable;

  /// No description provided for @explore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get explore;

  /// No description provided for @noNearbyEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement trouvé dans votre wilaya'**
  String get noNearbyEstablishments;

  /// No description provided for @addressCopied.
  ///
  /// In fr, this message translates to:
  /// **'Adresse copiée'**
  String get addressCopied;

  /// No description provided for @checkInComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Check-In — bientôt disponible'**
  String get checkInComingSoon;

  /// No description provided for @notAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible'**
  String get notAvailable;

  /// No description provided for @coordinatesNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées non disponibles pour cet établissement'**
  String get coordinatesNotAvailable;

  /// No description provided for @reviewDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Avis supprimé'**
  String get reviewDeleted;

  /// No description provided for @deleteReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet avis ?'**
  String get deleteReviewTitle;

  /// No description provided for @maxPhotosPerReview.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 5 photos par avis'**
  String get maxPhotosPerReview;

  /// No description provided for @maxVideosPerReview.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 3 vidéos par avis'**
  String get maxVideosPerReview;

  /// No description provided for @ratingRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez donner une note d\'ensemble'**
  String get ratingRequired;

  /// No description provided for @allCriteriaRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez noter tous les critères'**
  String get allCriteriaRequired;

  /// No description provided for @reviewMinChars.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez votre expérience (min. 10 caractères)'**
  String get reviewMinChars;

  /// No description provided for @photoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi des photos'**
  String get photoUploadError;

  /// No description provided for @videoUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'envoi des vidéos'**
  String get videoUploadError;

  /// No description provided for @clearFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Vider les favoris'**
  String get clearFavorites;

  /// No description provided for @clear.
  ///
  /// In fr, this message translates to:
  /// **'Vider'**
  String get clear;

  /// No description provided for @deleteAllNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer toutes les notifications'**
  String get deleteAllNotifications;

  /// No description provided for @message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @openEmail.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir l\'email'**
  String get openEmail;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @locationError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer votre position'**
  String get locationError;

  /// No description provided for @openWith.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir avec'**
  String get openWith;

  /// No description provided for @goHere.
  ///
  /// In fr, this message translates to:
  /// **'Y aller'**
  String get goHere;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @takePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir de la galerie'**
  String get chooseFromGallery;

  /// No description provided for @profileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès'**
  String get profileUpdated;

  /// No description provided for @notConnected.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get notConnected;

  /// No description provided for @changePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo'**
  String get changePhoto;

  /// No description provided for @personalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations personnelles'**
  String get personalInfo;

  /// No description provided for @firstNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le prénom est requis'**
  String get firstNameRequired;

  /// No description provided for @lastNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get lastNameRequired;

  /// No description provided for @wilaya.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @changePassword.
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// No description provided for @businessInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations entreprise'**
  String get businessInfo;

  /// No description provided for @editInfo.
  ///
  /// In fr, this message translates to:
  /// **'Modifier les informations'**
  String get editInfo;

  /// No description provided for @validationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de validation'**
  String get validationError;

  /// No description provided for @incorrectCurrentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe actuel est incorrect'**
  String get incorrectCurrentPassword;

  /// No description provided for @genericError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Veuillez réessayer.'**
  String get genericError;

  /// No description provided for @currentPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe actuel'**
  String get currentPassword;

  /// No description provided for @required.
  ///
  /// In fr, this message translates to:
  /// **'Requis'**
  String get required;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @minSixChars.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get minSixChars;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe modifié avec succès'**
  String get passwordChanged;

  /// No description provided for @change.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get change;

  /// No description provided for @ourMission.
  ///
  /// In fr, this message translates to:
  /// **'Notre mission'**
  String get ourMission;

  /// No description provided for @appDescription.
  ///
  /// In fr, this message translates to:
  /// **'Win est l\'annuaire de référence des établissements en Algérie. Nous aidons les Algériens à trouver facilement les commerces, restaurants, services et lieux culturels près de chez eux, grâce aux avis et recommandations de la communauté.'**
  String get appDescription;

  /// No description provided for @legalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations légales'**
  String get legalInfo;

  /// No description provided for @sendEmail.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un e-mail'**
  String get sendEmail;

  /// No description provided for @backToList.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la liste'**
  String get backToList;

  /// No description provided for @suggestAnother.
  ///
  /// In fr, this message translates to:
  /// **'Suggérer un autre'**
  String get suggestAnother;

  /// No description provided for @suggestEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Suggérer un établissement'**
  String get suggestEstablishment;

  /// No description provided for @submitSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer ma suggestion'**
  String get submitSuggestion;

  /// No description provided for @noCategorySelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie sélectionnée'**
  String get noCategorySelected;

  /// No description provided for @noWilayaSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune wilaya sélectionnée'**
  String get noWilayaSelected;

  /// No description provided for @mySuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Mes suggestions'**
  String get mySuggestions;

  /// No description provided for @makeSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Faire une suggestion'**
  String get makeSuggestion;

  /// No description provided for @noSuggestionsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucune suggestion pour le moment'**
  String get noSuggestionsYet;

  /// No description provided for @communitySuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions de la communauté'**
  String get communitySuggestions;

  /// No description provided for @beFirstToSuggest.
  ///
  /// In fr, this message translates to:
  /// **'Soyez le premier à suggérer un établissement !'**
  String get beFirstToSuggest;

  /// No description provided for @createAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get createAccount;

  /// No description provided for @loginToSeeSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour accéder aux suggestions de la communauté et voter pour vos établissements préférés.'**
  String get loginToSeeSuggestions;

  /// No description provided for @suggestYourEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Suggérez un établissement que vous aimeriez voir sur la plateforme.'**
  String get suggestYourEstablishment;

  /// No description provided for @infoBannerSuggest.
  ///
  /// In fr, this message translates to:
  /// **'Signalez un établissement manquant dans l\'annuaire. Plus il y a de votes, plus vite il sera ajouté.'**
  String get infoBannerSuggest;

  /// No description provided for @establishmentNameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'établissement *'**
  String get establishmentNameLabel;

  /// No description provided for @addressLabel.
  ///
  /// In fr, this message translates to:
  /// **'Adresse *'**
  String get addressLabel;

  /// No description provided for @phoneOptional.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone (optionnel)'**
  String get phoneOptional;

  /// No description provided for @contactEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email de contact *'**
  String get contactEmailLabel;

  /// No description provided for @categoryOptional.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie (optionnel)'**
  String get categoryOptional;

  /// No description provided for @wilayaOptional.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya (optionnel)'**
  String get wilayaOptional;

  /// No description provided for @descriptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Description (optionnel)'**
  String get descriptionOptional;

  /// No description provided for @suggestionReasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Motif de la suggestion (optionnel)'**
  String get suggestionReasonOptional;

  /// No description provided for @fieldRequired.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get fieldRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get invalidEmail;

  /// No description provided for @nameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Café Central, Clinique El Amel...'**
  String get nameHint;

  /// No description provided for @addressHint.
  ///
  /// In fr, this message translates to:
  /// **'Rue, quartier, ville...'**
  String get addressHint;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Décrivez brièvement cet établissement...'**
  String get descriptionHint;

  /// No description provided for @selectCategory.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une catégorie'**
  String get selectCategory;

  /// No description provided for @selectAWilaya.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner une wilaya'**
  String get selectAWilaya;

  /// No description provided for @paymentAccepted.
  ///
  /// In fr, this message translates to:
  /// **'Paiement accepté — abonnement activé !'**
  String get paymentAccepted;

  /// No description provided for @paymentFailed.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement a échoué. Veuillez réessayer.'**
  String get paymentFailed;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement annulé'**
  String get subscriptionCancelled;

  /// No description provided for @cancelSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Annuler l\'abonnement'**
  String get cancelSubscription;

  /// No description provided for @keepSubscription.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get keepSubscription;

  /// No description provided for @cannotOpenPaymentPage.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir la page de paiement'**
  String get cannotOpenPaymentPage;

  /// No description provided for @requestSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Demande soumise'**
  String get requestSubmitted;

  /// No description provided for @visitOurOffice.
  ///
  /// In fr, this message translates to:
  /// **'Rendez-vous à notre bureau :'**
  String get visitOurOffice;

  /// No description provided for @bankDetailsColon.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées bancaires :'**
  String get bankDetailsColon;

  /// No description provided for @bankDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées bancaires'**
  String get bankDetailsTitle;

  /// No description provided for @understood.
  ///
  /// In fr, this message translates to:
  /// **'Compris'**
  String get understood;

  /// No description provided for @transferRefHint.
  ///
  /// In fr, this message translates to:
  /// **'Référence du virement (optionnel)'**
  String get transferRefHint;

  /// No description provided for @paymentOnline.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get paymentOnline;

  /// No description provided for @paymentTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Virement'**
  String get paymentTransfer;

  /// No description provided for @paymentCash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get paymentCash;

  /// No description provided for @inOffice.
  ///
  /// In fr, this message translates to:
  /// **'En bureau'**
  String get inOffice;

  /// No description provided for @seePlan.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'offre {plan}'**
  String seePlan(String plan);

  /// No description provided for @freePlan.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get freePlan;

  /// No description provided for @alwaysFree.
  ///
  /// In fr, this message translates to:
  /// **'toujours gratuit'**
  String get alwaysFree;

  /// No description provided for @noCommitment.
  ///
  /// In fr, this message translates to:
  /// **'sans engagement'**
  String get noCommitment;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get paymentMethodLabel;

  /// No description provided for @cancelQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler ?'**
  String get cancelQuestion;

  /// No description provided for @cancelConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler ? Les modifications non enregistrées seront perdues.'**
  String get cancelConfirmBody;

  /// No description provided for @noContinue.
  ///
  /// In fr, this message translates to:
  /// **'Non, continuer'**
  String get noContinue;

  /// No description provided for @yesCancel.
  ///
  /// In fr, this message translates to:
  /// **'Oui, annuler'**
  String get yesCancel;

  /// No description provided for @editEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'établissement'**
  String get editEstablishment;

  /// No description provided for @newEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel établissement'**
  String get newEstablishment;

  /// No description provided for @nameAr.
  ///
  /// In fr, this message translates to:
  /// **'Nom en arabe'**
  String get nameAr;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionAr.
  ///
  /// In fr, this message translates to:
  /// **'Description en arabe'**
  String get descriptionAr;

  /// No description provided for @categoryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie *'**
  String get categoryRequired;

  /// No description provided for @subcategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie'**
  String get subcategoryLabel;

  /// No description provided for @communeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get communeLabel;

  /// No description provided for @addressAr.
  ///
  /// In fr, this message translates to:
  /// **'Adresse en arabe'**
  String get addressAr;

  /// No description provided for @latitudeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// No description provided for @longitudeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// No description provided for @wilayaRequired.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya *'**
  String get wilayaRequired;

  /// No description provided for @phoneRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le téléphone est requis'**
  String get phoneRequired;

  /// No description provided for @secondaryPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone secondaire'**
  String get secondaryPhone;

  /// No description provided for @websiteLabel.
  ///
  /// In fr, this message translates to:
  /// **'Site web'**
  String get websiteLabel;

  /// No description provided for @socialNetworks.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get socialNetworks;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameRequired;

  /// No description provided for @addressRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse est requise'**
  String get addressRequired;

  /// No description provided for @phoneTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Numéro trop court'**
  String get phoneTooShort;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur serveur. Veuillez réessayer plus tard.'**
  String get serverError;

  /// No description provided for @priceEconomy.
  ///
  /// In fr, this message translates to:
  /// **'Économique (\$)'**
  String get priceEconomy;

  /// No description provided for @priceModerate.
  ///
  /// In fr, this message translates to:
  /// **'Modéré (\$\$)'**
  String get priceModerate;

  /// No description provided for @priceHigh.
  ///
  /// In fr, this message translates to:
  /// **'Élevé (\$\$\$)'**
  String get priceHigh;

  /// No description provided for @priceLuxury.
  ///
  /// In fr, this message translates to:
  /// **'Luxe (\$\$\$\$)'**
  String get priceLuxury;

  /// No description provided for @featuredActivated.
  ///
  /// In fr, this message translates to:
  /// **'Mise à la une activée avec succès !'**
  String get featuredActivated;

  /// No description provided for @featureEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à la une'**
  String get featureEstablishment;

  /// No description provided for @payOnline.
  ///
  /// In fr, this message translates to:
  /// **'Payer en ligne (CIB / EDAHABIA)'**
  String get payOnline;

  /// No description provided for @bankTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Virement bancaire'**
  String get bankTransfer;

  /// No description provided for @cashPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en espèces'**
  String get cashPayment;

  /// No description provided for @replyReviewTitle.
  ///
  /// In fr, this message translates to:
  /// **'Répondre à cet avis'**
  String get replyReviewTitle;

  /// No description provided for @responseHintLong.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse (min. 10 caractères)'**
  String get responseHintLong;

  /// No description provided for @replySent.
  ///
  /// In fr, this message translates to:
  /// **'Réponse envoyée'**
  String get replySent;

  /// No description provided for @replyButton.
  ///
  /// In fr, this message translates to:
  /// **'Répondre'**
  String get replyButton;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In fr, this message translates to:
  /// **'Actifs'**
  String get filterActive;

  /// No description provided for @filterInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactifs'**
  String get filterInactive;

  /// No description provided for @filterRejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejetés'**
  String get filterRejected;

  /// No description provided for @statusInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get statusInactive;

  /// No description provided for @statusLabel.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statusLabel;

  /// No description provided for @establishmentDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Établissement supprimé'**
  String get establishmentDeleted;

  /// No description provided for @deleteEstablishmentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'établissement'**
  String get deleteEstablishmentTitle;

  /// No description provided for @changeStatus.
  ///
  /// In fr, this message translates to:
  /// **'Changer le statut'**
  String get changeStatus;

  /// No description provided for @activateStatus.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activateStatus;

  /// No description provided for @deactivateStatus.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver'**
  String get deactivateStatus;

  /// No description provided for @replyToReview.
  ///
  /// In fr, this message translates to:
  /// **'Répondre à l\'avis'**
  String get replyToReview;

  /// No description provided for @replyHint.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse...'**
  String get replyHint;

  /// No description provided for @publishReply.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get publishReply;

  /// No description provided for @replyPublished.
  ///
  /// In fr, this message translates to:
  /// **'Réponse publiée'**
  String get replyPublished;

  /// No description provided for @myInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Mes factures'**
  String get myInvoices;

  /// No description provided for @noInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Aucune facture'**
  String get noInvoices;

  /// No description provided for @invoicesWillAppear.
  ///
  /// In fr, this message translates to:
  /// **'Vos factures apparaîtront ici après votre premier paiement.'**
  String get invoicesWillAppear;

  /// No description provided for @subscribe.
  ///
  /// In fr, this message translates to:
  /// **'S\'abonner'**
  String get subscribe;

  /// No description provided for @paymentReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu de paiement'**
  String get paymentReceipt;

  /// No description provided for @invoiceNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° Facture'**
  String get invoiceNumber;

  /// No description provided for @paidOn.
  ///
  /// In fr, this message translates to:
  /// **'Payé le'**
  String get paidOn;

  /// No description provided for @plan.
  ///
  /// In fr, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get paymentMethod;

  /// No description provided for @reference.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get reference;

  /// No description provided for @period.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get period;

  /// No description provided for @welcomeAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, Admin'**
  String get welcomeAdmin;

  /// No description provided for @managePlatformWin.
  ///
  /// In fr, this message translates to:
  /// **'Gérez votre plateforme Win'**
  String get managePlatformWin;

  /// No description provided for @generalStats.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques générales'**
  String get generalStats;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @partners.
  ///
  /// In fr, this message translates to:
  /// **'Partenaires'**
  String get partners;

  /// No description provided for @establishments.
  ///
  /// In fr, this message translates to:
  /// **'Établissements'**
  String get establishments;

  /// No description provided for @userDemographics.
  ///
  /// In fr, this message translates to:
  /// **'Démographie des utilisateurs'**
  String get userDemographics;

  /// No description provided for @males.
  ///
  /// In fr, this message translates to:
  /// **'Hommes'**
  String get males;

  /// No description provided for @females.
  ///
  /// In fr, this message translates to:
  /// **'Femmes'**
  String get females;

  /// No description provided for @youth.
  ///
  /// In fr, this message translates to:
  /// **'Jeunes'**
  String get youth;

  /// No description provided for @children.
  ///
  /// In fr, this message translates to:
  /// **'Enfants'**
  String get children;

  /// No description provided for @notProvided.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get notProvided;

  /// No description provided for @ageRanges.
  ///
  /// In fr, this message translates to:
  /// **'Tranches d\'âge'**
  String get ageRanges;

  /// No description provided for @appVisits.
  ///
  /// In fr, this message translates to:
  /// **'Visites de l\'application'**
  String get appVisits;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @pendingApproval.
  ///
  /// In fr, this message translates to:
  /// **'En attente d\'approbation'**
  String get pendingApproval;

  /// No description provided for @pendingPartners.
  ///
  /// In fr, this message translates to:
  /// **'Partenaires en attente'**
  String get pendingPartners;

  /// No description provided for @pendingEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Établissements en attente'**
  String get pendingEstablishments;

  /// No description provided for @quickActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions rapides'**
  String get quickActions;

  /// No description provided for @managementEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des établissements'**
  String get managementEstablishments;

  /// No description provided for @managementPartners.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des partenaires'**
  String get managementPartners;

  /// No description provided for @managementUsers.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get managementUsers;

  /// No description provided for @searchByNameAddress.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher par nom ou adresse...'**
  String get searchByNameAddress;

  /// No description provided for @searchPartner.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un partenaire...'**
  String get searchPartner;

  /// No description provided for @searchUser.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un utilisateur...'**
  String get searchUser;

  /// No description provided for @allPlans.
  ///
  /// In fr, this message translates to:
  /// **'Tous les plans'**
  String get allPlans;

  /// No description provided for @allRoles.
  ///
  /// In fr, this message translates to:
  /// **'Tous les rôles'**
  String get allRoles;

  /// No description provided for @noEstablishmentFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement trouvé'**
  String get noEstablishmentFound;

  /// No description provided for @noPartnerFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partenaire trouvé'**
  String get noPartnerFound;

  /// No description provided for @noUserFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé'**
  String get noUserFound;

  /// No description provided for @noEstablishmentPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement en attente d\'approbation'**
  String get noEstablishmentPending;

  /// No description provided for @noPartnerPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucun partenaire en attente d\'approbation'**
  String get noPartnerPending;

  /// No description provided for @noPaymentPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucun paiement manuel en attente de validation'**
  String get noPaymentPending;

  /// No description provided for @noReviewFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis trouvé'**
  String get noReviewFound;

  /// No description provided for @noReviewForFilter.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis ne correspond à ce filtre'**
  String get noReviewForFilter;

  /// No description provided for @noReportedReview.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis signalé'**
  String get noReportedReview;

  /// No description provided for @noReportedReviewYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun avis n\'a été signalé pour le moment'**
  String get noReportedReviewYet;

  /// No description provided for @noSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune suggestion'**
  String get noSuggestion;

  /// No description provided for @modifySearchFilters.
  ///
  /// In fr, this message translates to:
  /// **'Essayez de modifier vos filtres de recherche'**
  String get modifySearchFilters;

  /// No description provided for @allUpToDate.
  ///
  /// In fr, this message translates to:
  /// **'Tout est à jour !'**
  String get allUpToDate;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get reject;

  /// No description provided for @suspend.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre'**
  String get suspend;

  /// No description provided for @remove.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get remove;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @dismiss.
  ///
  /// In fr, this message translates to:
  /// **'Ignorer'**
  String get dismiss;

  /// No description provided for @revoke.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer'**
  String get revoke;

  /// No description provided for @promote.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir'**
  String get promote;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @approveEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Approuver l\'établissement'**
  String get approveEstablishment;

  /// No description provided for @rejectEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter l\'établissement'**
  String get rejectEstablishment;

  /// No description provided for @rejectPartner.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter le partenaire'**
  String get rejectPartner;

  /// No description provided for @suspendPartner.
  ///
  /// In fr, this message translates to:
  /// **'Suspendre le partenaire'**
  String get suspendPartner;

  /// No description provided for @deleteUser.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'utilisateur'**
  String get deleteUser;

  /// No description provided for @deleteThisReview.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet avis'**
  String get deleteThisReview;

  /// No description provided for @rejectThisReview.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter cet avis'**
  String get rejectThisReview;

  /// No description provided for @approveSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Approuver la suggestion'**
  String get approveSuggestion;

  /// No description provided for @rejectSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter la suggestion'**
  String get rejectSuggestion;

  /// No description provided for @rejectReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Raison du rejet *'**
  String get rejectReasonLabel;

  /// No description provided for @suspensionReasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Raison de la suspension'**
  String get suspensionReasonLabel;

  /// No description provided for @enterReason.
  ///
  /// In fr, this message translates to:
  /// **'Entrez la raison...'**
  String get enterReason;

  /// No description provided for @enterRejectReason.
  ///
  /// In fr, this message translates to:
  /// **'Entrez la raison du rejet...'**
  String get enterRejectReason;

  /// No description provided for @pleaseEnterReason.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer une raison'**
  String get pleaseEnterReason;

  /// No description provided for @rejectReasonMin10.
  ///
  /// In fr, this message translates to:
  /// **'Raison du rejet (min. 10 caractères)'**
  String get rejectReasonMin10;

  /// No description provided for @deleteReasonMin10.
  ///
  /// In fr, this message translates to:
  /// **'Raison de la suppression (min. 10 caractères)'**
  String get deleteReasonMin10;

  /// No description provided for @rejectReasonOptional.
  ///
  /// In fr, this message translates to:
  /// **'Raison du rejet (optionnel)'**
  String get rejectReasonOptional;

  /// No description provided for @reasonMinChars.
  ///
  /// In fr, this message translates to:
  /// **'La raison doit faire au moins 10 caractères'**
  String get reasonMinChars;

  /// No description provided for @removeFeatured.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la une'**
  String get removeFeatured;

  /// No description provided for @featuredDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée :'**
  String get featuredDuration;

  /// No description provided for @noLimit.
  ///
  /// In fr, this message translates to:
  /// **'Sans limite'**
  String get noLimit;

  /// No description provided for @assignPartner.
  ///
  /// In fr, this message translates to:
  /// **'Associer un partenaire'**
  String get assignPartner;

  /// No description provided for @detachCurrentPartner.
  ///
  /// In fr, this message translates to:
  /// **'Détacher le partenaire actuel'**
  String get detachCurrentPartner;

  /// No description provided for @changePartner.
  ///
  /// In fr, this message translates to:
  /// **'Changer de partenaire'**
  String get changePartner;

  /// No description provided for @generalInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get generalInformation;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @coordinates.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées'**
  String get coordinates;

  /// No description provided for @interlocutor.
  ///
  /// In fr, this message translates to:
  /// **'Interlocuteur'**
  String get interlocutor;

  /// No description provided for @positionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poste'**
  String get positionLabel;

  /// No description provided for @positionFunction.
  ///
  /// In fr, this message translates to:
  /// **'Poste / Fonction'**
  String get positionFunction;

  /// No description provided for @partnerSection.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire'**
  String get partnerSection;

  /// No description provided for @company.
  ///
  /// In fr, this message translates to:
  /// **'Société'**
  String get company;

  /// No description provided for @createdOn.
  ///
  /// In fr, this message translates to:
  /// **'Créé le'**
  String get createdOn;

  /// No description provided for @updatedOn.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour'**
  String get updatedOn;

  /// No description provided for @accountManager.
  ///
  /// In fr, this message translates to:
  /// **'Responsable du compte'**
  String get accountManager;

  /// No description provided for @actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @addEstablishmentShort.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter établ.'**
  String get addEstablishmentShort;

  /// No description provided for @addPartner.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un partenaire'**
  String get addPartner;

  /// No description provided for @tel.
  ///
  /// In fr, this message translates to:
  /// **'Tél.'**
  String get tel;

  /// No description provided for @admins.
  ///
  /// In fr, this message translates to:
  /// **'Admins'**
  String get admins;

  /// No description provided for @userRole.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get userRole;

  /// No description provided for @adminRole.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get adminRole;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @gender.
  ///
  /// In fr, this message translates to:
  /// **'Sexe'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In fr, this message translates to:
  /// **'Âge'**
  String get age;

  /// No description provided for @ageCategory.
  ///
  /// In fr, this message translates to:
  /// **'Tranche'**
  String get ageCategory;

  /// No description provided for @lastLogin.
  ///
  /// In fr, this message translates to:
  /// **'Dernière connexion'**
  String get lastLogin;

  /// No description provided for @connections.
  ///
  /// In fr, this message translates to:
  /// **'Connexions'**
  String get connections;

  /// No description provided for @emailVerified.
  ///
  /// In fr, this message translates to:
  /// **'Email vérifié'**
  String get emailVerified;

  /// No description provided for @emailNotVerified.
  ///
  /// In fr, this message translates to:
  /// **'Email non vérifié'**
  String get emailNotVerified;

  /// No description provided for @activity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get activity;

  /// No description provided for @partnerProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil Partenaire'**
  String get partnerProfile;

  /// No description provided for @seeDetails.
  ///
  /// In fr, this message translates to:
  /// **'Voir détails'**
  String get seeDetails;

  /// No description provided for @establishmentsAndInterlocutors.
  ///
  /// In fr, this message translates to:
  /// **'Établissements & Interlocuteurs'**
  String get establishmentsAndInterlocutors;

  /// No description provided for @eliteStatus.
  ///
  /// In fr, this message translates to:
  /// **'Statut Élite'**
  String get eliteStatus;

  /// No description provided for @eliteMember.
  ///
  /// In fr, this message translates to:
  /// **'Membre Élite'**
  String get eliteMember;

  /// No description provided for @standardUser.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur standard'**
  String get standardUser;

  /// No description provided for @promoteToElite.
  ///
  /// In fr, this message translates to:
  /// **'Promouvoir en Élite'**
  String get promoteToElite;

  /// No description provided for @revokeEliteStatus.
  ///
  /// In fr, this message translates to:
  /// **'Révoquer le statut Élite'**
  String get revokeEliteStatus;

  /// No description provided for @userDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur supprimé avec succès'**
  String get userDeleted;

  /// No description provided for @userDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail utilisateur'**
  String get userDetail;

  /// No description provided for @pendingPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements en attente'**
  String get pendingPayments;

  /// No description provided for @paymentValidated.
  ///
  /// In fr, this message translates to:
  /// **'Paiement validé — abonnement activé'**
  String get paymentValidated;

  /// No description provided for @paymentCancelledAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Paiement annulé — abonnement révoqué'**
  String get paymentCancelledAdmin;

  /// No description provided for @verifyManualPayments.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez et validez les paiements manuels'**
  String get verifyManualPayments;

  /// No description provided for @verifyApproveEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez et approuvez les nouveaux établissements'**
  String get verifyApproveEstablishments;

  /// No description provided for @verifyApprovePartners.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez et approuvez les nouveaux partenaires'**
  String get verifyApprovePartners;

  /// No description provided for @planYearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get planYearly;

  /// No description provided for @planMonthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get planMonthly;

  /// No description provided for @totalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get totalAmount;

  /// No description provided for @submittedOn.
  ///
  /// In fr, this message translates to:
  /// **'Soumis le'**
  String get submittedOn;

  /// No description provided for @confirmValidation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer la validation'**
  String get confirmValidation;

  /// No description provided for @cancelPaymentTitle.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement ?'**
  String get cancelPaymentTitle;

  /// No description provided for @allReviews.
  ///
  /// In fr, this message translates to:
  /// **'Tous les avis'**
  String get allReviews;

  /// No description provided for @reportedReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis signalés'**
  String get reportedReviews;

  /// No description provided for @managePlatformReviews.
  ///
  /// In fr, this message translates to:
  /// **'Gérez l\'ensemble des avis de la plateforme'**
  String get managePlatformReviews;

  /// No description provided for @suggestionApproved.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion approuvée'**
  String get suggestionApproved;

  /// No description provided for @suggestionRejected.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion rejetée'**
  String get suggestionRejected;

  /// No description provided for @anonymeUser.
  ///
  /// In fr, this message translates to:
  /// **'Anonyme'**
  String get anonymeUser;

  /// No description provided for @allFeminine.
  ///
  /// In fr, this message translates to:
  /// **'Toutes'**
  String get allFeminine;

  /// No description provided for @approvedFeminine.
  ///
  /// In fr, this message translates to:
  /// **'Approuvées'**
  String get approvedFeminine;

  /// No description provided for @rejectedFeminine.
  ///
  /// In fr, this message translates to:
  /// **'Rejetées'**
  String get rejectedFeminine;

  /// No description provided for @adminSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions communauté'**
  String get adminSuggestions;

  /// No description provided for @wilayasAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité wilayas'**
  String get wilayasAvailability;

  /// No description provided for @categoriesAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité catégories'**
  String get categoriesAvailability;

  /// No description provided for @wilayasAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Wilayas disponibles'**
  String get wilayasAvailable;

  /// No description provided for @categoriesAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Catégories disponibles'**
  String get categoriesAvailable;

  /// No description provided for @updateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la mise à jour'**
  String get updateError;

  /// No description provided for @createPartner.
  ///
  /// In fr, this message translates to:
  /// **'Créer un partenaire'**
  String get createPartner;

  /// No description provided for @accountInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get accountInfo;

  /// No description provided for @atLeast8Chars.
  ///
  /// In fr, this message translates to:
  /// **'Au moins 8 caractères'**
  String get atLeast8Chars;

  /// No description provided for @passwordStrength.
  ///
  /// In fr, this message translates to:
  /// **'Doit contenir majuscule, minuscule et chiffre'**
  String get passwordStrength;

  /// No description provided for @invalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro invalide'**
  String get invalidPhone;

  /// No description provided for @companyInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations de la société'**
  String get companyInfo;

  /// No description provided for @societyName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la société'**
  String get societyName;

  /// No description provided for @companyNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la société requis'**
  String get companyNameRequired;

  /// No description provided for @registrationNumberOptional.
  ///
  /// In fr, this message translates to:
  /// **'N° registre de commerce (optionnel)'**
  String get registrationNumberOptional;

  /// No description provided for @taxIdOptional.
  ///
  /// In fr, this message translates to:
  /// **'NIF / Identifiant fiscal (optionnel)'**
  String get taxIdOptional;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email requis'**
  String get emailRequired;

  /// No description provided for @management.
  ///
  /// In fr, this message translates to:
  /// **'Gestion'**
  String get management;

  /// No description provided for @moderation.
  ///
  /// In fr, this message translates to:
  /// **'Modération'**
  String get moderation;

  /// No description provided for @paymentsSection.
  ///
  /// In fr, this message translates to:
  /// **'Paiements'**
  String get paymentsSection;

  /// No description provided for @community.
  ///
  /// In fr, this message translates to:
  /// **'Communauté'**
  String get community;

  /// No description provided for @suggestionsMenu.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get suggestionsMenu;

  /// No description provided for @deployment.
  ///
  /// In fr, this message translates to:
  /// **'Déploiement'**
  String get deployment;

  /// No description provided for @administration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get administration;

  /// No description provided for @createEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Créer un établissement'**
  String get createEstablishment;

  /// No description provided for @saveChanges.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les modifications'**
  String get saveChanges;

  /// No description provided for @subcategoryRequired.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie requise'**
  String get subcategoryRequired;

  /// No description provided for @descriptionRequired.
  ///
  /// In fr, this message translates to:
  /// **'Description requise'**
  String get descriptionRequired;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @addressRequiredMsg.
  ///
  /// In fr, this message translates to:
  /// **'Adresse requise'**
  String get addressRequiredMsg;

  /// No description provided for @interlocutorOptional.
  ///
  /// In fr, this message translates to:
  /// **'Interlocuteur (optionnel)'**
  String get interlocutorOptional;

  /// No description provided for @contactPersonDesc.
  ///
  /// In fr, this message translates to:
  /// **'Personne de contact au sein de l\'établissement'**
  String get contactPersonDesc;

  /// No description provided for @pricing.
  ///
  /// In fr, this message translates to:
  /// **'Tarification'**
  String get pricing;

  /// No description provided for @servicesOptional.
  ///
  /// In fr, this message translates to:
  /// **'Services (optionnel)'**
  String get servicesOptional;

  /// No description provided for @amenitiesOptional.
  ///
  /// In fr, this message translates to:
  /// **'Équipements (optionnel)'**
  String get amenitiesOptional;

  /// No description provided for @openingHoursOptional.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture (optionnel)'**
  String get openingHoursOptional;

  /// No description provided for @openShort.
  ///
  /// In fr, this message translates to:
  /// **'Ouv.'**
  String get openShort;

  /// No description provided for @closeShort.
  ///
  /// In fr, this message translates to:
  /// **'Ferm.'**
  String get closeShort;

  /// No description provided for @pleaseSelectSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une sous-catégorie'**
  String get pleaseSelectSubcategory;

  /// No description provided for @partnerCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire {companyName} créé avec succès'**
  String partnerCreatedSuccess(String companyName);

  /// No description provided for @establishmentCreatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Établissement \"{name}\" créé avec succès'**
  String establishmentCreatedSuccess(String name);

  /// No description provided for @establishmentUpdatedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Établissement \"{name}\" modifié avec succès'**
  String establishmentUpdatedSuccess(String name);

  /// No description provided for @filterPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get filterPending;

  /// No description provided for @filterSuspended.
  ///
  /// In fr, this message translates to:
  /// **'Suspendus'**
  String get filterSuspended;

  /// No description provided for @filterApproved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvés'**
  String get filterApproved;

  /// No description provided for @resetFilters.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get resetFilters;

  /// No description provided for @commune.
  ///
  /// In fr, this message translates to:
  /// **'Commune'**
  String get commune;

  /// No description provided for @subscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscription;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @yesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yesLabel;

  /// No description provided for @setAsFeatured.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à la une'**
  String get setAsFeatured;

  /// No description provided for @editTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editTooltip;

  /// No description provided for @partnerRole.
  ///
  /// In fr, this message translates to:
  /// **'Partenaire'**
  String get partnerRole;

  /// No description provided for @approveEstablishmentQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Approuver « {name} » ? Il sera visible sur l\'annuaire.'**
  String approveEstablishmentQuestion(String name);

  /// No description provided for @rejectQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter « {name} » ?'**
  String rejectQuestion(String name);

  /// No description provided for @removeFromFeaturedQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Retirer « {name} » de la mise en avant ?'**
  String removeFromFeaturedQuestion(String name);

  /// No description provided for @setAsFeaturedQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Mettre « {name} » à la une.'**
  String setAsFeaturedQuestion(String name);

  /// No description provided for @deleteEstablishmentConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer « {name} » ?\n\nCette action est irréversible.'**
  String deleteEstablishmentConfirm(String name);

  /// No description provided for @establishmentApprovedMsg.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été approuvé'**
  String establishmentApprovedMsg(String name);

  /// No description provided for @establishmentRejectedMsg.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été rejeté'**
  String establishmentRejectedMsg(String name);

  /// No description provided for @pendingEstablishmentsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} établissement(s) en attente'**
  String pendingEstablishmentsCount(int count);

  /// No description provided for @partnerApprovedMsg.
  ///
  /// In fr, this message translates to:
  /// **'{name} a été approuvé'**
  String partnerApprovedMsg(String name);

  /// No description provided for @rejectPartnerQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir rejeter {name} ?'**
  String rejectPartnerQuestion(String name);

  /// No description provided for @suspendPartnerQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir suspendre {name} ?'**
  String suspendPartnerQuestion(String name);

  /// No description provided for @searchReview.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un avis...'**
  String get searchReview;

  /// No description provided for @searchReportedReview.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un avis signalé...'**
  String get searchReportedReview;

  /// No description provided for @examineReports.
  ///
  /// In fr, this message translates to:
  /// **'Examinez et traitez les signalements'**
  String get examineReports;

  /// No description provided for @approveSuggestionQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Approuver « {name} » ? Elle sera convertie en établissement.'**
  String approveSuggestionQuestion(String name);

  /// No description provided for @noEstablishment.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement'**
  String get noEstablishment;

  /// No description provided for @phoneShort.
  ///
  /// In fr, this message translates to:
  /// **'Tél.'**
  String get phoneShort;

  /// No description provided for @explainRejectReason.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez la raison du rejet...'**
  String get explainRejectReason;

  /// No description provided for @explainSuspendReason.
  ///
  /// In fr, this message translates to:
  /// **'Expliquez la raison de la suspension...'**
  String get explainSuspendReason;

  /// No description provided for @noLabel.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get noLabel;

  /// No description provided for @refLabel.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get refLabel;

  /// No description provided for @deleteEstablishmentQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer \"{name}\" ? Cette action est irréversible.'**
  String deleteEstablishmentQuestion(String name);

  /// No description provided for @validatePaymentQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Valider le paiement de \"{name}\" ?\n\nL\'abonnement sera activé immédiatement.'**
  String validatePaymentQuestion(String name);

  /// No description provided for @cancelPaymentQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Annuler le paiement de \"{name}\" ?\n\nL\'abonnement sera immédiatement révoqué.'**
  String cancelPaymentQuestion(String name);

  /// No description provided for @previousShort.
  ///
  /// In fr, this message translates to:
  /// **'Préc.'**
  String get previousShort;

  /// No description provided for @nextShort.
  ///
  /// In fr, this message translates to:
  /// **'Suiv.'**
  String get nextShort;

  /// No description provided for @deleteUserQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer \"{name}\" ? Cette action est irréversible et supprimera également ses avis, favoris et profil partenaire.'**
  String deleteUserQuestion(String name);

  /// No description provided for @allEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Tous les établissements'**
  String get allEstablishments;

  /// No description provided for @performances.
  ///
  /// In fr, this message translates to:
  /// **'Performances'**
  String get performances;

  /// No description provided for @mySubscription.
  ///
  /// In fr, this message translates to:
  /// **'Mon abonnement'**
  String get mySubscription;

  /// No description provided for @suggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get suggestions;

  /// No description provided for @versionNumber.
  ///
  /// In fr, this message translates to:
  /// **'Version {version}'**
  String versionNumber(String version);

  /// No description provided for @copyrightNotice.
  ///
  /// In fr, this message translates to:
  /// **'© {year} Win — Tous droits réservés'**
  String copyrightNotice(int year);

  /// No description provided for @privacyHeaderTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont protégées'**
  String get privacyHeaderTitle;

  /// No description provided for @lastUpdatedJuly2026.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : juillet 2026'**
  String get lastUpdatedJuly2026;

  /// No description provided for @privacyS1Title.
  ///
  /// In fr, this message translates to:
  /// **'1. Qui sommes-nous ?'**
  String get privacyS1Title;

  /// No description provided for @privacyS1Content.
  ///
  /// In fr, this message translates to:
  /// **'Win (وِين) est un annuaire numérique des établissements en Algérie. Cette politique décrit comment nous collectons, utilisons et protégeons vos informations personnelles lorsque vous utilisez notre application mobile.'**
  String get privacyS1Content;

  /// No description provided for @privacyS2Title.
  ///
  /// In fr, this message translates to:
  /// **'2. Données collectées'**
  String get privacyS2Title;

  /// No description provided for @privacyS2Content.
  ///
  /// In fr, this message translates to:
  /// **'Lors de votre inscription :\n• Nom et prénom\n• Adresse e-mail\n• Numéro de téléphone (optionnel)\n• Wilaya de résidence\n\nLors de l\'utilisation de l\'application :\n• Localisation approximative (pour les recherches à proximité, uniquement si vous l\'autorisez)\n• Historique de navigation dans l\'application\n• Avis et notes publiés\n• Établissements ajoutés en favoris'**
  String get privacyS2Content;

  /// No description provided for @privacyS3Title.
  ///
  /// In fr, this message translates to:
  /// **'3. Utilisation des données'**
  String get privacyS3Title;

  /// No description provided for @privacyS3Content.
  ///
  /// In fr, this message translates to:
  /// **'Vos données nous permettent de :\n• Vous fournir les services de l\'annuaire Win\n• Personnaliser les résultats de recherche selon votre localisation\n• Vous envoyer des notifications relatives à vos favoris ou avis\n• Améliorer la qualité et la pertinence de nos contenus\n• Garantir la sécurité des comptes utilisateurs'**
  String get privacyS3Content;

  /// No description provided for @privacyS4Title.
  ///
  /// In fr, this message translates to:
  /// **'4. Partage des données'**
  String get privacyS4Title;

  /// No description provided for @privacyS4Content.
  ///
  /// In fr, this message translates to:
  /// **'Nous ne vendons jamais vos données personnelles. Elles peuvent être partagées avec :\n• Firebase (Google) : notifications push et authentification\n• Prestataires de paiement : traitement des abonnements partenaires (aucune donnée bancaire n\'est stockée sur nos serveurs)\n• Autorités compétentes : uniquement si la loi algérienne l\'exige'**
  String get privacyS4Content;

  /// No description provided for @privacyS5Title.
  ///
  /// In fr, this message translates to:
  /// **'5. Conservation des données'**
  String get privacyS5Title;

  /// No description provided for @privacyS5Content.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont conservées tant que votre compte est actif. En cas de suppression de compte, vos informations personnelles sont effacées dans un délai de 30 jours, à l\'exception des données requises à des fins légales ou comptables.'**
  String get privacyS5Content;

  /// No description provided for @privacyS6Title.
  ///
  /// In fr, this message translates to:
  /// **'6. Vos droits'**
  String get privacyS6Title;

  /// No description provided for @privacyS6Content.
  ///
  /// In fr, this message translates to:
  /// **'Conformément à la réglementation applicable, vous disposez des droits suivants :\n• Accès à vos données personnelles\n• Rectification des informations inexactes\n• Suppression de votre compte et de vos données\n• Opposition au traitement de vos données\n\nPour exercer ces droits, contactez-nous via la section \"Nous contacter\" de l\'application.'**
  String get privacyS6Content;

  /// No description provided for @privacyS7Title.
  ///
  /// In fr, this message translates to:
  /// **'7. Sécurité'**
  String get privacyS7Title;

  /// No description provided for @privacyS7Content.
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons le chiffrement HTTPS pour toutes les communications entre l\'application et nos serveurs. Les mots de passe sont hachés et ne sont jamais stockés en clair. L\'accès aux données est restreint au personnel autorisé.'**
  String get privacyS7Content;

  /// No description provided for @privacyS8Title.
  ///
  /// In fr, this message translates to:
  /// **'8. Modifications'**
  String get privacyS8Title;

  /// No description provided for @privacyS8Content.
  ///
  /// In fr, this message translates to:
  /// **'Cette politique peut être mise à jour. Toute modification importante vous sera notifiée par e-mail ou via une notification dans l\'application.'**
  String get privacyS8Content;

  /// No description provided for @privacyS9Title.
  ///
  /// In fr, this message translates to:
  /// **'9. Contact'**
  String get privacyS9Title;

  /// No description provided for @privacyS9Content.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question relative à cette politique de confidentialité, contactez-nous à :\nYassine-o@hotmail.fr'**
  String get privacyS9Content;

  /// No description provided for @termsS1Title.
  ///
  /// In fr, this message translates to:
  /// **'1. Présentation du service'**
  String get termsS1Title;

  /// No description provided for @termsS1Content.
  ///
  /// In fr, this message translates to:
  /// **'Win (وِين) est un annuaire numérique recensant les établissements commerciaux, culturels et de services en Algérie. En utilisant l\'application, vous acceptez sans réserve les présentes conditions d\'utilisation.'**
  String get termsS1Content;

  /// No description provided for @termsS2Title.
  ///
  /// In fr, this message translates to:
  /// **'2. Inscription et compte utilisateur'**
  String get termsS2Title;

  /// No description provided for @termsS2Content.
  ///
  /// In fr, this message translates to:
  /// **'• Vous devez fournir des informations exactes lors de votre inscription.\n• Vous êtes responsable de la confidentialité de votre mot de passe et de toutes les activités effectuées depuis votre compte.\n• Un seul compte par personne est autorisé.\n• L\'inscription est réservée aux personnes âgées de 13 ans et plus.'**
  String get termsS2Content;

  /// No description provided for @termsS3Title.
  ///
  /// In fr, this message translates to:
  /// **'3. Règles d\'utilisation'**
  String get termsS3Title;

  /// No description provided for @termsS3Content.
  ///
  /// In fr, this message translates to:
  /// **'Il est interdit de :\n• Publier des avis faux, trompeurs ou diffamatoires\n• Usurper l\'identité d\'un établissement ou d\'une personne\n• Utiliser l\'application à des fins illicites ou contraires à la législation algérienne\n• Scraper, copier ou reproduire le contenu sans autorisation\n• Spammer d\'autres utilisateurs ou partenaires\n• Tenter de compromettre la sécurité de la plateforme'**
  String get termsS3Content;

  /// No description provided for @termsS4Title.
  ///
  /// In fr, this message translates to:
  /// **'4. Avis et contenus utilisateurs'**
  String get termsS4Title;

  /// No description provided for @termsS4Content.
  ///
  /// In fr, this message translates to:
  /// **'En publiant un avis ou un contenu sur Win, vous nous accordez une licence non exclusive d\'utilisation de ce contenu à des fins d\'affichage sur la plateforme.\n\nNous nous réservons le droit de modérer, modifier ou supprimer tout contenu qui ne respecte pas nos règles ou la législation en vigueur, sans préavis.'**
  String get termsS4Content;

  /// No description provided for @termsS5Title.
  ///
  /// In fr, this message translates to:
  /// **'5. Espace partenaire'**
  String get termsS5Title;

  /// No description provided for @termsS5Content.
  ///
  /// In fr, this message translates to:
  /// **'Les établissements référencés sur Win peuvent souscrire à un abonnement partenaire pour bénéficier de fonctionnalités avancées (mise en avant, statistiques, etc.).\n\n• Les partenaires s\'engagent à fournir des informations exactes sur leurs établissements.\n• Les abonnements sont soumis à des conditions tarifaires spécifiques communiquées lors de la souscription.\n• Aucun remboursement n\'est accordé pour les périodes déjà consommées.'**
  String get termsS5Content;

  /// No description provided for @termsS6Title.
  ///
  /// In fr, this message translates to:
  /// **'6. Propriété intellectuelle'**
  String get termsS6Title;

  /// No description provided for @termsS6Content.
  ///
  /// In fr, this message translates to:
  /// **'L\'ensemble du contenu de l\'application Win (logo, design, textes, base de données) est protégé et appartient à ses créateurs. Toute reproduction, même partielle, sans autorisation écrite est interdite.'**
  String get termsS6Content;

  /// No description provided for @termsS7Title.
  ///
  /// In fr, this message translates to:
  /// **'7. Disponibilité du service'**
  String get termsS7Title;

  /// No description provided for @termsS7Content.
  ///
  /// In fr, this message translates to:
  /// **'Nous nous efforçons de maintenir l\'application disponible 24h/24, mais nous ne garantissons pas une disponibilité ininterrompue. Des interruptions peuvent survenir pour maintenance ou en cas de problème technique.'**
  String get termsS7Content;

  /// No description provided for @termsS8Title.
  ///
  /// In fr, this message translates to:
  /// **'8. Limitation de responsabilité'**
  String get termsS8Title;

  /// No description provided for @termsS8Content.
  ///
  /// In fr, this message translates to:
  /// **'Win agit en tant qu\'annuaire et ne peut être tenu responsable des informations fournies par les établissements ou les utilisateurs. Nous ne garantissons pas l\'exactitude ou l\'exhaustivité des données présentées.'**
  String get termsS8Content;

  /// No description provided for @termsS9Title.
  ///
  /// In fr, this message translates to:
  /// **'9. Modifications des conditions'**
  String get termsS9Title;

  /// No description provided for @termsS9Content.
  ///
  /// In fr, this message translates to:
  /// **'Ces conditions peuvent être mises à jour à tout moment. Vous serez informé de toute modification importante. La poursuite de l\'utilisation de l\'application après notification vaut acceptation des nouvelles conditions.'**
  String get termsS9Content;

  /// No description provided for @termsS10Title.
  ///
  /// In fr, this message translates to:
  /// **'10. Droit applicable'**
  String get termsS10Title;

  /// No description provided for @termsS10Content.
  ///
  /// In fr, this message translates to:
  /// **'Les présentes conditions sont régies par le droit algérien. Tout litige sera soumis aux tribunaux compétents de la wilaya d\'Alger.'**
  String get termsS10Content;

  /// No description provided for @termsS11Title.
  ///
  /// In fr, this message translates to:
  /// **'11. Contact'**
  String get termsS11Title;

  /// No description provided for @termsS11Content.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question relative aux présentes conditions, contactez-nous à :\nYassine-o@hotmail.fr'**
  String get termsS11Content;

  /// No description provided for @welcomePartner.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, Partenaire'**
  String get welcomePartner;

  /// No description provided for @manageYourEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos établissements'**
  String get manageYourEstablishments;

  /// No description provided for @totalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @averageRating.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne'**
  String get averageRating;

  /// No description provided for @reviewsN.
  ///
  /// In fr, this message translates to:
  /// **'{count} avis'**
  String reviewsN(int count);

  /// No description provided for @myEstablishmentsShort.
  ///
  /// In fr, this message translates to:
  /// **'Mes établ.'**
  String get myEstablishmentsShort;

  /// No description provided for @invoicesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get invoicesLabel;

  /// No description provided for @engagementFunnel.
  ///
  /// In fr, this message translates to:
  /// **'Funnel d\'engagement'**
  String get engagementFunnel;

  /// No description provided for @ratingDistributionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Distribution des notes'**
  String get ratingDistributionTitle;

  /// No description provided for @ratingTrend6Months.
  ///
  /// In fr, this message translates to:
  /// **'Note moyenne — 6 mois'**
  String get ratingTrend6Months;

  /// No description provided for @topCustomerWilayas.
  ///
  /// In fr, this message translates to:
  /// **'Top wilayas de vos clients'**
  String get topCustomerWilayas;

  /// No description provided for @stepGeneral.
  ///
  /// In fr, this message translates to:
  /// **'Général'**
  String get stepGeneral;

  /// No description provided for @stepLocation.
  ///
  /// In fr, this message translates to:
  /// **'Lieu'**
  String get stepLocation;

  /// No description provided for @stepDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get stepDetails;

  /// No description provided for @stepImages.
  ///
  /// In fr, this message translates to:
  /// **'Images'**
  String get stepImages;

  /// No description provided for @establishmentUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Établissement mis à jour'**
  String get establishmentUpdated;

  /// No description provided for @establishmentCreated.
  ///
  /// In fr, this message translates to:
  /// **'Établissement créé avec succès'**
  String get establishmentCreated;

  /// No description provided for @coverImageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Image de couverture'**
  String get coverImageLabel;

  /// No description provided for @imageGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie d\'images'**
  String get imageGallery;

  /// No description provided for @noImage.
  ///
  /// In fr, this message translates to:
  /// **'Aucune image'**
  String get noImage;

  /// No description provided for @deleteImageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'image ?'**
  String get deleteImageTitle;

  /// No description provided for @irreversibleAction.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get irreversibleAction;

  /// No description provided for @imageDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Image supprimée'**
  String get imageDeleted;

  /// No description provided for @addService.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un service'**
  String get addService;

  /// No description provided for @addAmenity.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un équipement'**
  String get addAmenity;

  /// No description provided for @openAbbrev.
  ///
  /// In fr, this message translates to:
  /// **'Ouv.'**
  String get openAbbrev;

  /// No description provided for @closeAbbrev.
  ///
  /// In fr, this message translates to:
  /// **'Ferm.'**
  String get closeAbbrev;

  /// No description provided for @addImage.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une image'**
  String get addImage;

  /// No description provided for @positionFunctionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poste / Fonction'**
  String get positionFunctionLabel;

  /// No description provided for @errorInvalidPhone.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide. Formats acceptés : 0555123456, +213555123456, 0770 123 456'**
  String get errorInvalidPhone;

  /// No description provided for @errorInvalidEstablishmentName.
  ///
  /// In fr, this message translates to:
  /// **'Le nom de l\'établissement est invalide.'**
  String get errorInvalidEstablishmentName;

  /// No description provided for @errorInvalidAddress.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse est invalide.'**
  String get errorInvalidAddress;

  /// No description provided for @errorSelectCategory.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une catégorie.'**
  String get errorSelectCategory;

  /// No description provided for @errorSelectWilaya.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une wilaya.'**
  String get errorSelectWilaya;

  /// No description provided for @errorInvalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide.'**
  String get errorInvalidEmail;

  /// No description provided for @errorInvalidUrl.
  ///
  /// In fr, this message translates to:
  /// **'L\'URL saisie est invalide.'**
  String get errorInvalidUrl;

  /// No description provided for @errorSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée. Veuillez vous reconnecter.'**
  String get errorSessionExpired;

  /// No description provided for @errorNetworkConnection.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion. Vérifiez votre accès internet.'**
  String get errorNetworkConnection;

  /// No description provided for @chooseYourOffer.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez votre offre'**
  String get chooseYourOffer;

  /// No description provided for @subscriptionPageSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Basic est gratuit pour toujours. Passez à Premium ou Gold pour débloquer plus de fonctionnalités.'**
  String get subscriptionPageSubtitle;

  /// No description provided for @featureEstablishmentProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil établissement visible'**
  String get featureEstablishmentProfile;

  /// No description provided for @featureContactLocation.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées & localisation'**
  String get featureContactLocation;

  /// No description provided for @featureAppointmentBooking.
  ///
  /// In fr, this message translates to:
  /// **'Prise de rendez-vous client'**
  String get featureAppointmentBooking;

  /// No description provided for @featureWhatsappButton.
  ///
  /// In fr, this message translates to:
  /// **'Bouton WhatsApp'**
  String get featureWhatsappButton;

  /// No description provided for @featureSocialNetworks.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux (Facebook, Instagram…)'**
  String get featureSocialNetworks;

  /// No description provided for @featurePhotoGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie photos & vidéos'**
  String get featurePhotoGallery;

  /// No description provided for @featureCustomerReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis & notes clients'**
  String get featureCustomerReviews;

  /// No description provided for @featureAllBasicIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Tout Basic inclus'**
  String get featureAllBasicIncluded;

  /// No description provided for @featureAllPremiumIncluded.
  ///
  /// In fr, this message translates to:
  /// **'Tout Premium inclus'**
  String get featureAllPremiumIncluded;

  /// No description provided for @featureFeaturedListing.
  ///
  /// In fr, this message translates to:
  /// **'Mise à la une automatique'**
  String get featureFeaturedListing;

  /// No description provided for @featurePriorityResults.
  ///
  /// In fr, this message translates to:
  /// **'Priorité dans les résultats'**
  String get featurePriorityResults;

  /// No description provided for @featureGoldBadge.
  ///
  /// In fr, this message translates to:
  /// **'Badge établissement Gold'**
  String get featureGoldBadge;

  /// No description provided for @pricePerMonth.
  ///
  /// In fr, this message translates to:
  /// **'{price} DA / mois'**
  String pricePerMonth(String price);

  /// No description provided for @pricePerYear.
  ///
  /// In fr, this message translates to:
  /// **'{price} DA / an'**
  String pricePerYear(String price);

  /// No description provided for @monthlyEquivalent.
  ///
  /// In fr, this message translates to:
  /// **'soit {price} DA/mois'**
  String monthlyEquivalent(String price);

  /// No description provided for @savingPercent.
  ///
  /// In fr, this message translates to:
  /// **'Économisez {percent}%'**
  String savingPercent(int percent);

  /// No description provided for @transferInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Effectuez votre virement puis soumettez votre demande. L\'admin validera dans les 24-48h.'**
  String get transferInstructions;

  /// No description provided for @inAgencyPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en agence'**
  String get inAgencyPayment;

  /// No description provided for @cashInstructions.
  ///
  /// In fr, this message translates to:
  /// **'Soumettez votre demande, puis rendez-vous à notre bureau pour régler en espèces. L\'admin validera votre paiement sur place.'**
  String get cashInstructions;

  /// No description provided for @submitMyRequest.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre ma demande'**
  String get submitMyRequest;

  /// No description provided for @confirmMyVisit.
  ///
  /// In fr, this message translates to:
  /// **'Je confirme ma visite'**
  String get confirmMyVisit;

  /// No description provided for @takeAdvantage.
  ///
  /// In fr, this message translates to:
  /// **'J\'en profite'**
  String get takeAdvantage;

  /// No description provided for @allFeatures.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les fonctionnalités'**
  String get allFeatures;

  /// No description provided for @featureOfPlan.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalité {planLabel}'**
  String featureOfPlan(String planLabel);

  /// No description provided for @featureAvailableFromPlan.
  ///
  /// In fr, this message translates to:
  /// **'Cette fonctionnalité est disponible à partir de l\'offre {planLabel}. Sélectionnez l\'offre {planLabel} ci-dessus pour en profiter.'**
  String featureAvailableFromPlan(String planLabel);

  /// No description provided for @paymentPendingValidation.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en cours de validation'**
  String get paymentPendingValidation;

  /// No description provided for @paymentPendingDescription.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a bien été enregistrée. Notre équipe la validera dans les 24–48h. Votre accès sera activé dès confirmation.'**
  String get paymentPendingDescription;

  /// No description provided for @refreshStatus.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser le statut'**
  String get refreshStatus;

  /// No description provided for @activeSubscriptionPlan.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif — {planLabel}'**
  String activeSubscriptionPlan(String planLabel);

  /// No description provided for @expiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String expiresOn(String date);

  /// No description provided for @establishmentsVisibleOnApp.
  ///
  /// In fr, this message translates to:
  /// **'Vos établissements sont visibles sur l\'application.'**
  String get establishmentsVisibleOnApp;

  /// No description provided for @confirmCancelSubscriptionContent.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler votre abonnement ?\n\nVos établissements ne seront plus visibles sur l\'application.'**
  String get confirmCancelSubscriptionContent;

  /// No description provided for @requestRegisteredWithNumber.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a été enregistrée ({number}).'**
  String requestRegisteredWithNumber(String number);

  /// No description provided for @bringRequestNumber.
  ///
  /// In fr, this message translates to:
  /// **'Munissez-vous de votre numéro de demande. L\'admin validera votre paiement sur place.'**
  String get bringRequestNumber;

  /// No description provided for @adminValidates24_48h.
  ///
  /// In fr, this message translates to:
  /// **'L\'admin validera votre paiement sous 24-48h.'**
  String get adminValidates24_48h;

  /// No description provided for @beneficiary.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire'**
  String get beneficiary;

  /// No description provided for @moreCategoriesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Plus de catégories'**
  String get moreCategoriesTitle;

  /// No description provided for @moreButton.
  ///
  /// In fr, this message translates to:
  /// **'Plus'**
  String get moreButton;

  /// No description provided for @comingSoon.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt'**
  String get comingSoon;

  /// No description provided for @comingSoonFull.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get comingSoonFull;

  /// No description provided for @seeLess.
  ///
  /// In fr, this message translates to:
  /// **'Voir moins'**
  String get seeLess;

  /// No description provided for @seeNMore.
  ///
  /// In fr, this message translates to:
  /// **'Voir {n} de plus'**
  String seeNMore(int n);

  /// No description provided for @noEstablishmentsInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'y a pas encore d\'établissement dans cette catégorie'**
  String get noEstablishmentsInCategory;

  /// No description provided for @anErrorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get anErrorOccurred;

  /// No description provided for @tabOverview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get tabOverview;

  /// No description provided for @tabInfos.
  ///
  /// In fr, this message translates to:
  /// **'Infos'**
  String get tabInfos;

  /// No description provided for @tabSimilar.
  ///
  /// In fr, this message translates to:
  /// **'Similaires'**
  String get tabSimilar;

  /// No description provided for @seeAllPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Voir toutes les photos ({count})'**
  String seeAllPhotos(int count);

  /// No description provided for @contactRequest.
  ///
  /// In fr, this message translates to:
  /// **'Prise de contact'**
  String get contactRequest;

  /// No description provided for @yourName.
  ///
  /// In fr, this message translates to:
  /// **'Votre nom'**
  String get yourName;

  /// No description provided for @yourEmail.
  ///
  /// In fr, this message translates to:
  /// **'Votre email'**
  String get yourEmail;

  /// No description provided for @yourMessage.
  ///
  /// In fr, this message translates to:
  /// **'Votre message'**
  String get yourMessage;

  /// No description provided for @contactRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Votre demande a bien été envoyée !'**
  String get contactRequestSent;

  /// No description provided for @contactRequestError.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue, réessayez.'**
  String get contactRequestError;

  /// No description provided for @customerReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis clients'**
  String get customerReviews;

  /// No description provided for @notAvailableForEstab.
  ///
  /// In fr, this message translates to:
  /// **'Non disponible pour cet établissement'**
  String get notAvailableForEstab;

  /// No description provided for @featureNotAvailable.
  ///
  /// In fr, this message translates to:
  /// **'{feature} n\'est pas disponible pour cet établissement pour le moment.'**
  String featureNotAvailable(String feature);

  /// No description provided for @sortMostRecent.
  ///
  /// In fr, this message translates to:
  /// **'Plus récents'**
  String get sortMostRecent;

  /// No description provided for @sortOldest.
  ///
  /// In fr, this message translates to:
  /// **'Plus anciens'**
  String get sortOldest;

  /// No description provided for @sortHighestRated.
  ///
  /// In fr, this message translates to:
  /// **'Mieux notés'**
  String get sortHighestRated;

  /// No description provided for @sortLowestRated.
  ///
  /// In fr, this message translates to:
  /// **'Moins bien notés'**
  String get sortLowestRated;

  /// No description provided for @eliteReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis d\'Élites'**
  String get eliteReviews;

  /// No description provided for @nStars.
  ///
  /// In fr, this message translates to:
  /// **'{n} étoiles'**
  String nStars(int n);

  /// No description provided for @visitedOn.
  ///
  /// In fr, this message translates to:
  /// **'Visité le {date}'**
  String visitedOn(String date);

  /// No description provided for @detailedRatings.
  ///
  /// In fr, this message translates to:
  /// **'Notes détaillées'**
  String get detailedRatings;

  /// No description provided for @subRatingQuality.
  ///
  /// In fr, this message translates to:
  /// **'Qualité'**
  String get subRatingQuality;

  /// No description provided for @subRatingWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get subRatingWelcome;

  /// No description provided for @subRatingInformation.
  ///
  /// In fr, this message translates to:
  /// **'Information'**
  String get subRatingInformation;

  /// No description provided for @subRatingValue.
  ///
  /// In fr, this message translates to:
  /// **'Qualité/prix'**
  String get subRatingValue;

  /// No description provided for @subRatingAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get subRatingAvailability;

  /// No description provided for @subRatingReliability.
  ///
  /// In fr, this message translates to:
  /// **'Fiabilité'**
  String get subRatingReliability;

  /// No description provided for @subRatingComfort.
  ///
  /// In fr, this message translates to:
  /// **'Confort'**
  String get subRatingComfort;

  /// No description provided for @timeAgoYears.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} an(s)'**
  String timeAgoYears(int count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} mois'**
  String timeAgoMonths(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count} jour(s)'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In fr, this message translates to:
  /// **'il y a {count}h'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoJustNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeAgoJustNow;

  /// No description provided for @seeHours.
  ///
  /// In fr, this message translates to:
  /// **'· Voir les horaires'**
  String get seeHours;

  /// No description provided for @addReview.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un avis'**
  String get addReview;

  /// No description provided for @website.
  ///
  /// In fr, this message translates to:
  /// **'Site internet'**
  String get website;

  /// No description provided for @favorited.
  ///
  /// In fr, this message translates to:
  /// **'Favori ✓'**
  String get favorited;

  /// No description provided for @recommendQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Recommander cet établissement ?'**
  String get recommendQuestion;

  /// No description provided for @maybe.
  ///
  /// In fr, this message translates to:
  /// **'Peut-être'**
  String get maybe;

  /// No description provided for @removedFromFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Retiré de vos favoris'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à vos favoris ! Revenez quand vous voulez 😊'**
  String get addedToFavorites;

  /// No description provided for @informationSection.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get informationSection;

  /// No description provided for @drivingMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{min} min en voiture'**
  String drivingMinutes(int min);

  /// No description provided for @seeDirections.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'itinéraire'**
  String get seeDirections;

  /// No description provided for @features.
  ///
  /// In fr, this message translates to:
  /// **'Fonctionnalités'**
  String get features;

  /// No description provided for @aboutThisPlace.
  ///
  /// In fr, this message translates to:
  /// **'À propos de cet établissement'**
  String get aboutThisPlace;

  /// No description provided for @showLess.
  ///
  /// In fr, this message translates to:
  /// **'Réduire'**
  String get showLess;

  /// No description provided for @readMore.
  ///
  /// In fr, this message translates to:
  /// **'Continuer à lire'**
  String get readMore;

  /// No description provided for @writeAReview.
  ///
  /// In fr, this message translates to:
  /// **'Laisser un avis'**
  String get writeAReview;

  /// No description provided for @writeReviewHint.
  ///
  /// In fr, this message translates to:
  /// **'Tapez pour écrire un avis...'**
  String get writeReviewHint;

  /// No description provided for @addPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get addPhoto;

  /// No description provided for @recommendedReviews.
  ///
  /// In fr, this message translates to:
  /// **'Avis recommandés'**
  String get recommendedReviews;

  /// No description provided for @noSimilarEstablishments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement similaire trouvé.'**
  String get noSimilarEstablishments;

  /// No description provided for @chooseNavApp.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une application de navigation'**
  String get chooseNavApp;

  /// No description provided for @gpsNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation GPS'**
  String get gpsNavigation;

  /// No description provided for @socialNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation sociale'**
  String get socialNavigation;

  /// No description provided for @appleNavigation.
  ///
  /// In fr, this message translates to:
  /// **'Navigation Apple'**
  String get appleNavigation;

  /// No description provided for @otherApps.
  ///
  /// In fr, this message translates to:
  /// **'Autres applications'**
  String get otherApps;

  /// No description provided for @openWithSystem.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir avec le système'**
  String get openWithSystem;

  /// No description provided for @copyAddress.
  ///
  /// In fr, this message translates to:
  /// **'Copier l\'adresse'**
  String get copyAddress;

  /// No description provided for @loginToClaimBusiness.
  ///
  /// In fr, this message translates to:
  /// **'Connectez-vous pour revendiquer cet établissement et accéder aux offres partenaires.'**
  String get loginToClaimBusiness;

  /// No description provided for @ownThisPlace.
  ///
  /// In fr, this message translates to:
  /// **'Vous possédez cet établissement ?'**
  String get ownThisPlace;

  /// No description provided for @claimNow.
  ///
  /// In fr, this message translates to:
  /// **'Revendiquez-le dès maintenant'**
  String get claimNow;

  /// No description provided for @allPhotosTab.
  ///
  /// In fr, this message translates to:
  /// **'Tout ({count})'**
  String allPhotosTab(int count);

  /// No description provided for @noPhotosAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucune photo disponible'**
  String get noPhotosAvailable;

  /// No description provided for @photoCategoryOthers.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get photoCategoryOthers;

  /// No description provided for @photoCategoryPlats.
  ///
  /// In fr, this message translates to:
  /// **'Plats'**
  String get photoCategoryPlats;

  /// No description provided for @photoCategoryBoissons.
  ///
  /// In fr, this message translates to:
  /// **'Boissons'**
  String get photoCategoryBoissons;

  /// No description provided for @photoCategoryDesserts.
  ///
  /// In fr, this message translates to:
  /// **'Desserts'**
  String get photoCategoryDesserts;

  /// No description provided for @photoCategoryMenu.
  ///
  /// In fr, this message translates to:
  /// **'Menu'**
  String get photoCategoryMenu;

  /// No description provided for @photoCategoryInterieur.
  ///
  /// In fr, this message translates to:
  /// **'Intérieur'**
  String get photoCategoryInterieur;

  /// No description provided for @photoCategoryExterieur.
  ///
  /// In fr, this message translates to:
  /// **'Extérieur'**
  String get photoCategoryExterieur;

  /// No description provided for @photoCategoryTerrasse.
  ///
  /// In fr, this message translates to:
  /// **'Terrasse'**
  String get photoCategoryTerrasse;

  /// No description provided for @photoCategoryAmbiance.
  ///
  /// In fr, this message translates to:
  /// **'Ambiance'**
  String get photoCategoryAmbiance;

  /// No description provided for @photoCategoryBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar'**
  String get photoCategoryBar;

  /// No description provided for @photoCategorySalle.
  ///
  /// In fr, this message translates to:
  /// **'Salle'**
  String get photoCategorySalle;

  /// No description provided for @photoCategoryEntree.
  ///
  /// In fr, this message translates to:
  /// **'Façade'**
  String get photoCategoryEntree;

  /// No description provided for @photoCategoryCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine'**
  String get photoCategoryCuisine;

  /// No description provided for @photoCategoryParking.
  ///
  /// In fr, this message translates to:
  /// **'Parking'**
  String get photoCategoryParking;

  /// No description provided for @photoCategoryEvenements.
  ///
  /// In fr, this message translates to:
  /// **'Événements'**
  String get photoCategoryEvenements;

  /// No description provided for @photoCategoryPromotions.
  ///
  /// In fr, this message translates to:
  /// **'Promos'**
  String get photoCategoryPromotions;

  /// No description provided for @photoCategoryProduits.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get photoCategoryProduits;

  /// No description provided for @searchBarHint.
  ///
  /// In fr, this message translates to:
  /// **'Restaurants, hôpitaux, banques...'**
  String get searchBarHint;

  /// No description provided for @resultsNearYou.
  ///
  /// In fr, this message translates to:
  /// **'Résultats près de vous'**
  String get resultsNearYou;

  /// No description provided for @locationDetectedRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Position détectée — Actualiser'**
  String get locationDetectedRefresh;

  /// No description provided for @useMyLocation.
  ///
  /// In fr, this message translates to:
  /// **'Utiliser ma position actuelle'**
  String get useMyLocation;

  /// No description provided for @searchesIncludeLocation.
  ///
  /// In fr, this message translates to:
  /// **'Les recherches incluent automatiquement votre position'**
  String get searchesIncludeLocation;

  /// No description provided for @recentSearches.
  ///
  /// In fr, this message translates to:
  /// **'Recherches récentes'**
  String get recentSearches;

  /// No description provided for @popularSearches.
  ///
  /// In fr, this message translates to:
  /// **'Recherches populaires'**
  String get popularSearches;

  /// No description provided for @searchNearMeFor.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher \"{query}\" près de moi'**
  String searchNearMeFor(String query);

  /// No description provided for @seeAllResultsFor.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les résultats pour \"{query}\"'**
  String seeAllResultsFor(String query);

  /// No description provided for @searchResultsOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Les résultats s\'affichent directement sur la carte'**
  String get searchResultsOnMap;

  /// No description provided for @searchWilayaHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une wilaya...'**
  String get searchWilayaHint;

  /// No description provided for @filterMinRating.
  ///
  /// In fr, this message translates to:
  /// **'Note minimum'**
  String get filterMinRating;

  /// No description provided for @ratingAndAbove.
  ///
  /// In fr, this message translates to:
  /// **'{rating} et plus'**
  String ratingAndAbove(String rating);

  /// No description provided for @sortRelevance.
  ///
  /// In fr, this message translates to:
  /// **'Pertinence'**
  String get sortRelevance;

  /// No description provided for @sortRecentLabel.
  ///
  /// In fr, this message translates to:
  /// **'Plus récent'**
  String get sortRecentLabel;

  /// No description provided for @priceEconomicalLabel.
  ///
  /// In fr, this message translates to:
  /// **'Économique'**
  String get priceEconomicalLabel;

  /// No description provided for @priceModerateLabel.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get priceModerateLabel;

  /// No description provided for @priceHighLabel.
  ///
  /// In fr, this message translates to:
  /// **'Élevé'**
  String get priceHighLabel;

  /// No description provided for @priceLuxuryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Luxe'**
  String get priceLuxuryLabel;

  /// No description provided for @mapSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant, hôtel...'**
  String get mapSearchHint;

  /// No description provided for @filteredResults.
  ///
  /// In fr, this message translates to:
  /// **'Résultats filtrés'**
  String get filteredResults;

  /// No description provided for @searchOnMap.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher sur la carte...'**
  String get searchOnMap;

  /// No description provided for @placesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count, plural, one{# lieu} other{# lieux}}'**
  String placesCount(int count);

  /// No description provided for @recommended.
  ///
  /// In fr, this message translates to:
  /// **'Recommandés'**
  String get recommended;

  /// No description provided for @openedNow.
  ///
  /// In fr, this message translates to:
  /// **'Ouverts maintenant'**
  String get openedNow;

  /// No description provided for @searchInArea.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher dans cette zone'**
  String get searchInArea;

  /// No description provided for @noEstablishmentsInArea.
  ///
  /// In fr, this message translates to:
  /// **'Aucun établissement trouvé dans cette zone'**
  String get noEstablishmentsInArea;

  /// No description provided for @filterAvailability.
  ///
  /// In fr, this message translates to:
  /// **'Disponibilité'**
  String get filterAvailability;

  /// No description provided for @maxDistanceLabel.
  ///
  /// In fr, this message translates to:
  /// **'Distance max.'**
  String get maxDistanceLabel;

  /// No description provided for @filterMinRatingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note minimale'**
  String get filterMinRatingLabel;

  /// No description provided for @kwRestaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get kwRestaurant;

  /// No description provided for @kwCafe.
  ///
  /// In fr, this message translates to:
  /// **'Café'**
  String get kwCafe;

  /// No description provided for @kwHospital.
  ///
  /// In fr, this message translates to:
  /// **'Hôpital'**
  String get kwHospital;

  /// No description provided for @kwPharmacy.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie'**
  String get kwPharmacy;

  /// No description provided for @kwBank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get kwBank;

  /// No description provided for @kwHotel.
  ///
  /// In fr, this message translates to:
  /// **'Hôtel'**
  String get kwHotel;

  /// No description provided for @kwHairdresser.
  ///
  /// In fr, this message translates to:
  /// **'Coiffeur'**
  String get kwHairdresser;

  /// No description provided for @kwSupermarket.
  ///
  /// In fr, this message translates to:
  /// **'Supermarché'**
  String get kwSupermarket;

  /// No description provided for @kwSchool.
  ///
  /// In fr, this message translates to:
  /// **'École'**
  String get kwSchool;

  /// No description provided for @kwDentist.
  ///
  /// In fr, this message translates to:
  /// **'Dentiste'**
  String get kwDentist;

  /// No description provided for @kwDoctor.
  ///
  /// In fr, this message translates to:
  /// **'Médecin'**
  String get kwDoctor;

  /// No description provided for @kwBakery.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie'**
  String get kwBakery;

  /// No description provided for @suggestionSent.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion envoyée !'**
  String get suggestionSent;

  /// No description provided for @suggestionSentBody.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre contribution !\nD\'autres utilisateurs pourront voter pour votre suggestion. L\'admin l\'examinera et pourra l\'ajouter à l\'annuaire.'**
  String get suggestionSentBody;

  /// No description provided for @reasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : souvent demandé dans le quartier, nouvel établissement...'**
  String get reasonHint;

  /// No description provided for @activeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Active'**
  String get activeLabel;

  /// No description provided for @inactiveLabel.
  ///
  /// In fr, this message translates to:
  /// **'Inactive'**
  String get inactiveLabel;

  /// No description provided for @pendingValidation.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get pendingValidation;

  /// No description provided for @phoneSecondary.
  ///
  /// In fr, this message translates to:
  /// **'Tél. secondaire'**
  String get phoneSecondary;

  /// No description provided for @featuredTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mise à la une'**
  String get featuredTitle;

  /// No description provided for @featuredActiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Votre établissement apparaît en tête des résultats.'**
  String get featuredActiveDesc;

  /// No description provided for @featuredInactiveDesc.
  ///
  /// In fr, this message translates to:
  /// **'Boostez votre visibilité — apparaissez en tête des résultats et dans la section « À la une ».'**
  String get featuredInactiveDesc;

  /// No description provided for @reservedForGold.
  ///
  /// In fr, this message translates to:
  /// **'Réservé au plan Gold'**
  String get reservedForGold;

  /// No description provided for @upgradeToGold.
  ///
  /// In fr, this message translates to:
  /// **'Passer à Gold →'**
  String get upgradeToGold;

  /// No description provided for @paymentPendingAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en attente de validation par l\'admin.'**
  String get paymentPendingAdmin;

  /// No description provided for @chooseDuration.
  ///
  /// In fr, this message translates to:
  /// **'Choisissez une durée et un mode de paiement.'**
  String get chooseDuration;

  /// No description provided for @cashRequestRegistered.
  ///
  /// In fr, this message translates to:
  /// **'Demande enregistrée. Présentez-vous à nos bureaux pour régler en espèces.'**
  String get cashRequestRegistered;

  /// No description provided for @accountHolder.
  ///
  /// In fr, this message translates to:
  /// **'Titulaire'**
  String get accountHolder;

  /// No description provided for @featuredActivationPending.
  ///
  /// In fr, this message translates to:
  /// **'La mise à la une sera activée après validation par l\'admin.'**
  String get featuredActivationPending;

  /// No description provided for @bankTransferInstruction.
  ///
  /// In fr, this message translates to:
  /// **'Effectuez le virement et envoyez la preuve à votre gestionnaire.'**
  String get bankTransferInstruction;

  /// No description provided for @featuredDaysLabel.
  ///
  /// In fr, this message translates to:
  /// **'{count} jours'**
  String featuredDaysLabel(int count);

  /// No description provided for @customerReviewsCount.
  ///
  /// In fr, this message translates to:
  /// **'Avis clients ({count})'**
  String customerReviewsCount(int count);

  /// No description provided for @eliteOnly.
  ///
  /// In fr, this message translates to:
  /// **'Élite seulement'**
  String get eliteOnly;

  /// No description provided for @allFilter.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get allFilter;

  /// No description provided for @seeAllReviewsCount.
  ///
  /// In fr, this message translates to:
  /// **'Voir tous les avis ({count})'**
  String seeAllReviewsCount(int count);

  /// No description provided for @yourReplyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Votre réponse'**
  String get yourReplyLabel;

  /// No description provided for @timeAgoNow.
  ///
  /// In fr, this message translates to:
  /// **'à l\'instant'**
  String get timeAgoNow;

  /// No description provided for @youLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vous'**
  String get youLabel;

  /// No description provided for @featureWifi.
  ///
  /// In fr, this message translates to:
  /// **'WiFi'**
  String get featureWifi;

  /// No description provided for @featureFreeWifi.
  ///
  /// In fr, this message translates to:
  /// **'WiFi gratuit'**
  String get featureFreeWifi;

  /// No description provided for @featureParking.
  ///
  /// In fr, this message translates to:
  /// **'Parking'**
  String get featureParking;

  /// No description provided for @featureCoveredParking.
  ///
  /// In fr, this message translates to:
  /// **'Parking couvert'**
  String get featureCoveredParking;

  /// No description provided for @featureDelivery.
  ///
  /// In fr, this message translates to:
  /// **'Livraison'**
  String get featureDelivery;

  /// No description provided for @featureReservation.
  ///
  /// In fr, this message translates to:
  /// **'Réservation'**
  String get featureReservation;

  /// No description provided for @featureOnlineOrder.
  ///
  /// In fr, this message translates to:
  /// **'Commande en ligne'**
  String get featureOnlineOrder;

  /// No description provided for @featureOnlinePayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement en ligne'**
  String get featureOnlinePayment;

  /// No description provided for @featureCardPayment.
  ///
  /// In fr, this message translates to:
  /// **'Carte bancaire'**
  String get featureCardPayment;

  /// No description provided for @featureDisabledAccess.
  ///
  /// In fr, this message translates to:
  /// **'Accès PMR'**
  String get featureDisabledAccess;

  /// No description provided for @featureDineIn.
  ///
  /// In fr, this message translates to:
  /// **'Sur place'**
  String get featureDineIn;

  /// No description provided for @featureTakeaway.
  ///
  /// In fr, this message translates to:
  /// **'À emporter'**
  String get featureTakeaway;

  /// No description provided for @featureDrive.
  ///
  /// In fr, this message translates to:
  /// **'Drive'**
  String get featureDrive;

  /// No description provided for @featureAirConditioning.
  ///
  /// In fr, this message translates to:
  /// **'Climatisation'**
  String get featureAirConditioning;

  /// No description provided for @featureTerrace.
  ///
  /// In fr, this message translates to:
  /// **'Terrasse'**
  String get featureTerrace;

  /// No description provided for @featureBar.
  ///
  /// In fr, this message translates to:
  /// **'Bar'**
  String get featureBar;

  /// No description provided for @featurePrayerRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salle de prière'**
  String get featurePrayerRoom;

  /// No description provided for @featureGarden.
  ///
  /// In fr, this message translates to:
  /// **'Jardin'**
  String get featureGarden;

  /// No description provided for @featureNonSmoking.
  ///
  /// In fr, this message translates to:
  /// **'Non-fumeur'**
  String get featureNonSmoking;

  /// No description provided for @featureSmokingArea.
  ///
  /// In fr, this message translates to:
  /// **'Espace fumeur'**
  String get featureSmokingArea;

  /// No description provided for @featurePetsWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Animaux acceptés'**
  String get featurePetsWelcome;

  /// No description provided for @featureSeaView.
  ///
  /// In fr, this message translates to:
  /// **'Vue mer'**
  String get featureSeaView;

  /// No description provided for @featurePool.
  ///
  /// In fr, this message translates to:
  /// **'Piscine'**
  String get featurePool;

  /// No description provided for @featureGym.
  ///
  /// In fr, this message translates to:
  /// **'Salle de sport'**
  String get featureGym;

  /// No description provided for @featureKidsArea.
  ///
  /// In fr, this message translates to:
  /// **'Espace enfants'**
  String get featureKidsArea;

  /// No description provided for @featureRoomService.
  ///
  /// In fr, this message translates to:
  /// **'Service en chambre'**
  String get featureRoomService;

  /// No description provided for @featureHeating.
  ///
  /// In fr, this message translates to:
  /// **'Chauffage'**
  String get featureHeating;

  /// No description provided for @featureHallRental.
  ///
  /// In fr, this message translates to:
  /// **'Location salle'**
  String get featureHallRental;

  /// No description provided for @featureDecoration.
  ///
  /// In fr, this message translates to:
  /// **'Décoration'**
  String get featureDecoration;

  /// No description provided for @featureCatering.
  ///
  /// In fr, this message translates to:
  /// **'Traiteur'**
  String get featureCatering;

  /// No description provided for @featureDj.
  ///
  /// In fr, this message translates to:
  /// **'DJ'**
  String get featureDj;

  /// No description provided for @featurePhotographer.
  ///
  /// In fr, this message translates to:
  /// **'Photographe'**
  String get featurePhotographer;

  /// No description provided for @featureSoundSystem.
  ///
  /// In fr, this message translates to:
  /// **'Sonorisation'**
  String get featureSoundSystem;

  /// No description provided for @featureProjector.
  ///
  /// In fr, this message translates to:
  /// **'Vidéoprojecteur'**
  String get featureProjector;

  /// No description provided for @featureVipArea.
  ///
  /// In fr, this message translates to:
  /// **'Espace VIP'**
  String get featureVipArea;

  /// No description provided for @featureConferenceRoom.
  ///
  /// In fr, this message translates to:
  /// **'Salle de conférence'**
  String get featureConferenceRoom;

  /// No description provided for @featureAnimation.
  ///
  /// In fr, this message translates to:
  /// **'Animation'**
  String get featureAnimation;

  /// No description provided for @featureEntertainment.
  ///
  /// In fr, this message translates to:
  /// **'Spectacle'**
  String get featureEntertainment;

  /// No description provided for @featureEquippedKitchen.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine équipée'**
  String get featureEquippedKitchen;

  /// No description provided for @featureChangingRooms.
  ///
  /// In fr, this message translates to:
  /// **'Vestiaires'**
  String get featureChangingRooms;

  /// No description provided for @featureShortTermRental.
  ///
  /// In fr, this message translates to:
  /// **'Location courte durée'**
  String get featureShortTermRental;

  /// No description provided for @featureLongTermRental.
  ///
  /// In fr, this message translates to:
  /// **'Location longue durée'**
  String get featureLongTermRental;

  /// No description provided for @featureInsurance.
  ///
  /// In fr, this message translates to:
  /// **'Assurance'**
  String get featureInsurance;

  /// No description provided for @featureNearbyParking.
  ///
  /// In fr, this message translates to:
  /// **'Parking à proximité'**
  String get featureNearbyParking;

  /// No description provided for @featureHammam.
  ///
  /// In fr, this message translates to:
  /// **'Hammam'**
  String get featureHammam;

  /// No description provided for @featureScrub.
  ///
  /// In fr, this message translates to:
  /// **'Gommage'**
  String get featureScrub;

  /// No description provided for @featureMassage.
  ///
  /// In fr, this message translates to:
  /// **'Massage'**
  String get featureMassage;

  /// No description provided for @featureFacialTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Soin visage'**
  String get featureFacialTreatment;

  /// No description provided for @featureBodyTreatment.
  ///
  /// In fr, this message translates to:
  /// **'Soins corps'**
  String get featureBodyTreatment;

  /// No description provided for @featureSpa.
  ///
  /// In fr, this message translates to:
  /// **'Spa'**
  String get featureSpa;

  /// No description provided for @featureSauna.
  ///
  /// In fr, this message translates to:
  /// **'Sauna'**
  String get featureSauna;

  /// No description provided for @featureJacuzzi.
  ///
  /// In fr, this message translates to:
  /// **'Jacuzzi'**
  String get featureJacuzzi;

  /// No description provided for @featureManicure.
  ///
  /// In fr, this message translates to:
  /// **'Manucure'**
  String get featureManicure;

  /// No description provided for @featurePedicure.
  ///
  /// In fr, this message translates to:
  /// **'Pédicure'**
  String get featurePedicure;

  /// No description provided for @featureWaxing.
  ///
  /// In fr, this message translates to:
  /// **'Épilation'**
  String get featureWaxing;

  /// No description provided for @featureMakeup.
  ///
  /// In fr, this message translates to:
  /// **'Maquillage'**
  String get featureMakeup;

  /// No description provided for @featureFitness.
  ///
  /// In fr, this message translates to:
  /// **'Fitness'**
  String get featureFitness;

  /// No description provided for @featureTennis.
  ///
  /// In fr, this message translates to:
  /// **'Tennis'**
  String get featureTennis;

  /// No description provided for @featureConsultation.
  ///
  /// In fr, this message translates to:
  /// **'Conseil'**
  String get featureConsultation;

  /// No description provided for @featureLaundry.
  ///
  /// In fr, this message translates to:
  /// **'Blanchisserie'**
  String get featureLaundry;

  /// No description provided for @featureValet.
  ///
  /// In fr, this message translates to:
  /// **'Service voiturier'**
  String get featureValet;

  /// No description provided for @featureBicycles.
  ///
  /// In fr, this message translates to:
  /// **'Vélos disponibles'**
  String get featureBicycles;

  /// No description provided for @featureEVCharging.
  ///
  /// In fr, this message translates to:
  /// **'Borne de recharge'**
  String get featureEVCharging;

  /// No description provided for @featureSafe.
  ///
  /// In fr, this message translates to:
  /// **'Coffre-fort'**
  String get featureSafe;

  /// No description provided for @feature24hReception.
  ///
  /// In fr, this message translates to:
  /// **'Réception 24h/24'**
  String get feature24hReception;
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
