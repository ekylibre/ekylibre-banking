require 'test_helper'
require_relative '../../test_helper'

module Banking
  class CashSynchronizationsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup_sign_in

    setup do 
      @cash = cashes(:cashes_001)
      cash.update(bank_identifier_code: 'TRWIGB22')
    end

    attr_reader :cash

    test '#new when params are not provided, return a list of all institution' do
      get :new, params: {}
      assert_response :success
      assert JSON.parse(@controller.instance_variable_get(:@list)).count > 0 , 'Assigns an institution list'
    end

    test '#new when cash has bank_identifier_code setted' do
      get :new, params: { cash_id: cash.id }
      assert_redirected_to build_requisition_banking_cash_synchronization_path(cash_id: cash.id), 'Redirects to build requisition'
    end

    test '#build_requisition' do
      institution_id = "WISE_TRWIGB22"
      get :build_requisition, params: { cash_id: cash.id, institution_id: institution_id }
      assert_response :redirect
      assert_not_nil Preference.get("requisition_id_cash_id_#{cash.id}").value, 'Stores the requisition_id in preference'
    end

    test '#perform' do
      assert_raises StandardError do
        get :perform, params: { cash_id: cash.id }
      end

      requisition_id = "44305d8a-42fd-4b19-9c2d-c0bae0479cb5"
      Preference.set!("requisition_id_cash_id_#{cash.id}", requisition_id)

      ::Banking::BankingFetchUpdateTransactionsJob = MiniTest::Mock.new
      ::Banking::BankingFetchUpdateTransactionsJob.expect(:perform_later, nil, [{cash_id: cash.id.to_s , requisition_id: requisition_id}])

      get :perform, params: { cash_id: cash.id }
      ::Banking::BankingFetchUpdateTransactionsJob.verify
      assert_redirected_to backend_cash_path(cash), 'Redirects to cash show view'
    end

  end
end
