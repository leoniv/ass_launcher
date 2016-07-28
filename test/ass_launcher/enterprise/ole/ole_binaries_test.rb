require 'test_helper'

class AbstractAssOleBinaryTest < Minitest::Test

  def cls
    AssLauncher::Enterprise::Ole::OleBinaries::AbstractAssOleBinary
  end

  def inst_stub
    cls.any_instance.expects(:linux?).returns(false)
    cls.new('0')
  end

  def test_initialize_windows
    cls.any_instance.expects(:linux?).returns(false)
    inst = cls.new('=0')
    assert_equal Gem::Version::Requirement.new('=0'), inst.requirement
  end

  def test_initialize_linux
    cls.any_instance.expects(:linux?).returns(true)
    assert_raises NotImplementedError do
      cls.new ''
    end
  end

  def test_ole
    inst = inst_stub
    inst.expects(:new_ole).returns(:ole)
    assert_equal :ole, inst.ole
  end

  def test_new_ole
    inst = inst_stub
    inst.expects(:reg)
    inst.expects(:prog_id).returns(:fake_ole)
    WIN32OLE.expects(:new).with(:fake_ole).returns(:ole)
    assert_equal :ole, inst.send(:new_ole)
  end

  def test_v8x
    inst = inst_stub
    inst.expects(:instaled_version).returns('8.3')
    assert_equal '83', inst.send(:v8x)
  end

  def test_instaled_version
    bw = mock
    bw.expects(:version).returns(:version)
    inst = inst_stub
    inst.expects(:binary_wrapper).returns(bw).twice
    assert_equal :version, inst.instaled_version
  end

  def test_binary_wrapper
    inst = inst_stub
    inst.expects(:_binary_wrapper).returns(:bw)
    assert_equal :bw, inst.send(:binary_wrapper)
  end

  def test__binary_wrapper
    assert_raises RuntimeError do
      inst_stub.send(:_binary_wrapper)
    end
  end

  def test_registred_version
    assert_raises NotImplementedError do
      inst_stub.send(:registred_version)
    end
  end

  def test_not_instaled?
    inst = inst_stub
    inst.expects(:version).returns(nil)
    refute inst.instaled?
  end

  def test_instaled?
    requirement = mock
    requirement.responds_like(Gem::Version::Requirement.new('0'))
    requirement.expects(:satisfied_by?).with(:version).returns(true)
    inst = inst_stub
    inst.expects(:version).returns(:version).twice
    inst.expects(:requirement).returns(requirement)
    inst.expects(:path).returns(__FILE__)
    assert inst.instaled?
  end


  def test_registred?
    refute inst_stub.send(:registred?)
  end

  def test_reg_if_registred
    inst = inst_stub
    inst.expects(:registred?).returns(true)
    inst.expects(:instaled?).never
    assert inst.reg
  end

  def test_reg_fail
    inst = inst_stub
    inst.expects(:registred?).returns(false)
    inst.expects(:instaled?).returns(false)
    assert_raises RuntimeError do
      inst.reg
    end
  end

  def test_reg
    inst = inst_stub
    inst.expects(:registred?).returns(false)
    inst.expects(:instaled?).returns(true)
    inst.expects(:reg_server).returns(true)
    assert inst.reg
  end

  def test_reg_server
    assert_raises RuntimeError do
      inst_stub.send :reg_server
    end
  end

  def test_unreg_not_registred
    inst = inst_stub
    inst.expects(:registred?).returns(false)
    inst.expects(:instaled?).never
    assert inst.unreg
  end

  def test_unreg_fail
    inst = inst_stub
    inst.expects(:registred?).returns(true)
    inst.expects(:instaled?).returns(false)
    assert_raises RuntimeError do
      inst.unreg
    end
  end

  def test_unreg
    inst = inst_stub
    inst.expects(:registred?).returns(true)
    inst.expects(:instaled?).returns(true)
    inst.expects(:unreg_server).returns(true)
    assert inst.unreg
  end

  def test_unreg_server
    assert_raises RuntimeError do
      inst_stub.send :unreg_server
    end
  end

  def test_path
    inst = inst_stub
    inst.expects(:_path).returns(:path)
    assert_equal :path, inst.send(:path)
  end

  def test__path_nil
    inst = inst_stub
    inst.expects(:binary_wrapper).returns(nil)
    refute inst.send(:_path)
  end

  def test_binary
    assert_raises RuntimeError do
      inst_stub.send :binary
    end
  end

  def test__path
    bw = mock
    bw.expects(:path).returns(bw)
    bw.expects(:dirname).returns(:dirname)
    platform = mock
    platform.expects(:path).with('dirname/binary').returns(:path)
    inst = inst_stub
    inst.expects(:binary_wrapper).returns(bw).twice
    inst.expects(:platform).returns(platform)
    inst.expects(:binary).returns(:binary.to_s)
    assert_equal :path, inst.send(:_path)
  end

  def test_clsid
    inst = inst_stub
    inst.expects(:v8x).returns('82')
    inst.expects(:clsids).returns({'82'=>:clsid})
    assert_equal :clsid, inst.send(:clsid)
  end

  def test_clsids
    assert_raises RuntimeError do
      inst_stub.send :clsids
    end
  end
end
