# frozen_string_literal: true
module Banking
  class DestroyRequisitonIdJob < ActiveJob::Base
    queue_as :default

    def perform(preference_id)
      Preference.find(preference_id).destroy
    end
  end
end