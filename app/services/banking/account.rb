# frozen_string_literal: true

module Banking
  class Account

    BASE_URL = 'https://ob.nordigen.com/api/v2'.freeze
    TOKEN_URL = '/token/new/'.freeze
    SECRET_ID = ENV['NORDIGEN_SECRET_ID']
    SECRET_KEY = ENV['NORDIGEN_SECRET_KEY']
    VENDOR = 'nordigen'.freeze

    def initialize
      params = { accept: :json, content_type: :json }
      payload = { secret_id: SECRET_ID, secret_key: SECRET_KEY }
      url = BASE_URL + TOKEN_URL
      call = RestClient.post(url, payload, headers=params)
      response = JSON.parse(call.body).deep_symbolize_keys
      @access_token = response[:access]
      @access_dead_at = Time.now + response[:access_expires]
      @refresh_token = response[:refresh]
      @refresh_dead_at = Time.now + response[:refresh_expires]
    end

  end
end
