# frozen_string_literal: true

module Banking
  class FetchUpdateTransactionsJob < ActiveJob::Base
    queue_as :default
    VENDOR = 'nordigen'

    def perform(cash_id:, requisition_id:, nordigen_service: ::Banking::NordigenService.instance)
      begin
        accounts = nordigen_service.get_requisition_accounts(requisition_id)
        update_cash_provider(accounts)

        account_uuid = Cash.find_by(id: cash_id).provider_data[:id]
        if account_uuid.present?
          transactions = nordigen_service.get_account_transactions(account_uuid: account_uuid)
          bs_service = ::Banking::BankTransaction.new(cash_id: cash_id)
          bs_service.import_bank_statements(transactions: transactions)
        end
      rescue StandardError => error
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
      end
    end

    def update_cash_provider(accounts)
      accounts.each do |account|
        cash = Cash.find_by(iban: account.iban)
        if cash
          cash.provider = { vendor: VENDOR, data: { id: account.id.to_s  } } if cash.provider.blank?
          cash.save!
        end
      end
    end
  end
end
