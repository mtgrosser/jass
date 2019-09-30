module Jass
  class BundleProcessor
    
    class << self
      def instance
        @instance ||= new
      end
      
      def call(input)
        instance.call(input)
      end
    end
    
    def call(input)
      env, filename = input.fetch(:environment), input.fetch(:filename)
      dependencies = Set.new(input.fetch(:metadata).fetch(:dependencies))
      globals = input.fetch(:metadata).fetch(:globals, {})
      bundle_root = Pathname.new(filename).dirname
      bundle = Jass.compiler.bundle(filename, Jass.input_options, globals: globals)
      dependencies += bundle.fetch('map').fetch('sources').map { |dep| Sprockets::URIUtils.build_file_digest_uri(bundle_root.join(dep).to_s) }
      
      { data: bundle.fetch('code'),
        dependencies: dependencies,
        map: bundle.fetch('map') }
    end
    
  end
end
