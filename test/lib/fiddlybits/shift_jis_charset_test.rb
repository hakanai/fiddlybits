require_relative 'charset_test_helper'

class ShiftJisCharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "decoding Shift JIS" do
    data = '82 a9 82 c8 8a bf 8e 9a ca b0 cc 72 6f 6d 61 6a 69 0a'

    assert_equal "かな漢字ﾊｰﾌromaji\n", decode(data, Fiddlybits::ShiftJisCharset::SHIFT_JIS_1997)
  end
end
