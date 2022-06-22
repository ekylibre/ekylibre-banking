# frozen_string_literal: true

require 'nordigen-ruby'

module Banking
  class NordigenService
    include Singleton
    SECRET_ID = ENV['NORDIGEN_SECRET_ID']
    SECRET_KEY = ENV['NORDIGEN_SECRET_KEY']
    using Nordigen::ApiRefinements

    def initialize
      @client = Nordigen::NordigenClient.new(secret_id: SECRET_ID, secret_key: SECRET_KEY)
      token_data = @client.generate_token
    end

    def get_institution_by_bic(bic)
      get_institutions.select {|b| b.bic == bic }.first
    end

    def get_institution_by_id(id)
      @client.institution.get_institution_by_id(id)
    end

    # @param [String] country country name abbreviated
    # @return [Array<OpenStruct>] institutions of the country
    # institution attr. : :id, :name, :bic, :transaction_total_days, :countries logo
    def get_institutions(country = Preference[:country])
      @client.institution.get_institutions(country)
    end

    def create_requisition(redirect_url:, institution_id:, reference_id:, max_historical_days: 90)
      @client.init_session( redirect_url: redirect_url,
                            institution_id: institution_id,
                            reference_id: reference_id,
                            max_historical_days: max_historical_days)
    end

    # :id, :iban
    def get_account_info(account_uuid)
      account = @client.account(account_uuid)
      account.get_metadata
    end

    # @param [Hash] opts
    # @option opts [String] :account_uuid account id
    # @return [OpenStructS] account transactions
    # transactions=>
    #   booked=> [{:bookingDate=>"2022-01-13",
    #              :remittanceInformationUnstructuredArray=>["PAIEMENT CB  1101 BORDEAUX CEDE", "CCI BDX ARCACHO  CARTE 27571395"],
    #              :transactionAmount=>{:amount=>"-120.00", :currency=>"EUR"},
    #              :transactionId=>"08001202201300001-87e1fe2a8311d43ddaab9c1fdf8714d0d7dbc1f0d683e0159f9a238d271638c3",
    #              :valueDate=>"2022-01-13"}, {...}]
    #   pending=> [{...},  {...}]
    def get_account_transactions(account_uuid: )
      account = @client.account(account_uuid)
      account.get_transactions
    end

    def get_requisition_by_id(requisition_id)
      @client.requisition.get_requisition_by_id(requisition_id)
    end

    def get_requisition_accounts(requisition_id)
      requisition = get_requisition_by_id(requisition_id)
      requisition.accounts.map do |account_uuid|
        get_account_info(account_uuid)
      end
    end
  end

end
