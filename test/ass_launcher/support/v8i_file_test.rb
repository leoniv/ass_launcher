# coding: utf-8
require 'test_helper'

class V8iTest < Minitest::Test
  BOM = "\xEF\xBB\xBF"

  def setup
    @tmp_dir = 'v8i_test.tmp'
  end

  def teardown
    FileUtils.rm_r @tmp_dir if File.exist? @tmp_dir
  end

  def write_file(filename, content)
    File.new(tmp_file(filename), 'w').write(content)
    tmp_file(filename)
  end

  def tmp_file(filename)
    FileUtils.mkdir_p @tmp_dir
    File.join(@tmp_dir, filename)
  end

  def v8i_good
    s = ''
    s << BOM+'[InfoBase1 caption]'+"\r\n"
    s << 'Connect=Srvr="host.name";Ref="info_base1";'+"\r\n"
    s << 'Field1=Value of f1'+"\r\n"
    s << 'Field2=Value of f2'+"\r\n"
    s << "\r\n"
    s << '[InfoBase2 caption]'+"\r\n"
    s << 'Connect=Srvr="host.name";Ref="info_base2";'+"\r\n"
    s << 'Field1=Value of f1'+"\r\n"
    s << 'Field2=Value of f2'+"\r\n"
    s << ''+"\r\n"
  end

  def section_fields(n)
    {'Connect' => "Srvr=\"host.name\";Ref=\"info_base#{n}\";",
     'Field1' => 'Value of f1',
     'Field2' => 'Value of f2',
    }
  end

  def caption(n)
    "InfoBase#{n} caption"
  end

  def mod
    AssLauncher::Support::V8iFile
  end

  def test_read_good
    AssLauncher::Support::V8iSection.expects(:new).with(caption(1),section_fields(1)).returns('fake1')
    AssLauncher::Support::V8iSection.expects(:new).with(caption(2),section_fields(2)).returns('fake2')

    sections = mod.read(StringIO.new(v8i_good))
    assert_instance_of Array, sections
    assert_equal ['fake1', 'fake2'], sections
  end

  def test_write
    mock = mock()
    mock.expects(:to_s).returns('fake').times(2)
    sections = [mock, mock]
    io = StringIO.new
    mod.write(io, sections)
    io.pos = 0
    assert_equal "fake\r\nfake\r\n", io.read
  end

  def test_load
    AssLauncher::Support::V8iFile.expects(:read).with() do |io|
      io.read
    end
    mod.load(write_file('some.v8i', v8i_good))
  end

  def test_save
    AssLauncher::Support::V8iFile.expects(:write).with() do |io, sections|
      io.write('0')
      assert_equal :sections, sections
    end
    mod.save(tmp_file('some.v8i'), :sections)
  end
end
