module Fiddlybits
  class Hex
    WIDTH = 16

    def self.hex_to_binary(hex_string)
      [ hex_string.scan(/\b[0-9a-fA-F]{2}\b/).join ].pack('H*')
    end

    def self.binary_to_hex(binary)
      result = ''
      ascii = ''
      counter = 0
      binary.each_byte do |b|
        result << ('%02x ' % b)
        ascii << (b.between?(32, 126) ? b : '.')
        if ascii.length >= WIDTH
          result << (' ' + ascii)
          ascii = ''
        end
        counter += 1
      end
      result << (('   ' * (WIDTH - ascii.length)) + ' ' + ascii)
    end
  end
end
