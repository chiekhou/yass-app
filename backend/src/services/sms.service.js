const config = require("../config/app");

class SmsService {
  constructor() {
    this.client = null;
    this._init();
  }

  _init() {
    const accountSid = config.twilio?.accountSid || process.env.TWILIO_ACCOUNT_SID;
    const authToken = config.twilio?.authToken || process.env.TWILIO_AUTH_TOKEN;

    if (accountSid && authToken) {
      try {
        const twilio = require("twilio");
        this.client = twilio(accountSid, authToken);
      } catch {
        console.warn("[SMS] Twilio module not installed. Run: npm install twilio");
      }
    } else {
      console.warn("[SMS] Twilio credentials not set — OTP will be logged to console only.");
    }
  }

  /**
   * Send an OTP code via SMS
   * @param {string} phone - Phone number in international format (e.g. +213XXXXXXXXX)
   * @param {string} otp   - 6-digit OTP code
   */
  async sendOtp(phone, otp) {
    const from = config.twilio?.phoneNumber || process.env.TWILIO_PHONE_NUMBER;
    const message = `Votre code de vérification est : ${otp}. Il expire dans 10 minutes.`;

    if (!this.client) {
      // Development fallback: log OTP to console
      console.log(`[SMS DEV] OTP pour ${phone} : ${otp}`);
      return { success: true, dev: true };
    }

    await this.client.messages.create({
      body: message,
      from,
      to: this._normalizePhone(phone),
    });

    return { success: true };
  }

  /**
   * Normalize Algerian phone number to E.164 format
   */
  _normalizePhone(phone) {
    const cleaned = phone.replace(/[\s\-().]/g, "");

    // Already E.164 (+XXXXXXXXXXX)
    if (cleaned.startsWith("+")) return cleaned;

    // International format with 00 prefix (0033... → +33...)
    if (cleaned.startsWith("00")) return "+" + cleaned.slice(2);

    // Algerian local format (0XXXXXXXXX → +213XXXXXXXXX)
    if (cleaned.startsWith("0")) return "+213" + cleaned.slice(1);

    // Bare country code without + (213XXXXXXXXX → +213XXXXXXXXX)
    return "+" + cleaned;
  }
}

module.exports = new SmsService();
