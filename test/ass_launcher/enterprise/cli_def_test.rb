require 'test_helper'

class CliDefTest < Minitest::Test
  require 'ass_launcher/enterprise/cli_def'

  def mod
    AssLauncher::Enterprise::CliDef
  end

  def test_extends
    assert mod.singleton_class.include? AssLauncher::Enterprise::Cli::SpecDsl
    assert mod.singleton_class.include? AssLauncher::Enterprise::CliDefsLoader
  end

  def test_loaded_defs
    assert_equal mod.enterprise_versions, mod.instance_variable_get(:@loaded_defs)
  end
end
