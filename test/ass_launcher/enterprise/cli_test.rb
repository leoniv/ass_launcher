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
    expect = [:createinfobase, :enterprise, :designer]
    assert_equal expect, AssLauncher::Enterprise::Cli::DEFINED_MODES
  end

  def test_defined_modes_for_thin_client
    expect = [:enterprise]
    cl = mock
    cl.expects(:instance_of?)
      .with(AssLauncher::Enterprise::BinaryWrapper::ThinClient)
      .returns(true)
    assert_equal expect, mod.defined_modes_for(cl)
  end
  def test_defined_modes_for_thick_client
    expect = AssLauncher::Enterprise::Cli::DEFINED_MODES
    cl = mock
    cl.expects(:instance_of?)
      .with(AssLauncher::Enterprise::BinaryWrapper::ThinClient)
      .returns(false)
    cl.expects(:instance_of?)
      .with(AssLauncher::Enterprise::BinaryWrapper::ThickClient)
      .returns(true)
    assert_equal expect, mod.defined_modes_for(cl)
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

  def test_for
    skip

  end

  def test_smoky_test_for
    AssLauncher::Enterprise::Cli::Parameters::StringParam\
      .any_instance.expects(:match?).at_least_once.returns(false)
    assert_instance_of cls, cls.for(:fake_binary, :fake_mode)
  end
end

class TestBinaryMatcher < Minitest::Test
  def cls
    AssLauncher::Enterprise::Cli::BinaryMatcher
  end

  def test_initialize
    inst = cls.new(:client, '> 12')
    assert_instance_of Gem::Requirement, inst.requirement
    assert_equal :client, inst.client
  end

  def test_initialize_def
    inst = cls.new()
    assert_equal '>= 0', inst.requirement.to_s
    assert_equal :all, inst.client
  end

  def test_match_version?
    inst = cls.new
    requirement = mock
    requirement.expects(:satisfied_by?).with(:version_stub).returns(:match)
    inst.expects(:requirement).returns(requirement)
    bw = mock
    bw.expects(:version).returns(:version_stub)
    assert_equal :match, inst.send(:match_version?, bw)
  end

  def test_match_client?
    inst = cls.new
    assert inst.send(:match_client?,:bw)
    inst = cls.new(:fake)
    class_ = mock
    class_.expects(:name).returns('FakeClient')
    bw = mock
    bw.expects(:class).returns(class_)
    assert inst.send(:match_client?, bw)
  end

  def test_not_match_client?
    inst = cls.new
    assert inst.send(:match_client?,:bw)
    inst = cls.new(:fake)
    class_ = mock
    class_.expects(:name).returns('NotClientClient')
    bw = mock
    bw.expects(:class).returns(class_)
    refute inst.send(:match_client?, bw)
  end

  def test_match?
    inst = cls.new
    inst.expects(:match_client?).with(:bw).returns(true)
    inst.expects(:match_version?).with(:bw).returns(true)
    assert inst.match?(:bw)
  end

  def test_not_match?
    inst = cls.new
    inst.expects(:match_client?).with(:bw).returns(true)
    inst.expects(:match_version?).with(:bw).returns(false)
    refute inst.match?(:bw)
  end
end
