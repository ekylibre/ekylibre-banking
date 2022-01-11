require 'rest-client'

module Banking
  class ServiceError < StandardError; end

  class BankingIntegration < ActionIntegration::Base

    authenticate_with :check do
      parameter :url
      parameter :api_key
      parameter :api_password
      parameter :api_secret
    end

    def check
      nil
    end

  end
end
