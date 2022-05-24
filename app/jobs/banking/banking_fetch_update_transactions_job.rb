# frozen_string_literal: true
module Banking
  class BankingFetchUpdateTransactionsJob < ActiveJob::Base
    queue_as :default
    VENDOR = 'nordigen'

    def perform(cash_id:, requisition_id:)
      begin
        nordign_service = ::Banking::NordigenService.instance
        accounts = nordign_service.get_requisition_accounts(requisition_id)
        accounts.each do |account|
          if cash = Cash.find_by(iban: account.iban)
            cash.provider = { vendor: VENDOR, data: { id: account.id.to_s  } } if cash.provider.blank?
            cash.save!
          end
        end
        account_uuid = Cash.find_by(id: cash_id).provider_data[:id]
        transactions = nordign_service.get_account_transactions(account_uuid: account_uuid)
        bs_service = ::Banking::BankTransaction.new(cash_id: cash_id)
        bs_service.import_bank_statements(transactions: transactions)
      rescue StandardError => error
        Rails.logger.error $ERROR_INFO
        Rails.logger.error $ERROR_INFO.backtrace.join("\n")
        ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
      end
    end
  end
end
