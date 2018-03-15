module Jass
  class ES6Processor
    class << self
      def instance
        @instance ||= new
      end
      
      def call(input)
        instance.call(input)
      end
    end
    
    def call(input)
      { data: Compiler.compile(input[:data]) }
    end
  end
end
