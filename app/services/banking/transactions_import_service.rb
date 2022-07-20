# frozen_string_literal: true

module Banking
  class TransactionsImportService
    def self.call(*args)
      new(*args).call
    end

    def initialize(cash:, transactions:)
      @cash = cash
      @transactions = transactions
    end

    def call
      transactions_by_month.each do |beginning_of_month, transaction_items|
        next if !bank_statement_can_be_imported?(beginning_of_month)

        bank_statement = create_bank_statement(beginning_of_month)

        transaction_items.each do |transaction_item|
          create_bank_statement_item(bank_statement, transaction_item)
        end
        recalculate_debit_credit(bank_statement)
      end
    end

    private
      attr_reader :cash, :transactions 

      def transactions_by_month
        transactions.booked.group_by do |item|
          date = item.transfered_on
          date.beginning_of_month.to_date
        end
      end

      def create_bank_statement(beginning_of_month)
        end_of_month = beginning_of_month.end_of_month

        number = "#{beginning_of_month.year}-#{beginning_of_month.month}"
        BankStatement.create!(cash: cash, number: number, started_on: beginning_of_month, stopped_on: end_of_month)
      end

      def bank_statement_can_be_imported?(beginning_of_month)
        end_of_month = beginning_of_month.end_of_month
        BankStatement.between(beginning_of_month, end_of_month).empty?
      end

      def create_bank_statement_item(bank_statement, item)
        return if BankStatementItem.find_by(transaction_number: item.transaction_number)

        bank_statement.items.create!(
          initiated_on: item.initiated_on,
          name: item.name,
          memo: item.memo,
          balance: item.balance,
          transaction_number: item.transaction_number,
          transfered_on: item.transfered_on
        )
      end

      def recalculate_debit_credit(bank_statement)
        bank_statement.reload.save!
      end

  end
end
