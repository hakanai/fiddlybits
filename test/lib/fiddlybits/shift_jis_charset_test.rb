require_relative 'charset_test_helper'

class ShiftJisCharsetTest < ActiveSupport::TestCase
  include CharsetTestHelper

  test "decoding Shift JIS" do
    data = '82 a9 82 c8 8a bf 8e 9a ca b0 cc 72 6f 6d 61 6a 69 0a'

    assert_equal "かな漢字ﾊｰﾌromaji\n", decode(data, Fiddlybits::ShiftJisCharset::SHIFT_JIS_1997)
  end

  test "Shift JIS X 2013 row offsets" do
    data = 'f0 40 f1 40 f1 9f f2 40 f0 9f f2 9f f3 40 f3 9f ' +
           'f4 40 f4 9f f5 40 f5 9f f6 40 f6 9f f7 40 f7 9f ' +
           'f8 40 f8 9f f9 40 f9 9f fa 40 fa 9f fb 40 fb 9f ' +
           'fc 40 fc 9f '
    str = "𠂉儈唼堠宖幮抙晛棙殛溓熳璠𥆩稸糍翲芲𦿶蠮豗𨗉𨨩靪騱鳦"
    assert_equal str, decode(data, Fiddlybits::ShiftJisCharset::SHIFT_JIS_2004)
  end

end
