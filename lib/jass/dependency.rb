module Jass
  class Dependency
    attr_reader :name, :package
    
    def initialize(name, package)
      @name, @package = name, package
    end
  
    def to_js
      "var #{name} = require(#{package.to_json});\n"
    end
   
  end
end
