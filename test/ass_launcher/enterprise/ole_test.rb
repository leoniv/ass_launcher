require 'test_helper'

module LikeCOMConnectorTest

  def test_open_opened
    inst = cls.new(:requirement)
    inst.expects(:__opened__?).returns(true)
    inst.expects(:__ole_binary__).never
    assert inst.__open__(:conn_str)
  end

  def test_open_closed
    ole = mock
    ole.expects(:ole).returns(ole)
    ole.expects(@connect_method).with(:conn_str.to_s).returns(:ole)
    inst = cls.new(:requirement)
    inst.expects(:__opened__?).returns(false)
    inst.expects(:__ole_binary__).returns(ole)
    inst.expects(:__init_ole__).with(:ole)
    assert inst.__open__(:conn_str)
  end
end

module LikeHaveOleBinaryTest
  def test_ole_binary
    @ole_binary_class.expects(:new)
      .with(:requirement.to_s).returns(:ole_binary)
    inst = cls.new(:requirement)
    assert_equal :ole_binary, inst.send(:__ole_binary__)
  end
end

class IbConnection < Minitest::Test

  include LikeCOMConnectorTest
  include LikeHaveOleBinaryTest

  def setup
    @connect_method = :connect
    @ole_binary_class = AssLauncher::Enterprise::Ole::OleBinaries::COMConnector
  end

  def cls
    AssLauncher::Enterprise::Ole::IbConnection
  end

  def test_initialize
    inst = cls.new(:requirement)
    assert_equal :requirement.to_s, inst.instance_variable_get(:@requirement)
  end

  def test_init_ole
    inst = cls.new(nil)
    assert_equal :ole, inst.send(:__init_ole__, :ole)
    assert_equal :ole, inst.send(:__ole__)
  end

  def test_close_closed
    inst = cls.new(nil)
    inst.expects(:__closed__?).returns(true)
    inst.expects(:__ole__).never
    assert inst.__close__
  end

  def test_close_opened
    ole = mock
    ole.expects(:send).with(:__ass_ole_free__)
    inst = cls.new(nil)
    inst.expects(:__closed__?).returns(false)
    inst.expects(:__ole__).returns(ole)
    inst.instance_variable_set(:@__ole__, :fake)
    assert inst.__close__
    assert_nil inst.instance_variable_get(:@__ole__)
  end

  def test_closed?
    ole = mock
    ole.expects(:nil?).returns(true)
    inst = cls.new nil
    inst.expects(:__ole__).returns(ole)
    assert inst.__closed__?
  end

  def test_opened?
    inst = cls.new nil
    inst.expects(:__closed__?).returns(false)
    assert inst.__opened__?
  end

  def test_configure_com_connector
    ole = mock
    ole.expects(:ole).returns(ole)
    opts = {}
    opts.expects(:each).yields(:key, :value)
    ole.expects(:setproperty).with(:key, :value).returns(:success)
    inst = cls.new(nil)
    inst.expects(:__ole_binary__).returns(ole)
    inst.__configure_com_connector__(opts)
  end

  def test_cs
    inst = cls.new nil
    cs = mock
    cs.responds_like(AssLauncher::Support::ConnectionString.new('File="/file"'))
    cs.expects(:to_ole_string).returns(:to_ole_string)
    assert_equal :to_ole_string, inst.send(:__cs__, cs)
    assert_equal :conn_str.to_s, inst.send(:__cs__, :conn_str)
  end

  def test_method_missing_closed_object
    inst = cls.new(nil)
    inst.expects(:__closed__?).returns(true)
    inst.expects(:__ole__).never
    assert_raises RuntimeError do
      inst.send(:method_missing, :fake_method, [1,2,3])
    end
  end

  def test_method_missing_opened_object
    ole = mock
    ole.expects(:fake_method).with(1,2,3).returns(:object)
    inst = cls.new(nil)
    inst.expects(:__closed__?).returns(false)
    inst.expects(:__ole__).returns(ole)
    assert_equal :object, inst.fake_method(1,2,3)
  end
end

class WpConectionTest < Minitest::Test
  include LikeCOMConnectorTest

  def setup
    @connect_method = 'ConnectWorkingProcess'.downcase.to_sym
  end

  def cls
    AssLauncher::Enterprise::Ole::WpConnection
  end
end

class AgentConectionTest < Minitest::Test
  include LikeCOMConnectorTest

  def setup
    @connect_method = 'ConnectAgent'.downcase.to_sym
  end

  def cls
    AssLauncher::Enterprise::Ole::AgentConnection
  end
end

class OleThinApplicationTest < Minitest::Test
  include LikeHaveOleBinaryTest
  def setup
    @ole_binary_class = AssLauncher::Enterprise::Ole::OleBinaries::ThinApplication
  end

  def cls
    AssLauncher::Enterprise::Ole::ThinApplication
  end

  def test_initialize
    AssLauncher::Enterprise::Ole::IbConnection.any_instance.expects(:initialize).
      with(:requirement)
    inst = cls.new(:requirement)
    assert_equal false, inst.instance_variable_get(:@opened)
  end

  def test_class_objects
    assert_equal [], cls.objects
  end

  def test_class_close_all
    object = mock
    object.expects(:each).yields(object)
    object.expects(:__close__)
    cls.expects(:objects).returns(object)
    cls.close_all
  end

  def test_open_opened
    inst = cls.new(nil)
    inst.expects(:__opened__?).returns(true)
    inst.expects(:__try_open__).never
    assert inst.__open__(nil)
  end

  def test_open_closed
    inst = cls.new(nil)
    inst.stubs(:__opened__?).returns(false, :opened)
    inst.expects(:__try_open__).with(:conn_str)
    assert_equal :opened, inst.__open__(:conn_str)
    assert_equal [inst], cls.objects
  end

  def test_try_open
    ole = mock
    ole.expects(:ole).returns(ole)
    ole.expects(:connect).with(:conn_str.to_s).returns(true)
    inst = cls.new nil
    inst.expects(:__ole_binary__).returns(ole)
    inst.send(:__try_open__, :conn_str)
    assert inst.__opened__?
  end

  def test_try_open_failure
    ole = mock
    ole.expects(:ole).returns(ole)
    ole.expects(:connect).returns(false)
    inst = cls.new nil
    inst.expects(:__ole_binary__).returns(ole)
    assert_raises AssLauncher::Enterprise::Ole::ApplicationConnectError do
      inst.send(:__try_open__, :conn_str)
    end
    refute inst.__opened__?
  end

  def test_ole
    ole = mock
    ole.expects(:ole).returns(:ole)
    inst = cls.new nil
    inst.expects(:__ole_binary__).returns(ole)
    assert_equal :ole, inst.send(:__ole__)
  end

  def test_opened?
    inst = cls.new nil
    inst.instance_variable_set(:@opened, :opened)
    assert_equal :opened, inst.__opened__?
  end

  def test_closed?
    inst = cls.new nil
    inst.expects(:__opened__?).returns(false)
    assert inst.__closed__?
  end

  def test_close_closed
    inst = cls.new nil
    inst.expects(:__closed__?).returns(true)
    inst.expects(:__ole__).never
    assert inst.__close__
  end

  def test_close_opened
    ole = mock
    ole.expects(:terminate)
    inst = cls.new nil
    inst.instance_variable_set(:@opened, true)
    inst.expects(:__ole__).returns(ole)
    assert inst.__close__
    assert inst.__closed__?
  end

  def test_close_failure_until_terminate
    ole = mock
    ole.expects(:terminate).raises(RuntimeError)
    inst = cls.new nil
    inst.instance_variable_set(:@opened, true)
    inst.expects(:__ole__).returns(ole)
    assert inst.__close__
    assert inst.__closed__?
  end
end

class OleThickApplicationTest < Minitest::Test
  include LikeHaveOleBinaryTest
  def setup
    @ole_binary_class = AssLauncher::Enterprise::Ole::OleBinaries::ThickApplication
  end

  def cls
    AssLauncher::Enterprise::Ole::ThickApplication
  end
end
