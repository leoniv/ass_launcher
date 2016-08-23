require 'test_helper'

class TestConfiguration < Minitest::Test
  def config_
    AssLauncher::Configuration.new
  end
  def test_platform_cli_cpec
    config = config_
    AssLauncher::Enterprise::Cli::CliSpec.expects(:load).returns(:cli_spec)
    assert_equal :cli_spec, config.platform_cli_spec
    assert_equal :cli_spec, config.platform_cli_spec
  end
end

class TestEnetrpriseCli < Minitest::Test
  def mod
    AssLauncher::Enterprise::Cli
  end

  def test_const
    expect = [:createinfobase, :enterprise, :designer, :webclient]
    assert_equal expect, AssLauncher::Enterprise::Cli::DEFINED_MODES
  end

  def test_defined_modes_for_thin_client
    expect = [:enterprise]
    klass = AssLauncher::Enterprise::BinaryWrapper::ThinClient
    assert_equal expect, mod.defined_modes_for(klass)
  end
  def test_defined_modes_for_thick_client
    expect = [:createinfobase, :enterprise, :designer]
    klass = AssLauncher::Enterprise::BinaryWrapper::ThickClient
    assert_equal expect, mod.defined_modes_for(klass)
  end
  def test_defined_modes_for_web_client
    expect = [:webclient]
    klass = AssLauncher::Enterprise::WebClient
    assert_equal expect, mod.defined_modes_for(klass)
  end
end

class TestEnetrpriseCliSpec < Minitest::Test
  def cls
    AssLauncher::Enterprise::Cli::CliSpec
  end

  def test_loader
    loader = cls.send(:loader, :binary_wrapper, :run_mode)
    assert_includes loader.class.included_modules, AssLauncher::Enterprise::Cli::SpecDsl
    assert_equal :binary_wrapper, loader.binary_wrapper
    assert_equal :run_mode, loader.run_mode
  end

  def stub_loader
    Class.new do
      def initialize

      end
    end.new
  end

  def test_smoky_test_for
    fake_binary = stub({run_modes:[]})
    AssLauncher::Enterprise::Cli::Parameters::StringParam\
      .any_instance.expects(:match?).at_least_once.returns(false)
    assert_instance_of cls, cls.for(fake_binary, :fake_mode)
  end
end
