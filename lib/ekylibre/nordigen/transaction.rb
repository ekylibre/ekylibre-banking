require 'forwardable'

module Ekylibre
  module Nordigen
    class Transaction
      extend Forwardable

      def_delegators :@nordigen_transaction, :bankTransactionCode, :bookingDate, :endToEndId,
                     :entryReference, :remittanceInformationUnstructured, :remittanceInformationUnstructuredArray,
                     :transactionAmount, :transactionId, :valueDate

      def initialize(nordigen_transaction)
        @nordigen_transaction = nordigen_transaction
      end

      def name
        if remittanceInformationUnstructuredArray&.any?
          remittanceInformationUnstructuredArray.first
        else
          remittanceInformationUnstructured
        end
      end

      def memo
        remittanceInformationUnstructuredArray&.join(', ')
      end

      def balance
        transactionAmount.amount.to_f
      end

      def transaction_number
        transactionId.to_s + entryReference.to_s
      end

      def transfered_on
        Date.parse(valueDate || bookingDate)
      end

      def initiated_on
        Date.parse(bookingDate)
      end
    end
  end
end
