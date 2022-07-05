require 'test_helper'
require_relative '../../test_helper'

module Banking
  class BankTransactionTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

    test 'It creates a new bank statement and item with correct attributes' do
      cash = cashes(:cashes_001)
      Banking::BankTransaction.new(cash_id: cash.id).import_bank_statements(transactions: transactions1)
      bank_statement = BankStatement.find_by(number: '2022-5')
      assert_equal('2022-05-01', bank_statement.started_on.to_s)
      assert_equal('2022-05-31', bank_statement.stopped_on.to_s)
      assert_equal(cash, bank_statement.cash)

      item = bank_statement.items.first
      assert_equal('2022-05-26', item.initiated_on.to_s)
      assert_equal('PAIEMENT PAR CARTE 25/05/2022 MARCHE', item.name)
      assert_nil(item.memo)
      assert_equal(80.20, item.balance)
      assert_equal('40001875091_12340', item.transaction_number)
      assert_equal('2022-05-26', item.transfered_on.to_s)
    end

    test 'It creates a new bank statement and item with correct attributes if data struture is different' do
      cash = cashes(:cashes_001)
      Banking::BankTransaction.new(cash_id: cash.id).import_bank_statements(transactions: transactions2)
      bank_statement = BankStatement.find_by(number: '2022-6')
      item = bank_statement.items.first
      assert_equal('2022-06-27', item.initiated_on.to_s)
      assert_equal('PAIEMENT PAR CARTE 26/06/2022 TRANSPORT', item.name)
      assert_equal('PAIEMENT PAR CARTE 26/06/2022 TRANSPORT, COMPTE 51532324', item.memo)
      assert_equal('2022-06-28', item.transfered_on.to_s)
    end

    def transactions1
      transaction1 = Nordigen::Transaction.new(
        OpenStruct.new(
          bookingDate: '2022-05-26',
          endToEndId: 'NOTPROVIDED',
          remittanceInformationUnstructured: 'PAIEMENT PAR CARTE 25/05/2022 MARCHE',
          transactionAmount:
            OpenStruct.new(
              amount: '-80.20',
              currency: 'EUR'
            ),
          transactionId: '40001875091_12340'
        )
      )

      OpenStruct.new(
        booked: [transaction1]
      )
    end

    def transactions2
      transaction2 = Nordigen::Transaction.new(
        OpenStruct.new(
          bookingDate: '2022-06-27',
          valueDate: '2022-06-28',
          endToEndId: 'NOTPROVIDED',
          remittanceInformationUnstructuredArray: ['PAIEMENT PAR CARTE 26/06/2022 TRANSPORT', 'COMPTE 51532324'],
          transactionAmount:
            OpenStruct.new(
              amount: '-50.20',
              currency: 'EUR'
            ),
          transactionId: '40001875091_12350'
        )
      )

      OpenStruct.new(
        booked: [transaction2]
      )
    end
  end
end
