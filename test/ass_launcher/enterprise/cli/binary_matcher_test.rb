require 'test_helper'

class TestBinaryMatcher < Minitest::Test
  def cls
    AssLauncher::Enterprise::Cli::BinaryMatcher
  end

  def test_modes_for
    expects = { web: [:webclient],
     thick: [:createinfobase, :enterprise, :designer],
     thin: [:enterprise] }
    assert_equal expects, cls.send(:modes_for)
  end

  def test_auto
    cls.expects(:auto_client).with(:run_modes).returns(:client)
    cls.expects(:new).with(:client, :version).returns(:matcher)
    assert_equal :matcher, cls.auto(:run_modes, :version)
  end

  def test_auto_client
    cls.expects(:satisfied?).with(:modes, :web).returns(true)
    cls.expects(:satisfied?).with(:modes, :thick).returns(false)
    cls.expects(:satisfied?).with(:modes, :thin).returns(true)
    assert_equal [:web, :thin], cls.send(:auto_client, :modes)
  end

  def test_satisfied?
    assert cls.send(:satisfied?, [:webclient, :enterprise], :web)
    assert cls.send(:satisfied?, [:webclient, :enterprise], :thin)
    assert cls.send(:satisfied?, [:webclient, :enterprise], :thick)

    assert cls.send(:satisfied?, [:webclient], :web)
    refute cls.send(:satisfied?, [:webclient], :thick)
    refute cls.send(:satisfied?, [:webclient], :thin)

    assert cls.send(:satisfied?, [:designer], :thick)
    refute cls.send(:satisfied?, [:designer], :web)
    refute cls.send(:satisfied?, [:designer], :thin)
  end

  def all_clients
    [:thick, :thin, :web]
  end

  def test_const
    assert_equal all_clients, AssLauncher::Enterprise::Cli::BinaryMatcher::ALL_CLIENTS
  end

  def test_initialize
    inst = cls.new(:client, '> 12')
    assert_instance_of Gem::Requirement, inst.requirement
    assert_equal :client, inst.clients
  end

  def test_initialize_def
    inst = cls.new()
    assert_equal '>= 0', inst.requirement.to_s
    assert_equal all_clients, inst.clients
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
    array = mock
    array.expects(:include?).with(:fake).returns(true)
    inst = cls.new
    inst.expects(:clients).returns(array)
    class_ = mock
    class_.expects(:name).returns('FakeClient')
    bw = mock
    bw.expects(:class).returns(class_)
    assert inst.send(:match_client?, bw)
  end

  def test_not_match_client?
    array = mock
    array.expects(:include?).with(:fake).returns(false)
    inst = cls.new
    inst.expects(:clients).returns(array)
    class_ = mock
    class_.expects(:name).returns('FakeClient')
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

  def test_attr_writer
    inst = cls.new
    assert_raises ArgumentError do
      inst.requirement = :requirement
    end
    expected = Gem::Version::Requirement.new('~> 9999')
    inst.requirement = expected
    assert_equal expected, inst.requirement
  end
end
