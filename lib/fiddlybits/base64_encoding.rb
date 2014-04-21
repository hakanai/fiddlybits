module Fiddlybits
  class Base64Encoding < Encoding
    NORMAL_ALPHABET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'.freeze

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
      enc = [data].pack('m0')
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
      if @alphabet
        data = data.tr(@alphabet, NORMAL_ALPHABET)
      end
      begin
        data.unpack('m0').first
      rescue ArgumentError => e
        raise InvalidEncoding
      end
    end

    NORMAL = new(
      'base64',
      'Base64',
      nil
      )

    URL_SAFE = new(
      'base64url',
      'Base64 with URL-safe Alphabet',
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'
      )
  end
end
