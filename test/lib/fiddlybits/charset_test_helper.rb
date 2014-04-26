require 'test_helper'

module CharsetTestHelper
  def decode(hex, charset)
    data = Fiddlybits::Hex.hex_to_binary(hex)
    string = ''
    #TODO It would help to have this method on the object returned from decode() now that it's complicated.
    charset.decode(data).each do |fragment|
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
