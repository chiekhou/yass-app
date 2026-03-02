const invoiceService = require("../services/invoice.service");
const { ApiResponse } = require("../utils");

class InvoiceController {
  /**
   * GET /partner/invoices
   * Liste des factures du partenaire connecté
   */
  async getInvoices(req, res, next) {
    try {
      const invoices = await invoiceService.getPartnerInvoices(req.partner.id);
      ApiResponse.success(invoices, "Factures récupérées").send(res);
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /partner/invoices/:id
   * Détail d'une facture
   */
  async getInvoice(req, res, next) {
    try {
      const invoice = await invoiceService.getInvoiceById(
        req.params.id,
        req.partner.id
      );
      ApiResponse.success(invoice, "Facture récupérée").send(res);
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new InvoiceController();
