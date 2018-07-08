require 'tmpdir'
require 'open3'

module Ethereum
  class CompilationError < StandardError;
    def initialize(msg)
      super
    end
  end

  class Solidity

    OUTPUT_REGEXP = /======= (\S*):(\S*) =======\s*Binary:\s*(\S*)\s*Contract JSON ABI\s*(\S*)/

    def initialize(bin_path = "solc")
      @bin_path = bin_path
      @args = "--bin --abi --optimize"
    end

    def compile(filename, allow_paths = [])
      result = {}
      execute_solc(filename).scan(OUTPUT_REGEXP).each do |match|
        _file, name, bin, abi = match
        result[name] = {}
        result[name]["abi"] = abi
        result[name]["bin"] = bin
      end
      result
    end

    private
      def execute_solc(filename, allow_paths = [])
        cmd = "#{@bin_path} #{@args} #{generate_allow_paths(allow_paths)}'#{filename}'"
        out, stderr, status = Open3.capture3(cmd)
        raise SystemCallError, "Unanable to run solc compliers" if status.exitstatus == 127
        raise CompilationError, stderr unless status.exitstatus == 0
        out
      end

      def generate_allow_paths(allow_paths = [])
        return '' if allow_paths.empty?

        "--allow-paths #{allow_paths.join(',')}"
      end
  end
end
