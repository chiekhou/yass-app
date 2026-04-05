const axios = require("axios");
const handlebars = require("handlebars");
const fs = require("fs");
const path = require("path");
const config = require("../config/app");

const BREVO_API_URL = "https://api.brevo.com/v3/smtp/email";

class EmailService {
  constructor() {
    this.templates = {};
    this.loadTemplates();

    if (!config.email.apiKey) {
      console.warn("⚠️  Email service: BREVO_API_KEY non configuré — les emails seront désactivés.");
    } else {
      console.log(`📧 Email service init: Brevo API — from=${config.email.from}`);
    }
  }

  /**
   * Load email templates from files
   */
  loadTemplates() {
    const templatesDir = path.join(__dirname, "../templates/emails");

    const templateFiles = [
      "verify-email",
      "reset-password",
      "welcome",
      "partner-pending",
      "partner-approved",
      "partner-rejected",
    ];

    templateFiles.forEach((name) => {
      const filePath = path.join(templatesDir, `${name}.hbs`);
      if (fs.existsSync(filePath)) {
        const source = fs.readFileSync(filePath, "utf-8");
        this.templates[name] = handlebars.compile(source);
      }
    });
  }

  /**
   * Send email via Brevo API (HTTP — pas de SMTP, pas de port bloqué)
   */
  async send(options) {
    const { to, subject, template, context, html } = options;

    if (!config.email.apiKey) {
      console.log(`📧 [Email skipped — BREVO_API_KEY absent] To: ${to} | Subject: ${subject}`);
      return { success: false, error: "BREVO_API_KEY not configured" };
    }

    let htmlContent = html;
    if (template && this.templates[template]) {
      htmlContent = this.templates[template](context);
    }

    try {
      const response = await axios.post(
        BREVO_API_URL,
        {
          sender: { name: "Win-وين", email: config.email.from },
          to: [{ email: to }],
          subject,
          htmlContent,
        },
        {
          headers: {
            "api-key": config.email.apiKey,
            "Content-Type": "application/json",
          },
          timeout: 10000,
        }
      );

      console.log(`📧 Email sent to ${to} | messageId: ${response.data.messageId}`);
      return { success: true, messageId: response.data.messageId };
    } catch (error) {
      const msg = error.response?.data?.message || error.message;
      console.error("❌ Email error:", msg);
      return { success: false, error: msg };
    }
  }

  /**
   * Send verification email
   */
  async sendVerificationEmail(user, token) {
    const verificationUrl = `${config.urls.app}/api/${config.apiVersion}/r/verify?token=${token}`;

    // Use API URL if no frontend URL
    const apiVerificationUrl = `${config.urls.app}/api/${config.apiVersion}/auth/verify-email/${token}`;

    const context = {
      firstName: user.first_name,
      lastName: user.last_name,
      verificationUrl: verificationUrl || apiVerificationUrl,
      appName: "Win",
      year: new Date().getFullYear(),
    };

    // Fallback HTML if template not loaded
    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #1B4F72; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 30px; background: #27AE60; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Win</h1>
          </div>
          <div class="content">
            <h2>Bienvenue ${context.firstName} !</h2>
            <p>Merci de vous être inscrit sur Win.</p>
            <p>Pour activer votre compte, veuillez cliquer sur le bouton ci-dessous :</p>
            <p style="text-align: center;">
              <a href="${context.verificationUrl}" class="button">Vérifier mon email</a>
            </p>
            <p>Ou copiez ce lien dans votre navigateur :</p>
            <p style="word-break: break-all; color: #666;">${context.verificationUrl}</p>
            <p>Ce lien expire dans 24 heures.</p>
          </div>
          <div class="footer">
            <p>© ${context.year} Win. Tous droits réservés.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "Vérifiez votre adresse email - Win",
      template: "verify-email",
      context,
      html: this.templates["verify-email"] ? undefined : fallbackHtml,
    });
  }

  /**
   * Send OTP code via email for account verification
   */
  async sendEmailOtp(user, otp) {
    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background: #f4f4f4; }
          .container { max-width: 600px; margin: 30px auto; background: #fff; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.08); }
          .header { background: linear-gradient(135deg, #006233 50%, #D21034 100%); color: white; padding: 30px 20px; text-align: center; }
          .header h1 { margin: 0; font-size: 26px; letter-spacing: 1px; }
          .header p { margin: 6px 0 0; font-size: 13px; opacity: 0.85; }
          .content { padding: 30px; }
          .otp-box { font-size: 40px; font-weight: bold; letter-spacing: 12px; text-align: center; padding: 20px; background: #f9f9f9; border-left: 5px solid #006233; border-radius: 6px; margin: 24px 0; color: #006233; }
          .warning { background: #fff8e1; border: 1px solid #ffe082; padding: 12px 16px; border-radius: 5px; margin: 20px 0; font-size: 13px; color: #795548; }
          .footer { background: #006233; padding: 16px; text-align: center; color: rgba(255,255,255,0.75); font-size: 12px; }
          .flag-bar { height: 6px; background: linear-gradient(to right, #006233 50%, #D21034 50%); }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="flag-bar"></div>
          <div class="header">
            <h1>Win</h1>
            <p>Le répertoire des services en Algérie</p>
          </div>
          <div class="content">
            <h2 style="color:#006233; margin-top:0;">Vérification de votre compte</h2>
            <p>Bonjour <strong>${user.first_name}</strong>,</p>
            <p>Voici votre code de vérification pour activer votre compte Win :</p>
            <div class="otp-box">${otp}</div>
            <div class="warning">
              <strong>⏱ Ce code expire dans 10 minutes.</strong><br>
              Ne le partagez avec personne. Notre équipe ne vous demandera jamais ce code.
            </div>
            <p style="color:#666; font-size:13px;">Si vous n'avez pas créé de compte, ignorez simplement cet email.</p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Win — Tous droits réservés</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "Votre code de vérification - Win",
      html: fallbackHtml,
    });
  }

  /**
   * Send password reset email
   */
  async sendPasswordResetEmail(user, token) {
    const resetUrl = `${config.urls.app}/api/${config.apiVersion}/r/reset?token=${token}`;

    const context = {
      firstName: user.first_name,
      lastName: user.last_name,
      resetUrl,
      appName: "Win",
      year: new Date().getFullYear(),
      expiresIn: "1 heure",
    };

    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #1B4F72; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 30px; background: #E74C3C; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .warning { background: #FFF3CD; border: 1px solid #FFEEBA; padding: 10px; border-radius: 5px; margin: 15px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Win</h1>
          </div>
          <div class="content">
            <h2>Réinitialisation de mot de passe</h2>
            <p>Bonjour ${context.firstName},</p>
            <p>Vous avez demandé la réinitialisation de votre mot de passe.</p>
            <p>Cliquez sur le bouton ci-dessous pour créer un nouveau mot de passe :</p>
            <p style="text-align: center;">
              <a href="${context.resetUrl}" class="button">Réinitialiser mon mot de passe</a>
            </p>
            <p>Ou copiez ce lien dans votre navigateur :</p>
            <p style="word-break: break-all; color: #666;">${context.resetUrl}</p>
            <div class="warning">
              <strong>⚠️ Ce lien expire dans ${context.expiresIn}.</strong>
            </div>
            <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
          </div>
          <div class="footer">
            <p>© ${context.year} Win. Tous droits réservés.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "Réinitialisation de votre mot de passe - Win",
      template: "reset-password",
      context,
      html: this.templates["reset-password"] ? undefined : fallbackHtml,
    });
  }

  /**
   * Send welcome email after verification
   */
  async sendWelcomeEmail(user) {
    const context = {
      firstName: user.first_name,
      lastName: user.last_name,
      appName: "Win",
      appUrl: config.urls.app,
      year: new Date().getFullYear(),
    };

    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #1B4F72; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 30px; background: #27AE60; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .features { margin: 20px 0; }
          .features li { margin: 10px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Bienvenue sur Win !</h1>
          </div>
          <div class="content">
            <h2>Votre compte est activé, ${context.firstName} !</h2>
            <p>Merci d'avoir vérifié votre adresse email. Votre compte est maintenant actif.</p>
            <p>Avec Win, vous pouvez :</p>
            <ul class="features">
              <li>🔍 Découvrir les meilleurs services près de chez vous</li>
              <li>⭐ Lire et publier des avis</li>
              <li>❤️ Sauvegarder vos établissements favoris</li>
              <li>🎁 Profiter de promotions exclusives</li>
            </ul>
            <p style="text-align: center;">
              <a href="${context.appUrl}" class="button">Commencer l'exploration</a>
            </p>
          </div>
          <div class="footer">
            <p>© ${context.year} Win. Tous droits réservés.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "Bienvenue sur Win ! 🎉",
      template: "welcome",
      context,
      html: this.templates["welcome"] ? undefined : fallbackHtml,
    });
  }

  /**
   * Send partner registration pending email
   */
  async sendPartnerPendingEmail(user, partner) {
    const context = {
      firstName: user.first_name,
      lastName: user.last_name,
      companyName: partner.company_name,
      appName: "Win",
      year: new Date().getFullYear(),
    };

    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #1B4F72; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .status { background: #FFF3CD; border: 1px solid #FFEEBA; padding: 15px; border-radius: 5px; margin: 15px 0; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Win - Espace Partenaire</h1>
          </div>
          <div class="content">
            <h2>Demande d'inscription reçue</h2>
            <p>Bonjour ${context.firstName},</p>
            <p>Nous avons bien reçu votre demande d'inscription en tant que partenaire pour <strong>${context.companyName}</strong>.</p>
            <div class="status">
              <strong>⏳ Statut : En attente de validation</strong>
            </div>
            <p>Notre équipe va examiner votre demande dans les plus brefs délais. Vous recevrez un email dès que votre compte sera validé.</p>
            <p>Ce processus prend généralement 24 à 48 heures ouvrées.</p>
          </div>
          <div class="footer">
            <p>© ${context.year} Win. Tous droits réservés.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "Votre demande de partenariat est en cours de traitement - Win",
      template: "partner-pending",
      context,
      html: this.templates["partner-pending"] ? undefined : fallbackHtml,
    });
  }

  /**
   * Send partner approved email
   */
  async sendPartnerApprovedEmail(user, partner) {
    const context = {
      firstName: user.first_name,
      lastName: user.last_name,
      companyName: partner.company_name,
      dashboardUrl: `${config.urls.app}/api/${config.apiVersion}/r/partner-dashboard`,
      appName: "Win",
      year: new Date().getFullYear(),
    };

    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #27AE60; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 30px; background: #1B4F72; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .status { background: #D4EDDA; border: 1px solid #C3E6CB; padding: 15px; border-radius: 5px; margin: 15px 0; text-align: center; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🎉 Félicitations !</h1>
          </div>
          <div class="content">
            <h2>Votre compte partenaire est activé</h2>
            <p>Bonjour ${context.firstName},</p>
            <div class="status">
              <strong>✅ Statut : Approuvé</strong>
            </div>
            <p>Votre demande de partenariat pour <strong>${context.companyName}</strong> a été approuvée !</p>
            <p>Vous pouvez maintenant :</p>
            <ul>
              <li>📝 Créer et gérer vos établissements</li>
              <li>🎁 Publier des promotions</li>
              <li>📊 Suivre vos statistiques</li>
              <li>💬 Répondre aux avis clients</li>
            </ul>
            <p style="text-align: center;">
              <a href="${context.dashboardUrl}" class="button">Accéder à mon espace</a>
            </p>
          </div>
          <div class="footer">
            <p>© ${context.year} Win. Tous droits réservés.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "✅ Votre compte partenaire est activé - Win",
      template: "partner-approved",
      context,
      html: this.templates["partner-approved"] ? undefined : fallbackHtml,
    });
  }

  /**
   * Send partner rejected email
   */
  async sendPartnerRejectedEmail(user, partner, reason) {
    const context = {
      firstName: user.first_name,
      lastName: user.last_name,
      companyName: partner.company_name,
      reason: reason || "Informations incomplètes ou non conformes",
      contactEmail: "support@annuaire-dz.com",
      appName: "Win",
      year: new Date().getFullYear(),
    };

    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #E74C3C; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .status { background: #F8D7DA; border: 1px solid #F5C6CB; padding: 15px; border-radius: 5px; margin: 15px 0; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>Win</h1>
          </div>
          <div class="content">
            <h2>Demande de partenariat non approuvée</h2>
            <p>Bonjour ${context.firstName},</p>
            <p>Nous avons examiné votre demande de partenariat pour <strong>${context.companyName}</strong>.</p>
            <div class="status">
              <strong>❌ Statut : Non approuvé</strong>
              <p><strong>Motif :</strong> ${context.reason}</p>
            </div>
            <p>Si vous pensez qu'il s'agit d'une erreur ou si vous souhaitez fournir des informations complémentaires, veuillez nous contacter.</p>
            <p style="text-align: center;">
              <a href="mailto:${context.contactEmail}">${context.contactEmail}</a>
            </p>
          </div>
          <div class="footer">
            <p>© ${context.year} Win. Tous droits réservés.</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: user.email,
      subject: "Mise à jour de votre demande de partenariat - Win",
      template: "partner-rejected",
      context,
      html: this.templates["partner-rejected"] ? undefined : fallbackHtml,
    });
  }

  /**
   * Send notification to admin for new partner registration
   */
  async sendAdminNewPartnerNotification(adminEmail, user, partner) {
    const fallbackHtml = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #F39C12; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f9f9f9; }
          .button { display: inline-block; padding: 12px 30px; background: #1B4F72; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
          .footer { padding: 20px; text-align: center; color: #666; font-size: 12px; }
          .info { background: #fff; padding: 15px; border-radius: 5px; margin: 15px 0; border-left: 4px solid #F39C12; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🔔 Nouvelle demande de partenariat</h1>
          </div>
          <div class="content">
            <p>Une nouvelle demande de partenariat a été soumise.</p>
            <div class="info">
              <p><strong>Nom :</strong> ${user.first_name} ${user.last_name}</p>
              <p><strong>Entreprise :</strong> ${partner.company_name}</p>
              <p><strong>Email :</strong> ${user.email}</p>
              <p><strong>Téléphone :</strong> ${user.phone || "Non renseigné"}</p>
            </div>
            <p style="text-align: center;">
              <a href="${config.urls.app}/api/${config.apiVersion}/r/admin-partners" class="button">Examiner la demande</a>
            </p>
          </div>
          <div class="footer">
            <p>© ${new Date().getFullYear()} Win - Administration</p>
          </div>
        </div>
      </body>
      </html>
    `;

    return this.send({
      to: adminEmail,
      subject: "🔔 Nouvelle demande de partenariat - Win",
      html: fallbackHtml,
    });
  }
}

module.exports = new EmailService();
