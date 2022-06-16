module Nordigen
  class Requisition < SimpleDelegator
    STATUS_DESCRIPTION = {
      'CR' => :requisition_created,
      'LN' => :account_linked,
      'EX' => :access_expired,
      'RJ' => :ssn_verification_failed,
      'UA' => :unedergoing_authentication,
      'GA' => :granting_access,
      'SA' => :selecting_accounts,
      'GC' => :giving_consent
    }

    def human_status
      "nordigen.#{STATUS_DESCRIPTION[status]}".tl
    end

    def linked?
      status == 'LN'
    end
  end
end
