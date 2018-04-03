require 'set'
require 'forwardable'
require 'pathname'

require 'sprockets'

module Jass
  class << self
    attr_accessor :vendor_modules_root
    
    def modules_root
      File.join(File.dirname(__FILE__), '..', 'vendor')
    end
  end
end

require 'jass/version'
require 'jass/errors'
require 'jass/base'
require 'jass/compiler'
require 'jass/global_directive_processor'
require 'jass/es6_processor'
require 'jass/bundle_processor'

require 'jass/railtie' if defined?(Rails)

if Sprockets.respond_to?(:register_transformer)
  Sprockets.register_mime_type 'text/ecmascript-6', extensions: %w[.jass], charset: :unicode
  Sprockets.register_transformer 'text/ecmascript-6', 'application/javascript', Jass::BundleProcessor
end

if Sprockets.respond_to?(:register_engine)
#  args = ['.es6', Jass::ES6Processor]
#  args << { mime_type: 'text/ecmascript-6', silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
#  Sprockets.register_engine(*args)
  
  args = ['.jass', Jass::BundleProcessor]
  args << { mime_type: 'text/ecmascript-6', silence_deprecation: true } if Sprockets::VERSION.start_with?("3")
  Sprockets.register_engine(*args)
end

Sprockets.register_preprocessor 'text/ecmascript-6', Jass::GlobalDirectiveProcessor
