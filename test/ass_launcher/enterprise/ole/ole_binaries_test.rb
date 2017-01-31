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

module LikeAssOleBinaryTest
  attr_reader :cls
  def inst_stub(version = '0')
    cls.any_instance.expects(:linux?).returns(false)
    cls.new(version)
  end

  def test_binary
    assert_equal @binary, inst_stub.send(:binary)
  end

  def test_prog_id
    inst = inst_stub
    inst.expects(:v8x).returns(@v8x)
    assert_equal @prog_id, inst.send(:prog_id)
  end

  def test__binary_wrapper
    inst = inst_stub
    inst.expects(:requirement).returns(:requirement)
    AssLauncher::Enterprise.expects(@binary_wrapper)
      .with(:requirement.to_s)
      .returns([1,3,2])
    assert_equal 3, inst.send(:_binary_wrapper)
  end
end

class COMConnectorTest < Minitest::Test

  include LikeAssOleBinaryTest

  def inst_stub(version = '0')
    cls.any_instance.expects(:linux?).returns(false)
    cls.any_instance.expects(:x32_arch?).returns(true)
    cls.new(version)
  end

  def setup
    @binary = 'comcntr.dll'
    @v8x = '69'
    @prog_id = 'v69.COMConnector'
    @cls = AssLauncher::Enterprise::Ole::OleBinaries::COMConnector
    @binary_wrapper = :thick_clients
  end

  def test_initialize_fail
    cls.any_instance.expects(:x32_arch?).returns(false)
    e = assert_raises RuntimeError do
      cls.new('> 0')
    end
    assert_match %r{v8x\.COMConnector unavailable}, e.message
  end

  def reg_unreg_server_inst(mode, key)
    inst = inst_stub
    inst.expects(:reg_unreg_server).with(key).returns(:childe_status)
    inst.expects(:fail_reg_unreg_server).with(mode, :childe_status)
      .returns(:success)
    inst
  end

  def test_reg_server_sucsess
    inst = reg_unreg_server_inst 'register', 'i'
    assert_equal :success, inst.send(:reg_server)
  end

  def test_unreg_server
    inst = reg_unreg_server_inst 'unregister', 'u'
    assert_equal :success, inst.send(:unreg_server)
  end

  def test_reg_unreg_server
    path = mock
    path.expects(:win_string).returns(:fake_path.to_s)
    inst = inst_stub
    inst.expects(:path).returns(path)
    inst.expects(:`).with('regsvr32 /mode /s "fake_path"')
    inst.expects(:childe_status).returns(:childe_status)
    assert_equal :childe_status, inst.send(:reg_unreg_server, :mode)
  end

  def test_childe_status
    inst = inst_stub
    assert_equal $CHILD_STATUS, inst.send(:childe_status)
  end

  def test_fail_reg_unreg_server
    inst = inst_stub
    status = mock
    status.expects(:success?).returns(true)
    assert_equal status, inst.send(:fail_reg_unreg_server,'',status)

    status.expects(:success?).returns(false)
    status.expects(:win_string).returns(:fake_path)
    inst.expects(:path).returns(status)
    assert_raises RuntimeError do
      inst.send(:fail_reg_unreg_server, 'message', status)
    end
  end

  def test_clsids
    assert_instance_of Hash, inst_stub.send(:clsids)
  end

  def test_const_x32_archs
    assert_equal ['i386-mingw32', 'i386-cygwin'], @cls::X32_ARCHS
  end

  def inst_fake
    Class.new(cls) do
      def initialize

      end
    end.new
  end

  def test_arch
    inst = inst_fake
    refute inst.arch.to_s.empty?
    assert_equal RbConfig::CONFIG['arch'], inst.arch
  end

  def test_x32_arch_true_if_cygwin
    inst = inst_fake
    inst.expects(:arch).returns('i386-cygwin')
    assert inst.x32_arch?
  end

  def test_x32_arch_true_if_mingw
    inst = inst_fake
    inst.expects(:arch).returns('i386-mingw32')
    assert inst.x32_arch?
  end

  def test_x32_arch_false
    inst = inst_fake
    inst.expects(:arch).returns('x86_64-cygwin')
    refute inst.x32_arch?
  end
end

module LikeAssOleBinaryAppliactionTest
  def test_run_as_enterprise
    command = mock
    command.expects(:run).returns(command)
    command.expects(:wait).returns(command)
    command.expects(:result).returns(command)
    command.expects(:verify!).returns(:success)
    binary_wrapper = mock
    binary_wrapper.expects(:command).with(*@run_as_enterprise_args).returns(command)
    inst = inst_stub
    inst.expects(:binary_wrapper).returns(binary_wrapper)
    assert_equal :success, inst.send(:run_as_enterprise, @run_as_enterprise_args.last)
  end
end

class ThickApplicationTest < Minitest::Test

  include LikeAssOleBinaryTest

  def setup
    @binary = '1cv8.exe'
    @v8x = '69'
    @prog_id = 'v69.Application'
    @cls = AssLauncher::Enterprise::Ole::OleBinaries::ThickApplication
    @binary_wrapper = :thick_clients
    @run_as_enterprise_args = [:enterprise, :args]
  end

  def test_reg_server_version_less_8_3_9
    inst = inst_stub('0')
    inst.expects(:version).returns(Gem::Version.new('8.3.8'))
    inst.expects(:run_as_enterprise).with(['/regserver']).returns(:success)
    assert_equal :success, inst.send(:reg_server)
  end

  def test_reg_server_version_from_8_3_9
    inst = inst_stub('8.3.9')
    inst.expects(:version).returns(Gem::Version.new('8.3.9'))
    inst.expects(:run_as_enterprise).with(['/regserver', '-currentuser'])\
      .returns(:success)
    assert_equal :success, inst.send(:reg_server)
  end

  def test_unreg_server
    inst = inst_stub
    inst.expects(:run_as_enterprise).with(['/unregserver']).returns(:success)
    assert_equal :success, inst.send(:unreg_server)
  end
  include LikeAssOleBinaryAppliactionTest
end

class ThinApplicationTest < Minitest::Test
  include LikeAssOleBinaryTest
  include LikeAssOleBinaryAppliactionTest
  def setup
    @binary = '1cv8c.exe'
    @v8x = '69'
    @prog_id = 'v69c.Application'
    @cls = AssLauncher::Enterprise::Ole::OleBinaries::ThinApplication
    @binary_wrapper = :thin_clients
    @run_as_enterprise_args = [:args]
  end
end
