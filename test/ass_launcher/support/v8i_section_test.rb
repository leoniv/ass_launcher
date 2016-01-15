# coding: utf-8
require 'test_helper'

class V8iSectionTest < Minitest::Test

  def cls
    AssLauncher::Support::V8iSection
  end

  def test_new_good
    section = cls.new('caption',Connect:'conn_str')
    assert_equal {Caption:'caption', Connect:'conn_str'}, section.fields
  end

  def test_new_whitout_fields_required
    assert_raises ArgumenError do
      cls.new('caption',{f1:'bla bla'})
    end
  end

  def tets_fields_required
    assert_equal [:Connect], cls.fields_required
  end

  def test_fields_optional
    skip
  end

  def test_fields_extras
    assert_equal [:AdmConnect,
                  :BaseCodeName
                  :GetUpdateInfoURI
                  :BaseCurentVersion
                  :GlobalWS
                  :Vendor
                  :ConfigName
                  ], cls.fields_required
  end

  def test_brackets
    skip
  end

  def test_fields
    skip
  end

  def test_key?
    skip
  end
end
