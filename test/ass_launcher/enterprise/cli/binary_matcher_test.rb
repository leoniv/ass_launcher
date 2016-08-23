require 'test_helper'

class TestBinaryMatcher < Minitest::Test
  def cls
    AssLauncher::Enterprise::Cli::BinaryMatcher
  end

  def test_initialize
    inst = cls.new(:client, '> 12')
    assert_instance_of Gem::Requirement, inst.requirement
    assert_equal :client, inst.client
  end

  def test_initialize_def
    inst = cls.new()
    assert_equal '>= 0', inst.requirement.to_s
    assert_equal :all, inst.client
  end

  def test_match_version?
    inst = cls.new
    requirement = mock
    requirement.expects(:satisfied_by?).with(:version_stub).returns(:match)
    inst.expects(:requirement).returns(requirement)
    bw = mock
    bw.expects(:version).returns(:version_stub)
    assert_equal :match, inst.send(:match_version?, bw)
  end

  def test_match_client?
    inst = cls.new
    assert inst.send(:match_client?,:bw)
    inst = cls.new(:fake)
    class_ = mock
    class_.expects(:name).returns('FakeClient')
    bw = mock
    bw.expects(:class).returns(class_)
    assert inst.send(:match_client?, bw)
  end

  def test_not_match_client?
    inst = cls.new
    assert inst.send(:match_client?,:bw)
    inst = cls.new(:fake)
    class_ = mock
    class_.expects(:name).returns('NotClientClient')
    bw = mock
    bw.expects(:class).returns(class_)
    refute inst.send(:match_client?, bw)
  end

  def test_match?
    inst = cls.new
    inst.expects(:match_client?).with(:bw).returns(true)
    inst.expects(:match_version?).with(:bw).returns(true)
    assert inst.match?(:bw)
  end

  def test_not_match?
    inst = cls.new
    inst.expects(:match_client?).with(:bw).returns(true)
    inst.expects(:match_version?).with(:bw).returns(false)
    refute inst.match?(:bw)
  end
end
