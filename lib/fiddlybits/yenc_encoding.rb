module Fiddlybits
  class YencEncoding < Encoding

    # Encodes binary to text.
    #
    # @param data [String] the data to encode.
    # @return the encoded data.
    def encode(data)
      [data].pack('u')
    end

    # Decodes text to binary.
    #
    # @param data [String] the encoded data to decode.
    # @return [String] the decoded data.
    def decode(data)
      data.unpack('u')[0]
    end

    NORMAL = new('uuencode', 'uuencode')
  end
end
