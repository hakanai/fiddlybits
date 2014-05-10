require 'ostruct'

module Fiddlybits
  using Fiddlybits::DeepFreeze

  class EucCharset < Charset

    def initialize(name, sets)
      super(name)
      #TODO Should be deep frozen but TableCharset isn't immutable and immutable+lazy things are difficult.
      @sets = sets.freeze
    end

    def decode(data)
      state = OpenStruct.new
      state.bytes = data.is_a?(String) ? data.bytes : data
      state.decode_result = DecodeResult.new
      while !state.bytes.empty?
        b = state.bytes[0]
        if b == 0x8E
          set = @sets[:g2]
          if set
            meaning = "SS2 - switch to G2 (#{set.name}) for next character"
            state.decode_result << EscapeSequence.new([b], meaning, 'escape sequence table lookup')
            state.bytes = state.bytes[1..-1]
            decode_one_character(state, set)
          else
            decode_result << RemainingData.new(bytes)
            state.bytes = []
          end
        elsif b == 0x8F
          set = @sets[:g3]
          if set
            meaning = "SS3 - switch to G3 (#{set.name}) for next character"
            state.decode_result << EscapeSequence.new([b], meaning, 'escape sequence table lookup')
            state.bytes = state.bytes[1..-1]
            decode_one_character(state, set)
          else
            decode_result << RemainingData.new(bytes)
            state.bytes = []
          end
        elsif b >= 0xA0
          decode_one_character(state, @sets[:g1])
        elsif b >= 0 && b < 0x20
          # C0 table    TODO: What about C1?
          state.decode_result << DecodedData.new([b], [b].pack('U'), 'cast')
          state.bytes = state.bytes[1..-1]
        elsif b >= 20 && b < 0x80
          decode_one_character(state, @sets[:g0])
        else
          decode_result << RemainingData.new([b])
          state.bytes = state.bytes[1..-1]
        end
      end
      state.decode_result.deep_freeze
    end

    #TODO: Code duplication with Iso2022Charset. The state objects are different but the properties used here match.
    def decode_one_character(state, charset)
      size = charset.min_bytes_per_char
      bs = state.bytes[0..size-1]

      if bs[0] >= 0x80
        bs = bs.map { |b| b - 0x80 }
      end

      state.decode_result.concat(charset.decode(bs))
      state.bytes = state.bytes[size..-1]
    end

    # aka CN-GB
    EUC_CN = EucCharset.new(
      'EUC-CN:1980',
      {
        g0: TableCharset::US_ASCII,
        g1: TableCharset::GB_2312_80
      })

    CN_GB_12345 = EucCharset.new(
      'CN-GB-12345:1990',
      {
        g0: TableCharset::US_ASCII,
        g1: TableCharset::GB_T_12345_90
      })

    CN_GC_ISOIR165 = EucCharset.new(
      'CN-GB-ISOIR165:1992',
      {
        g0: TableCharset::US_ASCII,
        g1: TableCharset::ISO_IR_165
      })

    EUC_JP = EucCharset.new(
      'EUC-JP:1990',
      {
        g0: TableCharset::JIS_X_0201_1976_ROMAN,
        g1: TableCharset::JIS_X_0208_1990,
        g2: TableCharset::JIS_X_0201_1976_KANA,
        g3: TableCharset::JIS_X_0212_1990
      })

    # aka KS X 2901 aka RFC 1557
    EUC_KR = EucCharset.new(
      'EUC-KR:1992',
      {
        #TODO some sources say KS X 1003 which is actually a different charset ISO 646-KR. who is right?
        g0: TableCharset::US_ASCII,
        # defined as 1987 in standards but 1992 is the same set. TODO: charset name aliases would improve this.
        g1: TableCharset::KS_X_1001_1992
      })

    #TODO EUC_TW. The real problem with this one is the CNS 11643 set itself and our incomplete information about the version history.
    # EUC_TW = EucCharset.new(
    #   'EUC-TW',
    #   {
    #     g0: AsciiCharset::US_ASCII,
    #     g1: TODO CNS 11643 plane 1
    #     g2: TODO CNS 11643 with plane specified by first byte
    #   })

  end
end
