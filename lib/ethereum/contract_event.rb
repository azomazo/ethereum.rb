module Ethereum
  class ContractEvent

    attr_accessor :name, :signature, :input_types, :inputs, :event_string, :address, :client

    def initialize(data)
      @name = data["name"]
      @input_types = data["inputs"].collect {|x| x["type"]}
      @inputs = data["inputs"].collect {|x| x["name"]}
      @event_string = "#{@name}(#{@input_types.join(",")})"
      @signature = Digest::SHA3.hexdigest(@event_string, 256)

      @inputs_desc = data["inputs"].map{|h| OpenStruct.new(h)}
    end

    def inputs_desc
      @inputs_desc
    end

    def inputs_indexed
      @inputs_indexed ||= @inputs_desc.select(&:indexed)
    end

    def inputs_not_indexed
      @inputs_not_indexed ||= @inputs_desc.reject(&:indexed)
    end

    def log_entry_correct?(event_log)
      event_log['topics'].first.gsub(/^0x/, '') == signature
    end

    def parse_event_log(event_log)
      return {} unless log_entry_correct?(event_log)

      decoder = Ethereum::Decoder.new

      result = Hash[inputs_desc.map{|i| [i.name, nil]}]

      inputs_indexed.each_with_index do |i, index|
        args = decoder.decode_arguments([i], event_log['topics'][index + 1])
        result[i.name] = args.first
      end

      decoder.decode_arguments(inputs_not_indexed, event_log['data']).each_with_index do |v, index|
        result[inputs_not_indexed[index].name] = v
      end

      result.map do |k, v|
        r = { name: k,
              value: v,
              type: inputs_desc.find{|i| i.name == k}.type }
        r[:value] = format_input_event_value(v, r[:type])
        r
      end
    end

    def set_address(address)
      @address = address
    end

    def set_client(client)
      @client = client
    end

    private
    def format_input_event_value(value, type)
      if type == 'address'
        Ethereum::Encoder.new.ensure_prefix(value).downcase
      else
        value
      end
    end

  end
end

