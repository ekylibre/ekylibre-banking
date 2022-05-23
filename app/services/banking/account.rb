# frozen_string_literal: true
require 'nordigen-ruby'

module Banking
  class Account
    include Rails.application.routes.url_helpers
    VENDOR = 'nordigen'.freeze

    # STEP 1
    def initialize(cash_id: nil)
      @cash_id = cash_id if cash_id
      @client = Banking::NordigenService.instance
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
  end
end
