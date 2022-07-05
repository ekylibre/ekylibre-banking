require 'ekylibre-banking/engine'
require 'ekylibre-banking/ext_navigation'
require 'nordigen-ruby'
require 'nordigen/requisition'
require 'nordigen/transaction'

module EkylibreBanking
  def self.root
    Pathname.new(File.dirname(__dir__))
  end
end
