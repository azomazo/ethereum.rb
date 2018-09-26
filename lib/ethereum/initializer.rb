module Ethereum

  class Initializer
    attr_accessor :contracts, :file, :client

    def initialize(file, client = Ethereum::Singleton.instance, libraries = {}, allow_paths = [])
      @client = client
      sol_output = Solidity.new.compile(file, libraries, allow_paths)
      contracts = sol_output.keys

      @contracts = []
      contracts.each do |contract|
        abi = sol_output[contract]["abi"]
        name = contract
        code = sol_output[contract]["bin"]
        c = Contract.new(name, code, abi, @client)
        c.srcmap_runtime = sol_output[contract]["srcmap-runtime"]
        @contracts << c
      end
    end

    def build_all
      @contracts.each do |contract|
        contract.build
      end
    end

  end
end
