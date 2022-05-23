require 'test_helper'
require_relative '../../test_helper'

module Banking
  class TransactionsControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    setup_sign_in

    test '#new when params are not provided, return a list of all institution' do
      get :new
      assert_response :success
      assert JSON.parse(@controller.instance_variable_get(:@list)).count > 0
    end

    test '#new when cash has bank_identifier_code setted' do
      cash = cashes(:cashes_001)
      get :new, params: { cash_id: cash.id }
      assert_redirected_to build_requisition_banking_transaction_path(cash)
    end

    test '#build_requisition ' do
      cash = cashes(:cashes_001)
      institution_id = "WISE_TRWIGB22"
      get :build_requisition, params: { id: cash.id, institution_id: institution_id }
      assert_response :redirect
      assert_not_nil Preference.get("requisition_id_cash_id_#{cash.id}").value
    end

  end
end
