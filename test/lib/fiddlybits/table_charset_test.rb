require_relative 'charset_test_helper'

class TableCharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "loading all table charsets" do
    Fiddlybits::CharsetRegistry.find_all.each do |cs|
      cs.decode([0]) if cs.is_a?(Fiddlybits::TableCharset)
    end
  end

  test "decoding Mac OS Devanagari" do
    hex = 'B0 F4 CC E8 20 28 A1 E9 29 20 CD DA 20 B0 A2 B3 ' +
          'DA CF 20 B3 DA 20 C6 DA CC DA A2 C2 CF 20 C8 E8 ' +
          'CF C1 D4 20 D8 E2 EA'

    assert_equal "ओ३म् (ॐ) या ओंकार का नामांतर प्रणव है।", decode(hex, Fiddlybits::TableCharset::MAC_OS_DEVANAGARI)
  end

  test "decoding Mac OS Hebrew" do
    hex = 'E4 F0 E7 E9 E5 FA A0 ' +
          'EC E4 F0 E2 F9 FA A0 ' +
          'FA EB F0 E9 A0 ' +
          'E0 FA F8 E9 A0 ' +
          'E0 E9 F0 E8 F8 F0 E8 A0 ' +
          '28 57 43 41 47 29 A0 ' +
          '32 2E 30'

    # rtl makes a mess of the source so I am using escapes.
    rtlspace = "\u202E \u202C"
    str = "\u05D4\u05E0\u05D7\u05D9\u05D5\u05EA" + rtlspace +
          "\u05DC\u05D4\u05E0\u05D2\u05E9\u05EA" + rtlspace +
          "\u05EA\u05DB\u05E0\u05D9" + rtlspace +
          "\u05D0\u05EA\u05E8\u05D9" + rtlspace +
          "\u05D0\u05D9\u05E0\u05D8\u05E8\u05E0\u05D8" + rtlspace +
          "\u202D(\u202C" + "WCAG" + "\u202D)\u202C" + rtlspace +
          "2" + "\u202D.\u202C" + "0"

    assert_equal str, decode(hex, Fiddlybits::TableCharset::MAC_OS_HEBREW)
  end

end
