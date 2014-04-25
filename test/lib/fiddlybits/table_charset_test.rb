require_relative 'charset_test_helper'

class TableCharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "decoding Mac OS Devanagari" do
    hex = 'B0 F4 CC E8 20 28 A1 E9 29 20 CD DA 20 B0 A2 B3 ' +
          'DA CF 20 B3 DA 20 C6 DA CC DA A2 C2 CF 20 C8 E8 ' +
          'CF C1 D4 20 D8 E2 EA'

    assert_equal "ओ३म् (ॐ) या ओंकार का नामांतर प्रणव है।", decode(hex, Fiddlybits::TableCharset::MAC_OS_DEVANAGARI)
  end



end
