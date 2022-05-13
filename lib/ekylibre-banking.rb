require 'ekylibre-banking/engine'
require 'ekylibre-banking/ext_navigation'

module EkylibreBanking
  def self.root
    Pathname.new(File.dirname(__dir__))
  end
end
