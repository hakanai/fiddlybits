module Fiddlybits
  class TableCharset < Charset
    def initialize(name, root)
      super(name)
      @root = root
    end

    # Decodes the given string as binary data, returning a structure explaining how it was done.
    # The return is an array of decoded fragments or markers indicating a failure to decode.
    # Parameter can be a list of byte values or a string. If it's a string, it will be converted
    # to bytes as the first step.
    def decode(data)
      bytes = data.is_a?(String) ? data.bytes : data
      decoded_fragments = []
      while bytes.size > 0
        node = @root
        (0...bytes.size).each do |i|
          b = bytes[i]
          node = node[b] # todo rewrite this bit in proper OO
          if node.is_a?(Integer)
            # terminal node
            decoded_bytes = bytes[0..i]
            decoded_fragments << DecodedData.new(decoded_bytes, node, 'table lookup')
            bytes = bytes[i+1..-1]
            break
          elsif node.nil?
            # invalid sequence
            decoded_fragments << RemainingData.new(bytes)
            bytes.clear
            break
          else
            # assumed to be an array, back around the loop
          end
        end
        if node.is_a?(Array)
          # incomplete sequence
          decoded_fragments << RemainingData.new(bytes)
          bytes.clear
        end
      end
      decoded_fragments
    end

    # Reads a file containing character mappings in ICU's UCM format.
    def self.new_from_ucm_file(name, file)
      in_charset = false
      root = []
      File.readlines(file).each do |line|
        line.strip!
        next if line.starts_with?('#')
        case line
        when 'CHARMAP'
          in_charset = true
        when 'END CHARMAP'
          in_charset = false
        else
          if in_charset
            # Lines look like this:
            # <U00D7>  \x21\x5F |0
            if line =~ /<U(.*?)>\s+(\\x\S+)\s+|(\d)/
              code_point = $1.hex
              bytes = [$2.gsub(/\\x/, '')].pack('H*').bytes
              type = $3.to_i

              # We can use types 0 and 3:
              # type 0 = normal round-trip mapping
              # type 1 = fallback mapping from Unicode to the codepage but not back
              # type 2 = code point is unmappable - use subchar1 instead of subchar
              # type 3 = reverse fallback mapping only from codepage to Unicode but not back
              # type 4 = good one-way mapping from Unicode to the codepage but not back
              if type == 0 || type == 3
                add_to_table(root, bytes, code_point)
              end
            end
          end
        end
      end

      new(name, root)
    end

    # Reads a file containing character mappings in the legacy text format Unicode use.
    # Maybe they use it for new character mappings too, but I haven't seen any new ones yet
    # and I'm just assuming they would use the XML format these days.
    def self.new_from_legacy_txt_file(name, file)
      root = []
      File.readlines(file).each do |line|
        line.gsub!(/#.*$/, '').strip!
        next if line.empty?
        
        # Lines look like this:
        # 0x2131  0x201D  # RIGHT DOUBLE QUOTATION MARK
        if line =~ /^0x(\S+)\s+0x(\S+)/
          bytes = [$1].pack('H*').bytes
          code_point = $2.hex
          add_to_table(root, bytes, code_point)
        end
      end
      new(name, root)
    end

    def self.add_to_table(root, bytes, code_point)
      node = root
      bytes[0..-2].each do |b|
        node = (node[b] ||= [])
      end

      node[bytes[-1]] = code_point
    end
  end
end
