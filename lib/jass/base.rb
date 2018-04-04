module Jass
  class Base
    
    class_attribute :dependencies
    self.dependencies = []
    
    class_attribute :functions
    self.functions = []
    
    class_attribute :plugins
    self.plugins = []
    
    class << self
      def dependency(deps)
        self.dependencies = dependencies + deps.map { |name, package| Dependency.new(name, package) }
      end

      def function(name, code)
        self.functions = functions + [Function.new(name, code)]
        define_method(name) { |*args| call_js_method(name, args) }
      end

      def generate_code
        %{
          function __handle_error__(error) {
            var errInfo = {};
            if (error instanceof Error) {
              errInfo.name = error.name;
              Object.getOwnPropertyNames(error).reduce((obj, prop) => { obj[prop] = error[prop]; return obj }, errInfo);
              // process.stdout.write(JSON.stringify(['err', error.toString().replace(new RegExp('^' + error.name + ': '), ''), error.name]));
            } else {
              errInfo.name = error.toString();
            }
            process.stdout.write(JSON.stringify(['err', errInfo]));
            process.stdout.write("\\n");
          }

          try {
            #{dependencies.map(&:to_js).join}
          } catch (e) {
            __handle_error__(e);
            process.exit(1);
          }
        
          var __plugins__ = [];
          #{plugins.map(&:to_js).join}
        
          process.stdout.write("[\\"ok\\"]\\n");
        
          var __methods__ = {};
          #{functions.map(&:to_js).join}
        
          require('readline').createInterface({
            input: process.stdin,
            terminal: false,
          }).on('line', function(line) {
            var input = JSON.parse(line);
            try {
              Promise.resolve(__methods__[input[0]].apply(null, input[1])
              ).then(function (result) {
                process.stdout.write(JSON.stringify(['ok', result]));
                process.stdout.write("\\n");
              }).catch(__handle_error__);
            } catch(error) {
              __handle_error__(error);
            }
          });
        }
      end

      protected

      def finalize(stdin, stdout, stderr, process_thread)
        proc do
          stdin.close
          stdout.close
          stderr.close
          Process.kill(0, process_thread.pid)
          process_thread.value
        end
      end
    end

    def initialize(root, env = {})
      @node_root = root
      @node_env = env
    end

    def pid
      @node_process_thread && @node_process_thread.pid
    end

    private
    
    def ensure_process_is_spawned
      return if @node_process_thread
      spawn_process
    end

    def spawn_process
      process_data = Open3.popen3(@node_env, 'node', '-e', self.class.generate_code, chdir: @node_root)
      ensure_packages_are_initiated(*process_data)
      ObjectSpace.define_finalizer(self, self.class.send(:finalize, *process_data))
      @node_stdin, @node_stdout, @node_stderr, @node_process_thread = process_data
    end

    def ensure_packages_are_initiated(stdin, stdout, stderr, process_thread)
      input = stdout.gets
      raise Jass::Error, "Failed to instantiate Node process:\n#{stderr.read}" if input.nil?
      result = JSON.parse(input)
      unless result[0] == 'ok'
        stdin.close
        stdout.close
        stderr.close
        process_thread.join

        error = result[1]
        if error.is_a?(Hash)
          raise Jass::DependencyError.new(error)
        elsif error.is_a?(String)
          raise Jass::Error, error
        end
      end
    end
    
    def call_js_method(method, args)
      ensure_process_is_spawned

      @node_stdin.puts JSON.dump([method, args])
      input = @node_stdout.gets
      raise Errno::EPIPE, "Can't read from stdout" if input.nil?
      status, result = JSON.parse(input)
      return result if status == 'ok'
      raise Jass::JavaScriptError.new(result)
    rescue Errno::EPIPE, IOError
      # TODO(bouk): restart or something? If this happens the process is completely broken
      raise Jass::Error, "Node process failed:\n#{@node_stderr.read}"
    end
    
  end
end
