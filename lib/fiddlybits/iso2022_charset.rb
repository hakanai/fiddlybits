require 'ostruct'

module Fiddlybits
  using DeepFreeze

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

      def min_bytes_per_char; 1; end
      def max_bytes_per_char; 1; end
    end

    def initialize(name, initial_state, rules)
      super(name)
      @initial_state = initial_state
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
      Iso2022Charset.new(name, @initial_state, rules)
    end

    def decode(data)
      state = OpenStruct.new
      state.bytes = data.is_a?(String) ? data.bytes : data
      state.decode_result = DecodeResult.new
      @initial_state.call(state)
      while !state.bytes.empty?
        # Are we looking at an escape sequence?
        escape_sequence, rule = @rules.find { |seq, rule| state.bytes[0..seq.size-1] == seq }
        if escape_sequence
          meaning = readable_escape_sequence(escape_sequence) + ' - ' + rule[:explanation]
          state.decode_result << EscapeSequence.new(escape_sequence, meaning, 'escape sequence table lookup')
          state.bytes = state.bytes[escape_sequence.size..-1]
          rule[:state_change].call(state)
          next
        end

        b = state.bytes[0]

        # Is the character some other control character?
        if (b >= 0x0 && b < 0x20) || (b >= 0x80 && b < 0xa0)
          state.decode_result << DecodedData.new([b], [b].pack('U*'), 'cast control character')
          state.bytes = state.bytes[1..-1]
          next
        end

        # Is the character in GL or GR? Determine which working set (Gn) it belongs to.
        # If it's in GR, offset it for the table lookups.
        working_set = if b > 0x80
          state.gr
          b -= 0x80
        else
          state.gl
        end

        # Are we looking at one of the special characters, SPACE or DELETE?
        if working_set == :g0 && [0x20, 0x7f].include?(b)
          state.decode_result << DecodedData.new([b], [b].pack('U*'), 'cast special value')
          state.bytes = state.bytes[1..-1]
          next
        end

        # It's none of the above so decode the character using the working set.
        charset = state.send(working_set)
        decode_one_character(state, charset)
      end

      state.decode_result.deep_freeze
    end

    def decode_one_character(state, charset)
      size = charset.min_bytes_per_char
      state.decode_result.concat(charset.decode(state.bytes[0..size-1]))
      state.bytes = state.bytes[size..-1]
    end

    def readable_escape_sequence(sequence)
      sequence.
        map { |b| b.chr }.join(' ').
        gsub(/^\e/, 'ESC').
        gsub(/\016/, 'SO').
        gsub(/\017/, 'SI')
    end

    def self.start_as_ascii_only
      proc { |s| s.g0 = AsciiCharset::US_ASCII; s.gl = :g0 }
    end

    def self.shift_out
      {
        explanation: 'locking shift one; GL encodes G1 from now on',
        state_change: proc { |s| s.gl = :g1 }
      }
    end

    def self.shift_in
      {
        explanation: 'locking shift zero; GL encodes G0 from now on',
        state_change: proc { |s| s.gl = :g0 }
      }
    end

    def self.single_shift(working_set)
      {
        explanation: "switch to #{working_set.to_s.upcase} for next character",
        state_change: proc { |s| decode_one_character(s, s.send(working_set)) }
      }
    end

    def self.designate_set(working_set, charset)
      explanation = "switch to #{charset.name}"
      explanation += " (designated to #{working_set.to_s.upcase})" if working_set != :g0
      {
        explanation: explanation,
        state_change: proc { |s| s[working_set] = charset }
      }
    end

    ISO_2022_JP = Iso2022Charset.new(
      'ISO-2022-JP',
      start_as_ascii_only,
      {
        "\e(B" => self.designate_set(:g0, AsciiCharset::US_ASCII),
        "\e(J" => designate_set(:g0, TableCharset::JISX0201_1976_ROMAN),
        "\e$@" => designate_set(:g0, TableCharset::JISX0208_1978_0),
        "\e$B" => designate_set(:g0, TableCharset::JISX0208_1983_0)
      })

    ISO_2022_JP_1 = ISO_2022_JP.new_extension(
      'ISO-2022-JP-1',
      {
        "\e$(D" => designate_set(:g0, TableCharset::JISX0212_1990)
      })

    ISO_2022_JP_2 = ISO_2022_JP_1.new_extension(
      'ISO-2022-JP-2',
      {
        "\e$A"  => designate_set(:g0, TableCharset::GB2312_1980),
        "\e$(C" => designate_set(:g0, TableCharset::KSX1001_1992),
        "\e.A"  => designate_set(:g2, HighPartOnlyCharset.new('ISO-8859-1 high part', TableCharset::ISO_8859_1_1998)),
        "\e.F"  => designate_set(:g2, HighPartOnlyCharset.new('ISO-8859-7 high part', TableCharset::ISO_8859_7_2003)),
        "\eN"   => single_shift(:g2)
      })

    # Note: this is not derived from ISO-2022-JP-2 as one might expect.
    ISO_2022_JP_3 = ISO_2022_JP.new_extension(
      'ISO-2022-JP-3',
      {
        "\e(I"  => designate_set(:g0, TableCharset::JISX0201_1976_KANA),
        "\e$(O" => designate_set(:g0, TableCharset::JISX0213_2000_PLANE1),
        "\e$(P" => designate_set(:g0, TableCharset::JISX0213_2000_PLANE2)
      })

    ISO_2022_JP_2004 = ISO_2022_JP_3.new_extension(
      'ISO-2022-JP-2004',
      {
        "\e$(Q" => designate_set(:g0, TableCharset::JISX0213_2004)
      })

    ISO_2022_KR = Iso2022Charset.new(
      'ISO-2022-KR',
      start_as_ascii_only,
      {
        "\016" => shift_out,
        "\017" => shift_in,
        "\e$)C" => designate_set(:g1, TableCharset::KSX1001_1992)
      })
  end
end
