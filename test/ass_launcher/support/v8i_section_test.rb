# coding: utf-8
require 'test_helper'

class V8iSectionTest < Minitest::Test

  def cls
    AssLauncher::Support::V8iSection
  end

  def test_new_good
    AssLauncher::Support::V8iSection::Fields.expects(:new)\
      .with('Connect' => 'conn_str')\
      .returns(:Fields)
    section = cls.new('caption', 'Connect' => 'conn_str')
    assert_equal section.caption, 'caption'
    assert_equal section.fields, :Fields
  end

  def test_brackets
    section = cls.new('caption', {'Connect' => 'connect_str'})
    AssLauncher::Support::V8iSection::Fields.any_instance.expects(:'[]')\
      .with(:field).returns(:value)
    assert_equal :value, section[:field]
#    assert_equal 'connect_str', section['Connect']
#    assert_equal 'connect_str', section['connect']
#    assert_equal 'connect_str', section[:connect]
  end

  def test_brackets=
    section = cls.new('caption', {'Connect' => 'connect_str'})
    AssLauncher::Support::V8iSection::Fields.any_instance.expects(:'[]=')\
      .with(:field, :value).returns(:value)
    assert_equal :value, section[:field] = :value
  end

  def test_key?
    section = cls.new('caption', {'Connect' => 'connect_str'})
    AssLauncher::Support::V8iSection::Fields.any_instance.expects(:'key?')\
      .with(:field).returns(:true)
    assert_equal :true, section.key?(:field)
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

class V8iSectionFieldsTest < Minitest::Test

  def cls
    AssLauncher::Support::V8iSection::Fields
  end

  def test_build_dict
    inst = cls.new('Connect'=>'')
    inst.expects(:_hash).returns('Fild1' => '', 'Fild2' => '')
    assert_equal({:fild1 => 'Fild1', :fild2 => 'Fild2'}, inst.send(:build_dict))
  end

  def test_trans
    inst = cls.new('Connect'=>'')
    assert_equal 'Connect', inst.send(:trans, 'Connect')
    assert_equal 'Connect', inst.send(:trans, 'CoNnEcT')
    assert_equal 'Connect', inst.send(:trans, 'Connect'.to_sym)
    assert_equal 'Connect', inst.send(:trans, 'CoNnEcT'.to_sym)
  end

  def test_to_s
    expected = ''
    expected << 'Connect=connect_str'+"\r\n"
    expected << 'Field1=Field 1 value'+"\r\n"
    section = cls.new({'Connect'=>'connect_str','Field1'=>'Field 1 value'})
    assert_equal expected, section.to_s
  end

  def test_brackets
    inst = cls.new('Connect'=>'')
    inst['Fields'] = :value
    assert_equal :value, inst[:fIeLdS]
    assert_equal :value, inst[:fIeLdS.to_s]
  end

  def test_key?
    inst = cls.new('Connect'=>'')
    assert inst.key?(:cOnNEcT)
    assert inst.key?(:cOnNEcT.to_s)
    refute inst.key?('BadKey')
  end

  def test_new_good
    section = cls.new('Connect' => 'conn_str')
    assert_equal section._hash, {'Connect' => 'conn_str'}
  end

  def test_new_whitout_fields_required
    assert_raises ArgumentError do
      cls.new({:F1 => 'bla bla'})
    end
  end

  def test_fields_required
    assert_equal [:connect], AssLauncher::Support::V8iSection::Fields::REQUIRED
  end
end
