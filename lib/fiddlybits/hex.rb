module Fiddlybits
  class Hex
    WIDTH = 16

    def self.hex_to_binary(hex_string)
      [ hex_string.scan(/\b[0-9a-fA-F]{2}\b/).join ].pack('H*')
    end

    #TODO The other direction
    # def self.binary_to_hex(binary)
    #   ascii = ''
    #   counter = 0
    #   binary.each_byte do |b|
    #     if counter >= start
    #       print '%02x ' % b
    #       ascii << (b.between?(32, 126) ? b : '.')
    #       if ascii.length >= WIDTH
    #         puts ascii 
    #         ascii = ''
    #       end
    #     end
    #     break if finish && finish <= counter
    #     counter += 1
    #   end
    #   puts '   ' * (WIDTH - ascii.length) + ascii
    # end
  end
end
