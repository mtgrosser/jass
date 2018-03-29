module Jass
  class Compiler < Base
    dependencies buble: 'buble',
                 NodentCompiler: 'nodent-compiler',
                 rollup: 'rollup',
                 nodeResolve: 'rollup-plugin-node-resolve',
                 commonjs: 'rollup-plugin-commonjs',
                 vue2: 'rollup-plugin-vue2'

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
          { es6target: true,
            sourcemap: false,
            parser: {
              sourceType: 'script',
              ecmaVersion: 9
            },
            promises: true,
            noRuntime: true }).code;
      }
    JS

    method :buble, <<~JS
      function(src) {
        return buble.transform(src,
          { transforms: { dangerousForOf: true },
            objectAssign: 'Object.assign' }).code;
      }
    JS
    
    # Compile ES6 without imports: buble(nodent(src))
    method :compile, <<~JS
      function(src, filename) {
        return send('buble', send('nodent', src, filename));
      }
    JS

    # Build bundle with imports: buble(rollup(nodent(src)))
    method :js_bundle, <<~JS
      function(entry, moduleDirectories, options) {
        options = options || {};
        // TODO: throw error unless moduleDirectories
        Object.assign(options,
          { input: entry,
            treeshake: false,
            plugins: [
              vue2({ include: /\.vue$/ }), 
              nodeResolve({ customResolveOptions: { moduleDirectory: moduleDirectories }}),
              commonjs()
            ]
          }
        );
        var promise = rollup.rollup(options)
            .then(bundle => bundle.generate({ format: 'iife', sourcemap: true }))
            .then(bundle => { return { code: send('compile', bundle.code), map: bundle.map }; });
        return promise;
      }
    JS
    
    def bundle(entry, options = {})
      js_bundle(entry, self.class.node_paths, options)
    end
    
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
      
      def node_paths
        [Jass.modules_root, Jass.vendor_modules_root].compact.map { |p| File.absolute_path(File.join(p, 'node_modules')) }
      end
      
      def node_path
        node_paths.join(':')
      end
    end
    
    def initialize
      super(Jass.modules_root)
      init
    end
    
  end
end
