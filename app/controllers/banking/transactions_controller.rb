require 'securerandom'

module Banking
  class TransactionsController < Backend::BaseController

    def build_requisition
      cash_id = params[:cash_id]
      bank_service = Banking::Account.new(cash_id: cash_id)
      institution = bank_service.get_institutions
      uuid = SecureRandom.uuid
      redirect_url = 'http://tim.ekylibre.lan:3000/backend/cashes/1'
      requisition = bank_service.create_requisition(redirect_url: redirect_url, institution_id: institution.id, reference_id: uuid, max_historical_days: 90)
      session[:requisition_id] = requisition.id
      redirect_to requisition.link
    end

    def sync_account
      cash_id = params[:cash_id]
      requisition_id = session[:requisition_id]
      if requisition_id.nil?
        requisition_id = Preference.get("requisition_id_cash_id_#{cash_id}").value
      end
      if !requisition_id
        raise "Requisition ID is not found. Please complete authorization with your bank"
      end
      ::Banking::BankingFetchUpdateTransactionsJob.perform_later(cash_id: cash_id, requisition_id: requisition_id)
      redirect_to controller: '/backend/cashes', action: :show, id: cash_id
    end

  end
end
