# frozen_string_literal: true

require 'nordigen-ruby'

module Banking
  class NordigenService
    class AccessExpiredError < StandardError; end

    include Singleton
    SECRET_ID = ENV['NORDIGEN_SECRET_ID']
    SECRET_KEY = ENV['NORDIGEN_SECRET_KEY']

    def initialize
      @client = Nordigen::NordigenClient.new(secret_id: SECRET_ID, secret_key: SECRET_KEY)
    end

    attr_reader :client

    def get_institution_by_bic(bic)
      generate_token

      get_institutions.select {|b| b.bic == bic }.first
    end

    def get_institution_by_id(id)
      generate_token

      client.institution.get_institution_by_id(id)
    end

    # @param [String] country country name abbreviated
    # @return [Array<OpenStruct>] institutions of the country
    # institution attr. : :id, :name, :bic, :transaction_total_days, :countries logo
    def get_institutions(country = Preference[:country])
      generate_token

      client.institution.get_institutions(country)
    end

    def create_requisition(redirect_url:, institution_id:, reference_id:, max_historical_days: 90)
      generate_token

      requisition = client.init_session( redirect_url: redirect_url,
                            institution_id: institution_id,
                            reference_id: reference_id,
                            max_historical_days: max_historical_days)
      Ekylibre::Nordigen::Requisition.new(requisition)
    end

    def delete_requisition(requisition_id)
      generate_token

      client.requisition.delete_requisition(requisition_id)
    end

    # :id, :iban
    def get_account_info(account_uuid)
      generate_token

      account = client.account(account_uuid)
      account.get_metadata
    end

    # @param [Hash] opts
    # @option opts [String] :account_uuid account id
    # @return [OpenStructS] account transactions
    # transactions=>
    #   booked=> [{:entryReference="7183900022293"
    #              :bookingDate=>"2022-01-13",
    #              :valueDate="2023-09-06",
    #              :remittanceInformationUnstructuredArray=>["PAIEMENT CB  1101 BORDEAUX CEDE", "CCI BDX ARCACHO  CARTE 27571395"],
    #              :transactionAmount=>{:amount=>"-120.00", :currency=>"EUR"},
    #              :internalTransactionId=>"08001202201300001-87e1fe2a8311d43ddaab9c1fdf8714d0d7dbc1f0d683e0159f9a238d271638c3",
    #              }, {...}]
    #   pending=> [{...},  {...}]
    def get_account_transactions(account_uuid: )
      generate_token

      account = client.account(account_uuid)
      response = account.get_transactions

      if response.status_code == 401
        raise AccessExpiredError.new(response.details)
      end

      acounts_transactions = response&.transactions

      if acounts_transactions.present?
        acounts_transactions.booked.map! do |transaction|
          Ekylibre::Nordigen::Transaction.new(transaction)
        end
        acounts_transactions.pending.map! do |transaction|
          Ekylibre::Nordigen::Transaction.new(transaction)
        end
      end
      acounts_transactions
    end

    def get_requisition_by_id(requisition_id)
      generate_token

      requisition = client.requisition.get_requisition_by_id(requisition_id)
      if requisition.status_code.present? && (%w(400 401 403 404 429).include? requisition.status_code.to_s)
        nil
      else
        Ekylibre::Nordigen::Requisition.new(requisition)
      end
    end

    def get_requisition_accounts(requisition_id)
      generate_token

      requisition = get_requisition_by_id(requisition_id)
      requisition.accounts.map do |account_uuid|
        get_account_info(account_uuid)
      end
    end

    private

      def generate_token
        client.generate_token
      end
  end

end
