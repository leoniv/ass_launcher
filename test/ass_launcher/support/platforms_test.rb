require 'test_helper'

class StringTest < Minitest::Test
  def test_escape
    string = 'string'
    Shellwords.expects(:escape).with(string).returns(string)
    assert_equal 'string', string.escape
  end
end

class PlatformsTest < Minitest::Test
  def test_ffi_platform
    assert_respond_to FFI::Platform, :cygwin?
    assert_equal FFI::Platform::IS_CYGWIN, FFI::Platform.cygwin?
  end
end

class PathnameExtTest < Minitest::Test

  def test_initialize_on_string
    skip
  end

  def test_initialize_on_object
    skip
    raise 'FIXME'
  end

  def test_returns_right_class_instance
    #metod #+(other)
    skip
    #method #join
    skip
    #method #parent
    skip
    #method ::glob
    skip
  end
end

class CygPathTest < Minitest::Test

  def cls
    AssLauncher::Support::Platforms::CygPath
  end

  def test_initialize_on_other_inst
    assert_instance_of cls, cls.new(cls.new('.'))
  end
end
