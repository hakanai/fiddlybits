require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  test "loading the page" do
    get 'index'
    assert_response 200
  end
end
