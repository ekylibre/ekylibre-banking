module EkylibreBanking
  class Engine < ::Rails::Engine
    initializer 'ekylibre_banking.assets.precompile' do |app|
      app.config.assets.precompile += %w[banking.js integrations/banking.png]
    end

    initializer :ekylibre_banking_i18n do |app|
      app.config.i18n.load_path += Dir[EkylibreBanking::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :ekylibre_banking_import_javascript do
      tmp_file = Rails.root.join('tmp', 'plugins', 'javascript-addons', 'plugins.js.coffee')
      tmp_file.open('a') do |f|
        import = '#= require banking'
        f.puts(import) unless tmp_file.open('r').read.include?(import)
      end
    end

  end
end
