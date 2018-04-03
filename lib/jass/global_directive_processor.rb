module Jass
  class GlobalDirectiveProcessor < Sprockets::DirectiveProcessor
    def process_global_directive(package, variable)
      @globals[package] = variable
    end
    
    def _call(input)
      @globals = (input[:metadata][:globals] ||= {})
      super
    end
  end
end
