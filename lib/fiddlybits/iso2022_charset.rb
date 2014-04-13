module Fiddlybits
  class Iso2022Charset < Charset

    # Delegating charset implementation allows us to treat charsets like ISO-8859-1
    # such that low bytes will decode as if they were high bytes.
    class HighPartOnlyCharset < Charset
      def initialize(name, delegate)
        @name = name
        @delegate = delegate
      end

      def decode(data)
        bytes = data.is_a?(String) ? data.bytes : data
        bytes.map { |b| b + 0x80 }
        @delegate.decode(bytes)
      end
    end

    def initialize(name, rules)
      super(name)
      @rules = {}
      # Convert keys to bytes in advance because we're doing all operations on lists of bytes.
      rules.each_pair do |escape, rule|
        bytes = escape.is_a?(String) ? escape.bytes : escape
        @rules[bytes] = rule
      end
    end

    # Derives a new charset which has all the rules of this charset plus some additional rules.
    # Reduces repetition in the rule definitions but also makes the definitions look more like
    # what you would see in a description of each charset.
    def new_extension(name, additional_rules)
      rules = @rules.clone
      additional_rules.each_pair do |escape, rule|
        bytes = escape.is_a?(String) ? escape.bytes : escape
        rules[bytes] = rule
      end
      Iso2022Charset.new(name, rules)
    end

    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      decoded_fragments = []
      # TODO: This algorithm is still wrong for charsets which use GR.
      g0 = Charset::US_ASCII
      g2 = nil
      while esc = bytes.find_index(0x1b)
        decoded_fragments += g0.decode(bytes[0...esc])
        bytes = bytes[esc..-1]

        # Escape sequences which apply only to the next byte.
        if bytes[0..1] == "\eN" # \eO would be to G3 but we're not using it yet.
          # Next byte is a character from G2.
          decoded_fragments << EscapeSequence.new(escape_sequence, readable_escape_sequence(escape_sequence), 'switch to G2 for next character')
          decoded_fragments += g2.decode(bytes[2..2])
          bytes = bytes[3..-1]
          next
        end

        # Escape sequences which switch character sets.
        # There is probably a more elegant way to go about this but we know all escape sequences are
        # either 3 or 4 bytes.
        escape_sequence = bytes[0..2]
        rule = @rules[escape_sequence]
        if !rule
          escape_sequence = bytes[0..3]
          rule = @rules[escape_sequence]
        end
        if rule
          if rule[1] == :g0
            g0 = rule[0]
          elsif rule[1] == :g2
            g1 = rule[0]
          else
            raise "Unexpected table: #{rule[1]}"
          end

          explanation = "switch to #{rule[0].name}"
          if rule[1] != :g0
            explanation += " (designated to #{rule[1].to_s.upcase})"
          end
          decoded_fragments << EscapeSequence.new(escape_sequence, readable_escape_sequence(escape_sequence), explanation)
          bytes = bytes[escape_sequence.size..-1]
        else
          decoded_fragments << RemainingData.new(bytes)
          bytes.clear
        end
      end
      decoded_fragments += g0.decode(bytes)
      decoded_fragments
    end

    def readable_escape_sequence(sequence)
      sequence.map { |b| b.chr }.join(' ').gsub(/^\e/, "ESC")
    end

    ISO_2022_JP = Iso2022Charset.new('ISO-2022-JP', {
      "\e(B" => [ Charset::US_ASCII,        :g0 ],
      "\e(J" => [ Charset::JISX0201_1976,   :g0 ],
      "\e$@" => [ Charset::JISX0208_1978_0, :g0 ],
      "\e$B" => [ Charset::JISX0208_1983_0, :g0 ]
      })

    ISO_2022_JP_1 = ISO_2022_JP.new_extension('ISO-2022-JP-1', {
      "\e$(D" => [ Charset::JISX0212_1990,   :g0 ]
      })

    ISO_2022_JP_2 = ISO_2022_JP_1.new_extension('ISO-2022-JP-2', {
      "\e$A"  => [ Charset::GB2312_1980,     :g0 ],
      "\e$(C" => [ Charset::KSX1001_1992,    :g0 ],
      "\e.A"  => [ HighPartOnlyCharset.new('ISO-8859-1 high part', Charset::ISO8859_1), :g2 ],
      "\e.F"  => [ HighPartOnlyCharset.new('ISO-8859-7 high part', Charset::ISO8859_7), :g2 ]
      })

  end
end
