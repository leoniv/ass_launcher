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

  def test_build_args
    zonde = {}
    builder = mock
    builder.responds_like(builder_stub).expects(:build_args)\
      .yields(zonde).returns(:args)
    binary_wrapper = mock
    binary_wrapper.responds_like(binary_wrapper_stub)
    binary_wrapper.expects(:cli_spec).with(:run_mode).returns(:cli_spec)
    cls.expects(:new).with(:cli_spec).returns(builder)

    assert_equal(:args,
                  cls.build_args(binary_wrapper, :run_mode) do |z|
                    z[:executed] = true
                  end
                 )
    assert zonde[:executed]
  end

  def test_initialize
    skip
  end
end

class InspectConnectionStringTest < Minitest::Test
  include AssLauncher::Api
  def inst(cli_spec)
    Class.new(AssLauncher::Enterprise::Cli::ArgumentsBuilder) do
      def initialize(cli_spec)
        super cli_spec,  nil
        extend AssLauncher::Enterprise::Cli::ArgumentsBuilder::InspectConnectionString
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
    cli_spec.expects(:current_run_mode).returns(:createinfobase)
    conn_str = mock
    conn_str.responds_like(cs('File="."'))
    conn_str.expects(:createinfobase_args).returns([3,4])
    ins = inst(cli_spec)
    assert_equal [3,4], ins.send(:conn_str_to_args, conn_str)
  end

  def test_conn_str_to_args_in_other_mode
    cli_spec = stub
    cli_spec.expects(:current_run_mode).returns(:other_mode)
    conn_str = mock
    conn_str.responds_like(cs('File="."'))
    conn_str.expects(:to_args).returns([3,4])
    ins = inst(cli_spec)
    assert_equal [3,4], ins.send(:conn_str_to_args, conn_str)
  end
end
