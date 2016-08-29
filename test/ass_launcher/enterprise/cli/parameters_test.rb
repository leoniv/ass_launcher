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

  def stub_binary_matcher
    Class.new(AssLauncher::Enterprise::Cli::BinaryMatcher) do
      def initialize

      end
    end.new
  end

  def test_match_version?
    requirement = mock
    requirement.responds_like Gem::Version::Requirement.new '> 0'
    requirement.expects(:satisfied_by?).with(:version).returns(:satisfied)
    binary_matcher = mock
    binary_matcher.responds_like stub_binary_matcher
    binary_matcher.expects(:requirement).returns(requirement)
    inst = param
    inst.expects(:binary_matcher).returns(binary_matcher)
    assert_equal :satisfied, inst.match_version?(:version)
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

  def cls_binary_matcher
    AssLauncher::Enterprise::Cli::BinaryMatcher
  end

  def test_auto_binary_matcher_by_matcher
    cls_binary_matcher.expects(:auto).never
    inst = param
    expects = cls_binary_matcher.new
    assert_equal expects, inst.send(:auto_binary_matcher, expects)
  end

  def test_auto_binary_matcher_by_string
    cls_binary_matcher.expects(:auto).with(:modes, 'string').returns(:matcher)
    inst = param
    inst.expects(:modes).returns(:modes)
    assert_equal :matcher, inst.send(:auto_binary_matcher, 'string')
  end

  def test_auto_binary_matcher_by_not_string
    cls_binary_matcher.expects(:auto).with(:modes).returns(:matcher)
    inst = param
    inst.expects(:modes).returns(:modes)
    assert_equal :matcher, inst.send(:auto_binary_matcher, :not_string)
  end

  def test_childs
    assert_equal [], param.childs
  end

  def test_add_child
    array = mock
    array.expects(:'<<').with(:param).returns(:child)
    inst = param
    inst.expects(:childs).returns(array)
    assert_equal :child, inst.add_child(:param)
  end

  def test_restrict_from
    binary_matcher = mock
    binary_matcher.expects(:requirement).returns(:requirement)
    binary_matcher.expects(:requirement=).with(:new_requirement).returns(:new_requirement)
    inst = param
    inst.expects(:binary_matcher).returns(binary_matcher).twice
    inst.expects(:restrict_childs).with(:version)
    inst.expects(:match_version?).with(:version).returns(:true)
    inst.expects(:restrict_v).with(:requirement, :version).returns(:new_requirement)
    assert_equal :new_requirement, inst.restrict_from(:version)
  end

  def test_restrict_childs
    p = mock
    p.responds_like param
    p.expects(:restrict_from).with(:version).times(3)
    childs = [p, p, p]
    inst = param
    inst.expects(:childs).returns(childs)
    assert_equal childs, inst.send(:restrict_childs, :version)
  end

  def test_restrict_v
    inst = param
    expects = Gem::Version::Requirement.new('>= 1', '< 12')
    r = Gem::Version::Requirement.new('>= 1')
    v = Gem::Version.new('12')
    assert_equal expects, inst.send(:restrict_v, r, v)
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
    assert cls.new('',nil ,nil, nil, nil, nil).send(:default_options)
      .key? :must_be
  end

  def test_to_args
    inst = cls.new('/PathParameter',nil,nil,nil,nil,nil)
    assert_equal ['/PathParameter', platform.path('.').realdirpath.to_s],
      inst.to_args('.')
  end

  def test_to_args_fail_if_exists
    inst = cls.new('/PathParameter',nil,nil,nil,nil,:must_be => :not_exist)
    assert_raises ArgumentError do
      inst.to_args('.')
    end
  end

  def test_to_args_fail_if_not_exists
    inst = cls.new('/PathParameter',nil,nil,nil,nil,:must_be => :exist)
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

  def parameter_stub
    Class.new(cls) do
      def initialize

      end
    end.new
  end

  def test_initialize
    def_options = mock
    def_options.responds_like({})
    def_options.expects(:merge).with({}).returns(:options)
    cls.any_instance.expects(:def_options).returns(def_options)
    cls.any_instance.expects(:auto_binary_matcher).with(:binary_matcher)\
      .returns(:binary_matcher)
    parent = mock
    parent.responds_like parameter_stub
    parent.expects(:add_child).with(is_a(cls))
    inst = cls.new(:name, :desc, :binary_matcher, :group, :modes, parent, {})
    assert_equal :name, inst.name
    assert_equal :desc, inst.desc
    assert_equal :binary_matcher, inst.binary_matcher
    assert_equal :group, inst.group
    assert_equal :modes, inst.modes
    assert_equal parent, inst.parent
    assert_equal :options, inst.options
  end

  def test_initialize_with_nil_parent
    cls.any_instance.expects(:auto_binary_matcher).with(:binary_matcher)
    parent_nil = mock
    parent_nil.responds_like parameter_stub
    parent_nil.expects(:nil?).returns(true)
    parent_nil.expects(:add_child).never
    inst = cls.new(:name, :desc, :binary_matcher, :group, :modes, parent_nil)
    assert_equal [], inst.childs
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

class CliAllParametersTest < Minitest::Test
  def new_inst
    AssLauncher::Enterprise::Cli::Parameters::AllParameters.new
  end

  def test_parameters
    assert_equal [], new_inst.parameters
  end

  def test_add
    inst = new_inst
    inst.expects(:fail_if_difined).with(1, :version)
    inst.expects(:fail_if_difined).with(2, :version)
    inst.expects(:fail_if_difined).with(3, :version)
    inst.add 1, :version
    inst.add 2, :version
    inst.add 3, :version
    assert_equal [1,2,3], inst.parameters
  end

  def pstub
    Class.new(AssLauncher::Enterprise::Cli::Parameters::StringParam) do
      def initialize

      end
    end.new
  end

  def test_to_parmeters_list
    p = mock
    p.responds_like pstub
    p.expects(:match?).with(:binary_wrapper, :run_mode).returns(true).twice
    p.expects(:match?).with(:binary_wrapper, :run_mode).returns(false)
    list = mock
    list.expects(:'<<').with(p).twice
    inst = new_inst
    inst.expects(:new_list).returns(list)
    3.times do
      inst.parameters << p
    end
    actual = inst.to_parameters_list(:binary_wrapper, :run_mode)
    assert_equal list, actual
  end

  def test_new_list
    assert_instance_of AssLauncher::Enterprise::Cli::Parameters::ParametersList,
      new_inst.send(:new_list)
  end

  def test_find
    p = mock
    p.responds_like pstub
    p.expects(:to_sym).returns(:pname).twice
    p.expects(:parent).returns(:parent).twice
    p.expects(:to_sym).returns(:other_name)
    p.expects(:to_sym).returns(:pname)
    p.expects(:parent).returns(:other_parent)
    inst = new_inst
    4.times do
      inst.parameters << p
    end
    assert_equal [p,p], inst.find(:Pname.to_s, :parent)
  end

  def test_fail_if_defined
    p = mock
    p.responds_like pstub
    p.expects(:full_name).returns(:name)
    inst = new_inst
    inst.expects(:param_defined?).with(p, :v).returns(true)
    assert_raises ArgumentError do
      assert_nil inst.send(:fail_if_difined, p, :v)
    end
  end

  def test_not_fail_if_not_defined
    p = mock
    p.responds_like pstub
    inst = new_inst
    inst.expects(:param_defined?).with(p, :v).returns(false)
    assert_nil inst.send(:fail_if_difined, p, :v)
  end

  def test_param_defined?
    p = mock
    p.responds_like pstub
    p.expects(:match_version?).with(:version).returns(true)
    p.expects(:name).returns(:name)
    p.expects(:parent).returns(:parent)
    inst = new_inst
    inst.expects(:find).with(:name, :parent).returns([p, p])
    assert inst.param_defined? p, :version
  end

  def test_param_not_defined?
    p = mock
    p.responds_like pstub
    p.expects(:match_version?).with(:version).returns(false).twice
    p.expects(:name).returns(:name)
    p.expects(:parent).returns(:parent)
    inst = new_inst
    inst.expects(:find).with(:name, :parent).returns([p, p])
    refute inst.param_defined? p, :version
  end

  def test_opps!
    inst = new_inst
    assert_equal :p, inst.send(:oops!, nil, :p, :v)
    p = mock
    p.responds_like pstub
    p.expects(:full_name)
    assert_raises do
      inst.send(:oops!, :not_nil, p, :v)
    end
  end

  def test_find_for_version
    p = mock
    p.responds_like pstub
    p.stubs(:match_version?).with(:version).returns(true, false)
    inst = new_inst
    inst.expects(:find).with(:name, :parent).returns([p, p])
    inst.expects(:oops!).with(nil, p, :version).returns(p)
    assert_equal p, inst.find_for_version(:name, :parent, :version)
  end
end
