# frozen_string_literal: true

module Banking
  class BankTransaction
    def initialize(cash_id: )
      @cash = Cash.find(cash_id)
    end

    # @param [Hash] opts
    # @option opts [OpenStruct] :transactions transactions
    def import_bank_statements(transactions: )
      transactions_by_month = transactions.booked.group_by do |item|
        date = item.transfered_on
        date.beginning_of_month.to_date
      end

      transactions_by_month.each do |month, transaction_items|
        bank_statement = find_or_create_bank_statement(month)
        transaction_items.each do |transaction_item|
          create_bank_statement_item(bank_statement, transaction_item)
        end
        bank_statement.reload.save!
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
        unless BankStatementItem.find_by(transaction_number: item.transaction_number)
          bank_statement.items.create!(
            initiated_on: item.initiated_on,
            name: item.name,
            memo: item.memo,
            balance: item.balance,
            transaction_number: item.transaction_number,
            transfered_on: item.transfered_on
          )
        end
      end

  end
end
