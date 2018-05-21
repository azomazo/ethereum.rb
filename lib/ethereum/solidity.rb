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

    def compile(filename, libraries = {})
      result = {}
      execute_solc(filename, libraries).scan(OUTPUT_REGEXP).each do |match|
        _file, name, bin, abi = match
        result[name] = {}
        result[name]["abi"] = abi
        result[name]["bin"] = bin
      end
      result
    end

    private
      def execute_solc(filename, libraries = {})
        cmd = "#{@bin_path} #{@args} #{generate_libraries_args(libraries)} '#{filename}'"
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
  end
end
