require "minitest/autorun"

load File.expand_path("../irbrc", __dir__)

class IrbrcTest < Minitest::Test
  def test_local_methods_keeps_class_specific_methods
    assert_includes [].local_methods, :length
    refute_includes [].local_methods, :display
  end

  def test_history_configuration_uses_the_home_directory
    assert_equal File.join(Dir.home, ".irb_history"), IRB.conf[:HISTORY_FILE]
    assert_equal 1_000, IRB.conf[:SAVE_HISTORY]
  end
end
