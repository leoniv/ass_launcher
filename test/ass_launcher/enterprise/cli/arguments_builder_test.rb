require 'test_helper'

class ArgumentsBuilderTest < Minitest::Test
  def test_fail
    fail 'FIXME'
  end

  def test_defined_parameters_FIXME
    fail 'FIXME'
    cli_spec = mock
    cli_spec.quacks_like(cli_spec_stub.new)
    cli_spec.expects(:parameters).returns(:defined_arguments)
    inst = inst_
    inst.expects(:cli_spec).with(:run_mode).returns(cli_spec)
    assert_equal :defined_arguments, inst.send(:defined_parameters, :run_mode)
  end

end
