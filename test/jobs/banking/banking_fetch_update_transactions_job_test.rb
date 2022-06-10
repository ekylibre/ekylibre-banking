require 'test_helper'
require_relative '../../test_helper'

module Banking
  class BankingFetchUpdateTransactionsJobTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup do
      iban = 'FR7430003000404656433924D84'
      id = 1
      @cash = cashes(:cashes_001)
      @cash.update(iban: iban)

      @nordigen_service = Minitest::Mock.new
      @nordigen_service.expect(:get_requisition_accounts, [OpenStruct.new(iban: iban, id: id)], ['requisition_id'])
      @nordigen_service.expect(:get_account_transactions, [], [{ account_uuid: '1' }])
    end

    test '#perform' do
      BankingFetchUpdateTransactionsJob.perform_now(cash_id: @cash.id, requisition_id: 'requisition_id',
nordigen_service: @nordigen_service )
      assert_equal({ data: { 'id'=> '1' }, vendor: 'nordigen' }, @cash.reload.provider)
      assert_mock(@nordigen_service)
    end
  end
end
