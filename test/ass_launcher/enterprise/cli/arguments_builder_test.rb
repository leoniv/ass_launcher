require 'test_helper'

class ArgumentsBuilderTest < Minitest::Test
  def binary_wrapper_stub
    Class.new(AssLauncher::Enterprise::BinaryWrapper) do
      def initialize

      end
    end.new
  end

  def builder_stub
    Class.new(cls) do
      def initialize

      end
    end
  end

  def cls
    AssLauncher::Enterprise::Cli::ArgumentsBuilder
  end

  def test_class_build_args
    zonde = {}
    builder = mock
    builder.responds_like(builder_stub).expects(:build_args)\
      .yields(zonde).returns(:args)
    binary_wrapper = mock
    binary_wrapper.responds_like(binary_wrapper_stub)
    binary_wrapper.expects(:cli_spec).returns(:cli_spec)
    cls.expects(:new).with(:cli_spec, :run_mode).returns(builder)

    assert_equal(:args,
                  cls.build_args(binary_wrapper, :run_mode) do |z|
                    z[:executed] = true
                  end
                 )
    assert zonde[:executed]
  end

  def test_initialize
    inst = cls.new(:cli_spec, :run_mode, :parent_parameter)
    assert_equal :cli_spec, inst.send(:cli_spec)
    assert_equal :run_mode, inst.send(:run_mode)
    assert_equal :parent_parameter, inst.send(:parent_parameter)
    assert_equal [], inst.send(:builded_args)
    assert_equal [], inst.send(:params_stack)
  end

  def stub_cli_spec
    Class.new(AssLauncher::Enterprise::Cli::CliSpec) do
      def initialize

      end
    end.new
  end

  def test_defined_parameters
    cli_spec = mock
    cli_spec.responds_like(stub_cli_spec)
    cli_spec.expects(:parameters).with(:run_mode).returns(:parameters)
    inst = cls.new cli_spec, :run_mode
    assert_equal :parameters, inst.send(:defined_parameters)
  end

  def test_binary_wrapper
    cli_spec = mock
    cli_spec.responds_like(stub_cli_spec)
    cli_spec.expects(:binary_wrapper).returns(:binary_wrapper)
    inst = cls.new cli_spec, :run_mode
    assert_equal :binary_wrapper, inst.send(:binary_wrapper)
  end

  def test_nested_builder
    inst = cls.new(:cli_spec, :run_mode)
    cls.expects(:new).with(:cli_spec, :run_mode, :parent_parameter).returns(:nested)
    assert_equal :nested, inst.send(:nested_builder, :parent_parameter)
  end

  def param_stub
    Class.new(AssLauncher::Enterprise::Cli::Parameters::StringParam) do
      def initialize

      end
    end.new
  end

  def test_fail_if_parameter_exists
    param = mock
    param.responds_like(param_stub)
    param.expects(:full_name).returns('fullname')
    inst = cls.new(nil, nil)
    inst.send(:params_stack) << param
    assert_raises AssLauncher::Enterprise::Cli::ArgumentsBuilder::BuildError do
      inst.send(:fail_if_parameter_exist, param)
    end
  end

  def test_not_fail_if_parameter_not_exists
    param = mock
    param.responds_like(param_stub)
    param.expects(:full_name).never
    inst = cls.new(nil, nil)
    assert_equal [ param ],  inst.send(:fail_if_parameter_exist, param)
    assert_equal [ param ],  inst.send(:params_stack)
  end

  def test_fail_no_parameter_error
    inst = cls.new(nil, nil)
    inst.expects(:bw_pesentation)
    inst.expects(:run_mode)
    inst.expects(:to_param_name).with(:method)
    assert_raises AssLauncher::Enterprise::Cli::ArgumentsBuilder::BuildError do
      inst.send(:fail_no_parameter_error, :method)
    end
  end

  def test_bw_presentatoion
    binary_wrapper = mock
    binary_wrapper.responds_like(binary_wrapper_stub)
    binary_wrapper.expects(:class).returns(AssLauncher::Enterprise::BinaryWrapper::ThinClient)
    binary_wrapper.expects(:version).returns('8.3.7.1')
    inst = cls.new(nil, nil)
    inst.expects(:binary_wrapper).returns(binary_wrapper).twice
    assert_equal 'ThinClient 8.3.7.1', inst.send(:bw_pesentation)
  end

  def test_to_param_name
    inst = cls.new(nil, nil)
    inst.expects(:param_key).returns('/').twice
    assert_equal '/Method', inst.send(:to_param_name, :_Method)
    assert_equal '/method', inst.send(:to_param_name, :method)
  end

  def test_param_ket_for_top_parameter
    inst = cls.new(nil, nil)
    assert_equal '/', inst.send(:param_key)
  end

  def test_param_key_for_nested_parameter
    inst = cls.new(nil, nil, :parent_parameter)
    assert_equal '-', inst.send(:param_key)
  end

  def test_add_args
    inst = cls.new(nil, nil)
    assert_equal [:arg1], inst.send(:add_args, [:arg1])
    assert_equal [:arg1, :arg2], inst.send(:add_args, [:arg2])
  end

  def test_build_args_fail
    inst = cls.new(nil, nil)
    e = assert_raises ArgumentError do
      inst.build_args
    end
    assert_equal 'Block require', e.message
  end

  def test_build_args_top_for_webclient
    inst = cls.new(:cli_spec, nil, nil)
    inst.expects(:run_mode).returns(:webclient)
    actual = inst.build_args do
      builded_args << 1
      builded_args << 2
    end
    refute_respond_to inst, :connection_string
    assert [1,2], actual
  end

  def test_build_args_top
    cli_spec = mock
    inst = cls.new(cli_spec, nil, nil)
    inst.expects(:run_mode).returns(:enterprise)
    actual = inst.build_args do
      builded_args << 1
      builded_args << 2
    end
    assert_respond_to inst, :connection_string
    assert [1,2], actual
  end

  def test_build_args_nested
    zonde = {}
    inst = cls.new(:cli_spec, nil, :parent_parameter)
    inst.expects(:run_mode).never
    inst.build_args do
      zonde[:executed] = true
    end
    refute_respond_to inst, :connection_string
    assert zonde[:executed]
  end

  def test_param_find
    parameters = mock
    parameters.responds_like(AssLauncher::Enterprise::Cli::Parameters::ParametersList.new)
    parameters.expects(:find).with(:param_name, :parent_parameter).returns(:param)
    inst = cls.new(nil, nil)
    inst.expects(:parent_parameter).returns(:parent_parameter)
    inst.expects(:to_param_name).with(:method).returns(:param_name)
    inst.expects(:defined_parameters).returns(parameters)
    assert_equal :param, inst.send(:param_find, :method)
  end

  def test_param_argument_get
    inst = cls.new(nil, nil)
    param = mock
    param.responds_like(param_stub)
    param.expects(:arguments_count).returns(0)
    param.expects(:argument_require).returns(false)
    assert_equal [], inst.send(:param_argument_get, param, [])
  end

  def test_param_argument_get_fail
    inst = cls.new(nil, nil)
    param = mock
    param.responds_like(param_stub)
    param.expects(:argument_require).returns(true)
    param.expects(:arguments_count).returns(1).twice
    param.expects(:full_name)
    assert_raises ArgumentError do
      inst.send(:param_argument_get, param, [])
    end
  end

  def test_method_missing_fail_no_parameter
    inst = cls.new(nil, nil)
    inst.expects(:param_find).with(:bad_param).returns(nil)
    inst.expects(:fail_no_parameter_error).with(:bad_param).raises(ArgumentError)
    assert_raises ArgumentError do
      inst.method_missing(:bad_param)
    end
  end

  def moked_inst(good_param)
    inst = cls.new(nil, nil)
    inst.expects(:param_find).with(:good_param).returns(good_param)
    inst.expects(:fail_no_parameter_error).never
    inst.expects(:fail_if_parameter_exist).with(good_param)
    inst.expects(:param_argument_get).with(good_param, [:args]).returns([:args])
    inst
  end

  def test_method_missing
    good_param = mock
    good_param.responds_like(param_stub)
    good_param.expects(:to_args).with(*[:args]).returns(['/good_param', 'args'])
    inst = moked_inst(good_param)
    inst.expects(:nested_builder).never
    inst.send(:builded_args) << 1
    inst.send(:builded_args) << 2
    inst.good_param(:args)
    assert_equal [1, 2, '/good_param', 'args'], inst.send(:builded_args)
  end

  def test_method_missing_with_block
    zonde = []
    nested_builder = mock
    nested_builder.responds_like(builder_stub)
    nested_builder.expects(:build_args).yields(zonde).returns(zonde)
    good_param = mock
    good_param.responds_like(param_stub)
    good_param.expects(:to_args).with(*[:args]).returns(['/good_param', 'args'])
    inst = moked_inst(good_param)
    inst.expects(:nested_builder).with(good_param).returns(nested_builder)
    inst.good_param :args do |z|
      z << 1
      z << 5
    end
    assert_equal ['/good_param', 'args', 1, 5], inst.send(:builded_args)
  end
end

class IncludeConnectionStringTest < Minitest::Test
  include AssLauncher::Api
  def inst(cli_spec)
    Class.new(AssLauncher::Enterprise::Cli::ArgumentsBuilder) do
      def initialize(cli_spec)
        super cli_spec,  nil
        extend AssLauncher::Enterprise::Cli::ArgumentsBuilder::IncludeConnectionString
      end

      def builded_args
        [5,6]
      end
    end.new(cli_spec)
  end

  def test_connection_string
    AssLauncher::Support::ConnectionString.expects(:new).with('File="."')\
      .returns(:conn_str)
    ins = inst(nil)
    ins.expects(:conn_str_to_args).with(:conn_str).returns([1,3,4])
    assert_equal [1,3,4,5,6], ins.connection_string('File="."')
  end

  def test_conn_str_to_args_in_createinfobase_mode
    cli_spec = stub
    conn_str = mock
    conn_str.responds_like(cs('File="."'))
    conn_str.expects(:createinfobase_args).returns([3,4])
    ins = inst(cli_spec)
    ins.expects(:run_mode).returns(:createinfobase)
    assert_equal [3,4], ins.send(:conn_str_to_args, conn_str)
  end

  def test_conn_str_to_args_in_other_mode
    cli_spec = stub
    conn_str = mock
    conn_str.responds_like(cs('File="."'))
    conn_str.expects(:to_args).returns([3,4])
    ins = inst(cli_spec)
    ins.expects(:run_mode).returns(:other_mode)
    assert_equal [3,4], ins.send(:conn_str_to_args, conn_str)
  end
end
