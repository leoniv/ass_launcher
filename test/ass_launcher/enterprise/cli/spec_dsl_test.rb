require 'test_helper'
class SpecDslTest < Minitest::Test
  def spec_dsl
    Class.new do
      include AssLauncher::Enterprise::Cli::SpecDsl
    end.new
  end

  def test_enterprise_version
    dsl = spec_dsl
    dsl.expects(:reset_all)
    dsl.expects(:add_enterprise_versions).with(Gem::Version.new('123'))
      .returns(:version)
    assert_equal :version, dsl.enterprise_version('123')
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

  def test_fail_if_wrong_modes
    dsl = spec_dsl
    dsl.expects(:defined_modes).returns([1,2,3])
    e = assert_raises do
      dsl.send :mode, [5, 6, 7]
    end
    assert_match /Undefined modes/, e.message
  end

  def test_mode_fail_without_block
    dsl = spec_dsl
    dsl.expects(:fail_if_wrong_modes)
    dsl.expects(:block_given?).returns(false)
    e = assert_raises do
      dsl.mode
    end
    assert_equal 'Block required', e.message
  end

  def test_mode
    dsl = spec_dsl
    dsl.expects(:fail_if_wrong_modes).with([:mod1, :mod2])
    dsl.expects(:current_modes=).with([:mod1, :mod2])
    dsl.expects(:reset_modes).returns(nil)
    zonde = {}
    dsl.expects(:instance_eval).yields(zonde)
    dsl.mode(:mod1, :mod2) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_nil dsl.send(:current_modes)
  end

  def test_group_fail_undefined_grop
    dsl = spec_dsl
    dsl.expects(:parameters_groups).returns({:group_name=>''})
    e = assert_raises do
      dsl.group(:bad_group)
    end
    assert_match /Undefined parameters group/, e.message
  end

  def test_group_fail_without_block
    dsl = spec_dsl
    dsl.expects(:fail_if_wrong_group)
    dsl.expects(:block_given?).returns(false)
    e = assert_raises do
      dsl.group(:group_name)
    end
    assert_equal 'Block required', e.message
  end

  def test_group
    dsl = spec_dsl
    dsl.expects(:fail_if_wrong_group).with(:group_name)
    dsl.expects(:current_group=).with(:group_name)
    dsl.expects(:reset_group).returns(nil)
    zonde = {}
    dsl.expects(:instance_eval).yields(zonde)
    dsl.group(:group_name) do |z|
      z[:value] = :set
    end
    assert_nil dsl.send(:current_group)
  end

  def test_switch_list
    dsl = spec_dsl
    dsl.expects(:_t).with(1).returns(1)
    dsl.expects(:_t).with(2).returns(2)
    assert_equal({_1:1, _2:2}, dsl.switch_list({_1:1, _2:2}))
    assert dsl.method(:switch_list) == dsl.method(:chose_list)
  end

  def param_dsl_method_test(klass, method, **options)
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:new_param).with(klass, :name, :desc, [:clients],
                                 {options:''}.merge(options))
      .yields(zonde).returns(:param)
    p = dsl.send(method, :name, :desc, :clients, {options:''}.merge(options)) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
    assert_equal :param, p
  end

  def test_path
    klass = AssLauncher::Enterprise::Cli::Parameters::Path
    param_dsl_method_test klass, :path
  end

  def test_path_exist
    klass = AssLauncher::Enterprise::Cli::Parameters::Path
    param_dsl_method_test klass, :path_exist, must_be: :exist
  end

  def test_path_not_exist
    klass = AssLauncher::Enterprise::Cli::Parameters::Path
    param_dsl_method_test klass, :path_not_exist, must_be: :not_exist
  end

  def test_string
    klass = AssLauncher::Enterprise::Cli::Parameters::StringParam
    param_dsl_method_test klass, :string
  end

  def test_flag
    klass = AssLauncher::Enterprise::Cli::Parameters::Flag
    param_dsl_method_test klass, :flag
  end

  def test_switch
    klass = AssLauncher::Enterprise::Cli::Parameters::Switch
    param_dsl_method_test klass, :switch
  end

  def test_chose
    klass = AssLauncher::Enterprise::Cli::Parameters::Chose
    param_dsl_method_test klass, :chose
  end

  def param_string_dsl_method_test(method, value_validator)
    options = {option:''}
    zonde = {}
    dsl = spec_dsl
    dsl.expects(value_validator).returns(value_validator)
    dsl.expects(:string).
      with(:name, :desc, :client1, :client2,
           has_entries(:option=>'', :value_validator=>value_validator)).
      yields(zonde).returns(:p)
    p = dsl.send(method, :name, :desc, :client1, :client2, **options) do |z|
      z[:value] = :set
    end
    assert_equal :p, p
    assert_equal({:value => :set}, zonde)
  end

  def test_url
    param_string_dsl_method_test :url, :url_value_validator
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
    param_string_dsl_method_test :num, :num_value_validator
  end

  def test_num_value_validator
    dsl = spec_dsl
    assert_equal '-10.2', dsl.send(:num_value_validator, 'name').call('-10.2')
    e = assert_raises ArgumentError do
      dsl.send(:num_value_validator, 'name').call(:bad_num)
    end
    assert_equal 'Invalid Number for parameter `name\': `bad_num\'', e.message
  end

  def test_thin_thick_web
    dsl = spec_dsl
    assert_equal :web, dsl.web
    assert_equal :thick, dsl.thick
    assert_equal :thin, dsl.thin
  end

  def test_restrict
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:current_version).returns(:version)
    dsl.expects(:restrict_params).with(:name, :version).returns(nil)
    assert_nil dsl.restrict(:name)
  end

  def test_change
    zonde = {}
    dsl = spec_dsl
    dsl.expects(:change_param).with(:name).yields(zonde)
    dsl.change(:name) do |z|
      z[:called] = true
    end
    assert zonde[:called]
  end
end
