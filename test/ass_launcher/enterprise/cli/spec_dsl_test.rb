require 'test_helper'
class SpecDslTest < Minitest::Test
  def spec_dsl
    Class.new do
      include AssLauncher::Enterprise::Cli::SpecDsl
    end.new
  end

  def test_enterprise_version
    dsl = spec_dsl
    dsl.enterprise_version '123'
  end

  def test_describe_mode_fail
    dsl = spec_dsl
    dsl.expects(:defined_modes).returns([])
    assert_raises do
      dsl.describe_mode(:bad_run_mode, :desc, :banner)
    end
  end

  def test_describe_mode
    dsl = spec_dsl
    dsl.expects(:defined_modes).returns([:run_mode])
    dsl.describe_mode(:run_mode, :desc, :banner)
    assert_equal({:run_mode => {:desc => :desc, :banner => :banner}},
                 dsl.described_modes)
  end

  def test_define_group
    dsl = spec_dsl
    dsl.define_group(:name, :desc, :priority)
    assert_equal({:name=>{:desc=>:desc, :priority=>:priority}}, dsl.parameters_groups)
  end

  def test_thick_client
    AssLauncher::Enterprise::Cli::BinaryMatcher.expects(:new).with(:thick, :v).
      returns(:matcher)
    assert_equal :matcher, spec_dsl.thick_client(:v)
  end

  def test_thin_client
    AssLauncher::Enterprise::Cli::BinaryMatcher.expects(:new).with(:thin, :v).
      returns(:matcher)
    assert_equal :matcher, spec_dsl.thin_client(:v)
  end

  def test_all_client
    AssLauncher::Enterprise::Cli::BinaryMatcher.expects(:new).with(:all, :v).
      returns(:matcher)
    assert_equal :matcher, spec_dsl.all_client(:v)
  end

  def test_mode_fail_bad_modes
    dsl = spec_dsl
    dsl.expects(:defined_modes).returns([1,2,3])
    assert_raises do
      dsl.mode(5,6,7)
    end
  end

  def test_mode_fail_without_block
    dsl = spec_dsl
    dsl.expects(:defined_modes).returns([1,2,3])
    dsl.expects(:block_given?).returns(false)
    assert_raises do
      dsl.mode(1)
    end
  end

  def test_mode
    dsl = spec_dsl
    dsl.expects(:defined_modes).returns([1,2,3])
    zonde = {}
    dsl.expects(:instance_eval).yields(zonde)
    dsl.mode(1) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal [1], dsl.send(:current_modes)
  end

  def test_group_fail_undefined_grop
    dsl = spec_dsl
    dsl.expects(:parameters_groups).returns({:group_name=>''})
    assert_raises do
      dsl.group(:bad_group)
    end
  end

  def test_group_fail_without_block
    dsl = spec_dsl
    dsl.expects(:parameters_groups).returns({:group_name=>''})
    dsl.expects(:block_given?).returns(false)
    assert_raises do
      dsl.group(:group_name)
    end
  end

  def test_group
    dsl = spec_dsl
    dsl.expects(:parameters_groups).returns({:group_name=>''})
    zonde = {}
    dsl.expects(:instance_eval).yields(zonde)
    dsl.group(:group_name) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :group_name, dsl.send(:current_group)
  end

  def test_switch_list
    dsl = spec_dsl
    dsl.expects(:_t).with(1).returns(1)
    dsl.expects(:_t).with(2).returns(2)
    assert_equal({_1:1, _2:2}, dsl.switch_list({_1:1, _2:2}))
    assert dsl.method(:switch_list) == dsl.method(:chose_list)
  end

  def test_path
    klass = AssLauncher::Enterprise::Cli::Parameters::Path
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:''}).
      yields(zonde).returns(:param)
    p = dsl.path(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_path_exist
    klass = AssLauncher::Enterprise::Cli::Parameters::Path
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:'', mast_be: :exist}).
      yields(zonde).returns(:param)
    p = dsl.path_exist(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_path_not_exist
    klass = AssLauncher::Enterprise::Cli::Parameters::Path
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:'', mast_be: :not_exist}).
      yields(zonde).returns(:param)
    p = dsl.path_not_exist(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_string
    klass = AssLauncher::Enterprise::Cli::Parameters::StringParam
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:''}).
      yields(zonde).returns(:param)
    p = dsl.string(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_flag
    klass = AssLauncher::Enterprise::Cli::Parameters::Flag
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:''}).
      yields(zonde).returns(:param)
    p = dsl.flag(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_switch
    klass = AssLauncher::Enterprise::Cli::Parameters::Switch
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:''}).
      yields(zonde).returns(:param)
    p = dsl.switch(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_chose
    klass = AssLauncher::Enterprise::Cli::Parameters::Chose
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, :binary_matcher, {options:''}).
      yields(zonde).returns(:param)
    p = dsl.chose(:name, :desc, :binary_matcher, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_url
    options = {option:''}
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:url_value_validator).returns(:url_value_validator)
    dsl.expects(:string).
      with(:name, :desc, :binary_matcher,
           has_entries(:option=>'', :value_validator=>:url_value_validator)).
      yields(zonde).returns(:p)
    p = dsl.url(:name, :desc, :binary_matcher, options) do |z|
      z[:value] = :set
    end
    assert_equal :p, p
    assert_equal({:value => :set}, zonde)
  end

  def test_url_value_validator
    dsl = spec_dsl
    dsl.expects(:URI).with(:value)
    assert_equal :value, dsl.send(:url_value_validator, 'name').call(:value)
    dsl.expects(:URI).raises(ArgumentError)
    e = assert_raises ArgumentError do
      dsl.send(:url_value_validator, 'name').call(:bad_url)
    end
    assert_equal 'Invalid URL for parameter `name\': `bad_url\'', e.message
  end

  def test_num
    options = {option:''}
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:num_value_validator).returns(:num_value_validator)
    dsl.expects(:string).
      with(:name, :desc, :binary_matcher,
           has_entries(:option=>'', :value_validator=>:num_value_validator)).
      yields(zonde).returns(:p)
    p = dsl.num(:name, :desc, :binary_matcher, options) do |z|
      z[:value] = :set
    end
    assert_equal :p, p
    assert_equal({:value => :set}, zonde)
  end

  def test_num_value_validator
    dsl = spec_dsl
    assert_equal '-10.2', dsl.send(:num_value_validator, 'name').call('-10.2')
    e = assert_raises ArgumentError do
      dsl.send(:num_value_validator, 'name').call(:bad_num)
    end
    assert_equal 'Invalid Number for parameter `name\': `bad_num\'', e.message
  end
end
