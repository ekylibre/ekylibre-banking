# frozen_string_literal: true

module Banking
  class BankTransaction
    def initialize(cash_id: )
      @cash = Cash.find(cash_id)
    end

    # @param [Hash] opts
    # @option opts [OpenStruct] :transactions transactions
    def import_bank_statements(transactions: )
      transactions_by_month = transactions.transactions.booked.group_by do |item|
        date = item.valueDate || item.bookingDate
        Date.parse(date).beginning_of_month.to_date
      end

      transactions_by_month.each do |month, items|
        bank_statement = find_or_create_bank_statement(month)
        items.each do |item|
          create_bank_statement_item(bank_statement, item)
        end
      end
    end

    private

      def find_or_create_bank_statement(started_on)
        number = "#{started_on.year}-#{started_on.month}"
        start = started_on.beginning_of_month
        stop = started_on.end_of_month
        BankStatement.find_or_create_by!(cash: @cash, number: number, started_on: start, stopped_on: stop)
      end

      def create_bank_statement_item(bank_statement, item)
        unless BankStatementItem.find_by(transaction_number: item.transactionId)
          name = if item.remittanceInformationUnstructuredArray&.any?
                   item.remittanceInformationUnstructuredArray.first
                 else
                   item.remittanceInformationUnstructured
                 end

          bank_statement.items.create!(
            initiated_on: Date.parse(item.bookingDate),
            name: name,
            memo: item.remittanceInformationUnstructuredArray&.join(', '),
            balance: item.transactionAmount.amount.to_f,
            transaction_number: item.transactionId,
            transfered_on: Date.parse(item.valueDate || item.bookingDate )
          )
        end
      end

  end
end
