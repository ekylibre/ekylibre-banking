# frozen_string_literal: true

module Banking
  class Account
    include Rails.application.routes.url_helpers

    SECRET_ID = ENV['NORDIGEN_SECRET_ID']
    SECRET_KEY = ENV['NORDIGEN_SECRET_KEY']
    VENDOR = 'nordigen'.freeze

    # STEP 1
    def initialize
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
    def get_institutions(cash_id = nil)

      institutions = @client.institution.get_institutions(@country)

      if cash_id
        bic = Cash.find(cash_id)&.bank_identifier_code
        banks = institutions.select {|b| b.bic == bic } if bic.present?
        if banks.any?
          banks.first
        else
          nil
        end
      else
        institutions
      end
    end

    # STEP 3
    def create_end_user_agreement(institution_id: nil, max_historical_days: 90, access_valid_for_days: 365, access_scope: @access_scope)
      url = BASE_URL + END_USER_AGREEMENT_URL
      params = { accept: :json, content_type: :json, authorization: "Bearer #{@access_token}" }
      payload = { institution_id: institution_id }
      # in options in payload
      # max_historical_days: max_historical_days.to_s,
      # access_valid_for_days: access_valid_for_days.to_s,
      # access_scope: access_scope

      call = RestClient.post(url, payload, headers=params)
      response = JSON.parse(call.body).deep_symbolize_keys
      # need to save :id from response as agrement_id
      # ex value "8f075a9d-770b-4bfa-ba42-acc226d478b5"
      name = "agrement_id_#{institution_id}"
      value = response[:id]
      Preference.set!(name, value)
      response
    end

    # STEP 4
    def create_requisition(cash_id: nil, institution_id: nil, reference: nil, redirect_url: nil, agreement_id: nil, user_language: nil)
      # if cash_id, get institution_id and build redirect_url
      if cash_id
        redirect_url ||= URI.join(root_url, "/backend/cashes/#{cash_id}").to_s
        institution = get_institutions(cash_id)
        if institution
          institution_id = institution.id
        else
          puts "No way to find BIC with cash_id #{cash_id} provide"
        end
      end

      response = @client.init_session( redirect_url: redirect_url,
                           institution_id: institution_id,
                           reference_id: SecureRandom.uuid
                         )

      name = "requisition_id_#{institution_id}"
      value = response.id
      Preference.set!(name, value)
      name = "requisition_link_#{institution_id}"
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
    def list_accounts(requisition_id: nil)
      accounts = @client.requisition.get_requisition_by_id(requisition_id)
      accounts.each do |account_uuid|
        infos = get_account_info(account_uuid)
        cash = Cash.find_by(iban: infos[:iban])
        if cash
          cash.provider = { vendor: VENDOR, data: { id: infos[:id].to_s  } } if cash.provider.blank?
          cash.save!
        end
        # account_uuid = "41483703-f49a-4c84-8b4a-2d229e620008"
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
    def get_account_transactions(account_uuid:, from:, to: , premium: false)
      account = @client.account(account_uuid)
      account.get_transactions()
    end

  end
end
