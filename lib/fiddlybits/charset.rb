module Fiddlybits
  class Charset

    # Result object indicating successfully-decoded data.
    class DecodedData
      attr_reader :bytes
      attr_reader :code_point
      attr_reader :explanation

      def initialize(bytes, code_point, explanation)
        @bytes = bytes
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
        @bytes = bytes
        @code = code
        @explanation = explanation
      end
    end

    # Result object indicating data which cannot be decoded.
    class RemainingData
      attr_reader :bytes

      def initialize(bytes)
        @bytes = bytes
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
    JISX0201_1976 = TableCharset.new_from_ucm_file('JIS X 0201-1976', "#{data}/charsets/ucm/ibm-897_P100-1995.ucm")
    JISX0208_1978_0 = TableCharset.new_from_ucm_file('JIS X208-1978', "#{data}/charsets/ucm/ibm-955_P110-1997.ucm")
    JISX0208_1983_0 = TableCharset.new_from_ucm_file('JIS X 0208-1983', "#{data}/charsets/ucm/aix-JISX0208.1983_0-4.3.6.ucm")
    ISO_2022_JP = Iso2022Charset.new('ISO-2022-JP')

    # Gets an array containing all known charsets.
    def self.all
      constants.map { |c| self.const_get(c) }.select { |v| v.is_a?(Charset) }
    end
  end
end
