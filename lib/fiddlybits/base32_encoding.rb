module Fiddlybits
  class Base32Encoding < Encoding

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
      enc = Base32.encode(data)
      if @alphabet
        enc = enc.tr(Base32::TABLE, @alphabet)
      end
      enc
    end

    # Decodes text to binary.
    #
    # @param data [String] the encoded data to decode.
    # @return [String] the decoded data.
    def decode(data)
      if @alphabet
        data = data.tr(@alphabet, Base32::TABLE)
      end
      begin
        Base32.decode(data)
      rescue => e   # unfortunately this library throws random errors for invalid data
        raise InvalidEncoding
      end
    end

    NORMAL = new(
      'base32',
      'Base32',
      nil
      )

    WITH_HEX_ALPHABET = new(
      'base32hex',
      'Base32 with Hex Alphabet',
      '0123456789ABCDEFGHIJKLMNOPQRSTUV'
      )
  end
end
