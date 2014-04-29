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
          meaning = 'SS2 - switch to G2 for next character'
          state.decode_result << EscapeSequence.new([b], meaning, 'escape sequence table lookup')
          state.bytes = state.bytes[1..-1]
          decode_one_character(state, @sets[:g2])
        elsif b == 0x8F
          meaning = 'SS3 - switch to G3 for next character'
          state.decode_result << EscapeSequence.new([b], meaning, 'escape sequence table lookup')
          state.bytes = state.bytes[1..-1]
          decode_one_character(state, @sets[:g3])
        elsif b >= 0xA0
          decode_one_character(state, @sets[:g1])
        elsif b >= 0 && b < 0x80
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

      if bs[0] > 0x80
        bs = bs.map { |b| b - 0x80 }
      end

      state.decode_result.concat(charset.decode(bs))
      state.bytes = state.bytes[size..-1]
    end

    #TODO EUC_CN
    # Wikipedia entry is too vague to implement, have to find another source.

    #TODO EUC-JP
    #  namely JIS X 0208, JIS X 0212, and JIS X 0201.

    EUC_JP = EucCharset.new(
      'EUC-JP',
      {
        g0: TableCharset::JIS_X_0201_1976_ROMAN,
        g1: TableCharset::JIS_X_0208_1990,
        g2: TableCharset::JIS_X_0201_1976_KANA,
        g3: TableCharset::JIS_X_0212_1990
      })
  end
end
