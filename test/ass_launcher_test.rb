require 'test_helper'

class AssLauncherTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::AssLauncher::VERSION
  end

  def test_known_enterprise_versions
    expects = %w{8.2.17 8.2.18 8.3.3 8.3.4 8.3.5 8.3.6 8.3.7 8.3.8 8.3.9
                 8.3.10}
    assert_equal expects.join(', '),
      AssLauncher::KNOWN_ENTERPRISE_VERSIONS.get.join(', ')
  end
end
