# coding: utf-8
require 'test_helper'

class V8iSectionTest < Minitest::Test

  def cls
    AssLauncher::Support::V8iSection
  end

  def test_new_good
    section = cls.new('caption', 'Connect' => 'conn_str')
    assert_equal section.caption, 'caption'
    assert_equal section.fields, {'Connect' => 'conn_str'}, section.fields
  end

  def test_new_whitout_fields_required
    assert_raises ArgumentError do
      cls.new('caption',{f1:'bla bla'})
    end
  end

  def tets_fields_required
    assert_equal ['Connect'], cls.fields_required
  end

  def test_fields_optional
    skip
  end

  def test_fields_extras
    assert_equal ['AdmConnect',
                  'BaseCodeName',
                  'GetUpdateInfoURI',
                  'BaseCurentVersion',
                  'GlobalWS',
                  'Vendor'
    ], cls.fields_extras
  end

  def test_brackets
    section = cls.new('caption', {'Connect' => 'connect_str'})
    assert_equal 'connect_str', section['Connect']
  end

  def test_brackets=
    section = cls.new('caption', {'Connect' => 'connect_str'})
    section['Connect'] = 'new_connect_str'
    section['Field'] = 'field value'
    assert_equal({'Connect'=>'new_connect_str', 'Field'=>'field value'},
      section.fields)
  end

  def test_key?
    section = cls.new('caption', {'Connect' => 'connect_str'})
    assert section.key? 'Connect'
    assert ! section.key?('Field')
  end

  def test_to_s
    expected = ''
    expected << '[caption 1]'+"\r\n"
    expected << 'Connect=connect_str'+"\r\n"
    expected << 'Field1=Field 1 value'+"\r\n"
    section = cls.new('caption 1', {'Connect'=>'connect_str','Field1'=>'Field 1 value'})
    assert_equal expected, section.to_s
  end
end
