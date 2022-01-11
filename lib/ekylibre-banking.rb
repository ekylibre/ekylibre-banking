require 'ekylibre-banking/engine'

module EkylibreBanking
  def self.root
    Pathname.new(File.dirname(__dir__))
  end
end
