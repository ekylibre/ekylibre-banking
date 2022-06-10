require 'securerandom'

module Banking
  class CashSynchronizationsController < Backend::BaseController
    def new
      cash = Cash.find_by_id(params[:cash_id])
      nordigen_service = Banking::NordigenService.instance
      if cash && (bic = cash.bank_identifier_code)
        institution = nordigen_service.get_institution_by_bic(bic)
        redirect_to(build_requisition_banking_cash_synchronization_path(cash_id: cash.id), institution_id: institution.id) if institution
      end
      institutions = nordigen_service.get_institutions
      @list = institutions.collect(&:marshal_dump).to_json
    end

    def build_requisition
      cash_id = params[:cash_id]
      nordingen_service = Banking::NordigenService.instance
      institution = nordingen_service.get_institution_by_id(params[:institution_id])
      uuid = SecureRandom.uuid
      redirect_url = self.request.base_url + '/backend/cashes/' + cash_id.to_s
      requisition = nordingen_service.create_requisition(redirect_url: redirect_url,
                                                         institution_id: institution.id,
                                                         reference_id: uuid,
                                                         max_historical_days: institution.transaction_total_days || 90)
      name = "requisition_id_cash_id_#{cash_id}"
      value = requisition.id
      preference = Preference.set!(name, value)
      ::Banking::DestroyRequisitonIdJob.set(wait: 90.days).perform_later(preference.id)
      # why should we store the link url ? it seems to be never used.

      # name = "requisition_link_cash_id_#{cash_id}"
      # value = requisition.link
      # Preference.set!(name, value)
      redirect_to requisition.link
    end

    def perform
      cash_id = params[:cash_id]
      cash = Cash.find(cash_id)
      unless cash.synchronizable?
        notify_warning(:iban_should_be_provided.tl)
        redirect_to backend_cash_path(cash_id)
        return
      end

      if (requisition_id = Preference.find_by(name: "requisition_id_cash_id_#{cash_id}")&.value).nil?
        notify_warning(:account_sync_authorization_required.tl)
      else
        ::Banking::BankingFetchUpdateTransactionsJob.perform_later(cash_id: cash_id, requisition_id: requisition_id)
      end
      redirect_to backend_cash_path(cash_id)
    end

  end
end
