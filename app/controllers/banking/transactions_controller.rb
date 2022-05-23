require 'securerandom'

module Banking
  class TransactionsController < Backend::BaseController
    include Rails.application.routes.url_helpers

    def index
    end

    def new
      cash = Cash.find_by_id(params[:cash_id])
      nordigen_service = Banking::NordigenService.instance
      if cash && (bic = cash.bank_identifier_code)
        institution = nordigen_service.get_institution_by_bic(bic)
        redirect_to(build_requisition_banking_transaction_path(cash), institution_id: institution.id) if institution
      end
      institutions = nordigen_service.get_institutions
      @list = institutions.collect {|el| el.marshal_dump }.to_json
    end

    def build_requisition
      cash_id = params[:id]
      nordingen_service = Banking::NordigenService.instance
      institution = nordingen_service.get_institution_by_id(params[:institution_id])
      uuid = SecureRandom.uuid
      redirect_url = self.request.base_url + '/backend/cashes/' + cash_id.to_s
      requisition = nordingen_service.create_requisition(redirect_url: redirect_url,
                                                         institution_id: institution.id,
                                                         reference_id: uuid,
                                                         max_historical_days: institution.transaction_total_days || 90)
      binding.pry
      name = "requisition_id_cash_id_#{cash_id}"
      value = requisition.id
      Preference.set!(name, value)

      # why should we stroe the link url ? it seems to be never used.

      # name = "requisition_link_cash_id_#{cash_id}"
      # value = requisition.link
      # Preference.set!(name, value)
      redirect_to requisition.link
    end

    def sync_account
      cash_id = params[:cash_id]
      if (requisition_id = Preference.get("requisition_id_cash_id_#{cash_id}").value)
        raise "Requisition ID is not found. Please complete authorization with your bank"
      end
      ::Banking::BankingFetchUpdateTransactionsJob.perform_later(cash_id: cash_id, requisition_id: requisition_id)
      redirect_to controller: '/backend/cashes', action: :show, id: cash_id
    end

  end
end
