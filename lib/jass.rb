require 'forwardable'
require 'pathname'

require 'sprockets'
require 'schmooze'

module Jass
  class << self
    attr_accessor :vendor_modules_root
    
    def modules_root
      File.join(File.dirname(__FILE__), '..', 'vendor')
    end
  end

#  def self.modules_root
#    File.join(File.dirname(__FILE__), '..')
#  end
end

require 'jass/version'
require 'jass/compiler'
require 'jass/es6_processor'
require 'jass/bundle_processor'

require 'jass/railtie' if defined?(Rails)

#require 'jass/vue_script'
#require 'jass/vue_template'
#require 'jass/vue_style'


if Sprockets.respond_to?(:register_transformer)
  Sprockets.register_mime_type 'text/ecmascript-6', extensions: ['.es6'], charset: :unicode
  Sprockets.register_transformer 'text/ecmascript-6', 'application/javascript', Jass::ES6Processor
end

if Sprockets.respond_to?(:register_engine)
  args = ['.es6', Jass::ES6Processor]
  args << { mime_type: 'text/ecmascript-6', silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
  Sprockets.register_engine(*args)
  
  args = ['.jass', Jass::BundleProcessor]
  args << { mime_type: 'text/ecmascript-6', silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
  Sprockets.register_engine(*args)
end
