require 'test_helper'

module PramArgumetRequire
  def test_argumet_require
    inst = cls.new(nil,nil,nil,nil,nil)
    assert inst.argument_require
  end
end

class CliParametersTest < Minitest::Test
  def param
    Class.new do
      include AssLauncher::Enterprise::Cli::Parameters
    end.new
  end

  def default_options
    AssLauncher::Enterprise::Cli::Parameters::DEFAULT_OPTIONS
  end

  def test_default_opts
    refute default_options[:required]
    assert_equal :value, default_options[:value_validator].call(:value)
    assert_equal nil, default_options[:switch_list]
    assert_equal nil, default_options[:chose_list]
    assert_equal :value, default_options[:switch_value].call(:value)
  end

  def test_attr_read_only
    [:name, :desc, :binary_matcher, :group, :modes, :parent, :options].each do |attr|
      assert_respond_to param, attr
    end
  end

  def test_match?
    binary_matcher = mock
    binary_matcher.expects(:match?).with(:binary_wrapper).returns(true)
    binary_matcher.expects(:match?).with(:binary_wrapper).returns(true)
    seq = sequence('true_false')
    modes = mock
    modes.responds_like({})
    modes.expects(:include?).with(:run_mode).returns(true).in_sequence(seq)
    modes.expects(:include?).with(:run_mode).returns(false).in_sequence(seq)
    inst = param
    inst.expects(:binary_matcher).returns(binary_matcher).twice
    inst.expects(:modes).returns(modes).twice
    assert inst.match?(:binary_wrapper, :run_mode)
    refute inst.match?(:binary_wrapper, :run_mode)
  end

  def test_to_sym
    inst = param
    inst.expects(:name).returns('Name')
    assert_equal :name, inst.to_sym
  end

  def test_full_name_for_root_parameter
    inst = param
    inst.expects(:root?).returns(true)
    inst.expects(:name).returns(:name)
    assert_equal :name, inst.full_name
  end

  def test_full_name_sub_parameter
    inst = param
    inst.expects(:root?).returns(false)
    inst.expects(:name).returns('-SubParam')
    parent = mock
    parent.expects(:full_name).returns('/ParentParam')
    inst.expects(:parent).returns(parent)
    assert_equal '/ParentParam-SubParam', inst.full_name
  end

  def test_parents_for_root_parameter
    inst = param
    inst.expects(:root?).returns(true)
    assert_equal [], inst.parents
  end

  def test_parents_for_sub_parameter
    inst = param
    inst.expects(:root?).returns(false)
    parent = mock
    parent.expects(:parents).returns([:root])
    inst.expects(:parent).returns(parent).twice
    assert_equal [:root,parent], inst.parents
  end

  def test_deep
    inst = param
    parents = mock
    parents.responds_like([])
    parents.expects(:size).returns(:size)
    inst.expects(:parents).returns(parents)
    assert_equal :size, inst.deep
  end

  def test_root?
    inst = param
    parent = mock
    parent.expects(:nil?).returns(:nil?)
    inst.expects(:parent).returns(parent)
    assert_equal :nil?, inst.root?
  end

  def test_child?
    inst = param
    inst.expects(:root?).returns(true)
    refute inst.child?(:parent)
    inst.expects(:root?).returns(false)
    inst.expects(:parent).returns(:parent)
    assert inst.child?(:parent)
  end

  def test_to_s
    inst = param
    inst.expects(:name).returns(:name)
    assert_equal 'name', inst.to_s
  end

  def test_to_args
    inst = param
    inst.expects(:key).with(:value).returns(:key)
    inst.expects(:value).with(:value).returns(:value)
    assert_equal [:key.to_s, :value.to_s], inst.to_args(:value)
  end

  def test_switch_list
    inst = param
    inst.expects(:options).returns({:switch_list => :switch_list_value})
    assert_equal :switch_list_value, inst.switch_list
  end

  def test_chose_list
    inst = param
    inst.expects(:options).returns({:chose_list => :chose_list_value})
    assert_equal :chose_list_value, inst.chose_list
  end

  def test_required?
    inst = param
    inst.expects(:options).returns({:required => :required})
    assert_equal :required, inst.required?
  end

  def test_key
    inst = param
    inst.expects(:name).returns(:name)
    assert_equal :name, inst.send(:key, :value)
  end

  def test_validate
    inst = param
    value_validator = mock
    value_validator.expects(:call).with(:value).returns(:value)
    inst.expects(:value_validator).returns(value_validator)
    assert_equal :value, inst.send(:validate, :value)
  end

  def test_value
    inst = param
    inst.expects(:validate).with(:value).returns(:value)
    assert_equal :value, inst.send(:value,:value)
  end

  def test_def_options
    assert_equal AssLauncher::Enterprise::Cli::Parameters::DEFAULT_OPTIONS,
      param.send(:def_options)
  end

  def test_usage
    assert_raises NotImplementedError do
      param.usage
    end
  end

  def test_auto_binary_matcher
    inst = param
    inst.expects(:auto_client).returns(:all)
    assert_instance_of AssLauncher::Enterprise::Cli::BinaryMatcher,
      inst.send(:auto_binary_matcher, nil)
  end

  def test_auto_client
    inst = param
    inst.expects(:modes).returns([:createinfobase, :designer])
    assert_equal :thick, inst.send(:auto_client)
    inst.expects(:modes).returns([:enterprise, :createinfobase, :designer])
    assert_equal :all, inst.send(:auto_client)
  end
end

class CliChoseParameterTest < Minitest::Test
  include PramArgumetRequire
  def cls
    AssLauncher::Enterprise::Cli::Parameters::Chose
  end

  def test_to_args
    inst = cls.new('/ChoseList',nil,nil,nil,nil,{chose_list: {ch1:'', ch2:''}})
    assert_equal ['/ChoseList', 'ch2'], inst.to_args('ch2')
  end

  def test_to_args_invalid_value
    inst = cls.new('/ChoseList',nil,nil,nil,nil,{chose_list: {ch1:'', ch2:''}})
    assert_raises ArgumentError do
      inst.to_args('ch3')
    end
  end
end

class CliFlagParameter < Minitest::Test
  def cls
    AssLauncher::Enterprise::Cli::Parameters::Flag
  end

  def test_to_args
    inst = cls.new('/FlagParameter',nil,nil,nil,nil)
    assert_equal ['/FlagParameter',''], inst.to_args
  end

  def test_argumet_require
    inst = cls.new(nil,nil,nil,nil,nil)
    refute inst.argument_require
  end
end

class CliParametersListTest < Minitest::Test
  def list
    AssLauncher::Enterprise::Cli::Parameters::ParametersList.new
  end

  def test_each
    zond = mock
    zond.expects(:each).yields(:zonde_value)
    inst = list
    inst.expects(:parameters).returns(zond)
    inst.each do |v|
      assert_equal :zonde_value, v
    end
  end

  def test_usage
    assert_raises NotImplementedError do
      list.usage
    end
  end

  def test_add
    inst = list
    inst.expects(:param_defined?).with(:p1).returns(false)
    inst.expects(:param_defined?).with(:p2).returns(false)
    inst << :p1
    inst << :p2
    assert_equal [:p1, :p2], inst.send(:parameters)
  end

  def test_find
    p1 = stub({:to_sym => :p1, :parent => nil})
    p2 = stub({:to_sym => :p2, :parent => p1})
    p3 = stub({:to_sym => :p3, :parent => p2})
    inst = list
    inst.expects(:parameters).returns([p1,p2,p3]).times(4)
    assert_nil inst.find('p4',p2)
    assert_equal p1, inst.find('p1', nil)
    assert_equal p3, inst.find('p3', p2)
    assert_equal p2, inst.find('p2', p1)
  end

  def test_initialize
    assert_equal [], list.send(:parameters)
  end

  def test_param_defined?
    inst = list
    inst.expects(:find).with(:name,:parent).returns(:param)
    p = mock({:name=>:name, :parent=>:parent})
    assert inst.param_defined?(p)
    inst.expects(:find).with(:name,:parent).returns(nil)
    p = mock({:name=>:name, :parent=>:parent})
    refute inst.param_defined?(p)
  end
end

class CliSwitchParameterTest < Minitest::Test
  include PramArgumetRequire
  def cls
    AssLauncher::Enterprise::Cli::Parameters::Switch
  end

  def test_to_args_with_switch_list
    inst = cls.new('/Fucking1C?',nil,nil,nil,nil,
                   {switch_list:{:yes=>'Is true', :true=>'Is true true'}})
    assert_equal ['/Fucking1C?yes',''], inst.to_args('yes')
    assert_equal ['/Fucking1C?true',''], inst.to_args('true')
    assert_raises ArgumentError do
      inst.to_args('not')
    end
  end

  def test_to_args_with_switch_value
    inst = cls.new('/Fucking1C?',nil,nil,nil,nil,
                   {switch_value: proc do |value|
                      " => #{value}"
                    end
                   }
                  )
    assert_equal ['/Fucking1C? => Yes it is!',''], inst.to_args('Yes it is!')
  end

  def test_to_args_with_switch_value_and_validate
    inst = cls.new('/Fucking1C?',nil,nil,nil,nil,
                   {switch_value: proc do |value|
                      " => #{value}"
    end,
    value_validator: proc { |value| fail ArgumentError if value =~ /no/i }
                   }
                  )
    assert_equal ['/Fucking1C? => Yes it is!',''], inst.to_args('Yes it is!')
    assert_raises ArgumentError do
      inst.to_args 'No'
    end
  end
end

class CliPathParameterTest < Minitest::Test
  include PramArgumetRequire
  include AssLauncher::Support::Platforms
  def cls
    AssLauncher::Enterprise::Cli::Parameters::Path
  end

  def test_def_options
    assert cls.new('',nil ,nil, nil, nil, nil).default_options.key? :mast_be
  end

  def test_to_args
    inst = cls.new('/PathParameter',nil,nil,nil,nil,nil)
    assert_equal ['/PathParameter', platform.path('.').realdirpath.to_s],
      inst.to_args('.')
  end

  def test_to_args_fail_if_exists
    inst = cls.new('/PathParameter',nil,nil,nil,nil,:mast_be => :not_exist)
    assert_raises ArgumentError do
      inst.to_args('.')
    end
  end

  def test_to_args_fail_if_not_exists
    inst = cls.new('/PathParameter',nil,nil,nil,nil,:mast_be => :exist)
    assert_raises ArgumentError do
      inst.to_args('./fake_path')
    end
  end
end

class CliStringParamTest < Minitest::Test
  include PramArgumetRequire

  def cls
    AssLauncher::Enterprise::Cli::Parameters::StringParam
  end

  def test_initialize
    def_options = mock
    def_options.responds_like({})
    def_options.expects(:merge).with({}).returns(:options)
    cls.any_instance.expects(:def_options).returns(def_options)
    cls.any_instance.expects(:auto_binary_matcher).with(:binary_matcher)\
      .returns(:binary_matcher)
    inst = cls.new(:name, :desc, :binary_matcher, :group, :modes, :parent, {})
    assert_equal :name, inst.name
    assert_equal :desc, inst.desc
    assert_equal :binary_matcher, inst.binary_matcher
    assert_equal :group, inst.group
    assert_equal :modes, inst.modes
    assert_equal :parent, inst.parent
    assert_equal :options, inst.options
  end

  def test_to_args
    inst = cls.new('/StringParam','',nil,'',nil,nil)
    assert_equal ['/StringParam', 'string value'], inst.to_args('string value')
  end

  def test_to_args_not_valid_value
    inst = cls.new('/S',nil,nil,nil,nil,
                   {value_validator: proc do |value|
                      fail ArgumentError if value == 'invalid value'
                    end
                   }
                  )
    assert_raises ArgumentError do
      inst.to_args 'invalid value'
    end
  end
end
