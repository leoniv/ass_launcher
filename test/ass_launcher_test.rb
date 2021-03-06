require 'test_helper'

class AssLauncherTest < Minitest::Test
  module KnownEnterpriseVersions
    extend AssLauncher::Enterprise::CliDefsLoader
    def self.get
      defs_versions
    end
  end

  def test_that_it_has_a_version_number
    refute_nil ::AssLauncher::VERSION
  end

  def test_known_enterprise_versions
    expects = %w{8.1.0 8.2.17 8.2.18 8.3.3 8.3.4 8.3.5 8.3.6 8.3.7 8.3.8 8.3.9
                 8.3.10 8.3.11 8.3.12 8.3.13}
    assert_equal expects.join(', '),
      KnownEnterpriseVersions.get.join(', ')
  end
end
