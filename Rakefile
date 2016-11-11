require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

Rake::TestTask.new(:run_examples) do |t|
  t.libs << 'examples'
  t.libs << 'lib'
  examples = FileList['examples/**/*_example.rb']
  t.test_files = examples - examples.grep(%r{trouble}i)
end

Rake::TestTask.new(:run_trouble_examples) do |t|
  t.libs << 'examples'
  t.libs << 'lib'
  examples = FileList['examples/**/*_example.rb']
  t.test_files = examples.grep(%r{trouble}i)
end

task :default => :test
