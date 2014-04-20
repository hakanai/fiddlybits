module Fiddlybits
  class Charset

    # Result object indicating successfully-decoded data.
    class DecodedData
      attr_reader :bytes
      attr_reader :string
      attr_reader :explanation

      def initialize(bytes, string, explanation)
        @bytes = bytes.dup
        @string = string
        @explanation = explanation
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
  end
end
