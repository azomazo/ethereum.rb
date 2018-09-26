require 'tmpdir'
require 'open3'
require 'json'

module Ethereum
  class CompilationError < StandardError;
    def initialize(msg)
      super
    end
  end

  class Solidity

    def initialize(bin_path = "solc")
      @bin_path = bin_path
    end

    def compile(filename, libraries = {}, allow_paths = [])
      result = {}
      string_result = execute_solc(filename, libraries, allow_paths)
      json_result = JSON.parse(string_result)
      json_result['contracts'].each do |key, desc|
        _file, name = key.split(':')
        result[name] = {}
        result[name]["abi"] = desc['abi'].is_a?(String) ? JSON.parse(desc['abi']) : desc['abi']
        result[name]["bin"] = desc['bin']
        result[name]["bin-runtime"] = desc['bin-runtime']
        result[name]["srcmap-runtime"] = desc['srcmap-runtime']
      end
      result
    end

    class << self
      def option_srcmap_runtime
        @option_srcmap_runtime ||= false
      end

      def option_srcmap_runtime=(value)
        @option_srcmap_runtime = value
      end

      def option_bin_runtime
        @option_bin_runtime ||= false
      end

      def option_bin_runtime=(value)
        @option_bin_runtime = value
      end
    end

    [:option_srcmap_runtime, :option_bin_runtime].each do |m|
      define_method m do
        self.class.public_send(m)
      end
    end

    def compile_arguments
      combine_json = %w(bin abi)
      combine_json << 'srcmap-runtime' if option_srcmap_runtime
      combine_json << 'bin-runtime' if option_bin_runtime

      "--optimize --combined-json #{combine_json.join(',')}"
    end

    private
      def execute_solc(filename, libraries = {}, allow_paths = [])
        cmd = "#{@bin_path} #{compile_arguments} #{generate_libraries_args(libraries)} #{generate_allow_paths(allow_paths)} '#{filename}'"
        out, stderr, status = Open3.capture3(cmd)
        raise SystemCallError, "Unanable to run solc compliers" if status.exitstatus == 127
        raise CompilationError, stderr unless status.exitstatus == 0
        out
      end


      def generate_libraries_args(libraries = {})
        return '' if libraries.empty?
        result = []
        formatter = Formatter.new
        libraries.each do |name, address|
          result << "#{name}:#{formatter.to_address(address)}"
        end
        "--libraries #{result.join(',')}"
      end
      
      def generate_allow_paths(allow_paths = [])
        return '' if allow_paths.empty?

        "--allow-paths #{allow_paths.join(',')}"
      end
  end
end
