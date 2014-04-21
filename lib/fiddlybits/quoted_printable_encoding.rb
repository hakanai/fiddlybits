module Fiddlybits
  class QuotedPrintableEncoding < Encoding

    # Encodes binary to text.
    #
    # @param data [String] the data to encode.
    # @return the encoded data.
    def encode(data)
      [data].pack('M')
    end

    # Decodes text to binary.
    #
    # @param data [String] the encoded data to decode.
    # @return [String] the decoded data.
    def decode(data)
      data.unpack('M')[0]
    end

    NORMAL = new('quoted-printable', 'quoted-printable')
  end
end

