module Jass
  class Compiler < Base
    dependency buble: 'buble',
               NodentCompiler: 'nodent-compiler',
               rollup: 'rollup',
               nodeResolve: 'rollup-plugin-node-resolve',
               commonjs: 'rollup-plugin-commonjs'

    function :init, <<~JS
      function () {
        global.nodent_compiler = new NodentCompiler;
        global.send = function() {
          var args = [...arguments];
          var method = args.shift();
          return __methods__[method].apply(null, args);
        }
      }
    JS
    
    function :nodent, <<~JS
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

    function :buble, <<~JS
      function(src) {
        return buble.transform(src,
          { transforms: { dangerousForOf: true },
            objectAssign: 'Object.assign' }).code;
      }
    JS
    
    # Compile ES6 without imports: buble(nodent(src))
    function :compile, <<~JS
      function(src, filename) {
        return send('buble', send('nodent', src, filename));
      }
    JS

    # Build bundle with imports: buble(rollup(nodent(src)))
    function :js_bundle, <<~JS
      function(entry, moduleDirectories, inputOptions, outputOptions) {
        inputOptions = inputOptions || {};
        outputOptions = outputOptions || {}
        // TODO: throw error unless moduleDirectories
        Object.assign(inputOptions,
          { input: entry,
            treeshake: false,
            plugins: [
              ...__plugins__,
              nodeResolve({ customResolveOptions: { moduleDirectory: moduleDirectories }}),
              commonjs()
            ]
          }
        );
        Object.assign(outputOptions,
          { format: 'iife',
            sourcemap: true,
            exports: 'none'
          }
        );
        var promise = rollup.rollup(inputOptions)
            .then(bundle => bundle.generate(outputOptions))
            .then(bundle => { return { code: send('compile', bundle.code), map: bundle.map }; });
        return promise;
      }
    JS
    
    def bundle(entry, input_options = {}, output_options = {})
      js_bundle(entry, self.class.node_paths, input_options, output_options)
    end
    
    # Get vendor library versions
    function :versions, <<~JS
      function() {
        return {  buble: buble.VERSION,
                  rollup: rollup.VERSION,
                  nodent: global.nodent_compiler.version };
      }
    JS

    class << self
      def prepend_plugin(package, name, arguments = nil, root = nil)
        plugins.unshift(Plugin.new(name, arguments, root))
        dependency name => package
      end
      
      def node_paths
        ([Jass.modules_root, Jass.vendor_modules_root] + plugins.map(&:root)).compact.map { |p| File.absolute_path(File.join(p, 'node_modules')) }
      end
      
      def node_path
        node_paths.join(':')
      end
    end
    
    def initialize
      super(Jass.modules_root, 'NODE_PATH' => self.class.node_path)
      init
    end
    
  end
end
