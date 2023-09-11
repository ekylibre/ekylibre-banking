# frozen_string_literal: true

module Banking
  class TransactionsImportService
    PROVIDER_VENDOR = 'nordigen'
    PROVIDER_NAME = 'transaction'

    class MissingTransactionIdError < StandardError
      def initialize(msg = 'Missing uniq id for transaction')
        super
      end
    end

    def self.call(*args)
      new(*args).call
    end

    def initialize(cash:, transactions:)
      @cash = cash
      @transactions = transactions
    end

    def call
      transactions_by_month.each do |beginning_of_month, transaction_items|
        bank_statement = find_or_create_bank_statement(beginning_of_month)
        next if bank_statement.nil?

        transaction_items.each do |transaction_item|
          next if bank_statement_item_already_exists?(transaction_item)

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

      def find_or_create_bank_statement(beginning_of_month)
        end_of_month = beginning_of_month.end_of_month
        number = "#{beginning_of_month.year}-#{beginning_of_month.month}"

        bank_statement = BankStatement.find_by(cash: cash, number: number, started_on: beginning_of_month, stopped_on: end_of_month)
        return bank_statement if bank_statement.present?

        if bank_statement_can_be_created?(beginning_of_month)
          BankStatement.create!(cash: cash, number: number, started_on: beginning_of_month, stopped_on: end_of_month)
        end
      end

      def bank_statement_can_be_created?(beginning_of_month)
        end_of_month = beginning_of_month.end_of_month
        BankStatement.for_cash(cash).between(beginning_of_month, end_of_month).empty?
      end

      def bank_statement_item_already_exists?(item)
        (item.transaction_number.present? && BankStatementItem.find_by(transaction_number: item.transaction_number)) ||
          (item.internalTransactionId.present? && BankStatementItem.of_provider(PROVIDER_VENDOR, PROVIDER_NAME, item.internalTransactionId).any?)
      end

      def create_bank_statement_item(bank_statement, item)
        raise MissingTransactionIdError.new if item.internalTransactionId.blank?

        bank_statement.items.create!(attributes(item))
      end

      def attributes(item)
        {
          initiated_on: item.initiated_on,
          transaction_number: item.transaction_number,
          name: item.name,
          memo: item.memo,
          balance: item.balance,
          transfered_on: item.transfered_on,
          provider:
            {
              vendor: PROVIDER_VENDOR,
              name: PROVIDER_NAME,
              id: item.internalTransactionId
            }
        }
      end

      def recalculate_debit_credit(bank_statement)
        bank_statement.reload.save!
      end

  end
end
