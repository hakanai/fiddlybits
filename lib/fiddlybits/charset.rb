module Fiddlybits
  class Charset

    # Result object indicating successfully-decoded data.
    class DecodedData
      attr_reader :bytes
      attr_reader :code_point
      attr_reader :explanation

      def initialize(bytes, code_point, explanation)
        @bytes = bytes.dup
        @code_point = code_point
        @explanation = explanation
      end

      def code_point_str
        [code_point].pack("U")
      end
    end

    # Result object indicating an escape sequence used to switch charset mid-stream.
    class EscapeSequence
      attr_reader :bytes
      attr_reader :code
      attr_reader :explanation

      def initialize(bytes, code, explanation)
        @bytes = bytes.dup
        @code = code
        @explanation = explanation
      end
    end

    # Result object indicating data which cannot be decoded.
    class RemainingData
      attr_reader :bytes

      def initialize(bytes)
        @bytes = bytes.dup
      end
    end

    # The display name of the charset.
    attr_reader :name

    def initialize(name)
      @name = name
    end


    #TODO: I really want a better place to put all the data.
    data = File.realpath(File.join(File.dirname(__FILE__), '../../data'))

    #TODO: More charsets
    # Here's where ICU's list of mappings from various names is:
    # http://source.icu-project.org/repos/icu/icu/trunk/source/data/mappings/convrtrs.txt

    #TODO: All these objects should be immutable including the arrays inside.
    #TODO: We probably shouldn't be loading this up-front once the collection gets bigger.
    US_ASCII = AsciiCharset.new

    ISO8859_1 = TableCharset.new_from_legacy_txt_file('ISO-8859-1', "#{data}/charsets/txt/iso-8859-1-1998.txt")
    ISO8859_7 = TableCharset.new_from_legacy_txt_file('ISO-8859-7', "#{data}/charsets/txt/iso-8859-7-2003.txt")
    GB2312_1980 = TableCharset.new_from_ucm_file('GB 2312-1980', "#{data}/charsets/ucm/ibm-5478_P100-1995.ucm")
    JISX0201_1976_ROMAN = TableCharset.new_from_legacy_txt_file('JIS X 0201-1976 roman', "#{data}/charsets/txt/jisx-0201-1976-roman.txt")
    JISX0201_1976_KANA = TableCharset.new_from_legacy_txt_file('JIS X 0201-1976 kana', "#{data}/charsets/txt/jisx-0201-1976-kana.txt")
    JISX0208_1978_0 = TableCharset.new_from_ucm_file('JIS X 0208-1978', "#{data}/charsets/ucm/ibm-955_P110-1997.ucm")
    JISX0208_1983_0 = TableCharset.new_from_ucm_file('JIS X 0208-1983', "#{data}/charsets/ucm/aix-JISX0208.1983_0-4.3.6.ucm")
    JISX0212_1990 = TableCharset.new_from_ucm_file('JIS X 0212-1990', "#{data}/charsets/ucm/jisx-0212-1990.ucm")
    JISX0213_2000_PLANE1 = TableCharset.new_from_legacy_txt_file('JIS X 0213-2000 plane 1', "#{data}/charsets/txt/jisx-0213-2000-plane1.txt")
    JISX0213_2000_PLANE2 = TableCharset.new_from_legacy_txt_file('JIS X 0213-2000 plane 2', "#{data}/charsets/txt/jisx-0213-2000-plane2.txt")
    KSX1001_1992 = TableCharset.new_from_legacy_txt_file('KS X 1001-1992', "#{data}/charsets/txt/ksx1001-1992.txt")

    ISO_2022_JP = Iso2022Charset::ISO_2022_JP
    ISO_2022_JP_1 = Iso2022Charset::ISO_2022_JP_1
    ISO_2022_JP_2 = Iso2022Charset::ISO_2022_JP_2
    ISO_2022_JP_3 = Iso2022Charset::ISO_2022_JP_3



    # Gets an array containing all known charsets.
    def self.all
      constants.sort.map { |c| self.const_get(c) }.select { |v| v.is_a?(Charset) }
    end
  end
end
