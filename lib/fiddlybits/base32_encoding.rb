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

    # http://philzimmermann.com/docs/human-oriented-base-32-encoding.txt
    ZIMMERMANN = new(
      'z-base-32',
      'Base32 (z-base-32)',
      'ybndrfg8ejkmcpqxot1uwisza345h769'
      )

    CROCKFORD = new(
      'base32crockford',
      'Base32 (Crockford variant)',
      '0123456789ABCDEFGHJKMNPQRSTVWXYZ'
      )

    #TODO An earlier form of base 32 notation was used by programmers working on the Electrologica X1 to represent machine addresses. The "digits" were represented as decimal numbers from 0 to 31. For example, 12-16 would represent the machine address 400 (= 12*32 + 16).

    WITH_HEX_ALPHABET = new(
      'base32hex',
      'Base32 (with extended hex alphabet)',
      '0123456789ABCDEFGHIJKLMNOPQRSTUV'
      )

    # TODO: The order on this is wrong.
   # ALT_1 = new(
   #   'base32alt1',
   #   'Base32 (without 0, 1, L, O)',
   #   '23456789ABCDEFGHIJKMNPQRSTUVWXYZ'
   #   )

  end
end
