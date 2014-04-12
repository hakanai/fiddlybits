module Fiddlybits
  class Iso2022Charset < Charset
    def initialize(name)
      super(name)
    end

    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      decoded_fragments = []
      next_charset = Charset::US_ASCII
      while esc = bytes.find_index(0x1b)
        decoded_fragments += next_charset.decode(bytes[0...esc])
        bytes = bytes[esc..-1]

        # Decode the escape sequence to determine the next charset.
        # This is obviously not very pluggable but we'll fix that later.
        # What we should have is a hash from escape sequence to charset.
        case bytes[1]
        when '('.ord
          case bytes[2]
          when 'B'.ord
            decoded_fragments << EscapeSequence.new(bytes[0..2], 'ESC ( B', 'switch to ASCII')
            next_charset = Charset::US_ASCII
            bytes = bytes[3..-1]
          when 'J'.ord
            decoded_fragments << EscapeSequence.new(bytes[0..2], 'ESC ( J', 'switch to JIS X 0201-1976')
            next_charset = Charset::JISX0201_1976
            bytes = bytes[3..-1]
          else
            decoded_fragments << RemainingData.new(bytes)
            bytes.clear
          end
        when '$'.ord
          case bytes[2]
          when '$'.ord
            decoded_fragments << EscapeSequence.new(bytes[0..2], 'ESC $ @', 'switch to JIS X 0208-1978')
            next_charset = Charset::JISX0208_1978_0
            bytes = bytes[3..-1]
          when 'B'.ord
            decoded_fragments << EscapeSequence.new(bytes[0..2], 'ESC $ B', 'switch to JIS X 0208-1983')
            next_charset = Charset::JISX0208_1983_0
            bytes = bytes[3..-1]
          else
            decoded_fragments << RemainingData.new(bytes)
            bytes.clear
          end
        else
          decoded_fragments << RemainingData.new(bytes)
          bytes.clear
        end
      end
      decoded_fragments += next_charset.decode(bytes)
      decoded_fragments
    end
  end
end
