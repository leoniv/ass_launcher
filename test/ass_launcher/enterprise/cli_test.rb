require 'test_helper'

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

  def test_initialize
    inst = cls.new(:binary_wrapper)
    assert_equal :binary_wrapper, inst.binary_wrapper
  end

  def test_for
    cls.expects(:new).with(:binary_wrapper).returns(:cli_spec)
    assert_equal :cli_spec, cls.for(:binary_wrapper)
  end

  def test_cli_def
    inst = cls.new(nil)
    cls.expects(:cli_def).returns(:cli_def)
    assert_equal :cli_def, inst.cli_def
  end

  def test_class_cli_def
    assert_equal 'AssLauncher::Enterprise::CliDef', cls.cli_def.name
  end

  def all_parameters_stub
    AssLauncher::Enterprise::Cli::Parameters::AllParameters.new
  end

  def test_parameters
    parameters = mock
    parameters.responds_like all_parameters_stub
    parameters.expects(:to_parameters_list).with(:binary_wrapper, :run_mode)
      .returns(:parameters_for_binary_wrapper)
    cli_def = mock
    cli_def.expects(:parameters).returns(parameters)
    inst = cls.new(:binary_wrapper)
    inst.expects(:cli_def).returns(cli_def)
    assert_equal :parameters_for_binary_wrapper, inst.parameters(:run_mode)
  end

  def test_smoky_load_cli_def
    actual = cls.send(:load_cli_def)
    assert_equal AssLauncher::Enterprise::CliDef, actual
  end
end
