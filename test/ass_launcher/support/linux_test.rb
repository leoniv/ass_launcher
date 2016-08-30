require 'test_helper'

class LinuxUtilsTest < Minitest::Test

  def mod
    AssLauncher::Support::Linux
  end

  def deb
    AssLauncher::Support::Linux::Deb
  end

  def rpm
    AssLauncher::Support::Linux::Rpm
  end

  def test_current_pkg_manager_deb
    deb.expects(:manager?).returns(true)
    rpm.expects(:manager?).never
    assert_equal deb, mod.current_pkg_manager
  end

  def test_current_pkg_manager_rpm
    deb.expects(:manager?).returns(false)
    rpm.expects(:manager?).returns(true)
    assert_equal rpm, mod.current_pkg_manager
  end

  def test_current_pkg_manager_nil
    deb.expects(:manager?).returns(false)
    rpm.expects(:manager?).returns(false)
    assert_nil mod.current_pkg_manager
  end

  def test_pkg_manager
    mod.instance_variable_set(:@pkg_manager, nil)
    mod.expects(:current_pkg_manager).returns(:fake_pkg_manager)
    assert_equal :fake_pkg_manager, mod.pkg_manager
    assert_equal :fake_pkg_manager, mod.pkg_manager
    mod.instance_variable_set(:@pkg_manager, nil)
  end

  def test_get_pkg_version
    manager = mock
    manager.expects(:version).with(:path).returns(:version)
    mod.expects(:pkg_manager).returns(manager).twice
    assert_equal :version, mod.get_pkg_version(:path)
  end

  def test_get_pkg_version_fail
    mod.expects(:pkg_manager).returns(nil)
    assert_raises NotImplementedError do
      mod.get_pkg_version(:path)
    end
  end

  def test_rpm?
    mod.expects(:pkg_manager).returns(rpm)
    assert mod.rpm?
  end

  def test_deb?
    mod.expects(:pkg_manager).returns(deb)
    assert mod.deb?
  end
end

module LinuxPkgManagerTest

  def test_manager?
    mod.expects(:`).with(@manager_command).returns("out")
    assert mod.manager?
  end

  def test_not_manager?
    mod.expects(:`).with(@manager_command).raises(Errno::ENOENT)
    refute mod.manager?
  end

  def test_pkg
    mod.expects(:`).with(@pkg_command).returns(@pkg_command_returns)
    assert_equal @pkg_name, mod.pkg(@file_path)
  end

  def test_version
    mod.expects(:pkg).with(@file_path).returns(@pkg_name)
    mod.expects(:`).with(@pkg_version_command).returns(@pkg_version_returns)
    assert_equal @pkg_version_result, mod.version(@file_path)
  end

  # :nocov:
  def test_smoky
    skip "Isn\'t #{mod.name} Linux disrib" unless mod.manager?
    assert_instance_of Gem::Version, mod.version('/bin/ls')
  end
  # :nocov:
end

class LinuxiDebTest < Minitest::Test
  include LinuxPkgManagerTest
  def mod
    AssLauncher::Support::Linux::Deb
  end

  def setup
    @manager_command = 'dpkg --version'
    @file_path = :file_path
    @pkg_command = "dpkg -S #{@file_path}"
    @pkg_name = 'packge-name'
    @pkg_command_returns = "#{@pkg_name}: #{@file_path}\n"
    @pkg_version_command = "apt-cache policy #{@pkg_name} | grep -i installed:"
    @pkg_version_returns = "  Installed: 8.3.6-2421"
    @pkg_version_result = Gem::Version.new('8.3.6.2421')
  end

end

class LinuxiRpmTest < Minitest::Test
  include LinuxPkgManagerTest
  def mod
    AssLauncher::Support::Linux::Rpm
  end

  def setup
    @manager_command = 'rpm --version'
    @file_path = :file_path
    @pkg_command = "rpm -qf #{@file_path}"
    @pkg_name = 'packge-name'
    @pkg_command_returns = "#{@pkg_name}\n"
    @pkg_version_command = "rpm -q --queryformat '%{RPMTAG_VERSION}.%{RPMTAG_RELEASE}' #{@pkg_name}"
    @pkg_version_returns = "8.3.6.2421"
    @pkg_version_result = Gem::Version.new('8.3.6.2421')
  end
end
