require 'test_helper'

class DslHelpersTest < Minitest::Test

  def dsl_helpered
    Class.new do
      include AssLauncher::Enterprise::Cli::SpecDsl::DslHelpers
    end.new
  end

  def test_t
    assert_equal :s, dsl_helpered._t(:s)
  end

  def test_defined_modes
    assert_equal AssLauncher::Enterprise::Cli::DEFINED_MODES,
      dsl_helpered.send(:defined_modes)
  end

  def test_described_modes
    assert_equal({}, dsl_helpered.described_modes)
  end

  def test_parameters_group
    assert_equal({}, dsl_helpered.parameters_groups)
  end

  def test_parameters
    assert_instance_of AssLauncher::Enterprise::Cli::Parameters::AllParameters,
      dsl_helpered.parameters
  end

  def test_current_modes
    dh = dsl_helpered
    dh.send(:current_modes=, :cm)
    assert_equal :cm, dh.send(:current_modes)
  end

  def test_current_group
    dh = dsl_helpered
    dh.send(:current_group=, :cg)
    assert_equal :cg, dh.send(:current_group)
  end

  def test_parent_stack
    assert_equal([], dsl_helpered.send(:parents_stack))
  end

  def test_current_parent
    dh = dsl_helpered
    assert_equal nil, dh.send(:current_parent)
    dh.send(:parents_stack).unshift :a
    dh.send(:parents_stack).unshift :b
    dh.send(:parents_stack).unshift :c
    assert_equal :c, dh.send(:current_parent)
  end

  def test_new_param_fail_without_group
    dh = dsl_helpered
    dh.expects(:current_group).returns(nil)
    e = assert_raises do
      dh.send :new_param, nil, nil, nil
    end
    assert_equal 'Group must be specifed', e.message
  end

  def test_new_param_fail_without_modes
    dh = dsl_helpered
    dh.expects(:current_group).returns(:group)
    dh.expects(:current_modes).returns(nil)
    e = assert_raises do
      dh.send :new_param, nil, nil, nil
    end
    assert_equal 'Modes must be specifed', e.message
  end

  def new_dh(klass)
    klass.expects(:new).with(:name, :desc, :binary_matcher,
                            :current_group, :current_modes,
                            :current_parent, {options:''}).returns(:parameter)
    dh = dsl_helpered
    dh.expects(:current_modes).returns(:current_modes).twice
    dh.expects(:current_group).returns(:current_group).twice
    dh.expects(:current_parent).returns(:current_parent)
    dh.expects(:new_binary_matcher).with(:clients).returns(:binary_matcher)
    dh.expects(:add_parameter).with(:parameter)
    dh
  end

  def test_new_param
    klass = mock
    dh = new_dh(klass)
    dh.expects(:eval_sub_params).never
    dh.send(:new_param, klass, :name, :desc, :clients, {options:''})
  end

  def test_new_param_with_subparameters_block
    klass = mock
    zonde = {}
    dh = new_dh(klass)
    dh.expects(:eval_sub_params).with(:parameter).yields(zonde)
    dh.send(:new_param, klass, :name, :desc, :clients, {options:''}) do |z|
      z[:value] = :set
    end
    assert_equal({:value => :set}, zonde)
  end

  def test_eval_sub_params
    dh = dsl_helpered
    parents_stack = mock
    parents_stack.responds_like([])
    parents_stack.expects(:unshift).with(:p)
    parents_stack.expects(:shift)
    dh.expects(:parents_stack).returns(parents_stack).twice
    zonde = {}
    dh.expects(:instance_eval).yields(zonde)
    dh.send(:eval_sub_params,:p) do |z|
      z[:value] = :set
    end
    assert_equal({:value=>:set}, zonde)
  end

  def test_add_enterprise_version_fail
    version = mock
    version.expects(:>).with(:current_version).returns(false)
    version.expects(:to_s)
    dh = dsl_helpered
    dh.expects(:current_version).returns(:current_version).twice
    e = assert_raises ArgumentError do
      dh.send(:add_enterprise_versions, version)
    end
    assert_match /Invalid version sequences\./, e.message
  end

  def test_add_enterprise_version
    dh = dsl_helpered
    dh.expects(:current_version).returns(2).times(3)
    dh.send(:add_enterprise_versions, 3)
    dh.send(:add_enterprise_versions, 4)
    dh.send(:add_enterprise_versions, 5)
    assert_equal [3, 4, 5], dh.enterprise_versions
  end

  def test_new_binary_matcher_with_clients
    AssLauncher::Enterprise::Cli::BinaryMatcher
      .expects(:new).with(nil, :current_version).returns(:new_binary_matcher)
    dh = dsl_helpered
    dh.expects(:from_current_version).returns(:current_version)
    assert_equal :new_binary_matcher, dh.send(:new_binary_matcher, [])
  end

  def test_new_binary_matcher_without_clients
    AssLauncher::Enterprise::Cli::BinaryMatcher
      .expects(:new).with([:web, :thin], :current_version).returns(:new_binary_matcher)
    dh = dsl_helpered
    dh.expects(:from_current_version).returns(:current_version)
    assert_equal :new_binary_matcher, dh.send(:new_binary_matcher, [:web, :thin])
  end

  def test_from_version
    dh = dsl_helpered
    expects = Gem::Version::Requirement.new('>= 42')
    version = Gem::Version.new('42')
    assert_equal expects, dh.send(:from_version, version)
  end

  def test_from_current_version
    dh = dsl_helpered
    dh.expects(:current_version).returns(:current_version)
    dh.expects(:from_version).with(:current_version).returns(:requirement)
    assert_equal :requirement, dh.send(:from_current_version)
  end

  def test_current_version
    dh = dsl_helpered
    dh.expects(:enterprise_versions).returns([1,2,3,:last]).twice
    assert_equal :last, dh.send(:current_version)
  end

  def test_current_version_deafult
    dh = dsl_helpered
    dh.expects(:enterprise_versions).returns([])
    assert_equal Gem::Version.new('0'), dh.send(:current_version)
  end

  def test_enterprise_versions
    dh = dsl_helpered
    assert_equal [], dh.enterprise_versions
  end

  def all_parameters_stub
    AssLauncher::Enterprise::Cli::Parameters::AllParameters.new
  end

  def test_get_parameters
    parameters = mock
    parameters.responds_like all_parameters_stub
    parameters.expects(:find).with(:name, :current_parent).returns([1,2,3])
    dh = dsl_helpered
    dh.expects(:current_parent).returns(:current_parent)
    dh.expects(:parameters).returns(parameters)
    assert_equal [1,2,3], dh.send(:get_parameters, :name)
  end

  def test_get_parameters_fail
    parameters = mock
    parameters.responds_like all_parameters_stub
    parameters.expects(:find).with(:name, :current_parent).returns([])
    dh = dsl_helpered
    dh.expects(:current_parent).returns(:current_parent)
    dh.expects(:parameters).returns(parameters)
    e = assert_raises do
      dh.send(:get_parameters, :name)
    end
    assert_equal 'Parameter name not found.', e.message
  end

  def param_stub
    Class.new(AssLauncher::Enterprise::Cli::Parameters::StringParam) do
      def initialize

      end
    end.new
  end

  def test_restrict_params
    param = mock
    param.responds_like param_stub
    param.expects(:restrict_from).with(:version).times(3)
    dh = dsl_helpered
    dh.expects(:get_parameters).with(:name).returns([param,param,param])
    assert_nil dh.send(:restrict_params, :name, :version)
  end

  def test_add_parameter
    parameters = mock
    parameters.responds_like all_parameters_stub
    parameters.expects(:add).with(:parameter, :current_version).returns(:parameter)
    dh = dsl_helpered
    dh.expects(:parameters).returns(parameters)
    dh.expects(:current_version).returns(:current_version)
    assert_equal :parameter, dh.send(:add_parameter, :parameter)
  end

  def test_change_param_with_block
    param = mock
    param.responds_like param_stub
    param.expects(:group).returns(:param_group)
    param.expects(:modes).returns(:param_modes)
    dh = dsl_helpered
    dh.expects(:get_parameter).with(:name).returns(param)
    dh.send :current_modes=, :old_modes
    dh.send :current_group=, :old_group
    zonde = {}
    dh.expects(:eval_sub_params).with(param).yields(dh)
    actual = dh.send(:change_param, :name) do
      zonde[:current_group] = dh.send :current_group
      zonde[:current_modes] = dh.send :current_modes
    end
    dh.unstub
    assert_equal :old_modes, actual
    assert_equal :old_modes, dh.send(:current_modes)
    assert_equal :old_group, dh.send(:current_group)
    assert_equal :param_modes, zonde[:current_modes]
    assert_equal :param_group, zonde[:current_group]
  end

  def test_get_parameter
    parameters = mock
    parameters.responds_like all_parameters_stub
    parameters.expects(:find_for_version)
      .with(:name, :current_parent, :current_version).returns(:parameter)
    dh = dsl_helpered
    dh.expects(:parameters).returns(parameters)
    dh.expects(:current_parent).returns(:current_parent)
    dh.expects(:current_version).returns(:current_version)
    assert_equal :parameter, dh.send(:get_parameter, :name)
  end

  def test_get_parameter_fail
    parameters = mock
    parameters.responds_like all_parameters_stub
    parameters.expects(:find_for_version)
      .with(:name, :current_parent, :current_version).returns(nil)
    dh = dsl_helpered
    dh.expects(:parameters).returns(parameters)
    dh.expects(:current_parent).returns(:current_parent)
    dh.expects(:current_version).returns(:current_version).twice
    e = assert_raises do
      dh.send(:get_parameter, :name)
    end
    assert_equal 'Parameter name not found for current_version.', e.message
  end

  def test_reset_all
    dh = dsl_helpered
    dh.expects(:reset_modes)
    dh.expects(:reset_group)
    dh.send :reset_all
  end

  def test_reset_modes
    dh = dsl_helpered
    dh.expects(:current_modes=).with(nil)
    assert_nil dh.send :reset_modes
  end

  def test_resrt_group
    dh = dsl_helpered
    dh.expects(:current_group=).with(nil)
    assert_nil dh.send :reset_group
  end
end
