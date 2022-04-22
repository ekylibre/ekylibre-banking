# frozen_string_literal: true
module Banking
  class BankingFetchUpdateTransactionsJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    VENDOR = 'nordigen'

    def perform(cash_id:, requisition_id:)
      begin
        bank_service = ::Banking::Account.new(cash_id: cash_id)
        account_uuid = bank_service.list_accounts(requisition_id: requisition_id)
        transactions = bank_service.get_account_transactions(account_uuid: account_uuid)
        bs_service = ::Banking::BankTransaction.new(cash_id: cash_id)
        bs_service.import_bank_statements(transactions: transactions)
      rescue StandardError => error
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
      end
    end

    private

      def error_notification_params(error)
        {
          message: 'error_during_banking_api_call',
          level: :error,
          target_type: '',
          target_url: '',
          interpolations: {
            error_message: error
          }
        }
      end
  end
end
