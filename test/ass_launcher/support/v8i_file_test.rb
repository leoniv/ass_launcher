# coding: utf-8
require 'test_helper'

class V8iTest < Minitest::Test
  BOM = "\xEF\xBB\xBF"

  def v8i_good
    BOM+'
    [InfoBase1 caption]
    Connect=Srvr="host.name";Ref="info_base1";
    Field1=Value of f1
    Field2=Value of f2

    [InfoBase2 caption]
    Connect=Srvr="host.name";Ref="info_base2";
    Field1=Value of f1
    Field2=Value of f2
    '
  end

  def v8i_bad_without_caption
    'F1=0
    [Caption]'
  end

  def section_fields(n)
    {Caption: "InfoBase#{n} caption",
     Connect: "Srvr=\"host.name\";Ref=\"info_base#{n}\";",
     Field1: 'Value of f1',
     Field2: 'Value of f2',
    }
  end

  def mod
    AssLauncher::Support::V8iFile
  end

  def test_read_good
    AssLauncher::Support::V8iSection.expects(:new).with(section_fields(1)).returns('fake1')
    AssLauncher::Support::V8iSection.expects(:new).with(section_fields(1)).returns('fake2')

    sections = mod.read(StringIO.new(v8i_good))
    assert_instance_of Array, sections
    assert_equal ['fake1', 'fake2'], sections
  end

  def test_read_bad
    assert_raises AssLauncher::Support::V8iFile::ReadError do
      mod.read(StringIO.new(v8i_bad_without_caption))
    end
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
end
