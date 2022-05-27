# frozen_string_literal: true

module Banking
  class BankTransaction
    def initialize(cash_id: )
      @cash = Cash.find(cash_id)
    end

    # @param [Hash] opts
    # @option opts [OpenStruct] :transactions transactions
    def import_bank_statements(transactions: )
      collection = transactions.transactions.booked.group_by { |item| Date.parse(item.bookingDate).beginning_of_month.to_date }
      collection.each do |month, items|
        bk = find_or_create_bank_statement(month)
        items.each do |item|
          create_bank_statement_item(bk, item)
        end
      end
    end

    private

      def find_or_create_bank_statement(started_on)
        number = "#{started_on.year}-#{started_on.month}"
        start = started_on.beginning_of_month
        stop = started_on.end_of_month
        bk = BankStatement.find_or_create_by!(cash: @cash, number: number, started_on: start, stopped_on: stop)
      end

      def create_bank_statement_item(bk, item)
        unless BankStatementItem.find_by(transaction_number: item.transactionId)
          bk.items.create!(
            initiated_on: Date.parse(item.bookingDate),
            name: item.remittanceInformationUnstructured,
            memo: item.remittanceInformationUnstructuredArray,
            balance: item.transactionAmount.amount.to_f,
            transaction_number: item.transactionId,
            transfered_on: Date.parse(item.bookingDate || item.valueDate)
          )
        end
      end

  end
end
