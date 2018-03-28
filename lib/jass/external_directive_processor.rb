module Jass
  class ExternalDirectiveProcessor < Sprockets::DirectiveProcessor
    def process_external_directive(external_dependency)
      @externals << external_dependency
    end
    
    def _call(input)
      @externals = (input[:metadata][:externals] ||= Set.new)
      super
    end
  end
end
