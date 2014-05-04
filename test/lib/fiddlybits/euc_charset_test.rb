require_relative 'charset_test_helper'

class EucCharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "decoding EUC-CN" do
    assert_equal "number一", decode('6e 75 6d 62 65 72 d2 bb', Fiddlybits::EucCharset::EUC_CN)
  end

  test "decoding EUC-JP" do
    data = 'a4 ab a4 ca b4 c1 bb fa 8e ca 8e b0 8e cc 72 6f 6d 61 6a 69 0a'

    assert_equal "かな漢字ﾊｰﾌromaji\n", decode(data, Fiddlybits::EucCharset::EUC_JP)
  end

  test "decoding EUC-KR" do
    assert_equal "한글.txt", decode('c7 d1 b1 db 2e 74 78 74', Fiddlybits::EucCharset::EUC_KR)
  end

end
