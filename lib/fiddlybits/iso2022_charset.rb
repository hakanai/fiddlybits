module Fiddlybits
  class Iso2022Charset < Charset
    # Escapes contain a hash of escape sequence to Charset.
    # Every escape sequence should include the \e (ESC) character at the start.
    # TODO: General implementation of ISO-2022-JP also requires single-character escapes.
    def initialize(name, escapes)
      super(name)
      @escapes = {}
      # Convert keys to bytes in advance because we're doing all operations on lists of bytes.
      escapes.each_pair do |escape, charset|
        @escapes[escape.bytes] = charset
      end
    end

    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      decoded_fragments = []
      next_charset = Charset::US_ASCII
      while esc = bytes.find_index(0x1b)
        decoded_fragments += next_charset.decode(bytes[0...esc])
        bytes = bytes[esc..-1]

        # Decode the escape sequence to determine the next charset.
        # There is probably a more elegant way to go about this but we know all escape sequences are
        # either 3 or 4 bytes.
        escape_sequence = bytes[0..2]
        charset = @escapes[escape_sequence]
        if !charset
          escape_sequence = bytes[0..3]
          charset = @escapes[escape_sequence]
        end
        if charset
          next_charset = charset
          readable_sequence = escape_sequence.map { |b| b.chr }.join(' ').gsub(/^\e/, "ESC")
          decoded_fragments << EscapeSequence.new(escape_sequence, readable_sequence, "switch to #{charset.name}")
          bytes = bytes[escape_sequence.size..-1]
        else
          decoded_fragments << RemainingData.new(bytes)
          bytes.clear
        end
      end
      decoded_fragments += next_charset.decode(bytes)
      decoded_fragments
    end

    ISO_2022_JP = Iso2022Charset.new('ISO-2022-JP', {
      "\e(B" => Charset::US_ASCII,
      "\e(J" => Charset::JISX0201_1976,
      "\e$@" => Charset::JISX0208_1978_0,
      "\e$B" => Charset::JISX0208_1983_0
      })

    ISO_2022_JP_1 = Iso2022Charset.new('ISO-2022-JP-1', {
      "\e(B" => Charset::US_ASCII,
      "\e(J" => Charset::JISX0201_1976,
      "\e$@" => Charset::JISX0208_1978_0,
      "\e$B" => Charset::JISX0208_1983_0,
      "\e$(D" => Charset::JISX0212_1990
      })

  end
end
