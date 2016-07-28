require 'test_helper'

class WIN32OLETest < Minitest::Test
  module WIN32OLE_Linux
    AssLauncher::Support::Platforms.expects(:linux?).returns(true)
    eval File.read(File.expand_path(
      '../../../../../lib/ass_launcher/enterprise/ole/win32ole.rb',
      __FILE__
    ))
    #AssLauncher::Support::Platforms.unstub
  end

  module WIN32OLE_Windows
    AssLauncher::Support::Platforms.expects(:linux?).returns(false)
    eval File.read(File.expand_path(
      '../../../../../lib/ass_launcher/enterprise/ole/win32ole.rb',
      __FILE__
    ))
    #AssLauncher::Support::Platforms.unstub
  end

  def cls
    Class.new(WIN32OLE) do
      def initialize(*_)

      end
    end
  end

  def test_initialize_in_windows
    assert WIN32OLE_Windows::WIN32OLE.instance_variable_get(:@win32ole_loaded)
  end

  def test_initialize_in_linux
    assert_raises NotImplementedError do
      WIN32OLE_Linux::WIN32OLE.new(nil)
    end
  end

  def test_objects
    inst = cls.new
    assert_equal [], inst.__objects__
  end

  def test_ruby?
    WIN32OLE.any_instance.expects(:ole_respond_to?).with(:object_id).returns(:yes)
    inst = cls.new
    assert_equal :yes, inst.__ruby__?
  end

  def test_real_object_ruby
    WIN32OLE.any_instance.expects(:__ruby__?).returns(true)
    WIN32OLE.any_instance.expects(:invoke).with(:object_id).returns(:ruby_object)
    ObjectSpace.expects(:_id2ref).with(:ruby_object).returns(:object)
    inst = cls.new
    assert_equal :object, inst.__real_obj__
  end

  def test_real_object_not_ruby
    inst = cls.new
    WIN32OLE.any_instance.expects(:__ruby__?).returns(false)
    assert_equal inst, inst.__real_obj__
  end

  def test_ass_ole_free
    inst = cls.new
    WIN32OLE.any_instance.expects(:__ass_ole_free_objects__).returns(:free_objects)
    WIN32OLE.expects(:__ass_ole_free__).with(inst)
    inst.__ass_ole_free__
    assert_equal :free_objects, inst.__objects__
  end

  def test_ass_ole_free_objects
    object = mock()
    object.expects(:is_a?).with(WIN32OLE).returns(true)
    object.expects(:__ass_ole_free__)
    objects = mock
    objects.expects(:each).yields(object)
    inst = cls.new
    WIN32OLE.any_instance.expects(:__objects__).returns(objects)
    inst = cls.new
    assert_nil inst.send(:__ass_ole_free_objects__)
  end

  def test_class_ass_ole_free
    inst = cls.new
    WIN32OLE.expects(:ole_reference_count).with(inst).returns(1)
    inst.expects(:ole_free).returns(true)
    assert WIN32OLE.__ass_ole_free__(inst)
  end

  def cls_linux
    Class.new(WIN32OLE_Linux::WIN32OLE) do
      def initialize(*_); end
    end
  end

  def test_method_missing
    object = mock
    object.expects(:is_a?).with(WIN32OLE_Linux::WIN32OLE).returns(true)
    inst = cls_linux.new
    assert_equal object, inst.fake_method(object)
    assert_equal [object], inst.__objects__
  end

  def test_smoky
    skip('NotImplemented in Linux') if FFI::Platform.linux?
    app = WIN32OLE.new('Scripting.Dictionary')
    assert_equal [], app.__objects__
  end
end
