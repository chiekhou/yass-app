const emailService = require("./email.service");

class MailService {
  async sendContactMessage({ to, establishmentName, senderName, senderEmail, message }) {
    const initials = senderName
      .split(' ')
      .map((w) => w[0]?.toUpperCase() || '')
      .slice(0, 2)
      .join('');

    const html = `
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Nouveau message de contact</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f6f8;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f4f6f8;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="max-width:600px;width:100%;background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 4px 20px rgba(0,0,0,0.08);">

          <!-- Barre drapeau -->
          <tr>
            <td style="height:5px;background:linear-gradient(to right,#006233 50%,#D21034 50%);"></td>
          </tr>

          <!-- Header -->
          <tr>
            <td style="background-color:#006233;padding:28px 32px;text-align:center;">
              <p style="margin:0;font-size:28px;font-weight:bold;color:#ffffff;letter-spacing:2px;">Win</p>
              <p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.8);letter-spacing:1px;">وِين — Le répertoire des services en Algérie</p>
            </td>
          </tr>

          <!-- Bandeau établissement -->
          <tr>
            <td style="background-color:#f0faf4;padding:14px 32px;border-bottom:1px solid #d8edd9;">
              <p style="margin:0;font-size:13px;color:#006233;font-weight:600;">
                Message reçu pour : <span style="font-weight:700;">${establishmentName}</span>
              </p>
            </td>
          </tr>

          <!-- Corps -->
          <tr>
            <td style="padding:32px;">

              <p style="margin:0 0 24px;font-size:20px;font-weight:bold;color:#1a1a1a;">
                Nouveau message de contact
              </p>

              <!-- Carte expéditeur -->
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:24px;">
                <tr>
                  <td style="background-color:#f8f9fa;border-radius:10px;padding:16px 20px;">
                    <table cellpadding="0" cellspacing="0">
                      <tr>
                        <!-- Avatar initiales -->
                        <td style="vertical-align:top;padding-right:14px;">
                          <div style="width:44px;height:44px;background-color:#006233;border-radius:50%;text-align:center;line-height:44px;font-size:16px;font-weight:bold;color:#ffffff;">
                            ${initials}
                          </div>
                        </td>
                        <td style="vertical-align:middle;">
                          <p style="margin:0;font-size:15px;font-weight:700;color:#1a1a1a;">${senderName}</p>
                          <p style="margin:3px 0 0;font-size:13px;color:#888888;">
                            <a href="mailto:${senderEmail}" style="color:#006233;text-decoration:none;">${senderEmail}</a>
                          </p>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <!-- Message -->
              <p style="margin:0 0 10px;font-size:12px;font-weight:700;color:#888;text-transform:uppercase;letter-spacing:1px;">Message</p>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin-bottom:28px;">
                <tr>
                  <td style="background-color:#f8f9fa;border-left:4px solid #006233;border-radius:0 8px 8px 0;padding:18px 20px;">
                    <p style="margin:0;font-size:14px;color:#333;line-height:1.8;">
                      ${message.replace(/\n/g, '<br>')}
                    </p>
                  </td>
                </tr>
              </table>

              <!-- CTA Répondre -->
              <table cellpadding="0" cellspacing="0">
                <tr>
                  <td style="background-color:#006233;border-radius:8px;">
                    <a href="mailto:${senderEmail}?subject=Re: Votre message concernant ${encodeURIComponent(establishmentName)}"
                       style="display:inline-block;padding:13px 28px;font-size:14px;font-weight:bold;color:#ffffff;text-decoration:none;letter-spacing:0.5px;">
                      Répondre à ${senderName} →
                    </a>
                  </td>
                </tr>
              </table>

            </td>
          </tr>

          <!-- Séparateur -->
          <tr>
            <td style="height:1px;background-color:#f0f0f0;"></td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color:#006233;padding:20px 32px;text-align:center;">
              <p style="margin:0;font-size:12px;color:rgba(255,255,255,0.7);">
                © ${new Date().getFullYear()} Win — Tous droits réservés
              </p>
              <p style="margin:6px 0 0;font-size:11px;color:rgba(255,255,255,0.5);">
                Ce message vous a été transmis via l'application Win.
              </p>
            </td>
          </tr>

          <!-- Barre drapeau bas -->
          <tr>
            <td style="height:5px;background:linear-gradient(to right,#006233 50%,#D21034 50%);"></td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

    return emailService.send({
      to,
      subject: `Nouveau message de ${senderName} — ${establishmentName}`,
      html,
    });
  }
}

module.exports = new MailService();
