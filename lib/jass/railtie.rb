require 'rails/railtie'
require 'active_support'

module Jass
  class Railtie < Rails::Railtie
    config.jass = ActiveSupport::OrderedOptions.new

    initializer 'jass' do |app|
      Jass.vendor_modules_root = Rails.root.join('vendor')
    end
  end
end
