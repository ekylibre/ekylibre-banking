module Nordigen
  module ApiRefinements
    refine Nordigen::RequisitionsApi do

      def create_requisition(redirect_url:, reference:, institution_id:, user_language: 'en', agreement: nil)
        Requisition.new(super)
      end

      def get_requisitions(limit: 100, offset: 0)
        Requisition.new(super)
      end

      def get_requisition_by_id(requisition_id)
        Requisition.new(super)
      end

      def delete_requisition(requisition_id)
        Requisition.new(super)
      end
    end
  end
end
