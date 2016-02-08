require 'test_helper'

class EnterpriseTest < Minitest::Test
  def mod
    AssLauncher::Enterprise
  end

  def test_extended_of_platforms_module
    assert mod.singleton_class.include? AssLauncher::Support::Platforms
  end

  def test_windows_or_cygwin_in_cygwin
    AssLauncher::Support::Platforms.expects(:cygwin?).returns(true)
    assert mod.send(:windows_or_cygwin?)
  end

  def test_windows_or_cygwini_in_windows
    AssLauncher::Support::Platforms.expects(:cygwin?).returns(false)
    AssLauncher::Support::Platforms.expects(:windows?).returns(true)
    assert mod.send(:windows_or_cygwin?)
  end

  def test_linux?
    AssLauncher::Support::Platforms.expects(:linux?).returns(true)
    assert mod.send(:linux?)
  end

  def test_search_paths
    %w(windows_or_cygwin linux).map(&:to_sym).each do |p|
      mock_platform = mock()
      mock_env = mock()
      if p == :windows_or_cygwin
        mod.expects(:platform).returns(mock_platform)
        mock_platform.expects(:env).returns(mock_env)
        mock_env.expects(:"[]").with(/ASSPATH/i).returns('asspath')
        mod.expects(:windows_or_cygwin?).returns(p == :windows_or_cygwin)
        mod.expects(:platform).returns(mock_platform)
        mock_platform.expects(:env).returns(mock_env)
        mock_env.expects(:"[]").with(/\Aprogram\s*files.*/i).returns(%w'path1 path2')
        assert_equal %w'asspath path1/1c* path2/1c*', mod.search_paths
      else
        mod.expects(:platform).returns(mock_platform)
        mock_platform.expects(:env).returns(mock_env)
        mod.expects(:windows_or_cygwin?).returns(p == :windows_or_cygwin)
        mod.expects(:linux?).returns(p == :linux)
        mock_env.expects(:"[]").with(/ASSPATH/i).returns('asspath')
        assert_equal %w'asspath /opt/1C /opt/1c', mod.search_paths
      end
    end
  end

  def test_find_clients
    mock_klass = mock()
    mod.expects(:find_binaries).with('fake_binary_name').returns(%w'bp1 bp2 pb3')
    mod.expects(:binaries).with(mock_klass).returns('fake_binary_name')
    mock_klass.expects(:new).returns('bin_wrapper').times(3)
    assert_equal Array.new(3, 'bin_wrapper'), mod.send(:find_clients, mock_klass)
  end

  def test_requirement?
    mock = mock()
    mock.expects(:version).returns(Gem::Version.new('1.0.1'))
    assert mod.send(:requiremet?, mock, '~> 1.0')
    assert mod.send(:requiremet?, mock, '')
  end

  def test_find_binaries_empty
    assert_equal [], mod.send(:find_binaries,'')
    mod.expects(:search_paths).returns([])
    assert_equal [], mod.send(:find_binaries,'basename')
  end

  def test_find_binaries
    mock_platform = mock()
    mod.expects(:platform).returns(mock_platform).times(3)
    mock_platform.expects(:glob).with('path/**/basename').returns(%w'path/path/basename').times(3)
    mod.expects(:search_paths).returns(%w'path path path')
    assert_equal Array.new(3, 'path/path/basename'), mod.send(:find_binaries, 'basename')
  end

  def test_thin_clients
    mod.expects(:find_clients).with(AssLauncher::Enterprise::BinaryWrapper::ThinClient).returns(%w'fake_client_v1 fake_client_v2')
    mod.expects(:requiremet?).returns(true).twice
    assert_equal %w'fake_client_v1 fake_client_v2', mod.thin_clients
  end

  def test_thick_clients
    mod.expects(:find_clients).with(AssLauncher::Enterprise::BinaryWrapper::ThickClient).returns(%w'fake_client_v1 fake_client_v2')
    mod.expects(:requiremet?).returns(true).twice
    assert_equal %w'fake_client_v1 fake_client_v2', mod.thick_clients
  end

  def test_binaries_on_windows
    { AssLauncher::Enterprise::BinaryWrapper::ThinClient => '1cv8c.exe',
      AssLauncher::Enterprise::BinaryWrapper::ThickClient => '1cv8.exe' }.each do |klass, bin_name|
      mod.expects(:windows_or_cygwin?).returns(true)
      assert_equal bin_name, mod.binaries(klass)
    end
  end

  def test_binaries_on_linux
    { AssLauncher::Enterprise::BinaryWrapper::ThinClient => '1cv8c',
      AssLauncher::Enterprise::BinaryWrapper::ThickClient => '1cv8' }.each do |klass, bin_name|
      mod.expects(:windows_or_cygwin?).returns(false)
      mod.expects(:linux?).returns(true)
      assert_equal bin_name, mod.binaries(klass)
    end
  end

  def test_binaries_on_other
    { AssLauncher::Enterprise::BinaryWrapper::ThinClient => nil,
      AssLauncher::Enterprise::BinaryWrapper::ThickClient => nil }.each do |klass, bin_name|
      mod.expects(:windows_or_cygwin?).returns(false)
      mod.expects(:linux?).returns(false)
      assert_equal bin_name, mod.binaries(klass)
    end
  end

  def test_web_client
    AssLauncher::Enterprise::WebClients.expects(:client).with(:fake_client).returns(:fake_class)
    assert_equal :fake_class, mod.web_client(:fake_client)
  end
end
