module Fiddlybits
  class Ascii85Encoding < Encoding

    # Encodes binary to text.
    #
    # @param data [String] the data to encode.
    # @return the encoded data.
    def encode(data)
      Ascii85.encode(data)
    end

    # Decodes text to binary.
    #
    # @param data [String] the encoded data to decode.
    # @return [String] the decoded data.
    def decode(data)
      Ascii85.decode(data)
    rescue Ascii85::DecodingError => e
      raise InvalidEncoding
    end

    NORMAL = new('ascii85', 'Ascii85')
  end
end
