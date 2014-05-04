module Fiddlybits
  using Fiddlybits::DeepFreeze

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
          elsif fragment.is_a?(Fiddlybits::Charset::RemainingData)
            string << "\uFFFD"
          end
        end
        string
      end

    end

    # Result object indicating successfully-decoded data.
    class DecodedData
      include Immutable

      attr_reader :bytes
      attr_reader :string
      attr_reader :explanation
      attr_reader :direction

      # Supported options:
      #   direction: Indicates a specific direction treatment for the character (:rtl or :ltr)
      def initialize(bytes, string, explanation, options = {})
        @bytes = bytes.dup.deep_freeze
        @string = string.freeze
        @explanation = explanation.freeze
        @direction = options[:direction].freeze if options[:direction]
        freeze
      end
    end

    # Result object indicating an escape sequence used to switch charset mid-stream.
    class EscapeSequence
      include Immutable

      attr_reader :bytes
      attr_reader :code
      attr_reader :explanation

      def initialize(bytes, code, explanation)
        @bytes = bytes.dup.deep_freeze
        @code = code.freeze
        @explanation = explanation.freeze
        freeze
      end
    end

    # Result object indicating data which cannot be decoded.
    class RemainingData
      include Immutable

      attr_reader :bytes

      def initialize(bytes)
        @bytes = bytes.dup.freeze
        freeze
      end
    end

    # The display name of the charset.
    attr_reader :name

    def initialize(name)
      @name = name.freeze
    end
  end
end
