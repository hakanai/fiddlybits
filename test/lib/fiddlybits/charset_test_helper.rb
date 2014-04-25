require 'test_helper'

module CharsetTestHelper
  def decode(hex, charset)
    data = Fiddlybits::Hex.hex_to_binary(hex)
    string = ''
    charset.decode(data).each do |fragment|
      string << fragment.string if fragment.is_a?(Fiddlybits::Charset::DecodedData)
    end
    string
  end
end
