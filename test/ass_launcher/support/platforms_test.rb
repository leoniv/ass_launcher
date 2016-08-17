require 'test_helper'

class PlatformsTest < Minitest::Test
  def test_ffi_platform
    assert_respond_to AssLauncher::Platform, :cygwin?
    assert_equal AssLauncher::Platform::IS_CYGWIN, AssLauncher::Platform.cygwin?
    assert_respond_to AssLauncher::Platform, :windows?
    assert_equal AssLauncher::Platform::IS_WINDOWS, AssLauncher::Platform.windows?
    assert_respond_to AssLauncher::Platform, :linux?
    assert_equal AssLauncher::Platform::IS_LINUX, AssLauncher::Platform.linux?
  end

  def mod
    AssLauncher::Support::Platforms
  end

  def cls_include_mod
    Class.new do
      include AssLauncher::Support::Platforms
    end.new
  end

  def test_class_include_mod_metods?
    %w(cygwin? windows? linux?).map(&:to_sym).each do |method|
      AssLauncher::Platform.expects(method).returns('fake value')
      assert_equal 'fake value', cls_include_mod.send(method)
    end
  end

  def test_mod_metods?
    %w(cygwin? windows? linux?).map(&:to_sym).each do |method|
      AssLauncher::Platform.expects(method).returns('fake value')
      assert_equal 'fake value', mod.send(method)
    end
  end

  def test_platform
    assert_equal mod, cls_include_mod.send(:platform)
  end

  def test_path_class
    mod.expects(:cygwin?).returns(true)
    assert_equal AssLauncher::Support::Platforms::PathnameExt::CygPath, mod.path_class
    mod.expects(:cygwin?).returns(false)
    mod.expects(:windows?).returns(true)
    assert_equal AssLauncher::Support::Platforms::PathnameExt::WinPath, mod.path_class
    mod.expects(:cygwin?).returns(false)
    mod.expects(:windows?).returns(false)
    assert_equal AssLauncher::Support::Platforms::PathnameExt::UnixPath, mod.path_class
  end

  def test_path
    mock_path_class = mock()
    mock_path_class.expects(:new).with('fake path').returns('fake path')
    mod.expects(:path_class).returns(mock_path_class)
    assert_equal 'fake path', mod.path('fake path')
  end

  def test_glob
    mock_path_class = mock()
    mock_path_class.expects(:glob).with('fake path', %w'arg1 arg2').returns('fake glob value')
    mod.expects(:path_class).returns(mock_path_class)
    assert_equal 'fake glob value', mod.glob('fake path', %w'arg1 arg2')
  end

  def test_env
    mod.expects(:cygwin?).returns(true)
    assert_equal AssLauncher::Support::Platforms::CygEnv, mod.env
    mod.expects(:cygwin?).returns(false)
    mod.expects(:windows?).returns(true)
    assert_equal AssLauncher::Support::Platforms::WinEnv, mod.env
    mod.expects(:cygwin?).returns(false)
    mod.expects(:windows?).returns(false)
    assert_equal AssLauncher::Support::Platforms::UnixEnv, mod.env
  end
end

class UnixEnvTest < Minitest::Test
  def cls
    AssLauncher::Support::Platforms::UnixEnv
  end

  def test_brakets
    assert_instance_of Array, cls[/./]
  end
end

class PathnameExtTest < Minitest::Test

  def cls
    AssLauncher::Support::Platforms::PathnameExt
  end

  def test_initialize
    mock_object = mock()
    cls.any_instance.expects(:mixed_path).with('path string').returns('path string')
    mock_object.expects(:to_s).returns(mock_object)
    mock_object.expects(:strip).returns('path string')
    assert_instance_of cls, cls.new(mock_object)
  end

  def test_methods_should_returns_right_class_instance
    #metod #+(other)
    assert_instance_of cls, (cls.new('.') + '1')
    assert_equal '../1', (cls.new('..') + '1').to_s
    #method #join
    assert_instance_of cls, cls.new('.').join('1','2','3')
    #method #parent
    assert_instance_of cls, cls.new('.').parent
    #method ::glob
    arr = cls.glob(__FILE__.tr('/','\\'))
    assert_equal 1, arr.size
    assert_instance_of cls, arr[0]
  end

  def test_cls_glob
    String.any_instance.expects(:tr).with('\\','/').returns('mixed path')
    Pathname.expects(:glob).with('mixed path', 'arg1', 'arg2').returns('fake glob')
    assert_equal 'fake glob', cls.glob('string', 'arg1', 'arg2')
  end

  def test_win_string
    assert_equal '\\\\host\\share', cls.new('//host/share').win_string
  end

  def test_mixed_path
    assert_equal 'C:/mixed/path', cls.new('').send(:mixed_path, 'C:\\mixed\\path')
  end
end

class WinPathTest < Minitest::Test
  def cls
    AssLauncher::Support::Platforms::PathnameExt::WinPath
  end

  def test_initialize
    assert_equal 'C:/mixed/path', cls.new('C:\\mixed\\path').to_s
  end
end

class UnixPathTest < Minitest::Test
  def cls
    AssLauncher::Support::Platforms::PathnameExt::UnixPath
  end

  def test_initialize
    assert_equal '//host/share', cls.new('\\\\host\\share').to_s
  end

  def test_win_string
    AssLauncher::Support::Platforms::PathnameExt.any_instance.expects(:win_string).never
    assert_equal 'path', cls.new('path').win_string
  end
end

class CygPathTest < Minitest::Test

  def cls
    AssLauncher::Support::Platforms::PathnameExt::CygPath
  end

  def test_initialize
    cls.any_instance.expects(:mixed_path).with('fake path').returns('fake path')
    assert_equal 'fake path', cls.new('fake path').to_s
  end

  def test_cls_cygpath
    %w(m u w).map(&:to_sym).each do |flag|
      String.any_instance.expects(:escape).returns('path')
      String.any_instance.expects(:chomp).returns('chomp path')
      cls.expects(:exitstatus).returns(0)
      cls.expects(:"`").with("cygpath -#{flag} path 2>&1").returns("path")
      assert_equal 'chomp path', cls.cygpath('path', flag)
    end
  end

  # TODO extract shell call into Shell module
  def test_cls_cygpath_fail_with_shell_run_error
    String.any_instance.expects(:escape).returns('path')
    String.any_instance.expects(:chomp).returns('chomp path')
    cls.expects(:exitstatus).returns(1)
    cls.expects(:"`").returns('out')
    assert_raises AssLauncher::Support::Shell::RunError do
      cls.cygpath('path', :m)
    end
  end

  # TODO extract shell call into Shell module
  def test_cls_exitstatus_fail
    skip 'TODO extract shell call into Shell module'
  end

  def test_cls_cygpath_fail_with_argument_error
    assert_raises ArgumentError do
      cls.cygpath('path', :bad_flag)
    end
  end

  def cygwin?
    RUBY_PLATFORM.match('cygwin')
  end

  def test_real_cygpath
    skip 'Runing on not Cygwin platform. Skiped' unless cygwin?
    assert_equal 'Q:/', cls.cygpath('/cygdrive/q', :m)
  end

  def test_cygpath
    cls.any_instance.expects(:mixed_path).returns('fake path')
    inst = cls.new('')
    cls.expects(:cygpath).with('arg1', 'arg2')
    inst.cygpath('arg1', 'arg2')
  end

  def test_mixed_path
    cls.any_instance.expects(:cygpath).with('fake path', :m).returns('fake path')
    cls.new('fake path')
  end

  def test_glob
    cls.expects(:cygpath).with('fake path', :u).returns('fake path')
    AssLauncher::Support::Platforms::PathnameExt.expects(:glob).with('fake path', 'arg1', 'arg2').returns('fake glob')
    cls.glob('fake path', 'arg1', 'arg2')
  end
end
