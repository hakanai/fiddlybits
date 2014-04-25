module Fiddlybits
  class TableCharset < Charset

    # Used for some encodings where the current byte may or may not end the sequence.
    class ConditionalSequence
      attr_reader :string
      attr_reader :array

      def initialize(string, array)
        @string = string
        @array = array
      end
    end

    attr_reader :min_bytes_per_char
    attr_reader :max_bytes_per_char

    def initialize(name, root, min_bytes_per_char, max_bytes_per_char)
      super(name)
      @root = root
      @min_bytes_per_char = min_bytes_per_char
      @max_bytes_per_char = max_bytes_per_char
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

          if node.is_a?(ConditionalSequence)
            # If the *next* byte is in the conditional sequence's array, pretend that
            # this node is an array. If it isn't, treat it like a terminal node.
            nb = bytes[i+1]
            if nb && node.array[nb]
              node = node.array
            else
              node = node.string
            end
          end

          if node.is_a?(String)
            # terminal node
            decoded_bytes = bytes[0..i]
            decoded_fragments << DecodedData.new(decoded_bytes, node, 'table lookup')
            bytes = bytes[i+1..-1]
            break
          elsif node.is_a?(Array)
            # back around 
          elsif node.nil?
            # invalid sequence
            decoded_fragments << RemainingData.new(bytes)
            bytes.clear
            break
          else
            raise "Unexpected node: #{node} of type: #{node.class}"
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
      min_bytes_per_char = 1000
      max_bytes_per_char = 0
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
            if line =~ /^<U(.*?)>\s+(\\x\S+)\s+\|(\d)$/
              string_raw, bytes_raw, type_raw = $1, $2, $3

              string = [string_raw.hex].pack('U*')
              bytes = [bytes_raw.gsub(/\\x/, '')].pack('H*').bytes
              type = type_raw.to_i

              min_bytes_per_char = [min_bytes_per_char, bytes.size].min
              max_bytes_per_char = [max_bytes_per_char, bytes.size].max

              # We can use types 0 and 3:
              # type 0 = normal round-trip mapping
              # type 1 = fallback mapping from Unicode to the codepage but not back
              # type 2 = code point is unmappable - use subchar1 instead of subchar
              # type 3 = reverse fallback mapping only from codepage to Unicode but not back
              # type 4 = good one-way mapping from Unicode to the codepage but not back
              if type == 0 || type == 3
                add_to_table(root, bytes, string)
              end
            else
              raise "Couldn't parse line: [#{line}] in file: #{file}"
            end
          end
        end
      end

      new(name, root, min_bytes_per_char, max_bytes_per_char)
    rescue => e
      raise "Cannot parse #{file}: #{e.message}"
    end

    # Reads a file containing character mappings in the plain text format Unicode use.
    def self.new_from_txt_file(name, file)
      root = []
      min_bytes_per_char = 1000
      max_bytes_per_char = 0

      File.readlines(file).each do |line|
        line.gsub!(/#.*$/, '')
        line.strip!
        next if line.empty?
        
        # Lines look like this:
        # 0x2131      0x201D
        # If a mapping maps to multiple code points:
        # 0x2477      0x304B+0x309A
        # If a mapping has special rules for multiple byte sequences, you can get this too:
        # 0xA1+0xE9   0x0AD0
        # And of course you can have a combination of the two.

        bp = '0x[0-9a-fA-F]{2}+'  # even number of hex digits
        cp = '0x[0-9a-fA-F]{4,}'  # at least 4 hex digits
        if line =~ /^(#{bp}(?:\+#{bp})*)\s+(#{cp}(?:\+#{cp})*)$/
          bytes_raw, string_raw = $1, $2

          bytes = [bytes_raw.gsub(/0x|\+/, '')].pack('H*').bytes
          string = string_raw.split(/\+/).map{|h| h.hex}.pack('U*')

          min_bytes_per_char = [min_bytes_per_char, bytes.size].min
          max_bytes_per_char = [max_bytes_per_char, bytes.size].max

          add_to_table(root, bytes, string)
        else
          raise "Couldn't parse line: [#{line}] in file: #{file}"
        end
      end
      new(name, root, min_bytes_per_char, max_bytes_per_char)
    end

    def self.add_to_table(root, bytes, string)
      node = root
      bytes[0..-2].each do |b|
        node = (node[b] ||= [])
      end

      existing = node[bytes[-1]]
      if existing
        if existing.is_a?(Array)
          node[bytes[-1]] = ConditionalSequence.new(string, existing)
        else
          raise "Would overwrite existing node: #{existing} for byte sequence: #{bytes.inspect}"
        end
      else
        node[bytes[-1]] = string
      end
    end

    #TODO: I really want a better place to put all the data.
    charsets_data = File.realpath(File.join(File.dirname(__FILE__), '../../data/charsets'))

    #TODO: More charsets
    # Here's where ICU's list of mappings from various names is:
    # http://source.icu-project.org/repos/icu/icu/trunk/source/data/mappings/convrtrs.txt

    #TODO: All these objects should be immutable including the arrays inside.
    #TODO: We probably shouldn't be loading this up-front once the collection gets bigger.

    File.readlines("#{charsets_data}/mappings.txt").each do |line|
      line.gsub!(/#.*$/, '')
      line.strip!
      next if line.empty?

      if line =~ /^(\S+)\s+(.*)$/
        path = $1
        human_name = $2

        const_name = $2.gsub(/\([^\)]+\)/, '').gsub(/[\s\-:]/, '_').strip.upcase.to_sym
        full_path = File.join(charsets_data, path)
        TableCharset.const_set(const_name, new_from_txt_file(human_name, full_path))
      end
    end

    GB2312_1980 = self.new_from_ucm_file('GB 2312-1980', "#{charsets_data}/ucm/ibm-5478_P100-1995.ucm")
    JISX0201_1976_ROMAN = self.new_from_txt_file('JIS X 0201-1976 roman', "#{charsets_data}/txt/jisx-0201-1976-roman.txt")
    JISX0201_1976_KANA = self.new_from_txt_file('JIS X 0201-1976 kana', "#{charsets_data}/txt/jisx-0201-1976-kana.txt")
    JISX0208_1978_0 = self.new_from_ucm_file('JIS X 0208-1978', "#{charsets_data}/ucm/ibm-955_P110-1997.ucm")
    JISX0208_1983_0 = self.new_from_ucm_file('JIS X 0208-1983', "#{charsets_data}/ucm/aix-JISX0208.1983_0-4.3.6.ucm")
    JISX0212_1990 = self.new_from_ucm_file('JIS X 0212-1990', "#{charsets_data}/ucm/jisx-0212-1990.ucm")
    JISX0213_2000_PLANE1 = self.new_from_txt_file('JIS X 0213-2000 plane 1', "#{charsets_data}/txt/jisx-0213-2000-plane1.txt")
    JISX0213_2000_PLANE2 = self.new_from_txt_file('JIS X 0213-2000 plane 2', "#{charsets_data}/txt/jisx-0213-2000-plane2.txt")
    JISX0213_2004 = self.new_from_txt_file('JIS X 0213-2004', "#{charsets_data}/txt/jisx-0213-2004.txt")
    KSX1001_1992 = self.new_from_txt_file('KS X 1001-1992', "#{charsets_data}/txt/ksx1001-1992.txt")
  end
end
