module Fiddlybits
  using Fiddlybits::DeepFreeze

  class ShiftJisCharset < Charset
    def initialize(human_name)
      super(human_name)
      @jisx0201 = TableCharset::JIS_X_0201_1997
      @jisx0208 = TableCharset::JIS_X_0208_1997
    end

    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      decode_result = []
      while !bytes.empty?
        b1 = bytes[0]
        if b1 < 0x80 || b1 >= 0xA0 && b1 < 0xE0
          decode_result += @jisx0201.decode([b1])
          bytes = bytes[1..-1]
        else
          if bytes.size < 2
            decode_result << RemainingData.new(bytes)
            bytes = []
            next
          end

          # Bring b1 into the range 0..93
          if b1 >= 0xE0
            b1 -= 0x40
          end
          b1 -= 0x81
          b1 *= 2

          # The logic here seems backwards because we're offsetting from 0 whereas the real thing offsets from 1.
          # So what we're calling an even value, the standard calls an odd one, and vice versa.
          b2 = bytes[1]
          case b2
          when 0x40..0x7E
            b1 += 0x1
            b2 -= 0x3F
          when 0x80..0x9E
            b1 += 0x1
            b2 -= 0x40
          when 0x9F..0xFC
            b1 += 0x2
            b2 -= 0x9E
          else
            decode_result << RemainingData.new(bytes)
            bytes = []
            next
          end

          # b1 and b2 are both in the range 1..94
          # But our tables are offset from 0x21, since they are mostly for use with EUC and ISO-2022.
          # This may change...
          b1 += 0x20
          b2 += 0x20

          decode_result += @jisx0208.decode([b1, b2])
          bytes = bytes[2..-1]
        end
      end
      DecodeResult.new(decode_result)
    end

    SHIFT_JIS_1997 = ShiftJisCharset.new('Shift JIS:1997')
  end
end
