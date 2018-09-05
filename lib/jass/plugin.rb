module Jass
  class Plugin
    attr_reader :name, :arguments, :root
    
    def initialize(name, arguments = nil, root = nil)
      @name, @arguments, @root = name, arguments, root
    end
    
    def to_js
      args = arguments.respond_to?(:call) ? arguments.call : arguments
      "__plugins__.push(#{name}(#{args}));\n"
    end
  end
end
