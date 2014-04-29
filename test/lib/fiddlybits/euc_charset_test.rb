require_relative 'charset_test_helper'

class EucCharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "decoding EUC-JP" do
    data = 'a4 ab a4 ca b4 c1 bb fa 8e ca 8e b0 8e cc 72 6f 6d 61 6a 69 0a'

    assert_equal "かな漢字ﾊｰﾌromaji", decode(data, Fiddlybits::EucCharset::EUC_JP)
  end


end
