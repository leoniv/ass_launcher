require 'test_helper'

class WebClientTest < Minitest::Test
  def test_const
    assert_equal :webclient, AssLauncher::Enterprise::WebClient::RUN_MODE
    assert_equal({ disable_startup_messages: true },
      AssLauncher::Enterprise::WebClient::DEFAULT_OPTIONS)
    assert_equal '999',
      AssLauncher::Enterprise::WebClient::DEFAULT_VERSION
  end

  def cls
    AssLauncher::Enterprise::WebClient
  end

  def test_initialize
    inst = cls.new('http://example.com', '888')
    assert_equal inst.uri, URI('http://example.com')
    assert_equal inst.version, Gem::Version.new('888')
  end

  def test_cli_spec
    inst = cls.new
    AssLauncher::Enterprise::Cli::CliSpec.expects(:for)\
      .with(inst, AssLauncher::Enterprise::WebClient::RUN_MODE).returns(:cli_spec)
    assert_equal :cli_spec, inst.cli_spec
  end

  def test_runmodes
    inst = cls.new
    assert_equal([AssLauncher::Enterprise::WebClient::RUN_MODE], inst.run_modes)
  end

  def builder_stub
    Class.new(AssLauncher::Enterprise::Cli::ArgumentsBuilder) do
      def initialize

      end
    end.new
  end

  def test_build_args
    zonde = {}
    inst = cls.new
    inst.expects(:cli_spec).returns(:cli_spec)
    builder = mock
    builder.responds_like(builder_stub)
    builder.expects(:build_args).yields(zonde).returns(:args)
    AssLauncher::Enterprise::Cli::ArgumentsBuilder.expects(:new).with(:cli_spec)\
      .returns(builder)
    actual = inst.send(:build_args) do |zonde|
      zonde[:called] = true
    end
    assert_equal :args, actual
    assert zonde[:called]
  end

  def location(zonde = nil, &block)
    uri = mock
    uri.expects(:dup).returns(:uri)
    inst = cls.new
    inst.expects(:uri).returns(uri)
    unless block_given?
      inst.expects(:build_args).never
      inst.expects(:args_to_query)\
        .with(['arg1','val1', 'DisableStartupMessages','']).returns(:args)
    else
      inst.expects(:build_args).yields(zonde)\
        .returns(['arg2','val2']) if block_given?
      inst.expects(:args_to_query)\
        .with(['arg1','val1', 'DisableStartupMessages','',
               'arg2', 'val2']).returns(:args)
    end
    inst.expects(:add_to_query).with(:uri, :args).returns(:new_uri)
    inst.location(['arg1', 'val1'], &block)
  end

  def test_location_without_block
    assert_equal :new_uri, location
  end

  def test_location_with_block
    zonde = {}
    actual = location(zonde) do |z|
      z[:called] = true
    end
    assert_equal :new_uri, actual
    assert zonde[:called]
  end

  def test_add_to_query_with_empty_query
    inst = cls.new('http://example.com')
    assert_equal 'http://example.com?arg1=value%201',
      inst.send(:add_to_query, inst.uri, 'arg1=value 1').to_s
  end

  def test_add_to_query_with_not_empty_query
    inst = cls.new('http://example.com?arg2=val2')
    assert_equal 'http://example.com?arg2=val2&arg1=value%201', inst\
      .send(:add_to_query, inst.uri, 'arg1=value 1').to_s
  end

  def test_args_to_query_with_epty_args
    inst = cls.new
    inst.expects(:to_query).with([]).returns('')
    assert_nil inst.send(:args_to_query, [])
  end

  def test_args_to_query_with_not_epty_args
    inst = cls.new
    inst.expects(:to_query).with([1,2,3]).returns('arg=value&arg=value&')
    assert_equal 'arg=value&arg=value', inst.send(:args_to_query, [1,2,3])
  end

  def test_to_query
    inst = cls.new
    expected = 'arg1=val1&arg2=val2&'
    actual = inst.send(:to_query, %w{arg1 val1 arg2 val2})
    assert_equal expected, actual
  end
end
