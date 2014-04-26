module Fiddlybits
  using DeepFreeze

  class AsciiCharset < Charset
    def initialize
      super('US-ASCII')
    end

    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      decode_result = DecodeResult.new
      bytes.each do |b|
        if b < 0x80
          decode_result << DecodedData.new([b], [b].pack('U'), 'cast')
        else
          decode_result << RemainingData.new([b])
        end
      end
      decode_result.deep_freeze
    end

    def min_bytes_per_char; 1; end
    def max_bytes_per_char; 1; end

    US_ASCII = AsciiCharset.new
  end
end
