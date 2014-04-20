module Fiddlybits
  class AsciiCharset < Charset
    def initialize
      super('US-ASCII')
    end

    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      bytes.map do |b|
        if b < 0x80
          DecodedData.new([b], [b].pack('U'), 'cast')
        else
          RemainingData.new([b])
        end
      end
    end

    def min_bytes_per_char; 1; end
    def max_bytes_per_char; 1; end
  end
end
