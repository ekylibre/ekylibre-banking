require 'test_helper'
require_relative '../../test_helper'

module Banking
  class TransactionsImportServiceTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

    test 'It creates a new bank statement and item with correct attributes' do
      cash = cashes(:cashes_001)
      Banking::TransactionsImportService.call(cash: cash, transactions: transactions1)
      bank_statement = BankStatement.find_by(number: '2022-5')
      assert_equal('2022-05-01', bank_statement.started_on.to_s)
      assert_equal('2022-05-31', bank_statement.stopped_on.to_s)
      assert_equal(cash, bank_statement.cash)
      assert_equal(80.20, bank_statement.debit)

      item = bank_statement.items.first
      assert_equal('2022-05-26', item.initiated_on.to_s)
      assert_equal('PAIEMENT PAR CARTE 25/05/2022 MARCHE', item.name)
      assert_nil(item.memo)
      assert_equal(80.20, item.balance)
      assert_nil(item.transaction_number)
      assert_equal('2022-05-26', item.transfered_on.to_s)
    end

    test 'It creates a new bank statement and item with correct attributes if data struture is different' do
      cash = cashes(:cashes_001)
      Banking::TransactionsImportService.call(cash: cash, transactions: transactions2)
      bank_statement = BankStatement.find_by(number: '2022-6')
      item = bank_statement.items.first
      assert_equal('2022-06-27', item.initiated_on.to_s)
      assert_equal('PAIEMENT PAR CARTE 26/06/2022 TRANSPORT', item.name)
      assert_equal('PAIEMENT PAR CARTE 26/06/2022 TRANSPORT, COMPTE 51532324', item.memo)
      assert_equal('2022-06-28', item.transfered_on.to_s)
    end

    test 'It doesn\'t creates a new bank statement if one with same dates already exist' do
      cash = cashes(:cashes_001)
      bank_statement = bank_statements(:bank_statements_001)
      started_on = '2022-04-26'
      stopped_on = '2022-05-29'
      bank_statement.update(started_on: started_on,  stopped_on: '2022-05-29')
      assert_no_difference 'BankStatement.count' do
        Banking::TransactionsImportService.call(cash: cash, transactions: transactions1)
      end
    end

    test "It raise an error if transaction doesn't have transacton id" do
      cash = cashes(:cashes_001)
      assert_raise StandardError do
        Banking::TransactionsImportService.call(cash: cash, transactions: transactions3)
      end
    end

    def transactions1
      transaction1 = Ekylibre::Nordigen::Transaction.new(
        OpenStruct.new(
          bookingDate: '2022-05-26',
          endToEndId: 'NOTPROVIDED',
          remittanceInformationUnstructured: 'PAIEMENT PAR CARTE 25/05/2022 MARCHE',
          transactionAmount:
            OpenStruct.new(
              amount: '-80.20',
              currency: 'EUR'
            ),
          transactionId: '40001875091_12340',
          internalTransactionId: '40001875091_12341'
        )
      )

      OpenStruct.new(
        booked: [transaction1]
      )
    end

    def transactions2
      transaction2 = Ekylibre::Nordigen::Transaction.new(
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
          transactionId: '40001875091_12350',
          internalTransactionId: '40001875091_12342'
        )
      )

      OpenStruct.new(
        booked: [transaction2]
      )
    end

    def transactions3
      transaction3 = Ekylibre::Nordigen::Transaction.new(
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
        booked: [transaction3]
      )
    end
  end
end
