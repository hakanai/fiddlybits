require 'test_helper'

module CharsetTestHelper
  def decode(hex, charset)
    data = Fiddlybits::Hex.hex_to_binary(hex)
    charset.decode(data).text
  end
end
