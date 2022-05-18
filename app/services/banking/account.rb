# frozen_string_literal: true
require 'nordigen-ruby'

module Banking
  class Account
    include Rails.application.routes.url_helpers

    SECRET_ID = ENV['NORDIGEN_SECRET_ID']
    SECRET_KEY = ENV['NORDIGEN_SECRET_KEY']
    VENDOR = 'nordigen'.freeze

    # STEP 1
    def initialize(cash_id: nil)
      @cash_id = cash_id if cash_id
      @country = Preference[:country]
      @client = Nordigen::NordigenClient.new(secret_id: SECRET_ID, secret_key: SECRET_KEY)
      token_data = @client.generate_token()
      @access_token = token_data.access
      @access_dead_at = Time.now + token_data.access_expires
      @refresh_token = token_data.refresh
      @refresh_dead_at = Time.now + token_data.refresh_expires
    end

    # STEP 2
    # return institutions (banks) for a country (fr, gb...)
    # return an Array of Hash
    # {"id"=>"ALLIANZ_BANQUE_AGFBFRPPXXX",
    #  "name"=>"Allianz Banque",
    #  "bic"=>"AGFBFRPPXXX",
    #  "transaction_total_days"=>"90",
    #  "countries"=>["FR"],
    #  "logo"=>"https://cdn.nordigen.com/ais/ALLIANZ_BANQUE_AGFBFRPPXXX.png"}
    def get_institution
      institutions = @client.institution.get_institutions(@country)
      if @cash_id && Cash.find(@cash_id)
        bic = Cash.find(@cash_id)&.bank_identifier_code
        banks = institutions.select {|b| b.bic == bic } if bic.present?
        if banks.any?
          banks.first
        else
          nil
        end
      else
        nil
      end
    end

    def get_institutions
      institutions = @client.institution.get_institutions(@country)
    end

    # STEP 3
    def create_requisition(redirect_url: , institution_id:, reference_id:, max_historical_days: 90)
      # if cash_id, get institution_id and build redirect_url

      response = @client.init_session( redirect_url: redirect_url,
                           institution_id: institution_id,
                           reference_id: reference_id,
                           max_historical_days: max_historical_days
                         )

      name = "requisition_id_cash_id_#{@cash_id}"
      value = response.id
      Preference.set!(name, value)
      name = "requisition_link_cash_id_#{@cash_id}"
      value = response.link
      Preference.set!(name, value)
      response
      # need to save response[:id] from response as requisition_id
      # need to save response[:link] from response as link_to_follow
      # Follow the link to start the end-user authentication process with the financial institution.
      # Save the requisition ID (id in the response).
      # You will later need it to retrieve the list of end-user accounts.
    end

    # STEP 5
    # return account_uuid
    def list_accounts(requisition_id: nil)
      call = @client.requisition.get_requisition_by_id(requisition_id)
      # set account_uuid in cashe for each account exist
      call.accounts.each do |account_uuid|
        infos = get_account_info(account_uuid)
        cash = Cash.find_by(iban: infos.iban)
        if cash
          cash.provider = { vendor: VENDOR, data: { id: infos.id.to_s  } } if cash.provider.blank?
          cash.save!
        end
      end
      if @cash_id
        cash = Cash.find_by(id: @cash_id).provider[:data]['id']
      else
        nil
      end
    end

    # STEP 5-1
    # :id, :iban
    def get_account_info(account_uuid)
      account = @client.account(account_uuid)
      account.get_metadata()
    end

    # BALANCES
    # {:balances=>[
    #    {:balanceAmount=>{:amount=>"131836.48", :currency=>"EUR"}, :balanceType=>"expected"},
    #    {:balanceAmount=>{:amount=>"131836.48", :currency=>"EUR"}, :balanceType=>"closingBooked"}
    #            ]
    # }
    def get_account_balances(account_uuid)
      account = @client.account(account_uuid)
      account.get_balances()
    end

    # DETAILS
    # {:account=>
    #   {:resourceId=>"87e1fe2a8311d43ddaab9c1fdf8714d0d7dbc1f0d683e0159f9a238d271638c3",
    #    :iban=>"FR7610057191080002016660128",
    #    :currency=>"EUR",
    #    :name=>"19108 000201666 01 C/C Contrat Pro Global EKYLIBRE",
    #   :cashAccountType=>"CACC"}
    # }
    def get_account_details(account_uuid)
      account = @client.account(account_uuid)
      account.get_details()
    end

    # TRANSACTIONS
    # transactions=>
    #   booked=> [{:bookingDate=>"2022-01-13",
    #              :remittanceInformationUnstructuredArray=>["PAIEMENT CB  1101 BORDEAUX CEDE", "CCI BDX ARCACHO  CARTE 27571395"],
    #              :transactionAmount=>{:amount=>"-120.00", :currency=>"EUR"},
    #              :transactionId=>"08001202201300001-87e1fe2a8311d43ddaab9c1fdf8714d0d7dbc1f0d683e0159f9a238d271638c3",
    #              :valueDate=>"2022-01-13"}, {...}]
    #   pending=> [{...},  {...}]
    def get_account_transactions(account_uuid: )
      account = @client.account(account_uuid)
      account.get_transactions()
    end

  end
end
