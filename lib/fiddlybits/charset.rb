module Fiddlybits
  class Charset

    # Result of decoding text.
    class DecodeResult < Array

      # Gets the result as plain text.
      def text
        string = ''
        each do |fragment|
          if fragment.is_a?(Fiddlybits::Charset::DecodedData)
            #TODO: This is overriding unnecessarily in some cases. Should be using the Unicode bidi algorithm
            #      to determine the natural direction of each character and override only if necessary.
            if fragment.direction == :ltr
              string << "\u202D"
            elsif fragment.direction == :rtl
              string << "\u202E"
            end

            string << fragment.string

            if fragment.direction
              string << "\u202C"
            end
          end
        end
        string
      end

    end

    # Result object indicating successfully-decoded data.
    class DecodedData
      attr_reader :bytes
      attr_reader :string
      attr_reader :explanation
      attr_reader :direction

      # Supported options:
      #   direction: Indicates a specific direction treatment for the character (:rtl or :ltr)
      def initialize(bytes, string, explanation, options = {})
        @bytes = bytes.dup
        @string = string
        @explanation = explanation
        @direction = options[:direction] if options[:direction]
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
