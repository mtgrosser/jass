module Jass
  class Base
    class << self

      def generate(imports, methods)
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
            #{imports.map { |import| generate_import(import) }.join}
          } catch (e) {
            __handle_error__(e);
            process.exit(1);
          }
          
          process.stdout.write("[\\"ok\\"]\\n");
          var __methods__ = {};
          #{methods.map{ |method| generate_method(method[:name], method[:code]) }.join}
          
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

      def generate_method(name, code)
        "__methods__[#{name.to_json}] = (#{code});\n"
      end

      def generate_import(import)
        if import[:package].start_with?('.') # if it local script else package
          _, _, package, mid, path = import[:package].partition('.')
          package = '.' + package
        else
          package, mid, path = import[:package].partition('.')
        end
        "  var #{import[:identifier]} = require(#{package.to_json})#{mid}#{path};\n"
      end
      
      protected
      
      def dependencies(deps)
        @_schmooze_imports ||= []
        @_schmooze_imports.concat(deps.map { |identifier, package| { identifier: identifier, package: package } })
      end

      def method(name, code)
        @_schmooze_methods ||= []
        @_schmooze_methods << { name: name, code: code }

        define_method(name) do |*args|
          call_js_method(name, args)
        end
      end

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
      @_schmooze_env = env
      @_schmooze_root = root
      @_schmooze_code = self.class.generate(self.class.instance_variable_get(:@_schmooze_imports) || [], self.class.instance_variable_get(:@_schmooze_methods) || [])
    end

    def pid
      @_schmooze_process_thread && @_schmooze_process_thread.pid
    end

    private
    
    def ensure_process_is_spawned
      return if @_schmooze_process_thread
      spawn_process
    end

    def spawn_process
      process_data = Open3.popen3(@_schmooze_env, 'node', '-e', @_schmooze_code, chdir: @_schmooze_root)
      ensure_packages_are_initiated(*process_data)
      ObjectSpace.define_finalizer(self, self.class.send(:finalize, *process_data))
      @_schmooze_stdin, @_schmooze_stdout, @_schmooze_stderr, @_schmooze_process_thread = process_data
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

        error_message = result[1]
        if /\AError: Cannot find module '(.*)'\z/ =~ error_message
          package_name = $1
          package_json_path = File.join(@_schmooze_root, 'package.json')
          begin
            package = JSON.parse(File.read(package_json_path))
            %w(dependencies devDependencies).each do |key|
              if package.has_key?(key) && package[key].has_key?(package_name)
                raise Jass::DependencyError, "Cannot find module '#{package_name}'. The module was found in '#{package_json_path}' however, please run 'npm install' from '#{@_schmooze_root}'"
              end
            end
          rescue Errno::ENOENT
          end
          raise Jass::DependencyError, "Cannot find module '#{package_name}'. You need to add it to '#{package_json_path}' and run 'npm install'"
        else
          raise Jass::Error, error_message
        end
      end
    end

    def call_js_method(method, args)
      ensure_process_is_spawned

      @_schmooze_stdin.puts JSON.dump([method, args])
      input = @_schmooze_stdout.gets
      raise Errno::EPIPE, "Can't read from stdout" if input.nil?
      STDERR.puts input
      status, result = JSON.parse(input)
      return result if status == 'ok'
      raise Jass::JavaScriptError.new(result)
    rescue Errno::EPIPE, IOError
      # TODO(bouk): restart or something? If this happens the process is completely broken
      raise Jass::Error, "Node process failed:\n#{@_schmooze_stderr.read}"
    end
    
  end
end
