require 'test_helper'
require_relative '../../test_helper'

module Banking
  class BankTransactionTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

    test "It create a new bank statement and item" do
      cash = cashes(:cashes_001)
      Banking::BankTransaction.new(cash_id: cash.id).import_bank_statements(transactions: transactions)
      bank_statement = BankStatement.order("created_at").last
      assert_equal('2022-5', bank_statement.number)
      assert_equal('2022-05-01', bank_statement.started_on.to_s)
      assert_equal('2022-05-31', bank_statement.stopped_on.to_s)
      assert_equal(cash, bank_statement.cash)
      item = bank_statement.items.first
      assert_equal("2022-05-26", item.initiated_on.to_s)
      assert_equal("PAIEMENT PAR CARTE 25/05/2022 MARCHE", item.name)
      assert_equal(nil, item.memo)
      assert_equal(80.20, item.balance)
      assert_equal("40001875091_12340", item.transaction_number)
      assert_equal("2022-05-26", item.transfered_on.to_s)
    end

    def transactions
      transaction = OpenStruct.new(
        bookingDate: "2022-05-26", 
        endToEndId:"NOTPROVIDED", 
        remittanceInformationUnstructured:"PAIEMENT PAR CARTE 25/05/2022 MARCHE", 
        transactionAmount:
          OpenStruct.new( 
            amount:"-80.20", 
            currency:"EUR" 
          ),
        transactionId: "40001875091_12340"
      )

      OpenStruct.new(
        transactions: OpenStruct.new(booked: [transaction])
      )
    end
  end
end