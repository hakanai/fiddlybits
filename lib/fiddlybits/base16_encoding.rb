module Fiddlybits
  class Base16Encoding < Encoding
    NORMAL_ALPHABET = '0123456789ABCDEF'.freeze

    # @param name [String] the short name of the encoding (used like a unique ID.)
    # @param human_name [String] the name of the encoding for people to read.
    # @param alphabet [String] the alphabet to use if not the default one.
    def initialize(name, human_name, alphabet)
      super(name, human_name)
      @alphabet = alphabet
    end

    # Encodes binary to text.
    #
    # @param data [String] the data to encode.
    # @return the encoded data.
    def encode(data)
      enc = data.unpack('H*')[0].upcase
      if @alphabet
        enc = enc.tr(NORMAL_ALPHABET, @alphabet)
      end
      enc
    end

    # Decodes text to binary.
    #
    # @param data [String] the encoded data to decode.
    # @return [String] the decoded data.
    def decode(data)
      data = data.gsub(/\s+/, '')
      if @alphabet
        data = data.tr(@alphabet, NORMAL_ALPHABET)
      end
      raise InvalidEncoding if data !~ /^([0-9A-F]{2})*$/
      [data].pack('H*')
    end

    NORMAL = new(
      'base16',
      'Base16',
      nil
      )
  end
end
