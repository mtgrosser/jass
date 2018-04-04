module Jass
  class Function
    attr_reader :name, :code
    
    def initialize(name, code)
      @name, @code = name, code
    end
    
    def to_js
      "__methods__[#{name.to_json}] = (#{code});\n"
    end
  end
end
