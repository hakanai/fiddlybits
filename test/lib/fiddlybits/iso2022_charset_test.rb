require_relative 'charset_test_helper'

class Iso2022CharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "decoding ISO-2022-CN" do
    data = '1B 24 29 41 0E 3D 3B 3B 3B 1B 24 29 47 47 28 5F 50 0F'
    assert_equal "交换交換", decode(data, Fiddlybits::Iso2022Charset::ISO_2022_CN)
  end

  test "decoding ISO-2022-JP" do
    data = '72 6f 6d 61 6a 69 1B 24 42 24 2B 24 4A 34 41 3B 7A 1B 28 4A'
    assert_equal "romajiかな漢字", decode(data, Fiddlybits::Iso2022Charset::ISO_2022_JP)
  end

  test "decoding ISO-2022-JP with invalid high bytes" do
    data = 'e0 1B 24 42 34 41 3B 7A e3 1B 28 4A'
    assert_equal "\uFFFD漢字\uFFFD", decode(data, Fiddlybits::Iso2022Charset::ISO_2022_JP)
  end

  test "decoding ISO-2022-KR" do
    assert_equal "김치", decode('1B 24 29 43 0E 31 68 44 21 0F', Fiddlybits::Iso2022Charset::ISO_2022_KR)
  end

end
