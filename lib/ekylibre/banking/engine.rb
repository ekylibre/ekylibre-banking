module Ekylibre
  module Banking
    class Engine < ::Rails::Engine
      initializer 'ekylibre-banking.i18n' do |app|
        app.config.i18n.load_path += Dir[Ekylibre::Banking::Engine.root.join('config', 'locales', '**', '*.yml')]
      end

      initializer 'ekylibre-banking.extend_navigation' do |_app|
        Ekylibre::Banking::ExtNavigation.add_navigation_xml_to_existing_tree
      end

      initializer 'ekylibre-banking.extend_toolbar' do |_app|
        Ekylibre::View::Addon.add(:main_toolbar, 'backend/cashes/sync_bank_account_toolbar', to: 'backend/cashes#show')
      end

      initializer 'ekylibre-banking.import_javascript' do
        tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
        tmp_file.open('a') do |f|
          import = '#= require banking/all'
          f.puts(import) unless tmp_file.open('r').read.include?(import)
        end
      end

      initializer 'ekylibre-banking.import_stylesheets' do
        tmp_file = Rails.root.join('tmp', 'plugins', 'theme-addons', 'themes', 'tekyla', 'plugins.scss')
        tmp_file.open('a') do |f|
          import = '@import "banking/all.scss";'
          f.puts(import) unless tmp_file.open('r').read.include?(import)
        end
      end

    end
  end
end
