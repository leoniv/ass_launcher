require 'test_helper'

class CliParametersTest < Minitest::Test
  def mod
    AssLauncher::Enterprise::Cli::Parameters
  end

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
    assert_equal [:key, :value], inst.to_args(:value)
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
    skip
  end

  def test_auto_client
    skip
  end
end

class CliStringParamTest < Minitest::Test
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

end
