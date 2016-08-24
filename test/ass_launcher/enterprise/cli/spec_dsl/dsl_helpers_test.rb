require 'test_helper'

class DslHelpersTest < Minitest::Test

  def dsl_helpered
    Class.new do
      include AssLauncher::Enterprise::Cli::SpecDsl::DslHelpers
      def binary_wrapper
        :binary_wrapper
      end

      def run_mode
        :run_mode
      end
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

  def test_new_param
    p = mock
    p.expects(:match?).with(:binary_wrapper, :run_mode).returns(true)
    klass = mock
    klass.expects(:new).with(:name, :desc, :binary_matcher,
                            :current_group, :current_modes,
                            :current_parent, {options:''}).returns(p)
    dh = dsl_helpered
    dh.expects(:current_modes).returns(:current_modes)
    dh.expects(:current_group).returns(:current_group)
    dh.expects(:current_parent).returns(:current_parent)
    parameters = mock
    parameters.expects(:<<).with(p)
    dh.expects(:parameters).returns(parameters)
    dh.expects(:eval_sub_params).never
    dh.send(:new_param, klass, :name, :desc, :clients, {options:''})
  end

  def test_new_param_with_subparameters_block
    p = mock
    p.expects(:match?).with(:binary_wrapper, :run_mode).returns(true)
    klass = mock
    klass.expects(:new).with(:name, :desc, :binary_matcher,
                            :current_group, :current_modes,
                            :current_parent, {options:''}).returns(p)
    dh = dsl_helpered
    dh.expects(:current_modes).returns(:current_modes)
    dh.expects(:current_group).returns(:current_group)
    dh.expects(:current_parent).returns(:current_parent)
    parameters = mock
    parameters.expects(:<<).with(p)
    dh.expects(:parameters).returns(parameters)
    zonde = {}
    dh.expects(:eval_sub_params).with(p).yields(zonde)
    dh.send(:new_param, klass, :name, :desc, :binary_matcher, {options:''}) do |z|
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

  def test_new_binary_matcher_with_clients
    skip
  end

  def test_new_binary_matcher_without_clients
    skip
  end

  def test_from_version
    skip
  end

  def test_to_version
    skip
  end

  def test_to_current_version
    skip
  end

  def test_from_current_version
    skip
  end

  def test_current_version
    skip
  end

  def test_eneterprise_verions
    skip
  end

  def test_get_parameters
    skip
  end

  def test_restrict_parameter_from_version
    skip
  end

  def test_restrict_params
    skip
  end

  def test_add_parameter
    skip
  end
end
