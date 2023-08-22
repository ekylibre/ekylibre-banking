require 'securerandom'

module Banking
  class CashSynchronizationsController < Backend::BaseController
    def new
      cash = Cash.find_by_id(params[:cash_id])
      nordigen_service = Banking::NordigenService.instance
      if (requisition_id = find_requisition_id(params[:cash_id]))
        requisition = nordigen_service.get_requisition_by_id(requisition_id)
        redirect_to(requisition.link)
        return
      end

      if cash && (bic = cash.bank_identifier_code).present?
        institution = nordigen_service.get_institution_by_bic(bic)
        if institution
          redirect_to(build_requisition_banking_cash_synchronization_path(cash_id: cash.id, institution_id: institution.id))
          return
        end
      end
      institutions = nordigen_service.get_institutions
      @list = institutions.collect(&:marshal_dump).to_json
    end

    def build_requisition
      cash_id = params[:cash_id]
      nordigen_service = Banking::NordigenService.instance
      institution = nordigen_service.get_institution_by_id(params[:institution_id])
      uuid = SecureRandom.uuid
      redirect_url = self.request.base_url + '/backend/cashes/' + cash_id.to_s
      requisition = nordigen_service.create_requisition(redirect_url: redirect_url,
                                                          institution_id: institution.id,
                                                          reference_id: uuid,
                                                          max_historical_days: institution.transaction_total_days || 90)
      name = "requisition_id_cash_id_#{cash_id}"
      value = requisition.id
      preference = Preference.set!(name, value)
      redirect_to requisition.link
    end

    def delete_requisition
      cash_id = params[:cash_id]
      requisition_id = find_requisition_id(cash_id)
      if requisition_id.present?
        nordigen_service = Banking::NordigenService.instance
        nordigen_service.delete_requisition(requisition_id)
        Preference.find_by(name: "requisition_id_cash_id_#{cash_id}").destroy
      end
      redirect_to backend_cash_path(cash_id)
    end

    def perform
      cash_id = params[:cash_id]
      cash = Cash.find(cash_id)
      unless cash.synchronizable?
        notify_warning(:iban_should_be_provided.tl)
        redirect_to backend_cash_path(cash_id)
        return
      end

      if (requisition_id = find_requisition_id(cash_id)).nil?
        notify_warning(:account_sync_authorization_required.tl)
      else
        ::Banking::FetchUpdateTransactionsJob.perform_later(cash_id: cash_id, requisition_id: requisition_id, user: current_user)
        notify_success(:cash_transactions_synchronizing.tl)
      end
      redirect_to backend_cash_path(cash_id)
    end

    private

      def find_requisition_id(cash_id)
        Preference.find_by(name: "requisition_id_cash_id_#{cash_id}")&.value
      end
  end
end
