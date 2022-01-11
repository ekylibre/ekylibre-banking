# frozen_string_literal: true

class BankingFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  VENDOR = 'nordigen'

  def perform
    begin
      # TODO: call create or update cashes from baqio api
      cash_handler = Integrations::Banking::Handlers::Cashes.new(vendor: VENDOR)
      cash_handler.bulk_find_or_create

    rescue StandardError => error
      Rails.logger.error $ERROR_INFO
      Rails.logger.error $ERROR_INFO.backtrace.join("\n")
      ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
    end
  end

  private

    def error_notification_params(error)
      {
        message: 'error_during_banking_api_call',
        level: :error,
        target_type: '',
        target_url: '',
        interpolations: {
          error_message: error
        }
      }
    end
end
