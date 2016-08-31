require 'test_helper'

class DefsLoaderTest < Minitest::Test
  require 'ass_launcher/enterprise/cli_defs_loader'
  attr_reader :mod
  def setup
    @mod = Module.new do
      extend AssLauncher::Enterprise::CliDefsLoader
    end
  end

  def test_const
    assert_equal File.expand_path('../../../../lib/ass_launcher/enterprise/cli_def',
                                 __FILE__),
      AssLauncher::Enterprise::CliDefsLoader::DEFS_PATH
  end

  def test_version_from_file_name
    assert_equal Gem::Version.new('8.2.15'),
      mod.send(:version_from_file_name,'path/to/files/8.2.15.rb')
  end

  def test_defs_versions
    files = %w{2.3.5 3.6.7 2.4.3}
    expects = files.map do |f|
      Gem::Version.new(f)
    end
    Dir.expects(:glob)
      .with(File.join(AssLauncher::Enterprise::CliDefsLoader::DEFS_PATH, '*.rb'))
      .returns(files)
    assert_equal expects.sort, mod.send(:defs_versions)
  end

  def test_loaded_def
    mod.expects(:require)\
      .with(File.join(AssLauncher::Enterprise::CliDefsLoader::DEFS_PATH, 'v.v.v'))\
      .times(3)
    expect = []
    3.times do
      expect << 'v.v.v'
      mod.send(:load_def, 'v.v.v')
    end
    assert_equal expect, mod.instance_variable_get(:@loaded_defs)
  end

  def test_load_defs
    sorted = sequence('sorted')
    mod.expects(:defs_versions).returns([2,1,3])
    mod.expects(:enterprise_version).in_sequence(sorted).with(1)
    mod.expects(:load_def).in_sequence(sorted).with(1)
    mod.expects(:enterprise_version).in_sequence(sorted).with(2)
    mod.expects(:load_def).in_sequence(sorted).with(2)
    mod.expects(:enterprise_version).in_sequence(sorted).with(3)
    mod.expects(:load_def).in_sequence(sorted).with(3)
    assert_equal [1,2,3], mod.send(:load_defs)
  end
end
