module Fiddlybits
  class TableCharset < Charset
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
            if line =~ /<U(.*?)>\s+(\\x\S+)\s+|(\d)/
              string = [$1.hex].pack('U*')
              bytes = [$2.gsub(/\\x/, '')].pack('H*').bytes
              type = $3.to_i

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
            end
          end
        end
      end

      new(name, root, min_bytes_per_char, max_bytes_per_char)
    end

    # Reads a file containing character mappings in the legacy text format Unicode use.
    # Maybe they use it for new character mappings too, but I haven't seen any new ones yet
    # and I'm just assuming they would use the XML format these days.
    def self.new_from_legacy_txt_file(name, file)
      root = []
      min_bytes_per_char = 1000
      max_bytes_per_char = 0

      File.readlines(file).each do |line|
        line.gsub!(/#.*$/, '')
        line.strip!
        next if line.empty?
        
        # Lines look like this:
        # 0x2131  0x201D  # RIGHT DOUBLE QUOTATION MARK
        # 0x2131  0x201D  # RIGHT DOUBLE QUOTATION MARK
        # If a mapping maps to multiple code points:
        # 0x2477  0x304B+309A
        if line =~ /^0x(\S+)\s+0x(\S+(?:\+\S+)*)/
          bytes = [$1].pack('H*').bytes
          string = $2.split(/\+/).map{|h| h.hex}.pack('U*')

          min_bytes_per_char = [min_bytes_per_char, bytes.size].min
          max_bytes_per_char = [max_bytes_per_char, bytes.size].max

          add_to_table(root, bytes, string)
        end
      end
      new(name, root, min_bytes_per_char, max_bytes_per_char)
    end

    def self.add_to_table(root, bytes, string)
      node = root
      bytes[0..-2].each do |b|
        node = (node[b] ||= [])
      end

      node[bytes[-1]] = string
    end

    #TODO: I really want a better place to put all the data.
    data = File.realpath(File.join(File.dirname(__FILE__), '../../data'))

    #TODO: More charsets
    # Here's where ICU's list of mappings from various names is:
    # http://source.icu-project.org/repos/icu/icu/trunk/source/data/mappings/convrtrs.txt

    #TODO: All these objects should be immutable including the arrays inside.
    #TODO: We probably shouldn't be loading this up-front once the collection gets bigger.

    ISO8859_1 = self.new_from_legacy_txt_file('ISO-8859-1', "#{data}/charsets/txt/iso-8859-1-1998.txt")
    ISO8859_7 = self.new_from_legacy_txt_file('ISO-8859-7', "#{data}/charsets/txt/iso-8859-7-2003.txt")
    GB2312_1980 = self.new_from_ucm_file('GB 2312-1980', "#{data}/charsets/ucm/ibm-5478_P100-1995.ucm")
    JISX0201_1976_ROMAN = self.new_from_legacy_txt_file('JIS X 0201-1976 roman', "#{data}/charsets/txt/jisx-0201-1976-roman.txt")
    JISX0201_1976_KANA = self.new_from_legacy_txt_file('JIS X 0201-1976 kana', "#{data}/charsets/txt/jisx-0201-1976-kana.txt")
    JISX0208_1978_0 = self.new_from_ucm_file('JIS X 0208-1978', "#{data}/charsets/ucm/ibm-955_P110-1997.ucm")
    JISX0208_1983_0 = self.new_from_ucm_file('JIS X 0208-1983', "#{data}/charsets/ucm/aix-JISX0208.1983_0-4.3.6.ucm")
    JISX0212_1990 = self.new_from_ucm_file('JIS X 0212-1990', "#{data}/charsets/ucm/jisx-0212-1990.ucm")
    JISX0213_2000_PLANE1 = self.new_from_legacy_txt_file('JIS X 0213-2000 plane 1', "#{data}/charsets/txt/jisx-0213-2000-plane1.txt")
    JISX0213_2000_PLANE2 = self.new_from_legacy_txt_file('JIS X 0213-2000 plane 2', "#{data}/charsets/txt/jisx-0213-2000-plane2.txt")
    JISX0213_2004 = self.new_from_legacy_txt_file('JIS X 0213-2004', "#{data}/charsets/txt/jisx-0213-2004.txt")
    KSX1001_1992 = self.new_from_legacy_txt_file('KS X 1001-1992', "#{data}/charsets/txt/ksx1001-1992.txt")
  end
end
