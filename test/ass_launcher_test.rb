require 'test_helper'

class AssLauncherTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AssLauncher::VERSION
  end
end
