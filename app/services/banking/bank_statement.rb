# frozen_string_literal: true

module Banking
  class BankStatement

    VENDOR = 'nordigen'.freeze

    # STEP 1
    def initialize(cash_id: )
      @cash_id = cash_id
      @country = Preference[:country]
    end

    # transactions OpenStruct
    def import_bank_statements(transactions: )
      number = '01'
      # started_on = Date.parse()
      # stopped_on = Date.parse()
      # bk = BankStatement.new(cash: @cash, number: number, started_on: , stopped_on: )
      transactions.transactions.booked.each do |item|
        initiated_on = Date.parse(item.bookingDate)
        name = item.remittanceInformationUnstructuredArray.first
        memo = item.remittanceInformationUnstructuredArray
        balance = item.transactionAmount.amount.to_f
        transaction_number = item.transactionId
        transfered_on = Date.parse(item.valueDate)
      end
    end

  end
end
