require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

Rake::TestTask.new(:run_examples) do |t|
  exec_ole = RbConfig::CONFIG['host_os'].downcase =~ %r{mingw|mswin|cygwin}
  t.libs << 'examples'
  t.libs << 'lib'
  examples = FileList['examples/**/*_example.rb']
  if exec_ole
    t.test_files = examples - examples.grep(%r{troubles/}i)
  else
    t.test_files = examples - examples.grep(%r{troubles/|enterprise_ole_example}i)
  end
end

Rake::TestTask.new(:run_trouble_examples) do |t|
  t.libs << 'examples'
  t.libs << 'lib'
  examples = FileList['examples/**/*_example.rb']
  t.test_files = examples.grep(%r{trouble}i)
end

task :default => :test
