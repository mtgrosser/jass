module Jass
  class Plugin
    attr_reader :name, :arguments, :root
    
    def initialize(name, arguments = nil, root = nil)
      @name, @arguments, @root = name, arguments, root
    end
    
    def to_js
      "__plugins__.push(#{name}(#{arguments}));\n"
    end
  end
end
