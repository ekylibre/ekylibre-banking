# frozen_string_literal: true

module Banking
  class FetchUpdateTransactionsJob < ActiveJob::Base
    queue_as :default
    VENDOR = 'nordigen'

    def perform(cash_id:, requisition_id:, nordigen_service: ::Banking::NordigenService.instance, user:)
      begin
        cash = Cash.find(cash_id)
        accounts = nordigen_service.get_requisition_accounts(requisition_id)
        check_iban(cash, accounts)
        import_bank_statements(cash, accounts, nordigen_service)
        user.notifications.create!(success_notification_params(cash))
      rescue StandardError => error
        error_message = error
        if error.is_a?(Faraday::ServerError)
          error_message = :nordigen_server_error.tl
        elsif error.is_a?(NordigenService::AccessExpiredError)
          error_message = :access_expired_error.tl
          nordigen_service.delete_requisition(requisition_id)
          Preference.find_by(name: "requisition_id_cash_id_#{cash_id}").destroy
        end
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
        ElasticAPM.report(error)
        user.notifications.create!(error_notification_params(error_message))
      end
    end

    private

      def error_notification_params(error)
        {
          message: :error_during_transactions_synchronization.tl,
          level: :error,
          interpolations: {
            message: error
          }
        }
      end

      def success_notification_params(cash)
        {
          message: :cash_transactions_synchronized.tl,
          level: :success,
          interpolations: {
            cash_name: cash.name
          }
        }
      end

      # Multiple account can be selected for synchronization, so we need to check that at
      # least one account matches cash account (using iban)
      def check_iban(cash, accounts)
        unless accounts.map(&:iban).include?(cash.iban)
          raise StandardError.new(:none_account_iban_matches_cash_iban.tl(cash_name: cash.name))
        end
      end

      def import_bank_statements(cash, accounts, nordigen_service)
        account = accounts.select {|account| account.iban == cash.iban }.first
        transactions = nordigen_service.get_account_transactions(account_uuid: account.id)
        ::Banking::TransactionsImportService.call(cash: cash, transactions: transactions)
      end
  end
end
