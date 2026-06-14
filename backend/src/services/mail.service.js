const emailService = require("./email.service");

class MailService {
  async sendContactMessage({ to, establishmentName, senderName, senderEmail, message }) {
    return emailService.send({
      to,
      subject: `Nouveau message de contact — ${establishmentName}`,
      html: `
        <div style="font-family:sans-serif;max-width:600px;margin:auto">
          <h2 style="color:#2e7d32">Nouveau message de contact</h2>
          <p><strong>Établissement :</strong> ${establishmentName}</p>
          <hr/>
          <p><strong>De :</strong> ${senderName}</p>
          <p><strong>Email :</strong> <a href="mailto:${senderEmail}">${senderEmail}</a></p>
          <p><strong>Message :</strong></p>
          <blockquote style="border-left:4px solid #2e7d32;margin:0;padding:8px 16px;background:#f1f8e9">
            ${message.replace(/\n/g, "<br/>")}
          </blockquote>
          <hr/>
          <p style="color:#999;font-size:12px">Ce message vous a été envoyé via Win-وين</p>
        </div>
      `,
    });
  }
}

module.exports = new MailService();
