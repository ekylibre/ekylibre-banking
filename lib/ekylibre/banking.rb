require_relative 'banking/engine'
require_relative 'banking/ext_navigation'

module Ekylibre
  module Banking
    def self.root
      Engine.root
    end
  end
end