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
        update_cash_provider(cash, accounts)
        import_bank_statements(cash.reload, nordigen_service)
        user.notifications.create!(success_notification_params(cash))
      rescue StandardError => error
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
        ElasticAPM.report(error)
        user.notifications.create!(error_notification_params(error))
      end
    end

    private

      def error_notification_params(error)
        {
          message: :error_during_transactions_synchronization,
          level: :error,
          interpolations: {
            error_message: error
          }
        }
      end

      def success_notification_params(cash)
        {
          message: :cash_transactions_synchronized,
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
          raise StandardError.new(:none_account_iban_match_cash_iban.tl(iban: cash.iban))
        end
      end

      def update_cash_provider(cash, accounts)
        account = accounts.select {|account| account.iban == cash.iban }.first
        if cash.provider.blank?
          cash.provider = provider_for_account(account)
          cash.save!
        end
      end

      def import_bank_statements(cash, nordigen_service)
        account_uuid = cash.provider_data[:id]
        return if account_uuid.nil?

        transactions = nordigen_service.get_account_transactions(account_uuid: account_uuid)
        ::Banking::BankTransaction.new(cash_id: cash.id).import_bank_statements(transactions: transactions)
      end

      def provider_for_account(account)
        { 
          vendor: VENDOR, 
          data: { 
            id: account.id.to_s,
            name: 'account'
          }
        }
      end

  end
end
