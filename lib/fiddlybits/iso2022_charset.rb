require 'ostruct'

module Fiddlybits
  using Fiddlybits::DeepFreeze

  class Iso2022Charset < Charset

    # Delegating charset implementation allows us to treat charsets like ISO-8859-1
    # such that low bytes will decode as if they were high bytes.
    class HighPartOnlyCharset < Charset
      def initialize(human_name, delegate)
        @human_name = human_name
        @delegate = delegate
      end

      def decode(data)
        bytes = data.is_a?(String) ? data.bytes : data
        bytes = bytes.map { |b| b + 0x80 }
        @delegate.decode(bytes)
      end

      def min_bytes_per_char; 1; end
      def max_bytes_per_char; 1; end
    end

    def initialize(human_name, initial_state, rules)
      super(human_name)
      @initial_state = initial_state
      # Convert sequences to bytes in advance because we're doing all operations on lists of bytes.
      rules.each do |rule|
        seq = rule[:sequence]
        seq = seq.is_a?(String) ? seq.bytes : seq
        rule[:sequence] = seq
      end
      @rules = rules
    end

    # Derives a new charset which has all the rules of this charset plus some additional rules.
    # Reduces repetition in the rule definitions but also makes the definitions look more like
    # what you would see in a description of each charset.
    def new_extension(human_name, additional_rules)
      rules = @rules + additional_rules
      Iso2022Charset.new(human_name, @initial_state, rules)
    end

    def decode(data)
      state = OpenStruct.new
      state.bytes = data.is_a?(String) ? data.bytes : data
      state.decode_result = DecodeResult.new
      @initial_state.call(state)
      while !state.bytes.empty?
        # Are we looking at an escape sequence?
        rule = @rules.find { |rule| seq = rule[:sequence]; state.bytes[0..seq.size-1] == seq }
        if rule
          escape_sequence = rule[:sequence]
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
        working_set = b > 0x80 ? state.gr : state.gl

        if !working_set
          state.decode_result << RemainingData.new([b])
          state.bytes = state.bytes[1..-1]
          next
        end

        # Are we looking at one of the special characters, SPACE or DELETE?
        if working_set == :g0 && [0x20, 0x7f].include?(b)
          state.decode_result << DecodedData.new([b], [b].pack('U*'), 'cast special value')
          state.bytes = state.bytes[1..-1]
          next
        end

        # It's none of the above so decode the character using the working set.
        charset = state.send(working_set)
        decode_one_character(state, charset, )
      end

      state.decode_result.deep_freeze
    end

    #TODO: Code duplication with EucCharset. The state objects are different but the properties used here match.
    def decode_one_character(state, charset)
      size = charset.min_bytes_per_char
      bs = state.bytes[0..size-1]

      if bs[0] > 0x80
        bs = bs.map { |b| b - 0x80 }
      end

      state.decode_result.concat(charset.decode(bs))
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
      proc { |s| s.g0 = TableCharset::US_ASCII; s.gl = :g0 }
    end

    def self.shift_out
      {
        sequence: "\016",
        explanation: 'locking shift one; GL encodes G1 from now on',
        state_change: proc { |s| s.gl = :g1 }
      }
    end

    def self.shift_in
      {
        sequence: "\017",
        explanation: 'locking shift zero; GL encodes G0 from now on',
        state_change: proc { |s| s.gl = :g0 }
      }
    end

    def self.single_shift(n)
      sequence = "\e#{(0x4C + n).chr}"
      working_set = "g#{n}".to_sym
      {
        sequence: sequence,
        explanation: "switch to #{working_set.to_s.upcase} for next character",
        state_change: proc { |s| decode_one_character(s, s.send(working_set)) }
      }
    end

    #TODO The sequence for each set should be in a table somewhere.
    def self.designate_set(n, sequence, charset)
      working_set = "g#{n}".to_sym
      explanation = "switch to #{charset.name}"
      explanation += " (designated to #{working_set.to_s.upcase})" if working_set != :g0
      {
        sequence: sequence,
        explanation: explanation,
        state_change: proc { |s| s[working_set] = charset }
      }
    end

    ISO_2022_CN = Iso2022Charset.new(
      'ISO-2022-CN',
      start_as_ascii_only,
      [
        designate_set(1, "\e$)A", TableCharset::GB_2312_80),
        designate_set(1, "\e$)G", TableCharset::CNS_11643_1986_PLANE_1),
        designate_set(2, "\e$*H", TableCharset::CNS_11643_1986_PLANE_2),
        shift_out,
        shift_in,
        single_shift(2)
      ])

    ISO_2022_CN_EXT = ISO_2022_CN.new_extension(
      'ISO-2022-CN-EXT',
      [
        # These additional sequences are standardised in advance of ISO-IR having mappings for them.
        # But it doesn't have mappings as of 2014 and I suppose it's unlikely they will ever be added. :)
        #designate_set(2, "\e$*<X7589>", GB 7589-87),
        #designate_set(3, "\e$+<X7590>", GB 7590-87),
        #designate_set(1, "\e$)<X12345>", GB 12345-90),
        #designate_set(2, "\e$*<X13131>", GB 13131-91),
        #designate_set(3, "\e$+<X13132>", GB 13132-91),
        designate_set(1, "\e$)E", TableCharset::ISO_IR_165),
        designate_set(3, "\e$+I", TableCharset::CNS_11643_1992_PLANE_3),
        designate_set(3, "\e$+J", TableCharset::CNS_11643_1992_PLANE_4),
        designate_set(3, "\e$+K", TableCharset::CNS_11643_1992_PLANE_5),
        designate_set(3, "\e$+L", TableCharset::CNS_11643_1992_PLANE_6),
        designate_set(3, "\e$+M", TableCharset::CNS_11643_1992_PLANE_7),
        single_shift(3)
      ])

    ISO_2022_JP = Iso2022Charset.new(
      'ISO-2022-JP',
      start_as_ascii_only,
      [
        designate_set(0, "\e(B", TableCharset::US_ASCII),
        designate_set(0, "\e(J", TableCharset::JIS_X_0201_1976_ROMAN),
        designate_set(0, "\e$@", TableCharset::JIS_X_0208_1978),
        designate_set(0, "\e$B", TableCharset::JIS_X_0208_1983)
      ])

    ISO_2022_JP_1 = ISO_2022_JP.new_extension(
      'ISO-2022-JP-1',
      [
        designate_set(0, "\e$(D", TableCharset::JIS_X_0212_1990)
      ])

    ISO_2022_JP_2 = ISO_2022_JP_1.new_extension(
      'ISO-2022-JP-2',
      [
        designate_set(0, "\e$A", TableCharset::GB_2312_80),
        designate_set(0, "\e$(C", TableCharset::KS_X_1001_1992),
        designate_set(2, "\e.A", HighPartOnlyCharset.new('ISO-8859-1 high part', TableCharset::ISO_8859_1_1998)),
        designate_set(2, "\e.F", HighPartOnlyCharset.new('ISO-8859-7 high part', TableCharset::ISO_8859_7_2003)),
        single_shift(2)
      ])

    # Note: this is not derived from ISO-2022-JP-2 as one might expect.
    ISO_2022_JP_3 = ISO_2022_JP.new_extension(
      'ISO-2022-JP-3',
      [
        designate_set(0, "\e(I", TableCharset::JIS_X_0201_1976_KANA),
        designate_set(0, "\e$(O", TableCharset::JIS_X_0213_2000_PLANE_1),
        designate_set(0, "\e$(P", TableCharset::JIS_X_0213_2000_PLANE_2)
      ])

    ISO_2022_JP_2004 = ISO_2022_JP_3.new_extension(
      'ISO-2022-JP-2004',
      [
        designate_set(0, "\e$(Q", TableCharset::JIS_X_0213_2004_PLANE_1)
      ])

    ISO_2022_KR = Iso2022Charset.new(
      'ISO-2022-KR',
      start_as_ascii_only,
      [
        designate_set(1, "\e$)C", TableCharset::KS_X_1001_1992),
        shift_out,
        shift_in
      ])
  end
end
