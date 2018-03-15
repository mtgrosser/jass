module Jass
  class Compiler < Schmooze::Base
    dependencies buble: 'buble',
                 NodentCompiler: 'nodent-compiler',
                 rollup: 'rollup'

    method :init, <<~JS
      function () {
        global.nodent_compiler = new NodentCompiler;
        global.send = function() {
          var args = [...arguments];
          var method = args.shift();
          return __methods__[method].apply(null, args);
        }
      }
    JS
    
    method :nodent, <<~JS
      function(src, filename) {
        return global.nodent_compiler.compile(src, filename,
          { sourcemap: false,
            promises: true,
            noRuntime: true }).code;
      }
    JS

    method :buble, <<~JS
      function(src) { return buble.transform(src).code; }
    JS
    
    # Compile ES6 without imports: buble(nodent(src))
    method :compile, <<~JS
      function(src, filename) {
        return send('buble', send('nodent', src, filename));
      }
    JS

    # Build bundle with imports: buble(rollup(nodent(src)))
    method :bundle, <<~JS
      function(entry, options) {
        options = options || {};
        Object.assign(options, { input: entry, treeshake: false });
        var promise = rollup.rollup(options)
            .then(bundle => bundle.generate({ format: 'es', sourcemap: true }))
            .then(bundle => { return { code: send('compile', bundle.code), map: bundle.map }; });
        return promise;
      }
    JS
    
    # Get vendor library versions
    method :versions, <<~JS
      function() {
        return {  buble: buble.VERSION,
                  rollup: rollup.VERSION,
                  nodent: global.nodent_compiler.version };
      }
    JS

    class << self
      extend Forwardable

      private :new
      
      def instance
        @instance ||= new
      end
      
      def_delegators :instance, :buble, :nodent, :compile, :bundle, :versions
    end
    
    def initialize
      super(Jass.modules_root)
      init
    end
  end
end
