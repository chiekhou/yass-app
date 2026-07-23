# 🇩WIN (وِين) - Annuaire Local

> **"Trouvez tout près de chez vous"** | **"لقى كلش قريب منك"**

Application mobile d'annuaire pour trouver des établissements : restaurants, hôtels, pharmacies, services...

---

## 📱 Démo

🎥 **Vidéo de démonstration** : [Voir la démo](https://drive.google.com/file/d/1pETDT_6yoLW48F8aAIHFGEkj8q8Q9qcA/view?usp=drive_link)

---

## 🚀 Démarrage Rapide

### Prérequis

- **Node.js** 18+
- **Flutter** 3.16+
- **PostgreSQL** 14+ (ou Neon/Supabase)

---

## 📁 Structure

```
demo-win/
├── backend/                 # API Node.js/Express
│   ├── src/
│   │   ├── config/         # Configuration
│   │   ├── controllers/    # Contrôleurs
│   │   ├── middlewares/    # Auth, validation
│   │   ├── models/         # Modèles Sequelize
│   │   ├── routes/         # Routes API
│   │   ├── services/       # Logique métier
│   │   └── validations/    # Joi schemas
│   └── uploads/            # Fichiers uploadés
│
├── frontend/               # App Flutter
│   ├── lib/
│   │   ├── core/          # Config, thème, network
│   │   ├── features/      # Modules (auth, home...)
│   │   └── shared/        # Widgets communs
│   └── assets/            # Images, fonts
│
└── docs/                   # Documentation
```

---

## 🔌 API Endpoints

### Auth

| Méthode | Endpoint                       | Description         |
| ------- | ------------------------------ | ------------------- |
| POST    | `/api/v1/auth/register`        | Inscription         |
| POST    | `/api/v1/auth/login`           | Connexion           |


### Établissements

| Méthode | Endpoint                   | Description       |
| ------- | -------------------------- | ----------------- |
| GET     | `/establishments`          | Liste + recherche |
| GET     | `/establishments/:id`      | Détails           |
| GET     | `/establishments/featured` | À la une          |
| GET     | `/establishments/nearby`   | Proximité         |

### Favoris & Avis

| Méthode | Endpoint                      | Description   |
| ------- | ----------------------------- | ------------- |
| POST    | `/favorites/:id/toggle`       | Toggle favori |
| GET     | `/favorites`                  | Mes favoris   |
| POST    | `/establishments/:id/reviews` | Ajouter avis  |
| GET     | `/establishments/:id/reviews` | Liste avis    |

## 📦 Technologies

### Backend

- **Express.js** - Framework web
- **Sequelize** - ORM PostgreSQL
- **JWT** - Authentification
- **Multer + Sharp** - Upload images
- **Brevo** - Emails transactionnels
- **Joi** - Validation

### Frontend

- **Flutter 3.16+** - Framework mobile
- **BLoC** - State management
- **Dio** - HTTP client
- **GoRouter** - Navigation
- **Flutter Secure Storage** - Tokens

---

---

## 📸 Captures d'écran

<!-- Ajoute tes screenshots dans demo/assets/ -->
<div align="center">
  <img src="assets/screenshots/home.png" width="200" alt="Accueil">
  <img src="assets/screenshots/categories.png" width="200" alt="Categories">
  <img src="assets/screenshots/details-categories.png" width="200" alt="Details-Categorie">
  <img src="assets/screenshots/profile.png" width="200" alt="Profil">
</div>

---

## 🗄️ Base de Données

### Modèles principaux

- **User** - Utilisateurs
- **Partner** - Partenaires (propriétaires)
- **Establishment** - Établissements
- **Category** / **SubCategory** - Catégories
- **Wilaya** / **Commune** - Géographie
- **Review** - Avis
- **Favorite** - Favoris

## 📱 Fonctionnalités

- [x] Authentification (JWT)
- [x] Recherche établissements
- [x] Filtres (catégorie, wilaya, note)
- [x] Géolocalisation (nearby)
- [x] Favoris
- [x] Avis et notes
- [x] Profil utilisateur
- [x] Upload images
- [x] Panel admin
- [ ] Push notifications
- [ ] Mode hors-ligne
- [ ] Paiement partenaires

---

## 🚀 Déploiement

### Backend recommandé

- **Render.com** (7$/mois)
- **Railway.app** (5$/mois)
- **DigitalOcean** (6$/mois)

### Base de données

- **Neon.tech** (gratuit)
- **Supabase** (gratuit)

### Frontend

- **Play Store** (25$ une fois)
- **App Store** (99$/an)

---

## 📄 Licence

Projet privé - Tous droits réservés © 2025

---

## 👨‍💻 Auteur

**Chiekhou Traoré ** - Ingénieur Web

---
